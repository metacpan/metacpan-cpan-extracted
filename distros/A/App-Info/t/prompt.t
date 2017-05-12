#!/usr/bin/perl -w

use strict;
use Test::More tests => 34;
use File::Spec::Functions qw(:ALL);

##############################################################################
# Make sure that we can use the stuff that's in our local lib directory.
BEGIN {
    if( $ENV{PERL_CORE} ) {
        chdir 't' if -d 't';
        @INC = ('../lib', 'lib');
    } else {
        unshift @INC, 't/lib', 'lib';
    }
}
chdir 't';
use TieOut;

##############################################################################
# Set up an App::Info subclass to ruin.
package App::Info::Category::FooApp;
use strict;
use App::Info;
use File::Spec::Functions qw(:ALL);
use vars qw(@ISA);
@ISA = qw(App::Info);
sub key_name { 'FooApp' }
my $tmpdir = tmpdir;

sub inc_dir {
    shift->unknown( key      => 'bin',
                    prompt   => 'Path to tmpdir',
                    callback => sub { -d $_[0] },
                    error    => 'Not a valid directory')
 }

sub lib_dir {
    shift->confirm( key      => 'bin',
                    prompt   => 'Path to tmpdir',
                    value    => $tmpdir,
                    callback => sub { -d $_[0] },
                    error    => 'Not a valid directory')
}

sub patch { shift->info("Info message" ) }
sub major { shift->error("Error message" ) }
sub minor { shift->unknown( key => 'minor version number') }

sub version {
    shift->unknown( key      => 'version number',
                    callback => sub { $_[0] =~ /^\d+$/ } )
}

sub so_lib_dir {
    shift->confirm( key   => 'shared object directory',
                    value => '/foo33')
}

sub name {
    shift->confirm( key      => 'name',
                    value    => 'ick',
                    callback => sub { $_[0] !~ /\d/ })
}

sub bin_dir { shift->confirm }
sub foo_dir { shift->unknown }

##############################################################################
# Set up the tests.
package main;

BEGIN { use_ok('App::Info::Handler::Prompt') }

# Tie off the file handles.
my $stdout = tie *STDOUT, 'TieOut' or die "Cannot tie STDOUT: $!\n";
my $stdin = tie *STDIN, 'TieOut' or die "Cannot tie STDIN: $!\n";
my $stderr = tie *STDERR, 'TieOut' or die "Cannot tie STDERR: $!\n";

ok( my $app = App::Info::Category::FooApp->new( on_unknown => 'prompt'),
    "Use keyword to set up for unknown" );
ok( my $p = App::Info::Handler::Prompt->new, "Create prompt" );
$p->{tty} = 1; # Cheat death.
ok( $app = App::Info::Category::FooApp->new( on_unknown => $p),
    "Set up for unknown" );
# Make sure there were no warnings.
is $stderr->read, '', "There should be no warnings";

##############################################################################
# Set up a couple of answers.
print STDIN 'foo3424324';
print STDIN $tmpdir;
# Trigger the unknown handler.
my $dir = $app->inc_dir;

# Check the result and the output.
is( $dir, $tmpdir, "Got tmpdir from inc_dir" );
my $expected = qq{Path to tmpdir Not a valid directory: 'foo3424324'
Path to tmpdir };
is ($stdout->read, $expected, "Check unknown prompt" );

##############################################################################
# Okay, now we'll test the confirm handler.
ok( $app = App::Info::Category::FooApp->new( on_confirm => $p),
    "Set up for first confirm" );

# Start with an affimative answer.
print STDIN "\n";
$dir = $app->lib_dir;
is($dir, $tmpdir, "Got tmpdir from lib_dir" );
$expected = qq{Path to tmpdir [$tmpdir] };
is( $stdout->read, $expected, "Check first confirm prompt" );

##############################################################################
# Now try an alternate answer.
ok( $app = App::Info::Category::FooApp->new( on_confirm => $p),
    "Set up for second confirm" );
# Set up the answers.
print STDIN "foo123123\n";
print STDIN "$tmpdir\n";
# Set it off.
$dir = $app->lib_dir;
# Check the answer.
is($dir, $tmpdir, "Got tmpdir from second confirm" );
# Check the output.
$expected = qq{Path to tmpdir [$tmpdir] Not a valid directory: 'foo123123'
Path to tmpdir [$tmpdir] };
is( $stdout->read, $expected, "Check second confirm prompt" );

