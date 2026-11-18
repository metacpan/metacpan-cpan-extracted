use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

# DBIx::Squirrel::Tooling holds every name Ekorn::Pipeline::Tooling
# exports, in a tag of the same name (roadmap 2026-0025, D6), so a name
# Ekorn adds is one to list here too. An author test, as Ekorn adds
# names in any v0.3.x, which a DBIx::Squirrel already installed can't
# hold: t/28-tooling.t checks what both export is one sub.

use DBIx::Squirrel::Tooling  ();
use Ekorn::Pipeline::Tooling ();


# The names a Tooling's tag holds, sorted.
sub tag ($name, $of) {
    no strict 'refs';    ## no critic (TestingAndDebugging::ProhibitNoStrict)
    return [sort @{ ${ "${of}::EXPORT_TAGS" }{$name} // [] }];
}

no warnings 'once';
for my $tag (sort keys %Ekorn::Pipeline::Tooling::EXPORT_TAGS) {
    my %ours = map { $_ => 1 } @{ tag($tag, 'DBIx::Squirrel::Tooling') };
    is [grep { !$ours{$_} } @{ tag($tag, 'Ekorn::Pipeline::Tooling') }], [],
        ":$tag holds every name Ekorn's does";
}

done_testing;
