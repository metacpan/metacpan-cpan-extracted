# Copyright (c) 2023-2025 Löwenfelsen UG (haftungsbeschränkt)
# Copyright (c) 2023-2025 Philipp Schafft

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: Extractor for identifiers from URIs

package Data::URIID;

use v5.10;
use strict;
use warnings;

use Carp;
use URI;
use LWP::UserAgent;
use Scalar::Util qw(blessed);
use I18N::LangTags;
use I18N::LangTags::Detect;

use Data::URIID::Result;
use Data::URIID::Service;

our $VERSION = v0.12;

my %names = (
    service => {
        'wikidata'          => '198bc92a-be09-42d2-bf96-20a177294b79',
        'fellig'            => '43e7f8fe-2b90-4a5d-88e2-b1d46856d942',
        'youtube'           => 'de49b663-ff54-428b-ac56-d1950fb3cec7',
        'youtube-nocookie'  => 'c7acc624-de92-4480-8a21-31186e8bef54',
        'dropbox'           => 'f8022569-fdc0-4922-8a95-3de51be087aa',
        '0wx'               => 'b279726c-a349-4d87-b87c-929319a20b3e',
        'e621'              => '9bde88c4-1784-4756-b009-6111b4a69f96',
        'dnb'               => '1c5eb5fb-3f2a-4a5a-9b28-9fba163873a0',
        'britishmuseum'     => 'ac0cad64-4bf2-4924-a855-bc4147f6cdb3',
        'musicbrainz'       => 'fcb39c86-34f6-481c-9bb7-63c4a7c2256b',
        'wikimedia-commons' => 'a283b6cb-c8c5-4b5d-8a58-e0327e087e50',
        'wikipedia'         => '1262f7fe-2d98-42aa-9ed5-5cc5182fc4f4',
        'noembed.com'       => '66c2ac78-936b-4241-b041-567080db3f6a',
        'osm'               => 'fdb14a39-f175-4aba-bcec-53c4683b72bd',
        'overpass'          => '5350885e-92f5-4aee-b72e-dd9d95c6700a',
        'xkcd'              => '6d90e7e2-c193-4e96-8d0a-c9a3d42beecf',
        'Data::URIID'       => '65a5000f-c37f-4fa1-9ad0-c9682fcd8756',
        'Data::Identifier'  => '1d1e84e9-dac5-43d6-9ff9-a72fb7de38d5',
        'viaf'              => 'b542f123-b304-4f60-a2a9-15a0cc62e25d',
        'europeana'         => '2ddf371f-20b5-4fdb-99d5-934b212ed596',
        'open-library'      => '173f7237-9ca0-490d-8a98-6a04c386769a',
        'ngv'               => '01aa1e39-6d90-41c6-a010-f3850844f2e1',
        'geonames'          => '2860d918-ac49-42a1-818d-68abd84972b3',
        'find-a-grave'      => '30deaf5b-470b-46da-8af1-6e5174d0eaf4',
        'nla'               => '0715561c-0189-4c1f-99bf-21cc6746f5ee', # National Library of Australia
        'agsa'              => 'a61dda0f-b914-496a-b473-2a333b9f0f9f', # Art Gallery of South Australia
        'amc'               => 'fec16f49-a9fe-4d89-bad2-7dbb44860e83', # Australian Music Centre
        'a-p-and-p'         => '91a4981f-c1c7-4136-9e2f-39f2cd2eda7f', # Australian Prints + Printmaking
        'tww'               => 'aafdcd22-828b-413e-be0c-ed9a92d941db', # The Watercolour World
        'factgrid'          => '9a6b8382-c004-458a-bf2a-68f03d863282', # FactGrid
        'grove-art-online'  => 'be8b12e5-b32d-4b89-9301-84827a79589e', # Grove Art Online
        'wikitree'          => '70b9de08-2b73-4c0d-91d2-e89561cf94d2', # WikiTree
        'doi'               => '60387716-fa98-4c92-ae2b-7f4496d6f9be', # doi.org
        'iconclass'         => '75cbefbb-e622-4b72-9829-348f3986d709', # iconclass.org
        'iana'              => 'f11657cc-95da-4eae-95fc-62d16fecf473', # iana.org
        'uriid'             => '772aa1ed-9a3a-4806-94a1-42cbc0e9f962', # uriid.org
        'oidref'            => 'b5a63482-f92c-4ed5-8ec3-49caa0bafa66', # oidref.com
        'furaffinity'       => '978a4622-2a87-4c67-b9bf-c1b1e5d69b05',
        'imgur'             => 'e6c5f855-221a-4c48-9f31-cf0a852140da', # imgur.com
    },
    type => {
        'uuid'                          => '8be115d2-dc2f-4a98-91e1-a6e3075cbc31',
        'oid'                           => 'd08dc905-bbf6-4183-b219-67723c3c8374',
        'uri'                           => 'a8d1637d-af19-49e9-9ef8-6bc1fbcf6439',
        'tagname'                       => 'bfae7574-3dae-425d-89b1-9c087c140c23',
        'wikidata-identifier'           => 'ce7aae1e-a210-4214-926a-0ebca56d77e3',
        'musicbrainz-identifier'        => '95bd826b-bd3e-4b40-b16a-aa20c9f673e4', # P434, P435, P436, P966, P982, P1004, P1330, P1407, P4404, P5813, P6423, and P8052
        'british-museum-term'           => '310776dc-1433-4623-9ffa-42d038d400a4', # P1711 (special)!
        'gnd-identifier'                => '893a7d5c-124c-4ad6-9a56-0ea8be50b536', # P227
        'fellig-box-number'             => 'c036d4d9-d983-4322-917c-acbf6133df64',
        'fellig-identifier'             => '90ecb0c5-f99a-4702-8575-430247de8f48',
        'youtube-video-identifier'      => '0d88a8f0-0fce-41ae-beef-88d74d83eb32', # P1651
        'e621tagtype'                   => 'da72fa90-5990-46b4-b4ca-05eaf68170a5',
        'wikimedia-commons-identifier'  => 'a6b1a981-48a0-445e-adc7-11df14e91769',
        'e621-post-identifier'          => '4a7fc2e2-854b-42ec-b24f-c7fece371865',
        'osm-node'                      => '6c09afad-0109-4a05-a430-f3bdade19c24',
        'osm-way'                       => '01da1735-25b3-4560-9c8c-186e42dd8904',
        'osm-relation'                  => 'bdd9b297-e0a8-427e-8487-83f600226f5b',
        'xkcd-num'                      => '943315e7-9efd-41df-b3f5-4a42b93df46d',
        'factgrid-identifier'           => 'd576b9d1-47d4-43ae-b7ec-bbea1fe009ba', # P8168 and P10787
        'viaf-identifier'               => '685c7871-2965-4f0a-ac63-d6bacd1e575e', # P214
        'open-library-identifier'       => '435f6b8c-cae4-4dcf-816a-1225fc35108f', # P3847
        'unesco-thesaurus-identifier'   => '3ff707af-1f72-4e1f-a81b-7871fb6079e1', # P3916
        'isni'                          => 'a6de24d2-95a2-4577-870c-31ad10339f22', # P213
        'aev-identifier'                => 'e9c13254-831f-474c-8881-31012ca45a72', # P7033
        'europeana-entity-identifier'   => 'a1cffa6b-6b78-4b11-9a6c-3673ec25c489', # P7704
        'ngv-artist-identifier'         => '8fb7807b-c15a-4ae1-8f15-4b3d8e4f5cef', # P2041
        'ngv-artwork-identifier'        => '4d25c32b-a169-40f5-be88-3d609b7d05ff', # P4684
        'geonames-identifier'           => '02e34fcc-cf5e-445a-ba54-bf6df8ae036a', # P1566
        'find-a-grave-identifier'       => '39ea7c88-3fc2-4a01-89f9-547f451764f7', # P535
        'libraries-australia-identifier'=> '22a80a6d-0c69-41f5-b5be-6c889f8e601b', # P409
        'agsa-creator-identifier'       => 'fb3bac19-7d4e-4995-9ef0-08dbcea7f340', # P6804
        'amc-artist-identifier'         => '0b907ca8-a84f-4780-b708-910a858228a8', # P9575
        'a-p-and-p-artist-identifier'   => '5bafcbd4-5fcf-4823-848f-7eab8175a80c', # P10086
        'nla-trove-people-identifier'   => '0edc2854-37bf-4562-a05b-ac4113ead938', # P1315
        'tww-artist-identifier'         => 'b49d88ba-1b61-4f13-b5c9-73a09ffb2b3f', # P6735
        'grove-art-online-identifier'   => '80c548f6-4d23-43c1-ab50-b4546319c752', # P8406
        'wikitree-person-identifier'    => 'a6f7d17a-ced2-4cf7-8ce7-fcb4a98f7aa0', # P2949
        'doi'                           => '931f155e-5a24-499b-9fbb-ed4efefe27fe', # P356
        'iconclass-identifier'          => '241348a8-c5d0-4473-9ec1-de7c2ba00fbb', # P1256
        'media-subtype-identifier'      => 'c1166bf7-c4ab-40ad-9a92-a55103bec509', # P1163, commonly also called media-type or mime-type.
        'gtin'                          => '82d529be-0f00-4b4f-a43f-4a22de5f5312',
        'small-identifier'              => 'f87a38cb-fd13-4e15-866c-e49901adbec5',
        'language-tag-identifier'       => 'd0a4c6e2-ce2f-4d4c-b079-60065ac681f1',
        'chat-0-word-identifier'        => '2c7e15ed-aa2f-4e2f-9a1d-64df0c85875a',
        'furaffinity-post-identifier'   => 'b8dd10ec-d46b-4316-b3f3-2bc28cff9d35',
        'imgur-post-identifier'         => 'f2425e42-0083-4205-aa0b-2005f1fa62a3',
    },
    action => {
        #What about: search/lookup? list? content?

        # Human readable:
        'documentation' => 'b75354b2-a43b-44d9-99d5-9c0ec4fa5287',
        'manage'        => '01fc3e42-7b5c-403e-94fb-a4fa7990c0ed',
        'render'        => 'b608ad23-e61a-4ab3-a1ca-f3f4e269b03b', # for display (of a work)
        'embed'         => '0fecb446-89a9-4b0c-a7db-e83b5acec419',
        'info'          => '478bc202-51ac-4c5e-9f9a-38e233a42dfb', # like metadata just human readable
        'edit'          => 'e775b770-90eb-4b2f-9b78-26021688722d',
        # Machine readable:
        'fetch'         => '4ab02627-c452-4f4e-a9c0-4bde8f1e6b0e',
        'file-fetch'    => 'a3b66e23-15f2-4bc6-b22e-8f072ba839e7',
        'stream-fetch'  => '4060a966-9fae-4d43-9006-2288b58afabb',
        'metadata'      => '6f1c921b-e0bb-4449-911f-a00719e91a1e',
    },
);

