package Bio::MUST::Drivers;
# ABSTRACT: Bio::MUST classes for driving external programs
# CONTRIBUTOR: Arnaud DI FRANCO <arnaud.difranco@gmail.com>
# CONTRIBUTOR: Amandine BERTRAND <amandine.bertrand@doct.uliege.be>
# CONTRIBUTOR: Loic MEUNIER <loic.meunier@doct.uliege.be>
$Bio::MUST::Drivers::VERSION = '0.180770';
use strict;
use warnings;

use Bio::MUST::Drivers::Blast;
use Bio::MUST::Drivers::Hmmer;
use Bio::MUST::Drivers::Cap3;
use Bio::MUST::Drivers::CdHit;
use Bio::MUST::Drivers::Exonerate;
use Bio::MUST::Drivers::Exonerate::Aligned;
use Bio::MUST::Drivers::ClustalO;
use Bio::MUST::Drivers::Mafft;

1;

__END__

=pod

=head1 NAME

Bio::MUST::Drivers - Bio::MUST classes for driving external programs

=head1 VERSION

version 0.180770

=head1 SYNOPSIS

    # TODO

=head1 DESCRIPTION

    # TODO

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 CONTRIBUTORS

=for stopwords Arnaud DI FRANCO Amandine BERTRAND Loic MEUNIER

=over 4

=item *

Arnaud DI FRANCO <arnaud.difranco@gmail.com>

=item *

Amandine BERTRAND <amandine.bertrand@doct.uliege.be>

=item *

Loic MEUNIER <loic.meunier@doct.uliege.be>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
