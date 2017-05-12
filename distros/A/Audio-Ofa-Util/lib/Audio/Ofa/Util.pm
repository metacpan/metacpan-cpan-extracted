package Audio::Ofa::Util;
use strict;
use warnings;
use Audio::Ofa qw(OFA_LITTLE_ENDIAN ofa_create_print);
use Audio::Extract::PCM;
use Carp;
use LWP::UserAgent;
use XML::Simple;
use Time::HiRes;
use base qw(Class::Accessor::Fast);

our $VERSION = '0.04';


=head1 NAME

Audio::Ofa::Util - Retrieve audio fingerprints and metadata for unknown audio files

=head1 SYNOPSIS

This module tries to make retrieving audio fingerprints and metadata for
unknown audio files as easy as possible.  It interfaces with the modules
L<Audio::Ofa> and L<WebService::MusicBrainz>, provides a simple L<LWP> based
interface to the MusicDNS library, and can make use of L<Audio::Extract::PCM> to
read some popular music formats.

The most comprehensive way to use this is to start with a (possibly untagged)
file name and get full metadata:

    my $util = Audio::Ofa::Util->new(filename => 'song.ogg');
    my @tracks = $util->musicbrainz_lookup or die $util->error;
    for (@tracks) {
        print 'Artist: ', $_->artist, "\n";
        print 'Title:  ', $_->title, "\n";
        print 'Track:  ', $_->track, "\n";
        print 'Album:  ', $_->album, "\n\n";
    }

To create an audio fingerprint:

    my $util = Audio::Ofa::Util->new(filename => 'song.ogg');
    $util->analyze_file or die $util->error;
    print $util->fingerprint, "\n";

To create a fingerprint B<and> look it up at MusicDNS:

    my $util = Audio::Ofa::Util->new(filename => 'song.ogg');
    $util->musicdns_lookup or die $util->error; # calls analyze_file implicitly
    print $util->artist, ' - ', $util->title, "\n";

To look up a known fingerprint at MusicDNS (you need the length of the song, too):

    my $util = Audio::Ofa::Util->new(fingerprint => $fp, duration => $millisecs);

The overall process goes like this:

=over 8

=item *

We create an audio fingerprint, which stores some characteristics of a
recording in a rather small amount of data.  This is what libofa (and the Perl
binding in L<Audio::Ofa>) does.  This module (L<Audio::Ofa::Util>) faciliates
this with L</analyze_file> by allowing to fingerprint some widely used music
formats and storing the results so they can be used for the next steps:

=item *

The audio fingerprint is submitted to the MusicDNS web service.  Using a
proprietary fuzzy algorithm and their database, they determine which song we
have at hand.  MusicDNS returns B<some> metadeta: The artist, the song title,
and a PUID.  This "portable unique identifier" is an arbitrary index into their
database and is unique for every recording of a given song.

Note that while libofa's audio fingerprints may change after transformations of
a recording (such as lossy audio compression or radio transmission), the fuzzy
algorithm will (ideally) still find the same PUID.

=item *

Because we usually want to know more than the artist and title, we look up the
PUID in a second Web Database called MusicBrainz.  It provides us with all
desired metadata such as all the albums the song has appeared on in this
particular version, and the respective track numbers.

This module provides a basic MusicBrainz PUID lookup through
L</musicbrainz_lookup>.  If you want to know even more (such as members of the
band and the previous bands of those members), you can use
L<WebService::MusicBrainz>, to which this module provides an easy frontend.

=back

=cut


my %musicdns_parameters = (
    client_id      => ['cid', 'c44f70e49000dd7c0d1388bff2bf4152'],
    client_version => ['cvr', __PACKAGE__ . '-' . __PACKAGE__->VERSION],
    fingerprint    => ['fpt', undef],
    metadata       => ['rmd', 1],
    bitrate        => ['brt', 0],
    extension      => ['fmt', 'unknown'],
    duration       => ['dur', undef],
    artist         => ['art', 'unknown'],
    title          => ['ttl', 'unknown'],
    album          => ['alb', 'unknown'],
    track          => ['tnm', 0],
    genre          => ['gnr', 'unknown'],
    year           => ['yrr', 0],
    #encoding       => ["enc=%s", undef],       // Encoding. e = true: ISO-8859-15; e = false: UTF-8 (default). Optional.
);



