#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Context::Vars;

# What can be imported, into which package, and that one name is one
# variable wherever it is imported.

# ---- strict ---------------------------------------------------------------
ok(eval q{package I::A; use strict; use Context::Vars qw($imp_a); $imp_a = 1; 1},
   'an imported name compiles under strict') or diag $@;
ok(!eval q{package I::B; use strict; $imp_a = 1; 1},
   'the same name in a package that did not import it does not');
like($@, qr/Global symbol "\$imp_a" requires explicit package name/, 'for the reason strict gives');
ok(eval q{package I::C; use strict; use warnings FATAL => 'all'; use Context::Vars qw($imp_once); 1},
   'a name imported and never used raises no warning') or diag $@;
ok(eval q{package I::D; use strict; use Context::Vars; 1}, 'use with no list imports nothing and is not an error')
    or diag $@;
ok(eval q{package I::E; use strict; use Context::Vars qw($e1 $e2 $e3); ($e1, $e2, $e3) = (1, 2, 3); 1},
   'several names in one use') or diag $@;
ok(eval q{package I::F; use strict; use Context::Vars q{$single}; $single = 1; 1},
   'a single name given as one string') or diag $@;

# ---- what is refused, at compile time, naming the argument ------------------
for my $bad ('@list', '%map', '&code', '*glob', 'bare', '$', '$1', '$9lives', '$Other::name',
             '$a b', '$a-b', '$x $y', '', '$caf' . chr(233)) {
    my $shown = $bad;
    ok(!eval "package I::Bad; use Context::Vars q\x01$bad\x01; 1", "'$shown' is refused");
    like($@, qr/^Context::Vars: cannot import '\Q$bad\E'/, "'$shown': the message names the argument");
    like($@, qr/BEGIN failed/, "'$shown': and it is a compile-time failure");
}
for my $forced (qw($_ $ENV $INC $ARGV $ARGVOUT $STDIN $STDOUT $STDERR)) {
    ok(!eval "package I::Forced; use Context::Vars q{$forced}; 1", "'$forced' is refused");
    like($@, qr/perl keeps that name in package main/, "'$forced': because perl would never look at it");
}
ok(eval q{package I::Under; use strict; use Context::Vars qw($_private $__ $a1 $A_b_C); $_private = 1; 1},
   'a leading underscore, a double underscore, digits and mixed case are names') or diag $@;

# ---- the scalar is one of ours ----------------------------------------------
{
    package I::Kind;
    use Context::Vars qw($kind);
    Test::More::ok(Context::Vars::_is_var(\$kind), 'an imported scalar is recognised as a variable');
    my $plain;
    our $pkg;
    Test::More::ok(!Context::Vars::_is_var(\$plain), 'a lexical is not');
    Test::More::ok(!Context::Vars::_is_var(\$pkg), 'nor an ordinary package scalar');
}

# ---- one name, one variable ---------------------------------------------------
# Each assignment is written in the sub that reads it back: an assignment in a
# helper sub would end when the helper returned.
{ package I::One; use Context::Vars qw($shared $only_one); sub get { $shared } sub ref_of { \$shared } }
{ package I::Two; use Context::Vars qw($shared $only_two); sub get { $shared } sub ref_of { \$shared } }
Context::Vars::_t_scope(sub {
    # The scope began from the program context, which the evals above put
    # names into, so the counts here are counted from where it started.
    my $start = Context::Vars::_t_count();
    $I::One::shared = 'from one';
    is(I::Two::get(), 'from one', 'assigned in one package and read in another');
    $I::Two::shared = 'from two';
    is(I::One::get(), 'from two', 'and the other way');
    is(I::One::ref_of(), I::Two::ref_of(), 'the two packages hold the very same scalar');
    is(Context::Vars::_t_count() - $start, 1, 'and the context holds one name for it');
    $I::One::only_one = 'a';
    $I::Two::only_two = 'b';
    is(Context::Vars::_t_count() - $start, 3, 'different names are different variables');
});
{
    package I::Again;
    use Context::Vars qw($shared);
    use Context::Vars qw($shared);
    Test::More::is(\$shared, I::One::ref_of(), 'importing a name twice changes nothing');
}

# ---- import called by hand, at run time ---------------------------------------
{
    package I::Late;
    Context::Vars->import('$late');
    no strict 'refs';
    Context::Vars::_t_scope(sub {
        ${'I::Late::late'} = 'set';
        Test::More::is(${'I::Late::late'}, 'set', 'import called at run time makes the variable too');
    });
}

# ---- recorded: a name the package already has ---------------------------------
{
    my @r;
    eval q{
        package I::Lex; use strict;
        my $taken = 'lexical';
        use Context::Vars qw($taken);
        push @r, "my then import reads '$taken'";
        1;
    } or push @r, "my then import: $@";
    eval q{
        package I::Our; use strict;
        our $held = 'assigned by the our statement';
        use Context::Vars qw($held);
        Context::Vars::_t_scope(sub { $held = 'context value'; push @r, "our then import, inside a scope '$held'" });
        push @r, "our then import, outside it '" . (defined $held ? $held : 'undef') . "'";
        1;
    } or push @r, "our then import: $@";
    eval q{
        package I::Earlier; use strict;
        our $before;
        BEGIN { $before = 'package value set before the import' }
        use Context::Vars qw($before);
        push @r, "a value set before the import reads '" . (defined $before ? $before : 'undef') . "'";
        1;
    } or push @r, "value before import: $@";
    diag $_ for @r;
    is($r[0], "my then import reads 'lexical'", 'a lexical of the same name hides the import, as it hides any package variable');
    is($r[1], "our then import, inside a scope 'context value'", 'a name declared with our becomes the variable');
    is($r[2], "our then import, outside it 'assigned by the our statement'",
       'the assignment in an our statement runs after the import, so it assigns the variable');
    is($r[3], "a value set before the import reads 'undef'", 'a value the package scalar had before the import is gone');
}

is(Context::Vars::_depth(), 0, 'nothing is left entered');
is(Context::Vars::_live_holders(), 0, 'and no holder is out');

done_testing;
