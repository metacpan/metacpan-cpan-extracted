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
        'type' => 'recommends',
        'version' => '0.26',
        'name' => 'Path::Class',
        'dist' => 'KWILLIAMS/Path-Class-0.26.tar.gz'
    },
    {
        'type' => 'recommends',
        'stage' => '',
        'dist' => 'MIYAGAWA/Hash-MultiValue-0.15.tar.gz',
        'name' => 'Hash::MultiValue',
        'version' => ''
    },
    {
        'stage' => '',
        'mirror' => 'http://cpan.cpantesters.org/',
        'type' => 'recommends',
        'name' => 'Cookie::Baker',
        'dist' => 'KAZEBURO/Cookie-Baker-0.08.tar.gz',
        'version' => ''
    },
    {
        'name' => 'Try::Tiny',
        'version' => '0.28',
        'type' => 'recommends',
        'stage' => ''
    },
    {
        'stage' => '',
        'type' => 'recommends',
        'name' => 'DBI',
        'version' => ''
    },
    {
        'type' => 'recommends',
        'stage' => '',
        'version' => '0.9970',
        'name' => 'Plack'
    },
    {
        'name' => 'Test::More',
        'version' => '',
        'stage' => 'test',
        'type' => 'recommends'
    },
    {
        'name' => 'perl',
        'version' => '>= 5.10.1, != 5.17, != 5.19.3',
        'type' => 'recommends',
        'stage' => ''
    }
];

is_deeply $parser->modules, $check;

done_testing();


__DATA__
recommends 'Path::Class', 0.26,
  dist => "KWILLIAMS/Path-Class-0.26.tar.gz";
 
# omit version specifier
recommends 'Hash::MultiValue',
  dist => "MIYAGAWA/Hash-MultiValue-0.15.tar.gz";
 
# use dist + mirror
recommends 'Cookie::Baker',
  dist => "KAZEBURO/Cookie-Baker-0.08.tar.gz",
  mirror => "http://cpan.cpantesters.org/";
 
# use the full URL
recommends 'Try::Tiny', 0.28,
  url => "http://backpan.perl.org/authors/id/E/ET/ETHER/Try-Tiny-0.28.tar.gz";

recommends 'DBI';
recommends 'Plack', '0.9970';

on 'test' => sub {
    recommends 'Test::More';
};

recommends 'perl' => '>= 5.10.1, != 5.17, != 5.19.3';

