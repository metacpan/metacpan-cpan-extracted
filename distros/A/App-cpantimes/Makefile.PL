my $author = ((grep{ $_ eq '--author' } @ARGV) or -d '.git' && `git remote -v` =~ /git\@github/);
print STDERR "Running as an author mode!\n" if $author;

# Author: perl Makefile.PL packs 'script/cpanm.PL' -> 'cpanm'
if ($author) {
	shift @ARGV;
	system $^X, "script/build.PL" and die $?;
}

# perl Makefile.PL (from git repo) copies 'cpanm' -> 'bin/cpanm'
if (-e 'cpant') {
	print STDERR "Generating bin/cpant from cpant\n";
	open my $in,  "<cpant"     or die $!;
	open my $out, ">bin/cpant" or die $!;
	while (<$in>) {
		s|^#!/usr/bin/env perl|#!perl|; # so MakeMaker can fix it
		print $out $_
	}
}

use ExtUtils::MakeMaker;

my %args = (
	NAME => 'App::cpantimes',
	VERSION_FROM => "lib/App/cpantimes.pm",
	ABSTRACT => 'Get, unpack, build, install and report on modules from CPAN.',
	PREREQ_PM => {
		'Module::Build' => 0.36,
		'ExtUtils::MakeMaker' => 6.31,
		'ExtUtils::Install' => 1.46,
	},
	LICENSE => 'perl',
	EXE_FILES => [ 'bin/cpant' ],
);

my $eummv = eval ($ExtUtils::MakeMaker::VERSION);
if ($eummv >= 6.45) {
    $args{META_MERGE} = {
        resources => {
            repository => 'https://bitbucket.org/tobyink/p5-app-cpantimes',
            bugtracker => 'https://rt.cpan.org/Ticket/Create.html?Queue=App-cpantimes',
        },
    };
}

WriteMakefile(%args);
