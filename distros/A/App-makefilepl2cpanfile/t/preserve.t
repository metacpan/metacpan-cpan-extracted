use Test::Most;
use App::makefilepl2cpanfile;

my $existing = <<'EOF';
on 'develop' => sub {
  requires 'Foo::Bar';
};
EOF

my $out = App::makefilepl2cpanfile::generate(
    makefile => 'Makefile.PL',
    existing => $existing,
    with_develop => 1,
);

like $out, qr/Foo::Bar/;

done_testing;
