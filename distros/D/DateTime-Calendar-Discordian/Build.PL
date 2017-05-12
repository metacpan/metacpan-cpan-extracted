#!/usr/bin/perl -w
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
	module_name        => 'DateTime::Calendar::Discordian',
	license            => 'perl',
	dist_version_from  => 'lib/DateTime/Calendar/Discordian.pm',
	dist_author        => 'Jaldhar H. Vyas <jaldhar@braincells.com>',
	requires           => {
                                'perl'              => 5.010,
                                'DateTime'          => 0,
                                'DateTime::Locale'  => 0,
                                'Params::Validate'  => 0,
                              },
	create_makefile_pl => 'traditional',
	sign => 1,
    meta_merge => {
        resources => {
            repository  => 'http://github.com/jaldhar/DateTime-Calendar-Discordian',
            homepage    => 'http://jaldhar.github.com/DateTime-Calendar-Discordian',
        },
    },
);

$builder->create_build_script();
