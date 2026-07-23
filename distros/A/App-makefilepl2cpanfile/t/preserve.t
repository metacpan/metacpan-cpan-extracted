use strict;
use warnings;
use Test::Most;
use App::makefilepl2cpanfile;

# This test uses the repository's own Makefile.PL as the input, which is
# intentional: it exercises generate() against a real, non-trivial file.

# The existing cpanfile contains a hand-curated 'requires' entry and a
# 'recommends' entry — both must survive regeneration.
my $existing_cpanfile = <<'END_CPANFILE';
on 'develop' => sub {
  requires   'Foo::Bar';
  recommends 'Baz::Qux';
};
END_CPANFILE

my $out = App::makefilepl2cpanfile::generate(
	makefile     => 'Makefile.PL',
	existing     => $existing_cpanfile,
	with_develop => 1,
);

# Hand-curated 'requires' entry must survive regeneration.
like $out, qr/Foo::Bar/, 'hand-curated develop requires entry is preserved';

# Hand-curated 'recommends' entry must also survive.
like $out, qr/Baz::Qux/, 'hand-curated develop recommends entry is preserved';

# The existing entries must not be duplicated by the default injections.
my @foo_hits = ($out =~ /Foo::Bar/g);
is scalar @foo_hits, 1, 'preserved requires entry appears exactly once';

my @baz_hits = ($out =~ /Baz::Qux/g);
is scalar @baz_hits, 1, 'preserved recommends entry appears exactly once';

done_testing;
