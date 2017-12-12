use 5.004;
package Acme::Eatemup;
@ISA=Exporter;use Exporter;@EXPORT=qw(yumyum eatemup);
require XSLoader;XSLoader'load(__PACKAGE__,
$VERSION='0.02'
);*yumyum=*eatemup;

=head1 NAME

Acme::Eatemup - A list chopper

=head1 VERSION

0.02

=head1 SYNOPSIS

  print foo(), yumyum;  # all but the last element
  print foo(), eatemup; # same

=head1 DESCRIPTION

Have you ever needed all but the last two items of a list?  Have you ever
been annoyed that Perl's C<(...)[...]> list slice has no way for you to
specify that without knowing the number of items?  Then this module is for
you.  Before, you would have to write:

  my @tmp = foo();
  print @tmp[0..$#tmp-2]; # ugly

Or:

  my @tmp = foo();
  pop @tmp, pop @tmp; # or splice @tmp, -2
  print @tmp; # THREE lines!

With this module, you can simply eat them off the list:

  use Acme::Eatemup;
  print foo(), yumyum, eatemup;

=head1 INSPIRATION

  $,=",",$\="\n";
  sub eat(){goto z;not 1 .do{z:1}}
  print 1,2,eat,3,4;

Output:

  1,,3,4

=head1 PREREQUISITES

This module requires perl 5.004 or later.  Whether it actually works that
far back I have not verified.  (The earliest I tested it with was 5.8.7.)

=head1 BUGS

There is no check to see whether you are eating more items off the list
that are present.  When used carelessly, this module can crash perl.

Please report bugs to
L<bug-Acme-Eatemup@rt.cpan.org|mailto:bug-Acme-Eatemup@rt.cpan.org>.

=head1 AUTHOR & COPYRIGHT

Copyright (C) 2017 Father Chrysostomos (sprout at, um,
cpan dot
org)

This program is free software; you may redistribute or modify it (or both)
under the same terms as perl.

=head1 SEE ALSO

L<Routes::Tiny>
