package Acme::CPANAuthors::Pumpkings;

use 5.006;
use strict;
use warnings;
no  warnings 'syntax';

our $VERSION = '2012032201';

use Acme::CPANAuthors::Register (
    q <LWALL>    => qq <Larry Wall>,
    q <ANDREWD>  => qq <Andy Dougherty>,
    q <TOMC>     => qq <Tom Christiansen>,
    q <CBAIL>    => qq <Charles Bailey>,
    q <NI-S>     => qq <Nick Ing-Simmons>,
    q <CHIPS>    => qq <Chip Salzenberg>,
    q <TIMB>     => qq <Tim Bunce>,
    q <MICB>     => qq <Malcolm Beattie>,
    q <GSAR>     => qq <Gurusamy Sarathy>,
    q <GBARR>    => qq <Graham Barr>,
    q <JHI>      => qq <Jarkko Hietaniemi>,
    q <HVDS>     => qq <Hugo van der Sanden>,
    q <MSCHWERN> => qq <Michael Schwern>,
    q <RGARCIA>  => qq <Rafa\x{EB}l Garcia-Suarez>,
    q <NWCLARK>  => qq <Nicholas Clark>,
    q <RCLAMP>   => qq <Richard Clamp>,
    q <LBROCARD> => qq <L\x{E9}on Brocard>,
    q <DAPM>     => qq <Dave Mitchell>,
    q <JESSE>    => qq <Jesse Vincent>,
    q <RJBS>     => qq <Ricardo Signes>,
    q <SHAY>     => qq <Steve Hay>,
    q <MSTROUT>  => qq <Matt S Trout>,
    q <DAGOLDEN> => qq <David Golden>,
    q <FLORA>    => qq <Florian Ragwitz>,
    q <MIYAGAWA> => qq <Tatsuhiko Miyagawa>,
    q <BINGOS>   => qq <Chris Williams>,
    q <ZEFRAM>   => qq <Andrew Main (Zefram)>,
    q <AVAR>     => qq <\x{C6}var Arnfj\x{F6}r\x{F0} Bjarmason>,
    q <STEVAN>   => qq <Stevan Little>,
    q <DROLSKY>  => qq <Dave Rolsky>,
    q <CORION>   => qq <Max Maischein>,
    q <ABIGAIL>  => qq <Abigail>,
);

1;

__END__

=head1 NAME

Acme::CPANAuthors::Pumpkings - We are pumpkings.

=head1 SYNOPSIS

 use Acme::CPANAuthors;

 my $authors  = Acme::CPANAuthors -> new ("Pumpkings");

 my $number   = $authors -> count;
 my @ids      = $authors -> id;
 my @distros  = $authors -> distributions ("LWALL");
 my $url      = $authors -> avatar_url    ("LWALL");
 my $kwalitee = $authors -> kwalitee      ("LWALL");
 my $name     = $authors -> name          ("LWALL");

See documentation for Acme::CPANAuthors for more details.

=head1 DESCRIPTION

This class provides a hash of PAUSE IDs and names of the Pumpkings.

=head1 DEVELOPMENT

The current sources of this module are found on github,
L<< git://github.com/Abigail/Acme--CPANAuthors--CPANTS--Pumpkings.git >>.

=head1 AUTHOR

Abigail, L<< mailto:cpan@abigail.be >>.

=head1 COPYRIGHT and LICENSE

Copyright (C) 2009-2011 by Abigail.

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the "Software"),   
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHOR BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

=head1 INSTALLATION

To install this module, run, after unpacking the tar-ball, the 
following commands:

   perl Makefile.PL
   make
   make test
   make install

=cut