my %service_lists = (
    ALL         => [keys %{$names{service}}],
    LOCAL       => [qw(Data::URIID Data::Identifier)],
    REMOTE      => [qw(wikidata factgrid wikimedia-commons fellig noembed.com osm overpass xkcd doi iconclass e621 furaffinity imgur)],

    wmf         => [qw(wikidata wikimedia-commons wikipedia)],
    osm         => [qw(osm overpass)],

    friendly    => [qw(fellig uriid)],
    uafriendly  => [qw(@friendly)],
);

# Inverse of %names:
my %ises;

foreach my $class (keys %names) {
    $ises{$class} = {
        map {$names{$class}{$_} => $_} keys %{$names{$class}}
    };
}

{
    my $found;
    do {
        $found = undef;

        foreach my $content (values %service_lists) {
            my @newlist;

            foreach my $entry (@{$content}) {
                if ($entry =~ /^\@(.+)$/) {
                    push(@newlist, @{$service_lists{$1}});
                    $found = 1;
                } else {
                    push(@newlist, $entry);
                }
            }

            @{$content} = @newlist;
        }
    } while ($found);
}



sub new {
    my ($pkg, %opts) = @_;
    my $self = bless \%opts, $pkg;

    if (defined(my $services_online = delete $self->{services_online})) {
        foreach my $service_name ($self->match_services($services_online)) {
            $self->service($service_name)->online(1);
        }
    }

    return $self;
}


