use 5.010;
use strict;
use warnings;

package AtomicParsley::Command;
$AtomicParsley::Command::VERSION = '1.153400';
# ABSTRACT: Interface to the Atomic Parsley command

use AtomicParsley::Command::Tags;
use IPC::Cmd '0.76', ();
use File::Spec '3.33';
use File::Copy;
use File::Glob qw{ bsd_glob };

sub new {
    my $class = shift;
    my $args  = shift;
    my $self  = {};

    # the path to AtomicParsley
    my $ap = $args->{'ap'} // 'AtomicParsley';
    $self->{'ap'} = IPC::Cmd::can_run($ap) or die "Can not run $ap";
    $self->{'verbose'} = $args->{'verbose'} // 0;

    $self->{'success'}       = undef;
    $self->{'error_message'} = undef;
    $self->{'full_buf'}      = undef;
    $self->{'stdout_buf'}    = undef;
    $self->{'stderr_buf'}    = undef;

    bless( $self, $class );
    return $self;
}

sub read_tags {
    my ( $self, $path ) = @_;

    $path = File::Spec->rel2abs($path);
    my ( $volume, $directories, $file ) = File::Spec->splitpath($path);

    my $cmd = [ $self->{ap}, $path, '-t' ];

    # run the command
    $self->_run($cmd);

    # parse the output and create new AtomicParsley::Command::Tags object
    my $tags = $self->_parse_tags( $self->{'stdout_buf'}[0] );

    # $tags
    return $tags;
}

sub write_tags {
    my ( $self, $path, $tags, $replace ) = @_;

    my ( $volume, $directories, $file ) = File::Spec->splitpath($path);

    my $cmd = [ $self->{ap}, $path, $tags->prepare ];

    # run the command
    $self->_run($cmd);

    # return the temp file
    my $tempfile = $self->_get_temp_file( $directories, $file );

    if ($replace) {

        # move
        move( $tempfile, $path );
        return $path;
    }
    else {
        return $tempfile;
    }
}

# Run the command
sub _run {
    my ( $self, $cmd ) = @_;

    local $IPC::Cmd::ALLOW_NULL_ARGS = 1;

    my ( $success, $error_message, $full_buf, $stdout_buf, $stderr_buf ) =
      IPC::Cmd::run( command => $cmd, verbose => $self->{'verbose'} );

    $self->{'success'}       = $success;
    $self->{'error_message'} = $error_message;
    $self->{'full_buf'}      = $full_buf;
    $self->{'stdout_buf'}    = $stdout_buf;
    $self->{'stderr_buf'}    = $stderr_buf;
}

# Parse the tags from AtomicParsley's output.
# Returns a new AtomicParsley::Command::Tags object
sub _parse_tags {
    my ( $self, $output ) = @_;

    my %tags;
    my $intag;
    for my $line ( split( /\n/, $output ) ) {
        if ( $line =~ /^Atom \"(.+)\" contains: (.*)$/ ) {
            my $key   = $1;
            my $value = $2;

            given ($key) {
                when (/alb$/) {
                    $tags{'album'} = $value;
                }
                when ('aART') {
                    $tags{'albumArtist'} = $value;
                }
                when (/ART$/) {
                    $tags{'artist'} = $value;
                }
                when ('catg') {
                    $tags{'category'} = $value;
                }
                when (/cmt$/) {
                    my $tag = 'comment';
                    $intag = $tag;
                    $tags{$tag} = $value;
                }
                when ('cpil') {
                    $tags{'compilation'} = $value;
                }
                when ('cprt') {
                    my $tag = 'copyright';
                    $intag = $tag;
                    $tags{$tag} = $value;
                }
                when (/day$/) {
                    $tags{'year'} = $value;
                }
                when ('desc') {
                    my $tag = 'description';
                    $intag = $tag;
                    $tags{$tag} = $value;
                }
                when ('ldes') {
                    my $tag = 'longdesc';
                    $intag = $tag;
                    $tags{$tag} = $value;
                }
                when ('disk') {
                    $value =~ s/ of /\//;
                    $tags{'disk'} = $value;
                }
                when (/ge?n(|re)$/) {
                    $tags{'genre'} = $value;
                }
                when (/grp$/) {
                    $tags{'grouping'} = $value;
                }
                when ('keyw') {
                    $tags{'keyword'} = $value;
                }
                when (/lyr$/) {
                    $tags{'lyrics'} = $value;
                }
                when (/nam$/) {
                    $tags{'title'} = $value;
                }
                when ('rtng') {
                    $tags{'advisory'} = _get_advisory_value($value);
                }
                when ('stik') {
                    $tags{'stik'} = $value;
                }
                when ('tmpo') {
                    $tags{'bpm'} = $value;
                }
                when ('trkn') {
                    $value =~ s/ of /\//;
                    $tags{'tracknum'} = $value;
                }
                when ('tven') {
                    $tags{'TVEpisode'} = $value;
                }
                when ('tves') {
                    $tags{'TVEpisodeNum'} = $value;
                }
                when ('tvsh') {
                    $tags{'TVShowName'} = $value;
                }
                when ('tvnn') {
                    $tags{'TVNetwork'} = $value;
                }
                when ('tvsn') {
                    $tags{'TVSeasonNum'} = $value;
                }
                when (/too$/) {
                    $tags{'encodingTool'} = $value;
                }
                when (/wrt$/) {
                    $tags{'composer'} = $value;
                }
            }
        }
        elsif ( $intag && defined $tags{$intag} ) {
            $tags{$intag} .= "\n$line";
        }
    }

    return AtomicParsley::Command::Tags->new(%tags);
}

