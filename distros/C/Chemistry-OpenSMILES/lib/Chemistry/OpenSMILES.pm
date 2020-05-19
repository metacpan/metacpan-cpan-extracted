package Chemistry::OpenSMILES;

use strict;
use warnings;
use 5.0100;

# ABSTRACT: OpenSMILES format reader
our $VERSION = '0.1.3'; # VERSION

1;

__END__

=pod

=head1 NAME

Chemistry::OpenSMILES - OpenSMILES format reader

=head1 SYNOPSIS

    use Chemistry::OpenSMILES::Parser;

    my $parser = Chemistry::OpenSMILES::Parser->new;
    my @moieties = $parser->parse( 'C#C.c1ccccc1' );

    $\ = "\n";
    for my $moiety (@moieties) {
        #  $moiety is a Graph::Undirected object
        print scalar $moiety->vertices;
        print scalar $moiety->edges;
    }

=head1 DESCRIPTION

Chemistry::OpenSMILES provides support for SMILES chemical identifiers
conforming to OpenSMILES v1.0 specification
(E<lt>http://opensmiles.org/opensmiles.htmlE<gt>).

Chemistry::OpenSMILES::Parser reads in SMILES strings and returns them
parsed to arrays of L<Graph::Undirected|Graph::Undirected> objects. Each
atom is represented by a hash. The parser does not have any chemical
inference heuristics, thus it plainly returns properties which it gets
from the SMILES descriptor. That means numbers of implicit hydrogens and
standard aromaticity representation are left for the user to derive.

=head1 CAVEATS

Element symbols in square brackets are not limited to the ones known to
chemistry. Currently any single or two-letter symbol is allowed.

Deprecated charge notations ('--' and '++') are supported.

OpenSMILES specification mandates a strict order of ring bonds and
branches:

    branched_atom ::= atom ringbond* branch*

Chemistry::OpenSMILES::Parser supports both the mandated, and inverted
structure, where ring bonds follow branch descriptions.

Whitespace is not supported yet. SMILES descriptors must be cleaned of
it before attempting reading with Chemistry::OpenSMILES::Parser.

=head1 SEE ALSO

perl(1)

=head1 AUTHORS

Andrius Merkys, E<lt>merkys@cpan.orgE<gt>

=cut