#@returns Data::URIID::Result
sub lookup {
    my ($self, $type, $uri) = @_;

    # Note: We use 'auto' as default and try to figure out of it's an ISE or an URI.

    # Shuffle arguments if the two argument form is used.
    if (scalar(@_) == 2) {
        ($type, $uri) = ('auto' => $type);
    }

    croak 'Passed undef as URI' unless defined $uri;

    if (blessed($uri) && !$uri->isa('URI')) {
        if ($uri->isa('Data::URIID::Result')) {
            $uri = $uri->url;
        } elsif ($uri->isa('Data::Identifier')) {
            $type = $uri->type->uuid;
            $uri  = $uri->id;
        } elsif (index(blessed($uri), __PACKAGE__) == 0 && $uri->can('ise')) {
            ($type, $uri) = (ise => $uri->ise);
        } elsif ($uri->isa('Mojo::URL')) {
            $uri = URI->new("$uri"); # convert to URI as per documentation of Mojo::URL
        } else {
            croak 'Invalid type of object passed';
        }
    }

    unless (blessed $uri) {
        if (ref $type) {
            my URI $u;

            if ($type->isa('URI')) {
                $type = $self->lookup($type);
            }

            $type = $type->ise;
            $u = URI->new('https://uriid.org/');
            $u->path_segments('', $type, $uri);
            $uri = $u;
        } else {

            if ($type eq 'qrcode') {
                # Bit more relaxed URLs...
                $uri =~ s#^www\.#https://www.#; # Try to add missing protocol.
                $type = 'auto';
            }

            if ($type eq 'auto' || $type eq 'ise') {
                if ($uri =~ /^[0-9a-fA-F]{8}-(?:[0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$/) {
                    $uri = 'urn:uuid:'.$uri;
                } elsif ($uri =~ /^[1-3](?:\.(?:0|[1-9][0-9]*))+$/) {
                    $uri = 'urn:oid:'.$uri;
                }
            } elsif ($type =~ /^[0-9a-fA-F]{8}-(?:[0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$/) {
                my $u = URI->new('https://uriid.org/');
                $u->path_segments('', $type, $uri);
                $uri = $u;
            }

            $uri = URI->new($uri);
        }
    }

    croak 'Passed a non-URI object' unless $uri->isa('URI');

    croak 'URI is not absolute' unless defined($uri->scheme) && length($uri->scheme);

    return Data::URIID::Result->new(uri => $uri, extractor => $self);
}


sub online {
    my ($self, $new_value) = @_;

    if (scalar(@_) == 2) {
        $self->{online} = !!$new_value;
    }

    return $self->{online};
}


sub default_online {
    my ($self, $new_value) = @_;

    if (scalar(@_) == 2) {
        $self->{default_online} = !!$new_value;
    }

    return $self->{default_online};
}


sub language_tags {
    my ($self, @new_value) = @_;

    if (scalar(@new_value)) {
        $self->{language_tags} = \@new_value;
    }

    $self->{language_tags} //= [I18N::LangTags::implicate_supers(I18N::LangTags::Detect::detect())];

    return @{$self->{language_tags}};
}

# Private method:
sub _get_language_tags {
    my ($self, %opts) = @_;

    if (defined(my $language_tags = $opts{language_tags})) {
        return @{$language_tags} if ref($language_tags) eq 'ARRAY';
        return I18N::LangTags::implicate_supers(I18N::LangTags::extract_language_tags($language_tags));
    }

    return $self->language_tags;
}

# Private method:
sub _ua {
    my ($self) = @_;
    return $self->{ua} //= do {
        my $ua = LWP::UserAgent->new(agent => $self->{agent});
        my $x = 1001; # we use 1001 and --$x here instead of 1000 and $x-- as that confuses parsers.

        $ua->default_header('Accept-Language' => join(', ', map {sprintf('%s; q=%.3f', $_, --$x/1000)} $self->language_tags));

        $ua;
    };
}



sub known {
    my ($self, $class, %opts) = @_;
    my @list;

    if ($class eq ':all') {
        foreach my $c (keys %names) {
            push(@list, values %{$names{$c}});
        }
    } else {
        @list = values %{$names{$class // ''} // croak 'Invalid class'};
    }

    # Experimental in v0.10, therefore not yet listed in POD.
    if (defined(my $as = $opts{as})) {
        if ($as eq 'ise') {
            # no-op
        } elsif ($as eq 'uuid') {
            foreach my $e (@list) {
                croak 'Cannot return requested data: as=uuid not supported on all elements of list. Try as=ise' unless $e =~ Data::URIID::Result->RE_UUID;
            }
        } elsif ($as eq 'Data::Identifier') {
            require Data::Identifier;
            @list = map {Data::Identifier->new(ise => $_)} @list;
        }
    }

    return @list;
}


sub name_to_ise {
    my ($self, $class, $name) = @_;
    return $name if $self->is_ise($name); # return name if name is already an ISE
    if (blessed($name)) {
        if (index(blessed($name), __PACKAGE__) == 0 && $name->can('ise')) {
            return $name->ise;
        } elsif ($name->isa('Data::Identifier')) {
            return $name->ise;
        }
    }
    return $names{$class // ''}{$name // ''} // croak sprintf('Invalid class or name: %s: %s', $class // '<undef>', $name // '<undef>');
}


sub ise_to_name {
    my ($self, $class, $ise) = @_;
    return $ises{$class // ''}{$ise // ''} // croak 'Invalid class or ISE';
}


sub is_ise {
    my ($self, $str) = @_;

    return $str =~ /^[0-9a-fA-F]{8}-(?:[0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$/ ||
           $str =~ /^[1-3](?:\.(?:0|[1-9][0-9]*))+$/ ||
           $str =~ /^[a-zA-Z][a-zA-Z0-9\+\.\-]+:[^:]/;
}


sub service {
    my ($self, $service) = @_;
    my $cache = $self->{service_cache} //= {};

    $service = $service->ise if ref $service;
    $service = $self->name_to_ise(service => $service);

    croak 'Not a known service: '.$service unless defined $ises{service}{$service};

    return $cache->{$service} //= Data::URIID::Service->new(
        extractor   => $self,
        ise         => $service,
        online      => $self->default_online,
    );
}

sub match_services {
    my ($self, @list) = @_;
    my %selected;

    @list = map {split /\s*[,:]\s*|\s+/} map {ref($_) eq 'ARRAY' ? @{$_} : $_} @list;

    foreach my $entry (@list) {
        my ($neg, $prefix, $name) = $entry =~ /^(\!?)(\@?)(.+)$/;
        my @sublist;

        if ($prefix eq '@') {
            @sublist = @{$service_lists{$name} // croak 'Invalid service list: '.$name};
        } else {
            $name = $name->ise if ref $name;
            $name = $self->name_to_ise(service => $name);
            $name = $self->ise_to_name(service => $name);
            @sublist = ($name);
        }

        if ($neg eq '') {
            $selected{$_} = 1 foreach @sublist;
        } else {
            $selected{$_} = 0 foreach @sublist;
        }
    }

    return grep {$selected{$_}} keys %selected;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::URIID - Extractor for identifiers from URIs

=head1 VERSION

version v0.12

=head1 SYNOPSIS

    use Data::URIID;

    my $extractor = Data::URIID->new;

    my $result = $extractor->lookup( $uri );

    my $id = $result->id( $type );

This module provides a way to extract knowledge (mainly identifier) from a given URL, a QR Code,
or similar objects.

The main usages for this module are:

=over

=item *

Provide information to display the object in question to the user (such as name, location, icons, thumbnails, and more)

=item *

Provide required identifiers and URLs to link the object with many services.

=back

In order to do so, an extractor (instance of this package) is created.
On that extractor L</lookup> is called for every input to process resulting in a L<Data::URIID::Result> object holding the acquired knowledge.

The module supports both online and offline lookups. See L</online>.

B<Note:>
Future versions of this module will depend on L<Data::Identifier>.

=head1 METHODS

=head2 new

    my $extractor = Data::URIID->new;
    # or:
    my $extractor = Data::URIID->new( option => value, ... );

Returns a new object that can be used for lookups.
The following options are defined:

=over

=item C<agent>

User agent string to use if no C<ua> is given.

This should be set to something of valid user agent string syntax that reflects your
application and contains contact details.

=item C<default_online>

Boolean indicating whether online operation is allowed by default.

Default false.
See also L<"default_online">.

=item C<language_tags>

An arrayref with all acceptable language tags (most acceptable first).

Default C<[I18N::LangTags::implicate_supers(I18N::LangTags::Detect::detect())]>
See also L<"language_tags">, L<I18N::LangTags>, and L<I18N::LangTags::Detect>
Note: If you perform online lookups and passed a user agent via C<ua> it must also reflect this setting.

=item C<online>

Boolean indicating whether online operations are permitted.

Default false.
See also L<"online">.

=item C<services_online>

List of services to set the online flag for.
Similar to C<default_online>, this allows for enable online mode for services.
The difference is that this option allows selective control.

The argument takes a list (arrayref or C<,> or C<:> delimited string) of elements which each name a service
or a group (prefixed with C<@>). Each entry might be prefixed with C<!> to negative (exclude) that element.

Currently defined:
C<@ALL> (all services),
C<@LOCAL> (all services that provide offline mode; note that offline mode is not affected by this setting),
C<@REMOTE> (all services that have an online mode),
C<@friendly> (all services that have a friendly policy),
C<@uafriendly> (all services that have a friendly policy but require the agent string to be set to something useful that includes contact details),
C<@wmf> (Wikimedia Foundation, Inc. related services),
C<@osm> (OpenStreetMap related services).

Defaults to an empty list.

B<Example:>

    [qw(@friendly @osm !@wmf)] # All friendly services plus OpenStreetMap services, but not Wikimedia Foundation

    '@uafriendly:!wikimedia-commons' # All services friendly (if 'agent' is set) but not Wikimedia commons.

B<Note:>
If a service is listed as negative in this setting this will not disable that service
but just not enable it. It might be enabled by other options.
This behaviour may change in future versions.

B<Note:>
You should not give this option together with C<default_online>.
Future versions might change behaviour if both are given.

=item C<ua>

Useragent to use (L<LWP::UserAgent>).

=back

=head2 lookup

    my $result = $extractor->lookup( $uri );
    # or:
    my $result = $extractor->lookup( $type, $uri );

Tries to look up the URI and returns the result.
Takes an L<URI> object (preferred) or a plain string as argument.
Alternatively can internally also convert from
L<Mojo::URL>, L<Data::URIID::Service>, L<Data::URIID::Result>, and L<Data::URIID::Colour>.

C<$type> is one of C<uri>, C<ise>, or C<qrcode>, an UUID, or an object of type L<URI> or L<Data::URIID::Result>.
Defaults to C<uri>.
When C<ise> an UUID or OID can be provided instead of an URI.
When C<qrcode> the text content from an QR code can be provided.

This method will return a L<Data::URIID::Result> if successful or C<die> otherwise.

=head2 online

    my $online = $extractor->online( [ $new_value ] );

Gets or sets the online status of extractor. If this value is false no online operations are permitted.
In addition to this value being true the online value for the services that should perform lookups
need to be true.

See also L<"default_online">.

=head2 default_online

    my $online = $extractor->default_online( [ $new_value ] );

Gets or sets the default online value for L<Data::URIID::Service> objects returned by L<"service">.
This value is only used if the service has not yet been accessed.
Therefore it is often unsafe to alter this value. The corresponding L<"new"> option should be used.

See also L<"online">.

=head2 language_tags

    my @language_tags = $extractor->language_tags( [ @new_value ] );

Gets or sets the list of acceptable language tags.

See also L<"new">.

=head1 UTILITY METHODS

=head2 known

    my @list = $extractor->known( $class );

Returns a list of known items of a class.
Not all items may have the same level of support by this module.
Class is one of C<service>, C<type>, C<action>, or C<:all>.
If the class is given as C<:all> this module will return the lists for all classes
but may also return additional entries known to it.

This method will return an array of ISEs if successful or C<die> otherwise.

=head2 name_to_ise

    my $ise = $extractor->name_to_ise( $class => $name );

Tries to lookup an ISE for a given well known name.
Class is one of C<service>, C<type>, or C<action>.

This method will return an ISE if successful or C<die> otherwise.
This is the reverse of L<"ise_to_name">.

=head2 ise_to_name

    my $name = $extractor->ise_to_name( $class => $ise );

Tries to lookup a name for a given well known ISE.
Class is one of C<service>, C<type>, or C<action>.

This method will return a name if successful or C<die> otherwise.
This is the reverse of L<"name_to_ise">.

=head2 is_ise

    my $bool = $extractor->is_ise( $str );

Returns whether or not a string is a valid ISE.

=head2 service

    my $service = $extractor->service( $service );

This method will return a L<Data::URIID::Service> for the given name or ISE if successful or C<die> otherwise.

=head1 KNOWN/SUPPORTED SERVICES

For a list of known/supported services see L<Data::URIID::Service/"KNOWN/SUPPORTED SERVICES">.

=head1 AUTHOR

Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023-2025 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
