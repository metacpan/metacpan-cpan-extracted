#!perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}


use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Perl::Critic::Subset 3.001.006

use Test::Perl::Critic (-profile => "") x!! -e "";

my $filenames = ['lib/Data/Sah/Coerce.pm','lib/Data/Sah/Coerce/js/To_bool/From_float/zero_one.pm','lib/Data/Sah/Coerce/js/To_bool/From_str/common_words.pm','lib/Data/Sah/Coerce/js/To_date/From_float/epoch.pm','lib/Data/Sah/Coerce/js/To_date/From_obj/date.pm','lib/Data/Sah/Coerce/js/To_date/From_str/date_parse.pm','lib/Data/Sah/Coerce/js/To_datenotime/From_float/epoch.pm','lib/Data/Sah/Coerce/js/To_datenotime/From_obj/date.pm','lib/Data/Sah/Coerce/js/To_datenotime/From_str/date_parse.pm','lib/Data/Sah/Coerce/js/To_datetime/From_float/epoch.pm','lib/Data/Sah/Coerce/js/To_datetime/From_obj/date.pm','lib/Data/Sah/Coerce/js/To_datetime/From_str/date_parse.pm','lib/Data/Sah/Coerce/js/To_duration/From_float/seconds.pm','lib/Data/Sah/Coerce/js/To_duration/From_str/iso8601.pm','lib/Data/Sah/Coerce/js/To_timeofday/From_str/hms.pm','lib/Data/Sah/Coerce/perl/To_bool/From_str/common_words.pm','lib/Data/Sah/Coerce/perl/To_date/From_float/epoch.pm','lib/Data/Sah/Coerce/perl/To_date/From_float/epoch_always.pm','lib/Data/Sah/Coerce/perl/To_date/From_float/epoch_always_jakarta.pm','lib/Data/Sah/Coerce/perl/To_date/From_float/epoch_always_local.pm','lib/Data/Sah/Coerce/perl/To_date/From_float/epoch_jakarta.pm','lib/Data/Sah/Coerce/perl/To_date/From_float/epoch_local.pm','lib/Data/Sah/Coerce/perl/To_date/From_obj/datetime.pm','lib/Data/Sah/Coerce/perl/To_date/From_obj/time_moment.pm','lib/Data/Sah/Coerce/perl/To_date/From_str/iso8601.pm','lib/Data/Sah/Coerce/perl/To_datenotime/From_float/epoch.pm','lib/Data/Sah/Coerce/perl/To_datenotime/From_float/epoch_always.pm','lib/Data/Sah/Coerce/perl/To_datenotime/From_obj/datetime.pm','lib/Data/Sah/Coerce/perl/To_datenotime/From_obj/time_moment.pm','lib/Data/Sah/Coerce/perl/To_datenotime/From_str/iso8601.pm','lib/Data/Sah/Coerce/perl/To_datetime/From_float/epoch.pm','lib/Data/Sah/Coerce/perl/To_datetime/From_float/epoch_always.pm','lib/Data/Sah/Coerce/perl/To_datetime/From_obj/datetime.pm','lib/Data/Sah/Coerce/perl/To_datetime/From_obj/time_moment.pm','lib/Data/Sah/Coerce/perl/To_datetime/From_str/iso8601.pm','lib/Data/Sah/Coerce/perl/To_duration/From_float/seconds.pm','lib/Data/Sah/Coerce/perl/To_duration/From_obj/datetime_duration.pm','lib/Data/Sah/Coerce/perl/To_duration/From_str/hms.pm','lib/Data/Sah/Coerce/perl/To_duration/From_str/human.pm','lib/Data/Sah/Coerce/perl/To_duration/From_str/iso8601.pm','lib/Data/Sah/Coerce/perl/To_float/From_str/percent.pm','lib/Data/Sah/Coerce/perl/To_int/From_str/percent.pm','lib/Data/Sah/Coerce/perl/To_num/From_str/percent.pm','lib/Data/Sah/Coerce/perl/To_timeofday/From_obj/date_timeofday.pm','lib/Data/Sah/Coerce/perl/To_timeofday/From_str/hms.pm','lib/Data/Sah/CoerceCommon.pm','lib/Data/Sah/CoerceJS.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
