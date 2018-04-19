package Business::BR::CNJ::Format;

use strict;
use utf8;
use Exporter 'import';

our $VERSION = 0.01;
our @EXPORT_OK = qw/ cnj_format /;

sub cnj_split {
 my $t = $_[0];
 $t =~ s/[^0-9]//g;
 my @r = $t =~ /(.+)(..)(....)(.)(..)(....)$/;
 return @r;
# return ( $1, $2, $3, $4, $5, $6 );
}

#
# Format number to CNJ format NNNNNNN-DD.AAAA.J.TR.OOOO 
#
sub cnj_format {
 return sprintf( '%07d-%02d.%04d.%d.%02d.%04d', cnj_split( shift ) );
}


1;

__END__

=head1 NAME

Business::BR::CNJ::Format - Format brazilian CNJ (Conselho Nacional de Justiça) numbers, from all numbers to correctly ponctuated strings.

=head1 SYNOPSIS

   use Business::BR::CNJ::Format ( qw/ cnj_format / );

   print cnj_format('00589677720168190000');

   # Will aouput "0058967-77.2016.8.19.0000"


=head1 DESCRIPTION

This module handles CNJ numbers formating.

=head1 METHDOS

=head2 cnj_format

Format a string of only numbers into a CNJ representation ( 00589677720168190000 => 0058967-77.2016.8.19.0000 ).

References:

http://www.cnj.jus.br/busca-atos-adm?documento=2748

Art. 1º Fica instituída a numeração única de processos no âmbito do Poder Judiciário, observada a estrutura NNNNNNN-DD.AAAA.J.TR.OOOO, composta de 6 (seis) campos obrigatórios, nos termos da tabela padronizada constante dos Anexos I a VII desta Resolução. 

=over

=head1 SEE ALSO

Please check CNJ website at http://www.cnj.jus.br/

=head1 AUTHOR

Diego de Lima, E<lt>diego_de_lima@hotmail.comE<gt>

=head1 SPECIAL THANKS

This module was kindly made available by the https://modeloinicial.com.br/ team.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by Diego de Lima

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
