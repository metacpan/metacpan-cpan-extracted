# $Id: Roman.pm,v 1.3 2006/08/28 15:54:02 ajk Exp $

use strict;
use warnings;

package Data::Passphrase::Graph::Roman; {
    use Object::InsideOut qw(Data::Passphrase::Graph);

    # generate a graph of the Roman alphabet
    my %Graph = (                     # a and z wrap around
        a => {z => 1, b => 1},
        z => {y => 1, a => 1},
    );
    foreach my $letter ('b' .. 'y') { # b through y link to adjacent letters

        my $ord = ord $letter;
        $Graph{$letter} = {
            chr($ord - 1) => 1,
            chr($ord + 1) => 1,
        };
    }

    # overload constructor so we can generate the alphabet graph
    sub new { shift->SUPER::new({graph => \%Graph, @_}) }
}

1;
__END__

=head1 NAME

Data::Passphrase::Graph::Roman - provide a graph of the Roman alphabet

=head1 SYNOPSIS

See L<Data::Passphrase::Graph/SYNOPSIS>.

=head1 DESCRIPTION

This module provides a graph for use with
L<Data::Passphrase|Data::Passphrase> to ensure that users don't choose
passphrases trivially based on the Roman alphabet.  The graph
interface is described in L<Data::Passphrase::Graph>.

=head1 AUTHOR

Andrew J. Korty <ajk@iu.edu>

=head1 SEE ALSO

Data::Passphrase(3), Data::Passphrase::Graph(3)
