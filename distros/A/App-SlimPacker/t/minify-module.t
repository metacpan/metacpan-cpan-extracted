#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin;

use lib "$FindBin::Bin/../lib";
# Only the minifier module — the whole point is that minification does not
# need the App::SlimPacker bundling facade.
use App::SlimPacker::Minify qw(process process_deps minify_file name_gen
    needs_space module_deps collect_bundle_globals rename_module_name);

# ── standalone single-file minification ───────────────────────────────────
{
    # `a`/`b` are reserved single-character names, so the first generated
    # short is `c`.
    is process('my $very_long_name = 1; print $very_long_name;', rename => 1),
       'my$c=1;print$c;', 'process renames my vars standalone';
    is process('my $x = 1;', rename => 0), 'my$x=1;', 'rename => 0 keeps names';
    is process("# c\nmy \$x = 1;\n=pod\n\n=cut\nmy \$y = 2;"),
       "my\$x=1;my\$y=2;", 'comments and POD pruned';
}

# ── bundle-aware renaming, no bundling module loaded ──────────────────────
{
    my $a = 'package App::Foo; our $count = 3; sub bump { $count++ }';
    my $b = 'package main; use App::Foo qw(); $App::Foo::count = 5;';
    my ($gmap, $glex, $gsubs, $mods) = collect_bundle_globals($a, $b);
    my $ma = process($a, global_rename => $gmap, global_lexicals => $glex,
                         global_subs => $gsubs, global_modules => $mods);
    my $mb = process($b, global_rename => $gmap, global_lexicals => $glex,
                         global_subs => $gsubs, global_modules => $mods);
    like $ma, qr/\Apackage \w+::\w+;our\$c=3;sub a\{\$c\+\+\}\z/,
        'process applies bundle-aware renames standalone';
    like $mb, qr/\Apackage main;use \w+::\w+ qw\(\);\$\w+::\w+::c=5;\z/,
        'cross-package global reference follows the rename standalone';
}

# ── process_deps and module_deps share the same dependency list ───────────
{
    my ($min, @deps) = process_deps('use App::Foo; require App::Bar;');
    is scalar(@deps), 2, 'process_deps returns 2 deps';
    is_deeply \@deps, [ module_deps('use App::Foo; require App::Bar;') ],
        'process_deps and module_deps agree';
}

# ── name_gen / needs_space primitives ─────────────────────────────────────
{
    is name_gen(0), 'a',  'name_gen 0 → a';
    is name_gen(25), 'z', 'name_gen 25 → z';
    is name_gen(26), 'aa', 'name_gen 26 → aa';
    require PPI;
    my $doc = PPI::Document->new(\'print foo');
    my @words = grep { $_->isa('PPI::Token::Word') }
                @{ $doc->find('PPI::Token') };
    ok needs_space($words[0], $words[1]), 'needs_space fires between glued words';
    my $doc2 = PPI::Document->new(\'my $x = 1;');
    my @t2 = @{ $doc2->find('PPI::Token') };
    ok !needs_space($t2[0], $t2[1]), 'no space needed between word and symbol';
}

done_testing;