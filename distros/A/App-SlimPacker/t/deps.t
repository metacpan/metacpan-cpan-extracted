#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin;

use lib "$FindBin::Bin/../lib";
use App::SlimPacker qw(perl_switches plugin_search_paths inline_plugins module_deps);

# ── perl_switches: -m / -M / -e / -E → program text ───────────────────────
{
    is perl_switches(['Foo'], [], [], []), "use Foo ();\n", '-m Foo → use Foo ();';
    is perl_switches([], ['Foo'], [], []), "use Foo;\n",    '-M Foo → use Foo;';
    is perl_switches([], ['Foo=bar,baz'], [], []), "use Foo qw(bar baz);\n", '-M Foo=bar,baz → use Foo qw(bar baz);';
    is perl_switches([], ['Foo=5.010'], [], []), "use Foo 5.010;\n", '-M Foo=5.010 → use Foo 5.010;';
    is perl_switches([], ['5.010'], [], []), "use 5.010;\n", '-M 5.010 → use 5.010;';
    is perl_switches([], [], ['print 1;'], []), "print 1;\n", '-e CODE → code';
    is perl_switches([], [], [], ['say q(hi);']),
        qq{BEGIN{require feature;eval{feature->import(':all');1}or feature->import(':5.10')}\nsay q(hi);\n},
        '-E CODE → feature on + code';
    is perl_switches([], ['List::Util=sum'], ['print sum(1,2);'], []),
       "use List::Util qw(sum);\nprint sum(1,2);\n", '-m/-M before -e code';
}

# ── plugin_search_paths ───────────────────────────────────────────────────
{
    my $p = plugin_search_paths('use Module::Pluggable (search_path => q{App::Foo});');
    is_deeply $p, { 'App::Foo' => 1 }, 'scalar search_path found';
    $p = plugin_search_paths(q{use Module::Pluggable (search_path => ['A::B','C::D'], require => 1);});
    is_deeply $p, { 'A::B' => 1, 'C::D' => 1 }, 'arrayref search_path found';
    $p = plugin_search_paths(q{use Module::Pluggable (search_path => "Dbl::Quoted");});
    is_deeply $p, { 'Dbl::Quoted' => 1 }, 'double-quoted search_path found';
    $p = plugin_search_paths('use Module::Pluggable (search_path => [q{Foo::A}, "Foo::B", q{Baz::C}]);');
    is_deeply $p, { 'Foo::A' => 1, 'Foo::B' => 1, 'Baz::C' => 1 }, 'arrayref with mixed quote styles';
    $p = plugin_search_paths('print 1;');
    is_deeply $p, {}, 'no Module::Pluggable → empty';
    $p = plugin_search_paths('use Module::Pluggable (inner => 1);');
    is_deeply $p, {}, 'Module::Pluggable without search_path → empty';
}

# ── inline_plugins ─────────────────────────────────────────────────────────
{
    my $classes = {
        'App::Foo::A'        => 1,
        'App::Foo::B'        => 1,
        'App::Foo::Deep::C'  => 1,   # nested → not a plugin (one level deep)
        'App::Bar::X'        => 1,
    };
    my $boot = 'use Module::Pluggable (search_path => q{App::Foo});' . "\n" . 'my @p = plugins();';
    my $out = inline_plugins($boot, $classes);
    like $out, qr/\(\s*"App::Foo::A","App::Foo::B"\s*\)/, 'search_path inlined, sorted, one level only';
    unlike $out, qr/Module::Pluggable/, 'use Module::Pluggable removed';
    unlike $out, qr/App::Foo::Deep::C/, 'nested class not inlined';
    like $out, qr/my \@p = /, 'rest of program preserved';
    my $ary = inline_plugins('use Module::Pluggable (search_path => [q{App::Foo}, q{App::Bar}]);' . "\n" . 'my @p = plugins();', $classes);
    like $ary, qr/"App::Bar::X"/,     'arrayref search_path matches both namespaces';
    like $ary, qr/"App::Foo::A"/,     'arrayref search_path matches both namespaces';
    like $ary, qr/require "App\/Foo\/A\.pm";/, 'inlined plugin gets a require to load it';
    like $ary, qr/require "App\/Foo\/B\.pm";/, 'each inlined plugin gets its own require';
    is inline_plugins('print 1;', $classes), 'print 1;', 'no Module::Pluggable → unchanged';
    my $kept = inline_plugins('use Module::Pluggable ();' . "\n" . 'my @p = plugins();', $classes);
    like $kept, qr/Module::Pluggable/, 'no search_path → Module::Pluggable kept';
    like $kept, qr/plugins\(\)/,       'no search_path → plugins() untouched';
}

# ── module_deps: use / require ─────────────────────────────────────────────
{
    my @d = module_deps('use App::Foo;');
    is_deeply \@d, ['App::Foo'], 'use App::Foo → (App::Foo)';
    @d = module_deps('use App::Foo 1.2; require Baz::Qux;');
    is_deeply \@d, ['App::Foo', 'Baz::Qux'], 'use + require → (Foo, Qux)';
}

# ── module_deps: use parent / use base ─────────────────────────────────────
{
    my @d = module_deps('use parent qw(A::B C::D);');
    is_deeply \@d, ['A::B', 'C::D'], 'use parent qw(A::B C::D)';
    @d = module_deps('use base q{Z::Y};');
    is_deeply \@d, ['Z::Y'], 'use base q{Z::Y}';
}

# ── module_deps: require "Foo/Bar.pm" string form ──────────────────────────
{
    my @d = module_deps('require "App/Saisons.pm";');
    is_deeply \@d, ['App::Saisons'], 'require "App/Saisons.pm" → App::Saisons';
}

# ── module_deps: pragmas skipped ───────────────────────────────────────────
{
    my @d = module_deps('use strict; use warnings; use 5.010; use lib "lib";');
    is_deeply \@d, [], 'pragmas and version deps → empty';
}

# ── module_deps: require 5.010 skipped ─────────────────────────────────────
{
    my @d = module_deps('require 5.010;');
    is_deeply \@d, [], 'require 5.010 → empty';
}

# ── module_deps: empty source ──────────────────────────────────────────────
{
    my @d = module_deps('');
    is_deeply \@d, [], 'empty source → empty deps';
}

done_testing;