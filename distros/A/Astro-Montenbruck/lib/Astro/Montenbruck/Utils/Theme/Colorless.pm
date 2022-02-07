package Astro::Montenbruck::Utils::Theme::Colorless;

use strict;
use warnings;

use base qw/Astro::Montenbruck::Utils::Theme/;

Readonly::Hash our %SCHEME => (
  data_row_title     => undef,
  data_row_data      => undef,
  data_row_selected  => undef,
  table_row_title    => undef,
  table_row_data     => undef,
  table_row_error    => undef,
  table_col_title    => undef
);

our $VERSION = 0.01;

sub new {
    my $class = shift;
    $class->SUPER::new( name => 'colorless', scheme => \%SCHEME);
}

# return only the text
sub decorate { $_[1] } 

1;


=pod

=encoding UTF-8

=head1 NAME
Astro::Montenbruck::Utils::Theme::Light - Console theme without colors.

=head1 SYNOPSIS

  use Astro::Montenbruck::Utils::Theme;
  
  my $theme = Astro::Montenbruck::Utils::Theme->create('colorless');


=head1 DESCRIPTION

Child class of LAstro::Montenbruck::Utils::Theme> for terminals that 
do not support colors. It overrides L<Astro::Montenbruck::Utils::Theme::colored>
method so that no ANSI color symbols ae included to the output.


=head1 METHODS

See he parent class L<Astro::Montenbruck::Utils::Theme>.

=head1 AUTHOR

Sergey Krushinsky, C<< <krushi at cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2022 by Sergey Krushinsky

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