my %fields;
@fields{'filename', 'puids', 'error', keys %musicdns_parameters} = ();

__PACKAGE__->mk_accessors(keys %fields);


=head1 ACCESSORS

=head2 filename

See L</analyze_file>.

=head2 fingerprint, duration

See L</analyze_file> and L</musicdns_lookup>.

=head2 client_id, client_version, metadata, bitrate, extension, artist, title,
album, track, genre, year, puids

See L</musicdns_lookup>.

Note that puids accesses an array reference.  If it is not defined or not set,
it means that no PUID has been looked up yet.  If it is an empty array, it
means that no PUIDs were found.

=head2 error

Description of the last error that happened.


=head1 METHODS

=head2 new

Constructor.  Accepts key-value pairs as initializers for all of the fields,
c.f. L</ACCESSORS>, but currently only the following calls make sense:

    Audio::Ofa::Util->new(filename => $filename);
    Audio::Ofa::Util->new(fingerprint => $fp, duration => $dur);
    Audio::Ofa::Util->new(puid => $puid);

=cut

sub new {
    my $class = shift;

    my (%args) = @_;
    for my $key (keys %args) {
        croak "Bad key $key" unless exists $fields{$key};
        if ('puids' eq $key && 'ARRAY' ne ref $args{$key}) {
            croak 'puids: Array expected';
        }
    }

    return bless \%args, $class;
}


use constant FREQ => 44100;


=head2 analyze_file

This creates an Audio Fingerprint of a sound file.  The audio file is read
using L<Audio::Extract::PCM>, which currently uses the extarnal "sox" program
and supports encodings such as MP3, Ogg/Vorbis and many others.

You must set C<filename> before calling this method.

The fingerprint is calculated by L<Audio::Ofa / ofa_create_print>, and the
C<fingerprint> field of the object will be set.
Additionally, the C<duration> (in milliseconds) and the C<extension> will be
set to the values provided by the file name.

In case of an error, an empty list is returned and the error message can be
retrieved via L</error>.  Otherwise, a true value will be returned.

=cut


sub analyze_file {
    my $this = shift;

    my $fn = $this->filename;
    croak 'No filename given' unless defined $fn;

    use bytes;

    my $extractor = Audio::Extract::PCM->new($fn);
    my $pcm = $extractor->pcm(FREQ, 2, 2);

    unless (defined $pcm) {
        $this->error('Could not extract audio data: ' . $extractor->error);
        return ();
    }

    my $duration = int (1000 * length($$pcm) / (2*2) / FREQ); # 2 channels, 2 bytes per sample

    # Fingerprinting only uses the first 135 seconds; we throw away the rest.
    # Certainly it would be more efficient to instruct sox not to generate more
    # than 135 seconds; however we need the rest to calculate the duration.
    # Unless I find a possibility to find out the duration from as many file
    # formats as sox supports, I will probably use this unefficient solution.
    # It's just a matter of Pink Floyd vs. Ramones.
    my $s135 = (2*2)*FREQ*135;
    substr($$pcm, $s135, length($$pcm)-$s135, '') if $s135 < length($$pcm);

    # This is usually the same, but "use bytes" has no effect here.
    # substr($pcm, $s135) = '' if length($pcm) > $s135;

    my $fp = ofa_create_print($$pcm, OFA_LITTLE_ENDIAN, length($$pcm)/2, FREQ, 1);
    undef $$pcm;
    unless ($fp) {
        $this->error("Fingerprint could not be calculated");
        return ();
    }

    my ($extension) = $fn =~ /^\.([a-z0-9])\z/i;

    $this->fingerprint($fp);
    $this->duration($duration);
    $this->extension($extension);
    
    return 1;
}


