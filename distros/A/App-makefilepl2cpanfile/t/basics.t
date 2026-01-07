use Test::Most;
use File::Temp qw(tempdir);
use File::Slurp qw(write_file);

BEGIN { use_ok('App::makefilepl2cpanfile') }

my $dir = tempdir(CLEANUP => 1);
chdir $dir;

write_file 'Makefile.PL', <<'EOF';
WriteMakefile(
	MIN_PERL_VERSION => '5.010',
	PREREQ_PM => { 'Try::Tiny' => 0 },
);
EOF

my $out = App::makefilepl2cpanfile::generate(
	makefile => 'Makefile.PL'
);

like $out, qr/requires 'Try::Tiny'/;
like $out, qr/'perl', '5.010'/;

done_testing();
