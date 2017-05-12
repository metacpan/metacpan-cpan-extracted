package Data::HexDump::XXD;

use version; our $VERSION = qv('0.1.1');

use warnings;
use strict;
use Carp;

use base 'Exporter';

our @EXPORT_OK = qw( xxd_pack xxd_r xxd_unpack xxd );

# Other recommended modules (uncomment to use):
#  use IO::Prompt;
#  use Perl6::Export;
#  use Perl6::Slurp;
#  use Perl6::Say;
#  use Regexp::Autoflags;
#  use Readonly;

# Module implementation here
sub _xxd_line {    # format a hex dump a-la xxd
   my ($counter, @octets) = @_;
   $counter = sprintf '%07x:', $counter;
   my ($hex, $dump);
   my @sep = ('', ' ');
   for my $i (0 .. $#octets) {
      $hex .= unpack('H*', $octets[$i]) . $sep[$i % 2];
      my $code = ord $octets[$i];
      $dump .= ($code >= 0x20 && $code < 0x7F) ? $octets[$i] : '.';
   }

   $hex .= ' ' x (40 - length $hex);
   return join ' ', $counter, $hex, $dump;
} ## end sub _xxd_line

sub xxd {
   my $length = length $_[0];
   my $offset = 0;
   my @retval;
   while ($offset < $length) {
      push @retval,
        _xxd_line($offset, split //, substr $_[0], $offset, 16);
      $offset += 16;
   }
   return @retval if wantarray;
   return join "\n", @retval;
} ## end sub xxd
*xxd_unpack = \&xxd;

sub xxd_r {
   my @retval;
   for my $line (scalar(@_) > 1 ? @_ : split /\n/, $_[0]) {
      my ($payload) = $line =~ m{\A\S+:\s (.*?) \s\s}xms;
      next unless defined $payload;
      $payload =~ s/\s//g;
      push @retval, pack 'H*', $payload;
   }
   return join '', @retval;
} ## end sub xxd_r
*xxd_pack = \&xxd_r;

1;    # Magic true value required at end of module
__END__

=encoding iso-8859-1

=head1 NAME

Data::HexDump::XXD - format hexadecimal dump like B<xxd>


=head1 VERSION

This document describes Data::HexDump::XXD version 0.0.1


=head1 SYNOPSIS

   use Data::HexDump::XXD qw( xxd xxd_r );
   
   my $dump_string = xxd($binary_data);
   my @dumped_lines = xxd($binary_data);

   my $binary = xxd_r($xxd_like_string);
   my $binary = xxd_r(@xxd_like_lines);
    
  
=head1 DESCRIPTION

Produce an hexadecimal dump like the program B<xxd> would do, and do the
reverse as well.

At the moment, only straight dumping is supported, and reverse assumes
the same.

=head1 INTERFACE 

=over

=item B<my $dump = xxd($bindata);>

=item B<my @dump_lines = xxd($bindata);>

=item B<my $dump = xxd_unpack($bindata);>

=item B<my @dump_lines = xxd_unpack($bindata);>

Produce an hex dump of the input C<$bindata>. The dump can be either a
single string or a list of lines depending on the calling context.

C<xxd_unpack()> and C<xxd()> are synonimous.


=item B<my $bindata = xxd_r($dump);>

=item B<my $bindata = xxd_r(@dump_lines);>

=item B<my $bindata = xxd_pack($dump);>

=item B<my $bindata = xxd_pack(@dump_lines);>

Reverse an B<xxd>-style hexadecimal dump. You can either provide a single
string or an array of lines; in the first case, the line terminator
is assumed to be a single newline character. Like B<xxd>, the ASCII dump
is ignored and only the hexadecimal part is taken into account.

=back


=head1 CONFIGURATION AND ENVIRONMENT

Data::HexDump::XXD requires no configuration files or environment variables.


=head1 DEPENDENCIES

Among the non-core, only C<version>.


=head1 BUGS AND LIMITATIONS

It is currently limited to the basic behaviour of B<xxd>. Note that plain
hex dump is pretty straightforward in Perl, you simply have to call:

   my $hex = unpack 'H*', $bindata;

Note also that the high nybble is always assumed to come first in
dumps (see C<perldoc -f unpack>, C<H> template).

No bugs have been reported.

Please report any bugs or feature requests through http://rt.cpan.org/


=head1 AUTHOR

Flavio Poletti  C<< <flavio [at] polettix [dot] it> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Flavio Poletti C<< <flavio [at] polettix [dot] it> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>
and L<perlgpl>.

Questo modulo è software libero: potete ridistribuirlo e/o
modificarlo negli stessi termini di Perl stesso. Vedete anche
L<perlartistic> e L<perlgpl>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=head1 NEGAZIONE DELLA GARANZIA

Poiché questo software viene dato con una licenza gratuita, non
c'è alcuna garanzia associata ad esso, ai fini e per quanto permesso
dalle leggi applicabili. A meno di quanto possa essere specificato
altrove, il proprietario e detentore del copyright fornisce questo
software "così com'è" senza garanzia di alcun tipo, sia essa espressa
o implicita, includendo fra l'altro (senza però limitarsi a questo)
eventuali garanzie implicite di commerciabilità e adeguatezza per
uno scopo particolare. L'intero rischio riguardo alla qualità ed
alle prestazioni di questo software rimane a voi. Se il software
dovesse dimostrarsi difettoso, vi assumete tutte le responsabilità
ed i costi per tutti i necessari servizi, riparazioni o correzioni.

In nessun caso, a meno che ciò non sia richiesto dalle leggi vigenti
o sia regolato da un accordo scritto, alcuno dei detentori del diritto
di copyright, o qualunque altra parte che possa modificare, o redistribuire
questo software così come consentito dalla licenza di cui sopra, potrà
essere considerato responsabile nei vostri confronti per danni, ivi
inclusi danni generali, speciali, incidentali o conseguenziali, derivanti
dall'utilizzo o dall'incapacità di utilizzo di questo software. Ciò
include, a puro titolo di esempio e senza limitarsi ad essi, la perdita
di dati, l'alterazione involontaria o indesiderata di dati, le perdite
sostenute da voi o da terze parti o un fallimento del software ad
operare con un qualsivoglia altro software. Tale negazione di garanzia
rimane in essere anche se i dententori del copyright, o qualsiasi altra
parte, è stata avvisata della possibilità di tali danneggiamenti.

Se decidete di utilizzare questo software, lo fate a vostro rischio
e pericolo. Se pensate che i termini di questa negazione di garanzia
non si confacciano alle vostre esigenze, o al vostro modo di
considerare un software, o ancora al modo in cui avete sempre trattato
software di terze parti, non usatelo. Se lo usate, accettate espressamente
questa negazione di garanzia e la piena responsabilità per qualsiasi
tipo di danno, di qualsiasi natura, possa derivarne.

=cut
