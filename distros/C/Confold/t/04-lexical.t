#!perl
# The operator is lexically scoped: it exists between `use Confold` and the end
# of the enclosing block, and nowhere else.
use 5.038;
use strict;
use warnings;
use Test::More;

plan tests => 7;

{
    use Confold;
    my $x = <: 42;
    is $x, 42, 'active in the importing scope';

    {
        my $y = <: "nested";
        is $y, "nested", 'active in a nested block';
    }

    {
        no Confold;
        # `<:` is no longer the operator here. It is not valid syntax on its
        # own either, so the check is that the file compiles at all and that
        # the outer scope is unaffected.
        my $z = 7;
        is $z, 7, 'no Confold does not disturb the enclosing code';
    }

    my $w = <: 9;
    is $w, 9, 'still active after the disabled block closes';
}

# Reading from a handle is the same `<` the operator borrows, so check an
# active scope leaves it alone. Only a term position is ever claimed.
{
    use Confold;
    open my $fh, '<', $0 or die "cannot read $0: $!";
    my $line = <$fh>;
    close $fh;
    like $line, qr/^#!perl/, 'readline still works inside an active scope';
}

{
    # A string eval outside the lexical scope must not see the operator.
    my $ok = eval 'my $q = <: 5; 1';
    ok !$ok, 'the operator is unavailable in an eval outside the scope';
}

{
    # ... and available inside one.
    use Confold;
    my $ok = eval 'my $q = <: 5; $q';
    is $ok, 5, 'the operator is available in an eval inside the scope';
}
