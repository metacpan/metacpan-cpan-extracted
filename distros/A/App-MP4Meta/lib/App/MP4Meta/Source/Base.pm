use 5.010;
use strict;
use warnings;

package App::MP4Meta::Source::Base;
{
  $App::MP4Meta::Source::Base::VERSION = '1.153340';
}

# ABSTRACT: Base class for sources

sub new {
    my $class = shift;
    my $args  = shift;
    my $self  = {};

    # cache results
    $self->{cache}        = {};
    $self->{banner_cache} = {};

    bless( $self, $class );
    return $self;
}

sub get_film {
    my ( $self, $args ) = @_;

    die 'no title' unless $args->{title};
}

sub get_tv_episode {
    my ( $self, $args ) = @_;

    die 'no title'   unless $args->{show_title};
    die 'no season'  unless $args->{season};
    die 'no episode' unless $args->{episode};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::MP4Meta::Source::Base - Base class for sources

=head1 VERSION

version 1.153340

=head1 METHODS

=head2 new()

Create a new object. Takes no arguments.

=head2 get_film( $args )

Base functionality for getting a film.

=head2 get_tv_episode( $args )

Base functionality for getting a TV episode.

=head1 AUTHOR

Andrew Jones <andrew@arjones.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Andrew Jones.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
