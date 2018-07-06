[![Build Status](https://travis-ci.org/rocky/p5-B-DeparseTree.png)](https://travis-ci.org/rocky/p5-B-DeparseTree)

Synopsis
--------

Perl's B::Deparse but we save abstract tree information and associate
that with Perl text fragments.  These are fragments accessible by OP
address. With this, you can determine get exactly where you inside Perl in
a program with granularity finer that at a line number boundary.

Uses for this could be in stack trace routines like _Carp_. It is used
in the [deparse](https://metacpan.org/pod/Devel::Trepan::Deparse)
command extension to
[Devel::Trepan](https://metacpan.org/pod/Devel::Trepan).

Example
-------

    use B::DeparseTree;
    my $deparse = B::DeparseTree->new();

    # create a subroutine to deparse...
    sub my_abs($) {
        return $a < 0 ? -$a : $a;
    };

    my $deparse_tree = B::DeparseTree->new();
    my $tree_node = $deparse_tree->coderef2info(\&my_abs);
    print $tree_node->{text};

The above produces:

    ($)
    {
        return $a < 0 ? -$a : $a
    }

but the result are reconstructed purely from the OPnode tree. To show
parent-child information in the tree:

    use B::DeparseTree::Fragment;
    B::DeparseTree::Fragment::dump_relations($deparse_tree);

which produces:

    0: ==================================================
    Child info:
    	addr: 0xe87280, parent: 0x16684c0
    	op: pushmark
    	text: return $a < 0 ? -$a : $a

    ($)...
        return $a < 0 ? -$a : $a
        ~~~~~~
    0: ==================================================
    1: ==================================================
    Child info:
    	addr: 0xe8b550, parent: 0xe9cba0
    	op: gvsv
    	text: $a

    return $a < 0 ? -$a : $a
           --
    1: ==================================================
    2: ==================================================
    Child info:
    	addr: 0xe8cd20, parent: 0xe9cba0
    	op: gvsv
    	text: $a

    return $a < 0 ? -$a : $a
           --
    2: ==================================================
    3: ==================================================
    Child info:
    	addr: 0xe966e0, parent: 0xe9cba0
    	op: B::IV=SCALAR(0x18e5b98)
    	text: 0

    return $a < 0 ? -$a : $a
                -
    3: ==================================================
    4: ==================================================
    Child info:
    	addr: 0xe9cba0, parent: 0x1668650
    	op: lt
    	text: $a < 0

    return $a < 0 ? -$a : $a
           ------
    4: ==================================================
    5: ==================================================
    Child info:
    	addr: 0xf2b520, parent: 0x1668650
    	op: negate
    	text: -$a

    return $a < 0 ? -$a : $a
                    ---
    5: ==================================================
    6: ==================================================
    Child info:
    	addr: 0x1327200, parent: 0x1667c60
    	op: nextstate
    	text:

    6: ==================================================
    7: ==================================================
    Child info:
    	addr: 0x161a4f0, parent: 0xf2b520
    	op: gvsv
    	text: $a

    return $a < 0 ? -$a : $a
                     --
    7: ==================================================
       ....


Installation
------------

Currently we support Perl 5.14, 5.16, 5.18, 5.20, 5.22, 5.24,
5.26, and 5.28.

To install this Devel::Trepan, run the following commands:

	perl Build.PL
	make
	make test
	[sudo] make install

License and Copyright
---------------------

Copyright (C) 2015, 2017, 2018 Rocky Bernstein <rocky@cpan.org>

See also
--------

* [Exact Perl location with B::Deparse (and Devel::Callsite)](http://blogs.perl.org/users/rockyb/2015/11/exact-perl-location-with-bdeparse-and-develcallsite.html)
* [Rewriting B:Deparse and Reintroducing B::DeparseTree and (part 1)](http://blogs.perl.org/users/rockyb/2018/06/introducing-bdeparsetree-and-rewriting-bdeparse-part-1.html)
