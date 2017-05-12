#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

if ( not $ENV{TEST_AUTHOR} ) {
    my $msg = 'Author test.  Set TEST_AUTHOR environment variable to a true value to run.';
    plan( skip_all => $msg );
}

# check that Test::Spelling is installed
eval { require Test::Spelling; Test::Spelling->import() };

# now check that the spell command is installed
my $found;
for my $dir ( split /:/, $ENV{PATH} ) {
    next if !-d $dir;
    next if !-x "$dir/spell";

    $found = 1;
    last;
}

plan skip_all => "Test::Spelling required for testing POD spelling" if $@;
plan skip_all => "spell command required for testing POD spelling" if !$found;

add_stopwords(qw/
    YAML NSW Hornsby templatecmd Arg arg var vars XHTML html CGI min Gtk dir fullname ttk txt pl funcs isa obj sig sigs
    MathML
    Param
    SVG
    TODO
    criticise
    perlcriticrc
    svg
    github
    CPAN
    MERCHANTIBILITY
    Makemaker
    OSX
    README
    SMB
    TIMESTAMP
    VARCHAR
    Xoo
    bugtracker
    gpl
    initialiser
    metadata
    param
    params
    pm
    yml
/);
all_pod_files_spelling_ok();
