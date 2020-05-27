use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.058

use Test::More;

plan tests => 42 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

my @module_files = (
    'Data/Sah/Coerce.pm',
    'Data/Sah/Coerce/js/To_bool/From_float/zero_one.pm',
    'Data/Sah/Coerce/js/To_bool/From_str/common_words.pm',
    'Data/Sah/Coerce/js/To_date/From_float/epoch.pm',
    'Data/Sah/Coerce/js/To_date/From_obj/date.pm',
    'Data/Sah/Coerce/js/To_date/From_str/date_parse.pm',
    'Data/Sah/Coerce/js/To_datenotime/From_float/epoch.pm',
    'Data/Sah/Coerce/js/To_datenotime/From_obj/date.pm',
    'Data/Sah/Coerce/js/To_datenotime/From_str/date_parse.pm',
    'Data/Sah/Coerce/js/To_datetime/From_float/epoch.pm',
    'Data/Sah/Coerce/js/To_datetime/From_obj/date.pm',
    'Data/Sah/Coerce/js/To_datetime/From_str/date_parse.pm',
    'Data/Sah/Coerce/js/To_duration/From_float/seconds.pm',
    'Data/Sah/Coerce/js/To_duration/From_str/iso8601.pm',
    'Data/Sah/Coerce/js/To_timeofday/From_str/hms.pm',
    'Data/Sah/Coerce/perl/To_bool/From_str/common_words.pm',
    'Data/Sah/Coerce/perl/To_date/From_float/epoch.pm',
    'Data/Sah/Coerce/perl/To_date/From_float/epoch_always.pm',
    'Data/Sah/Coerce/perl/To_date/From_obj/datetime.pm',
    'Data/Sah/Coerce/perl/To_date/From_obj/time_moment.pm',
    'Data/Sah/Coerce/perl/To_date/From_str/iso8601.pm',
    'Data/Sah/Coerce/perl/To_datenotime/From_float/epoch.pm',
    'Data/Sah/Coerce/perl/To_datenotime/From_float/epoch_always.pm',
    'Data/Sah/Coerce/perl/To_datenotime/From_obj/datetime.pm',
    'Data/Sah/Coerce/perl/To_datenotime/From_obj/time_moment.pm',
    'Data/Sah/Coerce/perl/To_datenotime/From_str/iso8601.pm',
    'Data/Sah/Coerce/perl/To_datetime/From_float/epoch.pm',
    'Data/Sah/Coerce/perl/To_datetime/From_float/epoch_always.pm',
    'Data/Sah/Coerce/perl/To_datetime/From_obj/datetime.pm',
    'Data/Sah/Coerce/perl/To_datetime/From_obj/time_moment.pm',
    'Data/Sah/Coerce/perl/To_datetime/From_str/iso8601.pm',
    'Data/Sah/Coerce/perl/To_duration/From_float/seconds.pm',
    'Data/Sah/Coerce/perl/To_duration/From_obj/datetime_duration.pm',
    'Data/Sah/Coerce/perl/To_duration/From_str/human.pm',
    'Data/Sah/Coerce/perl/To_duration/From_str/iso8601.pm',
    'Data/Sah/Coerce/perl/To_float/From_str/percent.pm',
    'Data/Sah/Coerce/perl/To_int/From_str/percent.pm',
    'Data/Sah/Coerce/perl/To_num/From_str/percent.pm',
    'Data/Sah/Coerce/perl/To_timeofday/From_obj/date_timeofday.pm',
    'Data/Sah/Coerce/perl/To_timeofday/From_str/hms.pm',
    'Data/Sah/CoerceCommon.pm',
    'Data/Sah/CoerceJS.pm'
);



# no fake home requested

my @switches = (
    -d 'blib' ? '-Mblib' : '-Ilib',
);

use File::Spec;
use IPC::Open3;
use IO::Handle;

open my $stdin, '<', File::Spec->devnull or die "can't open devnull: $!";

my @warnings;
for my $lib (@module_files)
{
    # see L<perlfaq8/How can I capture STDERR from an external command?>
    my $stderr = IO::Handle->new;

    diag('Running: ', join(', ', map { my $str = $_; $str =~ s/'/\\'/g; q{'} . $str . q{'} }
            $^X, @switches, '-e', "require q[$lib]"))
        if $ENV{PERL_COMPILE_TEST_DEBUG};

    my $pid = open3($stdin, '>&STDERR', $stderr, $^X, @switches, '-e', "require q[$lib]");
    binmode $stderr, ':crlf' if $^O eq 'MSWin32';
    my @_warnings = <$stderr>;
    waitpid($pid, 0);
    is($?, 0, "$lib loaded ok");

    shift @_warnings if @_warnings and $_warnings[0] =~ /^Using .*\bblib/
        and not eval { +require blib; blib->VERSION('1.01') };

    if (@_warnings)
    {
        warn @_warnings;
        push @warnings, @_warnings;
    }
}



is(scalar(@warnings), 0, 'no warnings found')
    or diag 'got warnings: ', ( Test::More->can('explain') ? Test::More::explain(\@warnings) : join("\n", '', @warnings) ) if $ENV{AUTHOR_TESTING};


