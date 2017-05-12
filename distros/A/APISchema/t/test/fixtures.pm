package t::test::fixtures;
use strict;
use warnings;
use APISchema::DSL;

sub prepare_bmi {
    APISchema::DSL::process {
        include 't/fixtures/bmi.def';
    };
}

sub prepare_family {
    APISchema::DSL::process {
        include 't/fixtures/family.def';
    };
}

sub prepare_user {
    APISchema::DSL::process {
        include 't/fixtures/user.def';
    };
}

sub prepare_author {
    APISchema::DSL::process {
        include 't/fixtures/author.def';
    };
}

sub prepare_status {
    APISchema::DSL::process {
        include 't/fixtures/status.def';
    };
}

1;
