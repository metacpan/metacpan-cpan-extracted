use 5.010;
use strict;
use warnings;

package App::MP4Meta::Base;
{
  $App::MP4Meta::Base::VERSION = '1.153340';
}

# ABSTRACT: Base class. Contains common functionality.

use Module::Load ();
use Try::Tiny;
use AtomicParsley::Command;

sub new {
    my $class = shift;
    my $args  = shift;
    my $self  = {};

    # file suffixes we support
    my @suffixes = qw/mp4 m4a m4p m4v m4b/;
    $self->{suffixes} = \@suffixes;

    # the path to AtomicParsley
    $self->{'ap'} = AtomicParsley::Command->new( { ap => $args->{'ap'} } );

    # if true, replace file
    $self->{'noreplace'} = $args->{'noreplace'};

    # if true, add to itunes
    $self->{'itunes'} = $args->{'itunes'};

    # if true, print verbosely
    $self->{'verbose'} = $args->{'verbose'};

    # internet sources
    $self->{'sources'} = $args->{'sources'};

    # common attributes for a media file
    $self->{'genre'}     = $args->{'genre'};
    $self->{'title'}     = $args->{'title'};
    $self->{'coverfile'} = $args->{'coverfile'};

    bless( $self, $class );

    # create sources now so they are in scope for as long as we are
    $self->{'sources_objects'} = [];
    for my $source ( @{ $self->{'sources'} } ) {
        try {
            push( @{ $self->{'sources_objects'} },
                $self->_new_source($source) );
        }
        catch {
            say STDERR "could not load source: $_";
        };
    }

    return $self;
}

# Calls AtomicParsley and writes the tags to the file
sub _write_tags {
    my ( $self, $path, $tags ) = @_;

    my $tempfile = $self->{ap}->write_tags( $path, $tags, !$self->{noreplace} );

    if ( !$self->{ap}->{success} ) {
        return $self->{ap}->{'stdout_buf'}[0] // $self->{ap}->{'full_buf'}[0];
    }

    if ( !$tempfile ) {
        return "Error writing to file";
    }

    return;
}

sub _strip_suffix {
    my ( $self, $file ) = @_;

    my $regex = sprintf( '\.(%s)$', join( '|', @{ $self->{suffixes} } ) );
    $file =~ s/$regex//;

    return $file;
}

# Converts 'THE_OFFICE' to 'The Office'
sub _clean_title {
    my ( $self, $title ) = @_;

    $title =~ s/(-|_)/ /g;
    $title =~ s/(?<=\w)\.(?=\w)/ /g;
    $title = lc($title);
    $title = join ' ', map( { ucfirst() } split /\s/, $title );

    return $title;
}

# adds file to itunes
sub _add_to_itunes {
    my ( $self, $path ) = @_;

    return unless $self->{'itunes'};

    unless ( $^O eq 'darwin' ) {
        say STDERR 'can only add to iTunes on Mac OSX';
        return 1;
    }

    $path =~ s!/!:!g;

    my $cmd = sprintf(
"osascript -e 'tell application \"iTunes\" to add file \"%s\" to playlist \"Library\" of source \"Library\"'",
        $path );

    my $result = `$cmd`;
    if ($?) {
        say STDERR "error adding to iTunes: $result";
        return 1;
    }
    if ( $self->{'verbose'} and $result ) {
        say $result;
    }

    return;
}

# load a module as a new source
sub _new_source {
    my ( $self, $source ) = @_;
    my $module = 'App::MP4Meta::Source::' . $source;
    Module::Load::load($module);
    return $module->new;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::MP4Meta::Base - Base class. Contains common functionality.

=head1 VERSION

version 1.153340

=head1 SYNOPSIS

  my $base = App::MP4Meta::Base->new( ap => 'path/to/ap' );

=head1 METHODS

=head2 new( %args )

Create new object. Takes the following arguments:

=over 4

=item *

ap - Path to the AtomicParsley command. Optional.

=item *

noreplace - If true, do not replace file, but save to temp instead

=item *

verbose - If true, print verbosely

=item *

sources - A list of sources to load

=item *

genre - Define a genre for the media file

=item *

title - Define a title for the media file

=item *

coverfile - Define the path to a coverfile for the media file

=back

=head1 AUTHOR

Andrew Jones <andrew@arjones.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Andrew Jones.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
