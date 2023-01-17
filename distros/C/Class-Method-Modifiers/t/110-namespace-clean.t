use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';

use B ();

sub is_method {
    my ($ns, $sub) = @_;
    no strict 'refs';
    my $cv = B::svref_2object(\&{"${ns}::${sub}"});
    return
        if !$cv->isa('B::CV');
    my $gv = $cv->GV;
    return
        if $gv->isa('B::SPECIAL');

    my $pack = $gv->STASH->NAME
      or return;

    return (
        $pack eq $ns
        || ($pack eq 'constant' && $gv->name eq '__ANON__')
    );
}

# see also Test::CleanNamespaces::_remaining_imports
sub imports
{
    my $ns = shift;
    no strict 'refs';

    my @symbols = grep !/::\z/ && defined &{"${ns}::$_"}, keys %{"${ns}::"};
    return grep !is_method($ns, $_), @symbols;
}

{
    package Foo;
    sub foo { print "normal Foo::foo sub\n"; }
    sub bar { print "normal Foo::bar sub\n"; }
    sub baz { print "normal Foo::baz sub\n"; }
}

ok(
    !(grep $_ eq 'foo' || $_ eq 'bar' || $_ eq 'baz', imports('Foo')),
    "original subs are not in Foo's list of imports",
)
    or note('Foo has imports: ' . join(', ', imports('Foo')));

# this should also pass:
# namespaces_clean('Foo');

eval {
    package Foo;
    use Class::Method::Modifiers;
    Test::More::note 'redefining Foo::foo';

    around foo => sub {
        my $orig = shift;
        my $ret = $orig->(@_);
        print "wrapped foo sub\n"
    };
    around bar => sub { print "wrapped bar sub\n" };
    around baz => sub { print "wrapped baz sub\n" };
};

ok(
    !(grep $_ eq 'foo' || $_ eq 'bar' || $_ eq 'baz', imports('Foo')),
    "modified subs are not in Foo's list of imports",
)
    or note('Foo has imports: ' . join(', ', imports('Foo')));

# this should also still pass, except for the 'before', 'around' and 'after'
# subs that CMM itself imported which should be cleaned:
# namespaces_clean('Foo');

done_testing;
