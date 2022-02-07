package Astro::Montenbruck::Utils::Theme::Light;

use strict;
use warnings;

use base qw/Astro::Montenbruck::Utils::Theme/;
use Readonly;

Readonly::Hash our %SCHEME => (
  data_row_title     => 'bright_blue',
  data_row_data      => 'black',
  data_row_selected  => 'bright_blue',
  table_row_title    => 'bright_blue',
  table_row_data     => 'black',
  table_row_error    => 'red',
  table_col_title    => 'bright_blue'
);

our $VERSION = 0.01;

sub new {
    my $class = shift;
    $class->SUPER::new( name => 'light', scheme => \%SCHEME);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME
Astro::Montenbruck::Utils::Theme::Light - Console theme, for light terminals.

=head1 SYNOPSIS

  use Astro::Montenbruck::Utils::Theme;
  
  my $theme = Astro::Montenbruck::Utils::Theme->create('light');


=head1 DESCRIPTION

Child class of LAstro::Montenbruck::Utils::Theme>, for light terminals.
It uses the following colors scheme:

  (
    data_row_title     => 'bright_blue',
    data_row_data      => 'black',
    data_row_selected  => 'bright_blue',
    table_row_title    => 'bright_blue',
    table_row_data     => 'black',
    table_row_error    => 'red',
    table_col_title    => 'bright_blue'
  );


=head1 METHODS

See he parent class L<Astro::Montenbruck::Utils::Theme>.

=head1 AUTHOR

Sergey Krushinsky, C<< <krushi at cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2022 by Sergey Krushinsky

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
