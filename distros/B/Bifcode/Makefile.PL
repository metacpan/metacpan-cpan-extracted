#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;
use ExtUtils::MakeMaker::CPANfile;
use Pod::Text;

WriteMakefile(
    NAME         => 'Bifcode',
    ABSTRACT     => 'Simple serialization format',
    AUTHOR       => 'Mark Lawrencde <nomad@null.net>',
    VERSION_FROM => 'lib/Bifcode.pm',
    LICENSE      => 'perl_5',
    EXE_FILES    => ['bin/diff-bifcode'],
    META_ADD     => {
        resources => {
            repository => 'https://github.com/mlawren/p5-Bifcode',
        }
    },
    META_MERGE => {
        no_index => {
            package => [qw(Bifcode::Boolean)],
        },
    },
);

if ( -e '.git' ) {
    my $parser = Pod::Text->new( sentence => 0 );

    # Read POD from file.pod and write to file.txt.
    $parser->parse_from_file( 'lib/Bifcode.pm', 'README' );
}