##############################################################################
# Now just try the default answer.
ok( $app = App::Info::Category::FooApp->new( on_confirm => $p),
    "Set up for third confirm" );
# Set up the answers.
print STDIN "\n";
# Set it off.
$dir = $app->lib_dir;
# Check the answer.
is($dir, $tmpdir, "Got tmpdir from third confirm" );
# Check the output.
$expected = qq{Path to tmpdir [$tmpdir] };
is( $stdout->read, $expected, "Check third confirm prompt" );

##############################################################################
# Now test just a key argument to unknown
ok( $app = App::Info::Category::FooApp->new( on_unknown => $p),
    "Set up for key argument" );
# Set up the answer.
print STDIN "$tmpdir\n";
# Set it off.
$app->minor;
# Check the answer.
is($dir, $tmpdir, "Got tmpdir from key argument" );
# Check the output.
$expected = qq{Enter a valid FooApp minor version number };
is( $stdout->read, $expected, "Check key argument prompt" );

##############################################################################
# Now test key argument with callback to unknown.
ok( $app = App::Info::Category::FooApp->new( on_unknown => $p),
    "Set up for key with callback");
# Set up the answers.
print STDIN "foo\n";
print STDIN "22";
# Set it off.
my $ver = $app->version;
# Check the answer.
is($ver, 22, "Got 22 from version" );
# Check the output.
$expected = qq{Enter a valid FooApp version number Invalid value: 'foo'
Enter a valid FooApp version number };
is( $stdout->read, $expected, "Check key with callback prompt" );

##############################################################################
# Now test just a key argument to confirm
ok( $app = App::Info::Category::FooApp->new( on_confirm => $p),
    "Set up for key argument" );
# Set up the answer.
print STDIN "$tmpdir\n";
# Set it off.
$app->so_lib_dir;
# Check the answer.
is($dir, $tmpdir, "Got tmpdir from key argument" );
# Check the output.
$expected = qq{Enter a valid FooApp shared object directory [/foo33] };
is( $stdout->read, $expected, "Check confirm key argument prompt" );

##############################################################################
# Now test key argument with callback to confirm.
ok( $app = App::Info::Category::FooApp->new( on_confirm => $p),
    "Set up for key with callback");
# Set up the answers.
print STDIN "foo22\n";
print STDIN "foo";
# Set it off.
$ver = $app->name;
# Check the answer.
is($ver, 'foo', "Got 'foo' from name" );
# Check the output.
$expected = qq{Enter a valid FooApp name [ick] Invalid value: 'foo22'
Enter a valid FooApp name [ick] };
is( $stdout->read, $expected, "Check confirm key with callback prompt" );

##############################################################################
# Now check how it handles info and error. These should just print to the
# relevant file handle. Info prints to STDOUT.
ok( $app = App::Info::Category::FooApp->new( on_info => $p),
    "Set up for info" );
$app->patch;
is( $stdout->read, "Info message\n", "Check info message" );

# And error prints to STDERR.
ok( $app = App::Info::Category::FooApp->new( on_error => $p),
    "Set up for error" );
$app->major;
is( $stderr->read, "Error message\n", "Check error message" );

##############################################################################
# Clean up our mess.
undef $stdout;
undef $stdin;
undef $stderr;
untie *STDOUT;
untie *STDIN;
untie *STDERR;

##############################################################################
# Test for errors when no key argument is passed.
{
    my $msg;
    local $SIG{__DIE__} = sub { $msg = shift };
    eval { $app->bin_dir };
    like( $msg, qr/No key parameter passed to confirm/,
          "Check no key confirm" );
    eval { $app->foo_dir };
    like( $msg, qr/No key parameter passed to unknown/,
          "Check no key unknown" );
}

##############################################################################
# Interactive tests for maintainer.
if ($ENV{APP_INFO_MAINTAINER} && ! $ENV{HARNESS_ACTIVE}) {
    # Interactive tests for maintainer only.
    $app = App::Info::Category::FooApp->new( on_confirm => $p);
    $app->inc_dir;
    $app->lib_dir;
}

__END__