=head2 musicdns_lookup

This looks up a track at the MusicDNS web service.

To do a fingerprint lookup, the keys C<fingerprint> and C<duration> must be
present, where duration is the length of the song in milli seconds.
Additionally, the following fields (defaults in parentheses) will be sent to
the MusicDNS service:

client_id (hardcoded client id), client_version (module name and version),
fingerprint, metadata (1), bitrate (0), extension ("unknown"), duration, artist
("unknown"), title ("unknown"), album ("unknown"), track (0), genre
("unknown"), year (0).

To do a fingerprint lookup, C<fingerprint> and C<duration> must have been set
(can be given to L</new>), where C<duration> is the song length in milli
seconds.

If C<fingerprint> hasn't been set, L</analyze_file> is called implicitly.

client_id defaults to a hard-coded Client ID.  You can get your own from
http://www.musicip.com.

You should set as much of the above-mentioned metadata (like artist, etc.) as
you have available, because the MusicDNS terms of service require this in order
to help clean errors in their database.

In the case of an error, C<musicdns_lookup> returns an empty list and the error
message can be retrieved with the L</error> method.

In the case of success, C<musicdns_lookup> sets the fields C<puids> to the
found PUIDs, and sets the fields C<artist> and C<title> to the first of the
found values, and returns a true value.  In list context, it returns a list of
objects which have C<artist>, C<title> and C<puid> methods.

=cut


sub musicdns_lookup {
    my $this = shift;

    if (defined $this->fingerprint) {
        unless (defined $this->duration) {
            croak 'Fingerprint was given but duration wasn\'t';
        }
    } else {
        $this->analyze_file or return ();
    }

    my %req_params;

    while (my ($key, $val) = each %musicdns_parameters) {
        my ($param, $default) = @$val;

        if (defined $this->$key()) {
            $req_params{$param} = $this->$key();

        } elsif (defined $default) {
            $req_params{$param} = $default;
        }
    }
    utf8::encode($_) for values %req_params;
    
    my $url = 'http://ofa.musicdns.org/ofa/1/track';
    my $ua = LWP::UserAgent->new;
    $ua->env_proxy;

    #use Data::Dumper;
    #warn Dumper \%req_params;

    my $response = $ua->post($url, \%req_params);

    unless ($response->is_success) {
        $this->error('Server says ' . $response->status_line);
        return ();
    }

    unless ('text/xml' eq $response->header('Content-Type')) {
        $this->error('Unexpected content type: ' . $response->header('Content-Type'));
        return ();
    }

    unless (defined $response->content) {
        $this->error('No content');
        return ();
    }

    my $xml = XMLin($response->content, ForceArray => ['track', 'puid']);

    # warn Dumper $xml;

    my @return = map {
        +{
            title => $_->{title},
            artist => $_->{artist}{name},
            puids => [keys %{$_->{'puid-list'}{puid}}],
        };
    } @{$xml->{track}};

    $this->error('No tracks returned') unless @return;

    $this->puids([map @{$_->{puids}}, @return]);
    $this->title($return[0]{title});
    $this->artist($return[0]{artist});

    if (wantarray) {
        return map Audio::Ofa::Util::Metadata->new(
            $_->{artist}, $_->{title}, $_->{puids}[0]
        ), @return;
    } else {
        return 1;
    }
}


=head2 musicbrainz_lookup

This looks up a PUID at MusicBrainz.  The PUID can come from a call to
L</musicdns_lookup>.  In fact this is implicitly done if there is no PUID
stored in the object (cf. L</SYNOPSIS>).

This returns a list of L<WebService::MusicBrainz::Response::Track> objects on
success, or the first of them in scalar context.
Otherwise it returns an empty list and the error message can be retrieved via
the L</error> method.

This method returns a list of tracks or the first track in scalar context.  The
tracks are represented as objects that are guaranteed to have the methods
C<artist>, C<title>, C<album>, C<track> and C<wsres>, where the latter is an
L<WebService::MusicBrainz::Response::Track> object, and the four former return
values that have been retrieved from that object for your convenience.

