package Acme::Laugh;

use version; $VERSION = qv('0.0.5');

use warnings;
use strict;
use Carp;
use Exporter;

our @ISA = qw( Exporter );
our %EXPORT_TAGS = ('all' => [qw( laugh )]);
our @EXPORT_OK   = (@{$EXPORT_TAGS{'all'}});
our @EXPORT      = qw();

# Module implementation here

my @incipit = ('', qw( m b mb ));
my @alto    = qw( w u );
my @basso   = qw( a e );

=encoding iso-8859-1

=begin Private

=over

=item incipit()

Returns the incipit of the laugh. No parameters.

=item minichunk( $first );

Returns a chunk of a laugh. It is compound of one to three letters.
The input parameter forces the inclusion of the first letter, for reasons
too difficult to explain here.

=item continuum( $chunks );

Returns the join of a $chunks number of elements, where $chunks defaults
to 1 + rand 4;

=item capitals( $laugh );

Returns the input $laugh where some of the letters are capitalised in
a random fashion.

=back

=end Private

=cut

sub incipit { return $incipit[rand @incipit]; }

sub minichunk {
   my ($dopre) = @_;
   my $pre = $alto[rand @alto];
   $pre = '' if (!$dopre) && (rand > 0.5);
   my $post = (rand > 0.5) ? 'h' : '';
   my $chunk = join '', $pre, $basso[rand @basso], $post;
   return ($chunk, $post);
} ## end sub minichunk

sub continuum {
   my $chunks = shift || 0;
   $chunks = 1 + rand 4 if $chunks < 1;
   my $p = 0;
   return join '',
     map { (my $c, $p) = minichunk(!$p); $c; } 1 .. $chunks;
} ## end sub continuum

sub capitals {
   return join '', map { rand > 0.5 ? uc($_) : $_; } split //, shift;
}

sub laugh { return capitals(join '', incipit(), continuum(shift)); }

1;    # Magic true value required at end of module
__END__

=head1 NAME

Acme::Laugh - add joy to your scripts.


=head1 VERSION

This document describes Acme::Laugh version 0.0.1


=head1 SYNOPSIS

    use Acme::Laugh qw( laugh );

    print laugh(5);  # print a short laugh
    print laugh(50); # print a long laugh


=head1 DESCRIPTION

=for l'autore, da riempire:
   Fornite una descrizione completa del modulo e delle sue caratteristiche.
   Aiutatevi a strutturare il testo con le sottosezioni (=head2, =head3)
   se necessario.

Laughing is something that lets humans distinguish themselves from other
forms of life. Now computers are nearer to us :)

Have you ever needed to generate a laugh? I had: in IRC, to laugh at
other people (for fun!). So, here we are!

=head1 INTERFACE 

This module lets you export the C<laugh> function:

=over

=item my $l = laugh( $length ); 

=item my $l = laugh();  # Random length

This function accepts an optional $length parameter, which lets you trim
the length of the generated laugh. This length has little to do with the
actual string length (which you can trim later, if you want), but higher
values generate longer laughs in average. Ok, peruse the code to see it!

=back


=head1 DEPENDENCIES

=for l'autore, da riempire:
   Una lista di tutti gli altri moduli su cui si basa questo modulo,
   incluse eventuali restrizioni sulle relative versioni, ed una
   indicazione se il modulo in questione è parte della distribuzione
   standard di Perl, parte della distribuzione del modulo o se
   deve essere installato separatamente.

None.


=head1 INCOMPATIBILITIES

Acme::Pain, if it will ever be released. And similars, too.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through http://rt.cpan.org/


=head1 AUTHOR

Flavio Poletti  C<< <flavio [at] polettix [dot] it> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2005, Flavio Poletti C<< <flavio [at] polettix [dot] it> >>. All rights reserved.

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

As a final note, I'll surely laugh at you if you ever try to bother
me about this module.

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

Con molta probabilità vi sghignazzerò in faccia se proverete a rompere
le scatole su questo modulo.

=cut
