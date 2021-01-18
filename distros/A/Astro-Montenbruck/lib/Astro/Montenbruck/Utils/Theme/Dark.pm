package Astro::Montenbruck::Utils::Theme::Dark;

use strict;
use warnings;

use base qw/Astro::Montenbruck::Utils::Theme/;
use Readonly;

Readonly::Hash our %SCHEME => (
  data_row_title     => 'white',
  data_row_data      => 'bright_white',
  data_row_selected  => 'bright_yellow',
  table_row_title    => 'white',
  table_row_data     => 'bright_yellow',
  table_row_error    => 'red',
  table_col_title    => 'white'
);

our $VERSION = 0.01;

sub new {
    my $class = shift;
    $class->SUPER::new( name => 'dark', scheme => \%SCHEME);
}

1;


=pod

=encoding UTF-8

=head1 NAME
Astro::Montenbruck::Utils::Theme::Light - Console theme, for dark terminals.

=head1 SYNOPSIS

  use Astro::Montenbruck::Utils::Theme;
  
  my $theme = Astro::Montenbruck::Utils::Theme->create('dark');


=head1 DESCRIPTION

Child class of LAstro::Montenbruck::Utils::Theme>, for dark terminals.
It uses the following colors scheme:

  (
    data_row_title     => 'white',
    data_row_data      => 'bright_white',
    data_row_selected  => 'bright_yellow',
    table_row_title    => 'white',
    table_row_data     => 'bright_yellow',
    table_row_error    => 'red',
    table_col_title    => 'white'
  );


=head1 METHODS

See he parent class L<Astro::Montenbruck::Utils::Theme>.

=head1 AUTHOR

Sergey Krushinsky, C<< <krushi at cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2021 by Sergey Krushinsky

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
