use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.058

use Test::More;

plan tests => 36 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

my @module_files = (
    'DBIx/Class/Smooth.pm',
    'DBIx/Class/Smooth/Fields.pm',
    'DBIx/Class/Smooth/FilterItem.pm',
    'DBIx/Class/Smooth/Flatten/DateTime.pm',
    'DBIx/Class/Smooth/Helper/ResultSet/Shortcut/AddColumn.pm',
    'DBIx/Class/Smooth/Helper/ResultSet/Shortcut/Join.pm',
    'DBIx/Class/Smooth/Helper/ResultSet/Shortcut/OrderByCollation.pm',
    'DBIx/Class/Smooth/Helper/ResultSet/Shortcut/RemoveColumns.pm',
    'DBIx/Class/Smooth/Helper/Row/Definition.pm',
    'DBIx/Class/Smooth/Helper/Row/JoinTable.pm',
    'DBIx/Class/Smooth/Helper/Util.pm',
    'DBIx/Class/Smooth/Lookup/DateTime.pm',
    'DBIx/Class/Smooth/Lookup/DateTime/datepart.pm',
    'DBIx/Class/Smooth/Lookup/DateTime/day.pm',
    'DBIx/Class/Smooth/Lookup/DateTime/hour.pm',
    'DBIx/Class/Smooth/Lookup/DateTime/minute.pm',
    'DBIx/Class/Smooth/Lookup/DateTime/month.pm',
    'DBIx/Class/Smooth/Lookup/DateTime/second.pm',
    'DBIx/Class/Smooth/Lookup/DateTime/year.pm',
    'DBIx/Class/Smooth/Lookup/Operators.pm',
    'DBIx/Class/Smooth/Lookup/Operators/gt.pm',
    'DBIx/Class/Smooth/Lookup/Operators/gte.pm',
    'DBIx/Class/Smooth/Lookup/Operators/in.pm',
    'DBIx/Class/Smooth/Lookup/Operators/like.pm',
    'DBIx/Class/Smooth/Lookup/Operators/lt.pm',
    'DBIx/Class/Smooth/Lookup/Operators/lte.pm',
    'DBIx/Class/Smooth/Lookup/Operators/not_in.pm',
    'DBIx/Class/Smooth/Lookup/Util.pm',
    'DBIx/Class/Smooth/Lookup/ident.pm',
    'DBIx/Class/Smooth/Lookup/substring.pm',
    'DBIx/Class/Smooth/Q.pm',
    'DBIx/Class/Smooth/Result.pm',
    'DBIx/Class/Smooth/ResultBase.pm',
    'DBIx/Class/Smooth/ResultSet.pm',
    'DBIx/Class/Smooth/ResultSetBase.pm',
    'DBIx/Class/Smooth/Schema.pm'
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


