use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.058

use Test::More;

plan tests => 32 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

my @module_files = (
    'Data/Sah/Filter.pm',
    'Data/Sah/Filter/js/Str/downcase.pm',
    'Data/Sah/Filter/js/Str/lc.pm',
    'Data/Sah/Filter/js/Str/lcfirst.pm',
    'Data/Sah/Filter/js/Str/lowercase.pm',
    'Data/Sah/Filter/js/Str/ltrim.pm',
    'Data/Sah/Filter/js/Str/rtrim.pm',
    'Data/Sah/Filter/js/Str/trim.pm',
    'Data/Sah/Filter/js/Str/uc.pm',
    'Data/Sah/Filter/js/Str/ucfirst.pm',
    'Data/Sah/Filter/js/Str/upcase.pm',
    'Data/Sah/Filter/js/Str/uppercase.pm',
    'Data/Sah/Filter/perl/Float/ceil.pm',
    'Data/Sah/Filter/perl/Float/check_has_fraction.pm',
    'Data/Sah/Filter/perl/Float/check_int.pm',
    'Data/Sah/Filter/perl/Float/floor.pm',
    'Data/Sah/Filter/perl/Float/round.pm',
    'Data/Sah/Filter/perl/Str/check.pm',
    'Data/Sah/Filter/perl/Str/downcase.pm',
    'Data/Sah/Filter/perl/Str/lc.pm',
    'Data/Sah/Filter/perl/Str/lcfirst.pm',
    'Data/Sah/Filter/perl/Str/lowercase.pm',
    'Data/Sah/Filter/perl/Str/ltrim.pm',
    'Data/Sah/Filter/perl/Str/replace_map.pm',
    'Data/Sah/Filter/perl/Str/rtrim.pm',
    'Data/Sah/Filter/perl/Str/trim.pm',
    'Data/Sah/Filter/perl/Str/uc.pm',
    'Data/Sah/Filter/perl/Str/ucfirst.pm',
    'Data/Sah/Filter/perl/Str/upcase.pm',
    'Data/Sah/Filter/perl/Str/uppercase.pm',
    'Data/Sah/FilterCommon.pm',
    'Data/Sah/FilterJS.pm'
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


