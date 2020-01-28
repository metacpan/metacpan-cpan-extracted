package Dash::Config;

use Moo;
use strictures 2;
use JSON;
use namespace::clean;

has url_base_pathname => ( is      => 'rw',
                           default => sub { JSON::null } );

has requests_pathname_prefix => ( is      => 'rw',
                                  default => '/' );

has ui => ( is      => 'rw',
            default => sub { JSON::false } );

has props_check => ( is      => 'rw',
                     default => sub { JSON::false } );

has show_undo_redo => ( is      => 'rw',
                        default => sub { JSON::false } );

has hot_reload => ( is => 'rw' );

has name => ( is => 'rw' );

sub TO_JSON {
    my $self = shift;
    my %hash =
      map { $_ => $self->{$_} } qw(url_base_pathname requests_pathname_prefix ui props_check show_undo_redo hot_reload);
    return \%hash;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dash::Config

=head1 VERSION

version 0.10

=head1 AUTHOR

Pablo Rodríguez González <pablo.rodriguez.gonzalez@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Pablo Rodríguez González.

This is free software, licensed under:

  The MIT (X11) License

=cut
