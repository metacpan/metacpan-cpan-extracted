package App::GitGot::Outputter::dark;
our $AUTHORITY = 'cpan:GENEHACK';
$App::GitGot::Outputter::dark::VERSION = '1.333';
# ABSTRACT: Color scheme appropriate for dark terminal backgrounds
use 5.014;

use Types::Standard -types;

use App::GitGot::Types;

use Moo;
extends 'App::GitGot::Outputter';
use namespace::autoclean;

has color_error => (
  is      => 'ro' ,
  isa     => Str ,
  default => 'bold white on_red'
);

has color_major_change => (
  is      => 'ro' ,
  isa     => Str ,
  default => 'bold black on_green'
);

has color_minor_change => (
  is      => 'ro' ,
  isa     => Str ,
  default => 'green'
);

has color_warning => (
  is      => 'ro' ,
  isa     => Str ,
  default => 'bold black on_yellow'
);


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::GitGot::Outputter::dark - Color scheme appropriate for dark terminal backgrounds

=head1 VERSION

version 1.333

=for Pod::Coverage color_error color_major_change color_minor_change color_warning

=head1 AUTHOR

John SJ Anderson <genehack@genehack.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by John SJ Anderson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
