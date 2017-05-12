# $Id: Qwerty.pm,v 1.3 2006/08/28 15:54:02 ajk Exp $

use strict;
use warnings;

package Data::Passphrase::Graph::Qwerty; {
    use Object::InsideOut qw(Data::Passphrase::Graph);

    # generate a graph of the qwerty keyboard
    my %Graph = (
        a => {map { $_ => 1 } qw(q w s z    )},
        b => {map { $_ => 1 } qw(g h n     v)},
        c => {map { $_ => 1 } qw(d f v     x)},
        d => {map { $_ => 1 } qw(e r f c x s)},
        e => {map { $_ => 1 } qw(    r d s w)},
        f => {map { $_ => 1 } qw(r t g v c d)},
        g => {map { $_ => 1 } qw(t y h b v f)},
        h => {map { $_ => 1 } qw(y u j n b g)},
        i => {map { $_ => 1 } qw(    o k j u)},
        j => {map { $_ => 1 } qw(u i k m n h)},
        k => {map { $_ => 1 } qw(i o l   m j)},
        l => {map { $_ => 1 } qw(o p       k)},
        m => {map { $_ => 1 } qw(j k       n)},
        n => {map { $_ => 1 } qw(h j m     b)},
        o => {map { $_ => 1 } qw(    p l k i)},
        p => {map { $_ => 1 } qw(        l o)},
        q => {map { $_ => 1 } qw(    w a    )},
        r => {map { $_ => 1 } qw(    t f d e)},
        s => {map { $_ => 1 } qw(w e d x z a)},
        t => {map { $_ => 1 } qw(    y g f r)},
        u => {map { $_ => 1 } qw(    i j h y)},
        v => {map { $_ => 1 } qw(f g b     c)},
        w => {map { $_ => 1 } qw(    e s a q)},
        x => {map { $_ => 1 } qw(s d c     z)},
        y => {map { $_ => 1 } qw(    u h g t)},
        z => {map { $_ => 1 } qw(a s x      )},
    );

    # overload constructor so we can generate the qwerty graph
    sub new { shift->SUPER::new({graph => \%Graph, @_}) }
}

1;
__END__

=head1 NAME

Data::Passphrase::Graph::Qwerty - provide a graph of the qwerty keyboard

=head1 SYNOPSIS

See L<Data::Passphrase::Graph/SYNOPSIS>.

=head1 DESCRIPTION

This module provides a graph for use with
L<Data::Passphrase|Data::Passphrase> to ensure that users don't choose
passphrases trivially based on the qwerty keyboard.  The graph
interface is described in L<Data::Passphrase::Graph>.

=head1 AUTHOR

Andrew J. Korty <ajk@iu.edu>

=head1 SEE ALSO

Data::Passphrase(3), Data::Passphrase::Graph(3)
