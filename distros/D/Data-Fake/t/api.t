use 5.008001;
use strict;
use warnings;
use Test::More 0.96;

subtest 'Core' => sub {

    package Test1;

    use Data::Fake qw/Core/;

    Test::More::can_ok( "Test1", $_ ) for qw(
      fake_hash
      fake_array
      fake_pick
      fake_binomial
      fake_weighted
      fake_int
      fake_float
      fake_digits
      fake_template
      fake_join
    );
};

subtest 'Company' => sub {

    package Test2;

    use Data::Fake qw/Company/;

    Test::More::can_ok( "Test2", $_ ) for qw(
      fake_company
      fake_title
    );
};

subtest 'Text' => sub {

    package Test3;

    use Data::Fake qw/Text/;

    Test::More::can_ok( "Test3", $_ ) for qw(
      fake_words
      fake_sentences
      fake_paragraphs
    );
};

subtest 'Dates' => sub {

    package Test4;

    use Data::Fake qw/Dates/;

    Test::More::can_ok( "Test4", $_ ) for qw(
      fake_past_epoch
      fake_future_epoch
      fake_past_datetime
      fake_future_datetime
    );
};

subtest 'Internet' => sub {

    package Test5;

    use Data::Fake qw/Internet/;

    Test::More::can_ok( "Test5", $_ ) for qw(
      fake_tld
      fake_domain
      fake_email
    );
};

subtest 'Names' => sub {

    package Test6;

    use Data::Fake qw/Names/;

    Test::More::can_ok( "Test6", $_ ) for qw(
      fake_name
      fake_first_name
      fake_surname
    );
};

done_testing;
#
# This file is part of Data-Fake
#
# This software is Copyright (c) 2015 by David Golden.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#

# vim: ts=4 sts=4 sw=4 et tw=75:
