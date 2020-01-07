package Bio::Variation;
$Bio::Variation::VERSION = '1.7.5';
use utf8;
use strict;
use warnings;

1;

# ABSTRACT: BioPerl variation-related functionality
# AUTHOR: Heikki Lehväslaiho <heikki-at-bioperl-dot-org>
# OWNER: See the individual modules for their copyright holders
# LICENSE: Perl_5

=head1 SYNOPSIS

See L<Bio::Perl> for examples.

=head1 DESCRIPTION

These classes are part of "Computational Mutation Expression Toolkit"
project at European Bioinformatics Institute
<http://www.ebi.ac.uk/mutations/toolkit/>, but they are written to be
as general as possinble.

Bio::Variation name space contains modules to store sequence variation
information as differences between the reference sequence and changes
sequences. Also included are classes to write out and recrete objects
from EMBL-like flat files and XML. Lastly, there are simple classes to
calculate values for sequence change objects.

See "Computational Mutation Expression Toolkit" web pages for more
information:

	http://www.ebi.ac.uk/mutations/toolkit/

=cut

__END__
