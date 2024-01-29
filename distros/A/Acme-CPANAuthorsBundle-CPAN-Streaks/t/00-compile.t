use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.058

use Test::More;

plan tests => 19 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

my @module_files = (
    'Acme/CPANAuthors/CPAN/Streaks/DailyDistributions/AllTime.pm',
    'Acme/CPANAuthors/CPAN/Streaks/DailyDistributions/Current.pm',
    'Acme/CPANAuthors/CPAN/Streaks/DailyNewDistributions/AllTime.pm',
    'Acme/CPANAuthors/CPAN/Streaks/DailyNewDistributions/Current.pm',
    'Acme/CPANAuthors/CPAN/Streaks/DailyReleases/AllTime.pm',
    'Acme/CPANAuthors/CPAN/Streaks/DailyReleases/Current.pm',
    'Acme/CPANAuthors/CPAN/Streaks/MonthlyDistributions/AllTime.pm',
    'Acme/CPANAuthors/CPAN/Streaks/MonthlyDistributions/Current.pm',
    'Acme/CPANAuthors/CPAN/Streaks/MonthlyNewDistributions/AllTime.pm',
    'Acme/CPANAuthors/CPAN/Streaks/MonthlyNewDistributions/Current.pm',
    'Acme/CPANAuthors/CPAN/Streaks/MonthlyReleases/AllTime.pm',
    'Acme/CPANAuthors/CPAN/Streaks/MonthlyReleases/Current.pm',
    'Acme/CPANAuthors/CPAN/Streaks/WeeklyDistributions/AllTime.pm',
    'Acme/CPANAuthors/CPAN/Streaks/WeeklyDistributions/Current.pm',
    'Acme/CPANAuthors/CPAN/Streaks/WeeklyNewDistributions/AllTime.pm',
    'Acme/CPANAuthors/CPAN/Streaks/WeeklyNewDistributions/Current.pm',
    'Acme/CPANAuthors/CPAN/Streaks/WeeklyReleases/AllTime.pm',
    'Acme/CPANAuthors/CPAN/Streaks/WeeklyReleases/Current.pm',
    'Acme/CPANAuthorsBundle/CPAN/Streaks.pm'
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


