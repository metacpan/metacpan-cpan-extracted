#!/usr/local/bin/perl
BEGIN
{
    use strict;
    use Test::More;
	unless( ( $ENV{AUTHOR_TESTING} && $ENV{AUTHOR_TESTING} > 1 ) || $ENV{RELEASE_TESTING} )
	{
        plan(skip_all => 'These tests are for author or release candidate testing');
    }
};

eval { require Test::Prereq; Test::Prereq->import() }; 
plan( skip_all => 'Test::Prereq not installed; skipping' ) if $@;
prereq_ok();
