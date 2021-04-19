use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.058

use Test::More;

plan tests => 58 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

my @module_files = (
    'Dancer2.pm',
    'Dancer2/CLI.pm',
    'Dancer2/CLI/Gen.pm',
    'Dancer2/CLI/Version.pm',
    'Dancer2/Core.pm',
    'Dancer2/Core/App.pm',
    'Dancer2/Core/Cookie.pm',
    'Dancer2/Core/DSL.pm',
    'Dancer2/Core/Dispatcher.pm',
    'Dancer2/Core/Error.pm',
    'Dancer2/Core/Factory.pm',
    'Dancer2/Core/HTTP.pm',
    'Dancer2/Core/Hook.pm',
    'Dancer2/Core/MIME.pm',
    'Dancer2/Core/Request.pm',
    'Dancer2/Core/Request/Upload.pm',
    'Dancer2/Core/Response.pm',
    'Dancer2/Core/Response/Delayed.pm',
    'Dancer2/Core/Role/ConfigReader.pm',
    'Dancer2/Core/Role/DSL.pm',
    'Dancer2/Core/Role/Engine.pm',
    'Dancer2/Core/Role/Handler.pm',
    'Dancer2/Core/Role/HasLocation.pm',
    'Dancer2/Core/Role/Hookable.pm',
    'Dancer2/Core/Role/Logger.pm',
    'Dancer2/Core/Role/Serializer.pm',
    'Dancer2/Core/Role/SessionFactory.pm',
    'Dancer2/Core/Role/SessionFactory/File.pm',
    'Dancer2/Core/Role/StandardResponses.pm',
    'Dancer2/Core/Role/Template.pm',
    'Dancer2/Core/Route.pm',
    'Dancer2/Core/Runner.pm',
    'Dancer2/Core/Session.pm',
    'Dancer2/Core/Time.pm',
    'Dancer2/Core/Types.pm',
    'Dancer2/FileUtils.pm',
    'Dancer2/Handler/AutoPage.pm',
    'Dancer2/Handler/File.pm',
    'Dancer2/Logger/Capture.pm',
    'Dancer2/Logger/Capture/Trap.pm',
    'Dancer2/Logger/Console.pm',
    'Dancer2/Logger/Diag.pm',
    'Dancer2/Logger/File.pm',
    'Dancer2/Logger/Note.pm',
    'Dancer2/Logger/Null.pm',
    'Dancer2/Plugin.pm',
    'Dancer2/Serializer/Dumper.pm',
    'Dancer2/Serializer/JSON.pm',
    'Dancer2/Serializer/Mutable.pm',
    'Dancer2/Serializer/YAML.pm',
    'Dancer2/Session/Simple.pm',
    'Dancer2/Session/YAML.pm',
    'Dancer2/Template/Implementation/ForkedTiny.pm',
    'Dancer2/Template/Simple.pm',
    'Dancer2/Template/TemplateToolkit.pm',
    'Dancer2/Template/Tiny.pm',
    'Dancer2/Test.pm'
);

my @scripts = (
    'script/dancer2'
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


