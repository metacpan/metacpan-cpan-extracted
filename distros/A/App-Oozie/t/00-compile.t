use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.058

use Test::More;

plan tests => 43 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

my @module_files = (
    'App/Oozie.pm',
    'App/Oozie/Action/Deploy.pm',
    'App/Oozie/Action/Rerun.pm',
    'App/Oozie/Action/Run.pm',
    'App/Oozie/Action/UpdateCoord.pm',
    'App/Oozie/Compare/LocalToHDFS.pm',
    'App/Oozie/Constants.pm',
    'App/Oozie/Date.pm',
    'App/Oozie/Deploy.pm',
    'App/Oozie/Deploy/Template.pm',
    'App/Oozie/Deploy/Template/ttree.pm',
    'App/Oozie/Deploy/Validate/DAG/Vertex.pm',
    'App/Oozie/Deploy/Validate/DAG/Workflow.pm',
    'App/Oozie/Deploy/Validate/Meta.pm',
    'App/Oozie/Deploy/Validate/Oozie.pm',
    'App/Oozie/Deploy/Validate/Spec.pm',
    'App/Oozie/Deploy/Validate/Spec/Bundle.pm',
    'App/Oozie/Deploy/Validate/Spec/Coordinator.pm',
    'App/Oozie/Deploy/Validate/Spec/Workflow.pm',
    'App/Oozie/Forked/Template/ttree.pm',
    'App/Oozie/Rerun.pm',
    'App/Oozie/Role/Fields/Common.pm',
    'App/Oozie/Role/Fields/Generic.pm',
    'App/Oozie/Role/Fields/Objects.pm',
    'App/Oozie/Role/Fields/Path.pm',
    'App/Oozie/Role/Git.pm',
    'App/Oozie/Role/Log.pm',
    'App/Oozie/Role/Meta.pm',
    'App/Oozie/Role/NameNode.pm',
    'App/Oozie/Run.pm',
    'App/Oozie/Serializer.pm',
    'App/Oozie/Serializer/Dummy.pm',
    'App/Oozie/Serializer/YAML.pm',
    'App/Oozie/Types/Common.pm',
    'App/Oozie/Types/DateTime.pm',
    'App/Oozie/Types/States.pm',
    'App/Oozie/Types/Workflow.pm',
    'App/Oozie/Update/Coordinator.pm',
    'App/Oozie/Util/Log4perl.pm',
    'App/Oozie/Util/Misc.pm',
    'App/Oozie/Util/Plugin.pm',
    'App/Oozie/XML.pm'
);

my @scripts = (
    'bin/oozie-tool'
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

foreach my $file (@scripts)
{ SKIP: {
    open my $fh, '<', $file or warn("Unable to open $file: $!"), next;
    my $line = <$fh>;

    close $fh and skip("$file isn't perl", 1) unless $line =~ /^#!\s*(?:\S*perl\S*)((?:\s+-\w*)*)(?:\s*#.*)?$/;
    @switches = (@switches, split(' ', $1)) if $1;

    close $fh and skip("$file uses -T; not testable with PERL5LIB", 1)
        if grep { $_ eq '-T' } @switches and $ENV{PERL5LIB};

    my $stderr = IO::Handle->new;

    diag('Running: ', join(', ', map { my $str = $_; $str =~ s/'/\\'/g; q{'} . $str . q{'} }
            $^X, @switches, '-c', $file))
        if $ENV{PERL_COMPILE_TEST_DEBUG};

    my $pid = open3($stdin, '>&STDERR', $stderr, $^X, @switches, '-c', $file);
    binmode $stderr, ':crlf' if $^O eq 'MSWin32';
    my @_warnings = <$stderr>;
    waitpid($pid, 0);
    is($?, 0, "$file compiled ok");

    shift @_warnings if @_warnings and $_warnings[0] =~ /^Using .*\bblib/
        and not eval { +require blib; blib->VERSION('1.01') };

    # in older perls, -c output is simply the file portion of the path being tested
    if (@_warnings = grep { !/\bsyntax OK$/ }
        grep { chomp; $_ ne (File::Spec->splitpath($file))[2] } @_warnings)
    {
        warn @_warnings;
        push @warnings, @_warnings;
    }
} }



is(scalar(@warnings), 0, 'no warnings found')
    or diag 'got warnings: ', ( Test::More->can('explain') ? Test::More::explain(\@warnings) : join("\n", '', @warnings) ) if $ENV{AUTHOR_TESTING};


