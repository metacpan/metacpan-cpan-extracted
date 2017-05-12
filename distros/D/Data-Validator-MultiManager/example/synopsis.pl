#!/usr/bin/env perl
use strict;
use warnings;

use Data::Validator::MultiManager;

my $manager = Data::Validator::MultiManager->new;
# my $manager = Data::Validator::MultiManager->new('Data::Validator::Recursive');
$manager->common(
    category => { isa => 'Int' },
);
$manager->add(
    collection => {
        id => { isa => 'ArrayRef' },
    },
    entry => {
        id => { isa => 'Int' },
    },
);

my $param = {
    category => 1,
    id       => [1,2],
};

my $result = $manager->validate($param);

if (my $e = $result->errors) {
    errors_common($e);
    # $result->invalid is guess to match some validator
    if ($result->invalid eq 'collection') {
        errors_collection($e);
    }
    elsif ($result->invalid eq 'entry') {
        errors_entry($e);
    }
}
else {
    if ($result->valid eq 'collection') {
        process_collection($result->value);
    }
    elsif ($result->valid eq 'entry') {
        process_entry($result->value);
    }
}
