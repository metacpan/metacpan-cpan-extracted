#!/usr/bin/perl -w

# Make sure that we can use the stuff that's in our local lib directory.
BEGIN {
    if( $ENV{PERL_CORE} ) {
        chdir 't' if -d 't';
        @INC = ('../lib', 'lib');
    }
    else {
        unshift @INC, 't/lib', 'lib';
    }
}
chdir 't';

use strict;
use Test::More tests => 23;
use File::Spec::Functions qw(:ALL);
use File::Path;
use FileHandle;
use TieOut;

# This is the message we'll test for.
my $msg = "Run away! Run away!";

# Set up an App::Info subclass to ruin.
package App::Info::Category::FooApp;
use App::Info;
use strict;
use vars qw(@ISA);
@ISA = qw(App::Info);

sub version { shift->info($msg) }

package main;

BEGIN { use_ok('App::Info::Handler::Print') }

my $file = catfile tmpdir, 'app-info-print.tst';

# Start by testing the default.
my $stderr = tie *STDERR, 'TieOut' or die "Cannot tie STDERR: $!\n";
ok( my $p = App::Info::Handler::Print->new, "Create default" );
ok( my $app = App::Info::Category::FooApp->new( on_info => $p ),
    "Set up for default" );
$app->version;
is ($stderr->read, "$msg\n", "Check default" );

# Now try STDERR, which should be the same thing.
ok( $p = App::Info::Handler::Print->new( fh => 'stderr' ), "Create STDERR" );
ok( $app = App::Info::Category::FooApp->new( on_info => $p ),
    "Set up for STDERR" );
$app->version;
is ($stderr->read, "$msg\n", "Check STDERR" );

# Release!
undef $stderr;
untie *STDERR;

# Now test STDOUT.
my $stdout = tie *STDOUT, 'TieOut' or die "Cannot tie STDOUT: $!\n";
ok( $p = App::Info::Handler::Print->new( fh => 'stdout' ), "Create STDOUT" );
ok( $app = App::Info::Category::FooApp->new( on_info => $p ),
    "Set up for STDOUT" );
$app->version;
is ($stdout->read, "$msg\n", "Check STDOUT" );
undef $stdout;
untie *STDOUT;

# Now try STDOUT.

# Try a file handle.
my $fh = FileHandle->new(">$file");
ok( $p = App::Info::Handler::Print->new( fh => $fh ), "Create with file handle" );
is( ($app->on_info($p))[0], $p, "Set file handle handler" );
is( ($app->on_info)[0], $p, "Make sure the file handle handler is set" );
$app->version;
$fh->close;
chk_file($file, "Check file handle output", "$msg\n");

# Try appending.
$fh = FileHandle->new(">>$file");
ok( $p = App::Info::Handler::Print->new( fh => $fh ), "Create with append" );
is( ($app->on_info($p))[0], $p, "Set append handler" );
is( ($app->on_info)[0], $p, "Make sure the append handler is set" );
$app->version;
$fh->close;
chk_file($file, "Check append output", "$msg\n$msg\n");

# Try a file handle glob.
open F, ">$file" or die "Cannot open $file: $!\n";
ok( $p = App::Info::Handler::Print->new( fh => \*F ), "Create with glob" );
is( ($app->on_info($p))[0], $p, "Set glob handler" );
is( ($app->on_info)[0], $p, "Make sure the glob handler is set" );
$app->version;
close F or die "Cannot close $file: $!\n";
chk_file($file, "Check glob output", "$msg\n");

# Try an invalid argument.
eval { App::Info::Handler::Print->new( fh => 'foo') };
like( $@, qr/^Invalid argument to new\(\): 'foo'/, "Check invalid argument" );

# Delete the test file.
rmtree $file;

sub chk_file {
    my ($file, $tst_name, $val) = @_;
    open F, "<$file" or die "Cannot open $file: $!\n";
    local $/;
    is(<F>, $val || "$msg\n", $tst_name);
    close F or die "Cannot close $file: $!\n";
}

__END__
