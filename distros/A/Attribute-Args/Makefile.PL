#!/usr/bin/perl

use strict;
use warnings;
use YAML;
use ExtUtils::MakeMaker;

###

my $deps = {
	'Attribute::Handlers' => 0,
	'YAML' => 0,
	'Test::Strict' => 0,
};
my $name = 'Attribute::Args';
my $author = 'Alex Alexandrov <swined@cpan.org>';

###

my $main = $name;
$main =~ s/::/\//g;
$main = "lib/${main}.pm";

(my $dist = $name) =~ s/::/-/g;

my $ver = 0;
open F, '<', $main;
$ver = eval $_ while !$ver && (local $_ = <F>);
close F;

open F, '>', 'META.yml';
print F Dump {
	name		=> $name,
	version		=> $ver,
	version_from	=> $main,
	installdirs	=> 'site',
	requires	=> $deps,
	distribution_type => 'module',
	generated_by	=> "ExtUtils::MakeMaker version $ExtUtils::MakeMaker::VERSION",
};
close F;

###

WriteMakefile(
    NAME                => $name,
    AUTHOR              => $author,
    VERSION_FROM        => $main,
    ABSTRACT_FROM       => $main,
    PL_FILES            => {},
    PREREQ_PM		=> $deps,
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => "${dist}-* META.yml" },
);
