#===============================================================================
#
#         FILE:  Open.pm
#
#  DESCRIPTION:  App::Open, Command-Line interface library
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Erik Hollensbe (), <erik@hollensbe.org>
#      COMPANY:
#      VERSION:  1.0
#      CREATED:  06/02/2008 01:50:56 AM PDT
#     REVISION:  ---
#===============================================================================

package App::Open;

use strict;
use warnings;

use version;
our $VERSION = version::qv("0.0.4");

use File::Basename qw(basename);
use URI;

=head1 NAME

App::Open - Library to drive the 'openit' command line tool

=head1 USING

If you are just looking to use the `openit` command and learn how to configure
it, please see App::Open::Using, which addresses this issue.

=head1 SYNOPSIS

See the `openit` script.

=head1 WARNING

While this probably can be re-used, it has a specific function to support a
specific tool. Use this at your own risk and expect breakage on upgrades.
Expect side-effects, even if the author himself detests them.

=head1 METHODS

=over 4

=item new( $config, $filename )

`$config` is a App::Open::Config object. `$filename` is a filename or URL which
`openit` will attempt to locate a program to launch for it.

=cut

sub new {
    my ( $class, $config, $filename ) = @_;
    
    my $self = bless { filename => $filename, config => $config }, $class;

    $self->parse_filename;

    die "MISSING_ARGUMENT" unless ( $config && $self->{filename} );
    die "INVALID_ARGUMENT" unless ( $config->isa('App::Open::Config') );
    die "FILE_NOT_FOUND"   unless ( $self->is_url || -e $self->{filename} );

    $self->config->load_backends;

    return $self;
}

=item filename

Produces the stored filename.

=cut

sub filename { $_[0]->{filename} }

=item config

Produces the App::Open::Config object

=cut

sub config { $_[0]->{config} }

=item is_url

Predicate to indicate whether the `filename` is a URL or not. This is a bit
distracting as `file` URLs are not indicated by this method. I'll probably get
to fixing this shortly after I become a Nobel Laureate.

=cut

sub is_url { $_[0]->{is_url} }

=item scheme

In the event the `filename` is a URL, return the URL scheme (http, ftp, etc)

=cut

sub scheme { $_[0]->{scheme} }

=item parse_filename

Figure out if the file is a local file or not. `file` URLs are massaged into
filenames, see is_url(). 

=cut

sub parse_filename {
    my $self = shift;

    my $u = URI->new($self->filename);

    if (!$u->scheme || $u->scheme eq 'file') {
        $self->{filename} = $u->path if $u->scheme;
    } else {
        $self->{scheme} = $u->scheme;
        $self->{is_url} = 1;
    }

    return;
}

=item extensions

Build a list of extensions from the filename. Since it's possible that files
may have multiple extensions (e.g., .tar.gz), we break this down into
increasingly diminuitive portions. The idea is that we handle the "largest"
extension first, for example, using tar to unpack .tar.gz files, and falling
back to gunzip if we have to.

=cut

sub extensions {
    my $self = shift;

    my @extensions = split( /\./, basename($self->filename) );

    shift @extensions;    # remove the filename

    #
    # combine the extensions so that they are a list of full extensions,
    # ranging from the largest combination to the smallest.
    #
    # e.g., foo.jpg.tar.gz would turn into this list:
    #
    # jpg.tar.gz, tar.gz, gz
    #

    my @combined_extensions;

    while (@extensions) {
        push @combined_extensions, join( ".", @extensions );
        shift @extensions;
    }

    return @combined_extensions;
}

=item backends

Return the backend list. Please note that these are objects, not merely package
names.

=cut

sub backends {
    my $self = shift;

    $self->config->backend_order;
}

=item lookup_program

Locate the program to execute the file, searching the provided backends. If we
have found a program and it has a template, it will replace '%s' with the
filename in all occurrences. Otherwise, it will append it to the end of the
command.

This method returns a list suitable for sending to system(). It makes no
attempt to correct your potentially problematic shell quoting, but it does
ensure that the filename, whether templated or appended, is fully intact and
not split across list elements.

=cut

sub lookup_program {
    my $self = shift;

    my $program;
    my @command;

    foreach my $backend ( @{ $self->backends } ) {

        if ($self->is_url) {
            $program = $backend->lookup_url($self->scheme);
        } else {
            foreach my $ext ( $self->extensions ) {
                $program = $backend->lookup_file($ext);
                last if $program;
            }
        }

        last if $program;
    }

    if ($program) {
        @command = split(/\s+/, $program);
        my $command_changed = 0;

        foreach (@command) {
            if (/%s/) {
                s/%s/$self->filename/eg;
                $command_changed = 1;
            }
        }

        # if the filename's already in the command, assume we don't need to append
        # it.
        push @command, $self->filename unless ($command_changed);
    }

    return @command;
}

=item execute_program

Execute the program against the filename supplied by the constructor.

In most cases, this is the only method you need to call; it does all the work
for you.

=cut

sub execute_program {
    my $self = shift;

    my @command = $self->lookup_program;

    die "NO_PROGRAM" unless @command;

    if ( $self->config->config->{"fork"} ) {
        if (fork) { exec( @command ); }
        return 0;
    } else {
        return system( @command );
    }
}

=back

=head1 LICENSE

This file and all portions of the original package are (C) 2008 Erik Hollensbe.
Please see the file COPYING in the package for more information.

=head1 BUGS AND PATCHES

Probably a lot of them. Report them to <erik@hollensbe.org> if you're feeling
kind. Report them to CPAN RT if you'd prefer they never get seen.

=cut

1;