# Try our best to get the name of the temp file.
# Unfortunately. the temp file contains a random number,
# so this is a best guess.
sub _get_temp_file {
    my ( $self, $directories, $file ) = @_;

    # remove suffix
    $file =~ s/(\.\w+)$/-temp-/;
    my $suffix = $1;

    # search directory
    for my $tempfile ( bsd_glob("$directories*$suffix") ) {

        # return the first match
        if ( $tempfile =~ /^$directories$file.*$suffix$/ ) {
            return $tempfile;
        }
    }
}

# Get the advisory value of an mp4 file, if present.
sub _get_advisory_value {
    my $advisory = shift;

    # TODO: check all values
    given ($advisory) {
        when ('Clean Content') {
            return 'clean';
        }
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AtomicParsley::Command - Interface to the Atomic Parsley command

=head1 VERSION

version 1.153400

=head1 SYNOPSIS

  my $ap = AtomicParsley::Command->new({
    ap => '/path/to/AtomicParsley', # will die if not found
    verbose => 1,
  });
  
  # read tags from a file
  my $tags = $ap->read_tags( '/path/to/mp4' );
  
  # write tags to a file
  my $path = $ap->write_tags( '/path/to/mp4', $tags, 1 );

=head1 DESCRIPTION

This is an interface to the AtomicParsley command.

AtomicParsley is a lightweight command line program for reading, parsing and setting metadata into MPEG-4 files. For more information see https://bitbucket.org/wez/atomicparsley.

=head1 METHODS

=head2 new ( %args )

Creates a new AtomicParsley::Command object. Takes the following arguments:

=over 4

=item *

ap - the path to the AtomicParsley command. Defaults to 'AtomicParsley' (assumes its on your PATH).

=item *

verbose - runs verbosely. (TODO)

=back

=head2 read_tags( $path )

Read the meta tags from a file and returns a L<AtomicParsley::Command::Tags> object.

=head2 write_tags( $path, $tags, $replace )

Writes the tags to a mp4 file.

$tags is a L<AtomicParsley::Command::Tags> object.

If $replace is true, the existing file will be replaced with the new, tagged file. Otherwise, the tagged file will be a temp file, with the existing file untouched.

Returns the path on success.

=head1 ISSUES

=over 4

=item *

Doesn't run verbosely.

=item *

Doesn't load all the "advisory" values for an mp4 file.

=item *

The following tags have not been implemented: * artwork * compilation * podcastFlag * podcastURL * podcastGUID * purchaseDate * gapless

=back

=head1 UPDATING

If you are updating, ensure you use the latest version of AtomicParsley from https://bitbucket.org/wez/atomicparsley.

=head1 SEE ALSO

=over 4

=item *

L<App::MP4Meta>

=back

=head1 AUTHOR

Andrew Jones <andrew@arjones.co.uk>

=head1 CONTRIBUTORS

=over 4

=item *

Andrew Jones <andrew@andrew-jones.com>

=item *

Andrew Jones <andrewjones86@googlemail.com>

=item *

Jim Graham <jim@jim-graham.net>

=item *

WATANABE Hiroaki <hwat@mac.com>

=item *

andrewrjones <andrewjones86@googlemail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Andrew Jones.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
