#!/usr/bin/env perl
use 5.008001;
use strict;
use warnings;

use Data::Fake qw/Core Internet/;

my $fake_url = fake_template(
    "%s://%s%s/",
    fake_pick(qw(http https)),
    fake_pick( "", "www.", fake_digits("www##.") ),
    fake_domain(),
);

print $fake_url->() . "\n";