In the case of an error, an empty list is returned and the error can be
returned via the L</error> method.

=cut


# MusicBrainz demands that we not look up more often than once a second.
my $last_mb_lookup = 0;


sub musicbrainz_lookup {
    my $this = shift;
    my (%args) = @_;

    require WebService::MusicBrainz::Track;

    unless ($this->puids) {
        $this->musicdns_lookup or return ();
    }
    my @puids = @{ $this->puids };

    my @tracks;
    my $searcherror;

    for my $puid (@puids) {

        my $next_lookup_in = $last_mb_lookup + 1 - Time::HiRes::time();
        if ($next_lookup_in > 0 && $next_lookup_in < 1) {
            Time::HiRes::sleep($next_lookup_in);
        }
        $last_mb_lookup = Time::HiRes::time();

        my $ws = WebService::MusicBrainz::Track->new();

        local $@;
        local $SIG{__DIE__};

        my $resp = eval { $ws->search({ PUID => $puid }) };

        unless ($resp && $resp->track_list) {
            if ($@) {
                # search throws exception e.g. for "503 Service Temporarily
                # Unavailable" errors
                $this->error("$@");
                return ();
            }

            $searcherror = 'search failed';
            next;
        }

        push @tracks, $resp->track_list;
    }

    unless (@tracks) {
        $this->error($searcherror || 'no tracks were returned');
    }

    $_ = Audio::Ofa::Util::Metadata->new($_) for @tracks;

    return wantarray ? @tracks : $tracks[0];
}


package # hide from PAUSE
    Audio::Ofa::Util::Metadata;
use strict;
use warnings;
use base qw(Class::Accessor::Fast);
__PACKAGE__->mk_accessors(qw(title artist album track wsres puid));

sub new {
    my $class = shift;
    my $this = bless {}, $class;

    if (@_ == 1) {
        my ($ws_track) = @_; # should be a WebService::MusicBrainz::Response::Track object

        $this->artist($ws_track->artist->name);
        $this->title($ws_track->title);
        $this->track(($ws_track->release_list->releases->[0]->track_list->offset || 0) + 1);
        $this->album($ws_track->release_list->releases->[0]->title);
        $this->wsres($ws_track);
    } else {
        my ($artist, $title, $puid) = @_;

        $this->artist($artist);
        $this->title($title);
        $this->puid($puid);
    }

    return $this;
}


1;

__END__

=head1 SEE ALSO

=over 8

=item *

L<MusicBrainz::Client> - A client for the old MusicBrainz web service

=item *

L<MusicBrainz::TRM> - Obsolete TRM-based audio fingerprinting library

=item *

tunepimp - C library which does pretty much everything that this module does.
It even includes Perl bindings, but as of this writing, they don't compile in
the current tunepimp version and only support the old TRM fingerprints.

=item *

L<http://www.musicdns.org> - Web site of the MusicDNS web service as provided by MusicIP

=item *

L<http://www.musicbrainz.org> - Web site of MusicBrainz

=item *

L<http://wiki.musicbrainz.org/HowPUIDsWork> - How PUIDs work

=back

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License (GPL) as published by the Free
Software Foundation (http://www.fsf.org/); either version 2 of the License, or
(at your option) any later version.

The GPL, which is quite restrictive (when compared to LGPL or Artistic), seems
to be necessary because of libofa's licenses, but IANAL and if you need a
license change please contact me.

B<Please note> that in addition to the license which allows you to use this
software, the MusicDNS web service has its own terms of service.  The most
important fact is that you can use it for free B<unless> you use it
commercially.  See L<http://www.musicdns.org> for more information.  You are
encouraged to register your own client id (for free) if you build a client on
top of this module.

=head1 AUTHOR

Christoph Bussenius (pepe at cpan.org)

Please mention the module's name in the subject of your mails so that they will
not be lost in the spam.

If you find this module useful I'll be glad if you drop me a note.

=cut
