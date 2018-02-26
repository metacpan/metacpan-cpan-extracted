#!/usr/bin/env perl

use strict;
use warnings;
use Data::Section -setup;
use Test::More;
use Config::Pg::ServiceFile;

# ABSTRACT: testing Config::Pg::ServiceFile (primarily that comments work)

subtest basic => \&test_basic;

sub test_basic {
    my $data = Config::Pg::ServiceFile->read_string(
        ${__PACKAGE__->section_data('pg_service.conf')}
    );
    ok exists $data->{bar};
    ok exists $data->{foo};
}

done_testing;

__DATA__

__[ pg_service.conf ]__

[foo]
host=localhost
port=5432
user=foo
dbname=db_foo
password=password

# a comment
[bar]
host=localhost
port=5432
user=bar
dbname=db_bar
#password=password
