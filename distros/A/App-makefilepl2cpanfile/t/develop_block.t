use strict;
use warnings;
use Test::Most;
use File::Temp qw(tempdir);
use Path::Tiny;
use App::makefilepl2cpanfile;

my $dir = tempdir(CLEANUP => 1);
chdir $dir;

path('Makefile.PL')->spew_utf8(<<'END_MF');
use ExtUtils::MakeMaker;
WriteMakefile(
	NAME      => 'Test::Dummy',
	PREREQ_PM => { 'Foo::Bar' => 0 },
);
END_MF

my $out = App::makefilepl2cpanfile::generate(
	makefile     => 'Makefile.PL',
	with_develop => 1,
);

# All four built-in develop tools must appear somewhere in the output.
for my $mod (qw(Perl::Critic Devel::Cover Test::Pod Test::Pod::Coverage)) {
	like $out, qr/\b\Q$mod\E\b/, "default develop module '$mod' is present";
}

# with_develop => 0 must produce no develop block at all.
my $no_dev = App::makefilepl2cpanfile::generate(
	makefile     => 'Makefile.PL',
	with_develop => 0,
);
unlike $no_dev, qr/on 'develop'/, 'no develop block when with_develop is false';

done_testing;
