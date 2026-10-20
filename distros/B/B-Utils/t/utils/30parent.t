use B qw( OPf_KIDS );
use Config ();
my @empty_array = ();
test_data() for @empty_array;

{
    no warnings;

    sub test_data {
        BB() if AA();
        DD() for CC();
        my $x = 10;
        FF() while EE() < --$x;
        for ( my $y; $y; ++$y ) {
            ++$x;
        }

        0 for 0;
    }
}

use strict;
use Test::More;
use B 'svref_2object';
use B::Utils 'walkoptree_simple';

# use B::Concise;
# B::Concise::set_style(
#     "#hyphseq2 (*(   (x( ;)x))*)#exname-#class=(#addr) #arg ~#flags(?(/#private)?)(x(;~->#next)x)\n",
#     "  (*(    )*)     goto #seq\n",
#     "(?(<#seq>)?)#exname#arg(?([#targarglife])?)"
# );
# B::Concise::compile("test_data")->();

# FIXME: Consider moving this into B::Utils. But consider warning about
# adding to B::OPS and B::Concise.
sub has_branch($)
{
    my $op = shift;
    return ref($op) and $$op and ($op->flags & OPf_KIDS);
}

# Set the # of tests to run and make a table of parents
my $tests = 0;
my $root  = svref_2object( \&test_data )->ROOT;
walkoptree_simple( $root, sub {
    my $op = shift;
    $tests++ if has_branch($op)}
    );
plan( tests => ( $tests * 2 ) - 1 );

walkoptree_simple(
    $root,
    sub {
        my $op = shift;
        my $parent;

        if ("$]" >= 5.021002 and exists &B::OP::parent) {
            $parent = $op->_parent;
        } else {
            $parent = $op->parent;
        }

        if ( $$op == $$root) {
            # small discrepancy between core 5.21 (or -DPERL_OP_PARENT) returning B::NULL
            # and B::Utils::parent
            ok( !$parent or ref $parent eq 'B::NULL',
                "No parent for root " . $op->stringify );
        }
        else {

            ok( $parent, $op->stringify . " has a parent" );

            my $correct_parent;
            for ( $parent ? $parent->kids : () ) {
                if ( $$_ == $$op ) {
                    $correct_parent = $_;
                    last;
                }
            }
            is( $$correct_parent, $$op,
                $op->stringify . " has the *right* parent " . $parent);
        }
    }
);
