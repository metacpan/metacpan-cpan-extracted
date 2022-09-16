#!/usr/bin/perl

use strict;
use warnings;

use CPANfile::Parse::PPI;
use Test::More;
use Data::Dumper;

my $cpanfile = do { local $/; <DATA> };
my $parser   = CPANfile::Parse::PPI->new( \$cpanfile );

my $check = [
    {
        'stage' => '',
        'type' => 'requires',
        'version' => '0.26',
        'name' => 'Path::Class',
        'feature' => '',
        'dist' => 'KWILLIAMS/Path-Class-0.26.tar.gz'
    },
    {
        'type' => 'requires',
        'stage' => '',
        'dist' => 'MIYAGAWA/Hash-MultiValue-0.15.tar.gz',
        'name' => 'Hash::MultiValue',
        'feature' => '',
        'version' => ''
    },
    {
        'stage' => '',
        'mirror' => 'http://cpan.cpantesters.org/',
        'type' => 'requires',
        'name' => 'Cookie::Baker',
        'dist' => 'KAZEBURO/Cookie-Baker-0.08.tar.gz',
        'feature' => '',
        'version' => ''
    },
    {
        'name' => 'Try::Tiny',
        'version' => '0.28',
        'type' => 'requires',
        'feature' => '',
        'stage' => ''
    },
    {
        'stage' => '',
        'type' => 'requires',
        'name' => 'DBI',
        'feature' => '',
        'version' => ''
    },
    {
        'type' => 'requires',
        'stage' => '',
        'version' => '0.9970',
        'feature' => '',
        'name' => 'Plack'
    },
    {
        'name' => 'Test::More',
        'version' => '',
        'stage' => 'test',
        'feature' => '',
        'type' => 'requires'
    },
    {
        'stage' => 'test',
        'type' => 'requires',
        'version' => '0.1',
        'feature' => '',
        'name' => 'Test::Warn'
    },
    {
        'stage' => 'develop',
        'type' => 'requires',
        'name' => 'Module::Install',
        'feature' => '',
        'version' => '0.99'
    },
    {
        'stage' => 'test',
        'type' => 'requires',
        'version' => '0.26',
        'feature' => '',
        'name' => 'Path::Class',
    },
    {
        'stage' => '',
        'type' => 'requires',
        'version' => '0.26',
        'feature' => 'xyz',
        'name' => 'Path::Class',
    },
    {
        'name' => 'perl',
        'version' => '>= 5.10.1, != 5.17, != 5.19.3',
        'type' => 'requires',
        'feature' => '',
        'stage' => ''
    }
];

is_deeply $parser->modules, $check;

done_testing();


__DATA__
requires 'Path::Class', 0.26,
  dist => "KWILLIAMS/Path-Class-0.26.tar.gz";
 
# omit version specifier
requires 'Hash::MultiValue',
  dist => "MIYAGAWA/Hash-MultiValue-0.15.tar.gz";
 
# use dist + mirror
requires 'Cookie::Baker',
  dist => "KAZEBURO/Cookie-Baker-0.08.tar.gz",
  mirror => "http://cpan.cpantesters.org/";
 
# use the full URL
requires 'Try::Tiny', 0.28,
  url => "http://backpan.perl.org/authors/id/E/ET/ETHER/Try-Tiny-0.28.tar.gz";

requires 'DBI';
requires 'Plack', '0.9970';

on 'test' => sub {
    requires 'Test::More';
};

test_requires 'Test::Warn', 0.1;
author_requires 'Module::Install', 0.99;

on 'test' => sub {
    requires 'Path::Class', 0.26;
};

feature 'xyz', 'great new feature' => sub {
    requires 'Path::Class', 0.26;
};

requires 'perl' => '>= 5.10.1, != 5.17, != 5.19.3';

