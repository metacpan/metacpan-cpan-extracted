#!/usr/bin/perl
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %parms = (
    'NAME'         => 'Bio::Phylo::Forest::DBTree',
    'AUTHOR'       => 'Rutger Vos',
    'EXE_FILES'    => [
        'script/megatree-loader',
        'script/megatree-ncbi-loader',
        'script/megatree-bold-loader',
        'script/megatree-phylotree-loader',
        'script/megatree-pruner'
    ],
    'VERSION_FROM' => 'lib/Bio/Phylo/Forest/DBTree.pm',
    'LICENSE'      => 'perl',
    'ABSTRACT'     => 'DBIx::Class-backed, Bio::Phylo-like API for large phylogenies',
    'PREREQ_PM'    => {
    	'DBIx::Class' => '0',
    	'Bio::Phylo'  => '0.52',
    	'DBD::SQLite' => '0',
    },
    'dist'         => {
        'COMPRESS' => 'gzip -9f',
        'SUFFIX'   => 'gz',
        'TARFLAGS' => '--format=ustar -c -v -f',
    },
);

if ( $ExtUtils::MakeMaker::VERSION ge '6.46' ) {
    $parms{META_MERGE} = {
        resources => {
            homepage    => 'http://biophylo.blogspot.com/',
            bugtracker  => 'https://github.com/rvosa/bio-phylo-forest-dbtree/issues',
            repository  => 'git://github.com/rvosa/bio-phylo-forest-dbtree.git',
            license     => 'http://dev.perl.org/licenses/',
            MailingList => 'mailto:bio-phylo@googlegroups.com',
        },
    };
}

WriteMakefile( %parms );
