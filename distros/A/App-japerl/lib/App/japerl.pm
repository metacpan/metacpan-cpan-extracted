package App::japerl;
######################################################################
#
# App::japerl - JPerl-again Perl glocalization scripting environment
#
# https://metacpan.org/dist/App-japerl
#
# Copyright (c) 2018, 2019, 2021, 2023 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

$VERSION = '0.15';
$VERSION = $VERSION;

use 5.00503;
use strict;
BEGIN { $INC{'warnings.pm'} = '' if $] < 5.006 }; use warnings; local $^W=1;

1;

__END__

=pod

=head1 NAME

App::japerl - JPerl-again Perl glocalization scripting environment

=head1 SYNOPSIS

  japerl [switches] [--] MBCS_script.pl [arguments]

=head1 DESCRIPTION

japerl.bat is a wrapper for the mb.pm modulino.
This software assists in the execution of Perl scripts written in MBCS encoding.

It differs in function and purpose from jacode.pl, which has a similar name and is often misunderstood.
jacode.pl is mainly used to convert I/O data encoding.

On the other hand, mb.pm modulino handles script you wrote, and it does not convert its encoding.

       software
  <<elder   younger>>     software purpose
  ----------------------+---------------------------------------
  jcode.pl  jacode.pl   | to convert encoding of data for I/O
  ----------------------+---------------------------------------
  jperl     japerl.bat  | to execute native encoding scripts
                        | (NEVER convert script encoding)
  ----------------------+---------------------------------------

This software can do the following.

=over 2

=item *

choose one perl interpreter in system

=item *

select local use libraries

=item *

execute script written in system native encoding

=back

=head1 How to find mb.pm modulino ?

Running japerl.bat requires mb.pm modulino.
japerl.bat finds for mb.pm modulino in the following order and uses the first mb.pm found.

=over 2

=item 1

@PERL_LOCAL_LIB_ROOT

=item 2

$FindBin::Bin

=item 3

$FindBin::Bin/lib

=item 4

@INC

=back

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

