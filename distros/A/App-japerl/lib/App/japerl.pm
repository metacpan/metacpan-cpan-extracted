package App::japerl;
######################################################################
#
# App::japerl - JPerl-again Perl glocalization scripting environment
#
# https://metacpan.org/release/App-japerl
#
# Copyright (c) 2018, 2019 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

$VERSION = '0.12';
$VERSION = $VERSION;

use 5.00503;
use strict;
BEGIN { $INC{'warnings.pm'} = '' if $] < 5.006 }; use warnings; $^W=1;

1;

__END__

=pod

=head1 NAME

App::japerl - JPerl-again Perl glocalization scripting environment

=head1 SYNOPSIS

  japerl [switches] [--] script.pl [arguments]

=head1 DESCRIPTION

japerl was created with the intention of succeeding JPerl.
japerl provides glocalization script environment on both modern Perl
and traditional Perl by using Char::* software family.

This is often misunderstood, but japerl and jacode.pl have different
purposes and functions.

       software
  <<elder   younger>>     software purpose
  ----------------------+---------------------------------------
  jcode.pl  jacode.pl   | to convert encoding of data for I/O
  ----------------------+---------------------------------------
  jperl     japerl.bat  | to execute native encoding scripts
                        | (NEVER convert script encoding)
  ----------------------+---------------------------------------

This software can do the following.

=over 4

=item * choose one perl interpreter in system

=item * select local use libraries

=item * execute script written in system native encoding

=back

May you do good magic with japerl.

=head1 AUTHOR

INABA Hitoshi E<lt>ina@cpan.orgE<gt> in a CPAN

This project was originated by INABA Hitoshi.

=head1 LICENSE AND COPYRIGHT

This software is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

This software is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut

