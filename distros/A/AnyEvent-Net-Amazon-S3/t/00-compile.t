use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.052

use Test::More;

plan tests => 30 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

my @module_files = (
    'AnyEvent/Net/Amazon/S3.pm',
    'AnyEvent/Net/Amazon/S3/Bucket.pm',
    'AnyEvent/Net/Amazon/S3/Client.pm',
    'AnyEvent/Net/Amazon/S3/Client/Bucket.pm',
    'AnyEvent/Net/Amazon/S3/Client/Object.pm',
    'AnyEvent/Net/Amazon/S3/HTTPRequest.pm',
    'AnyEvent/Net/Amazon/S3/Request.pm',
    'AnyEvent/Net/Amazon/S3/Request/AbortMultipartUpload.pm',
    'AnyEvent/Net/Amazon/S3/Request/CompleteMultipartUpload.pm',
    'AnyEvent/Net/Amazon/S3/Request/CreateBucket.pm',
    'AnyEvent/Net/Amazon/S3/Request/DeleteBucket.pm',
    'AnyEvent/Net/Amazon/S3/Request/DeleteMultiObject.pm',
    'AnyEvent/Net/Amazon/S3/Request/DeleteMultipleObjects.pm',
    'AnyEvent/Net/Amazon/S3/Request/DeleteObject.pm',
    'AnyEvent/Net/Amazon/S3/Request/GetBucketAccessControl.pm',
    'AnyEvent/Net/Amazon/S3/Request/GetBucketLocationConstraint.pm',
    'AnyEvent/Net/Amazon/S3/Request/GetObject.pm',
    'AnyEvent/Net/Amazon/S3/Request/GetObjectAccessControl.pm',
    'AnyEvent/Net/Amazon/S3/Request/InitiateMultipartUpload.pm',
    'AnyEvent/Net/Amazon/S3/Request/ListAllMyBuckets.pm',
    'AnyEvent/Net/Amazon/S3/Request/ListBucket.pm',
    'AnyEvent/Net/Amazon/S3/Request/ListParts.pm',
    'AnyEvent/Net/Amazon/S3/Request/PutObject.pm',
    'AnyEvent/Net/Amazon/S3/Request/PutPart.pm',
    'AnyEvent/Net/Amazon/S3/Request/SetBucketAccessControl.pm',
    'AnyEvent/Net/Amazon/S3/Request/SetObjectAccessControl.pm',
    'Module/AnyEvent/Helper/PPI/Transform/Net/Amazon/S3.pm',
    'Module/AnyEvent/Helper/PPI/Transform/Net/Amazon/S3/Client/Bucket.pm',
    'Module/AnyEvent/Helper/PPI/Transform/Net/Amazon/S3/Client/Object.pm'
);

my @scripts = (
    'bin/s3cl_ae'
);

# no fake home requested

my $inc_switch = -d 'blib' ? '-Mblib' : '-Ilib';

use File::Spec;
use IPC::Open3;
use IO::Handle;

open my $stdin, '<', File::Spec->devnull or die "can't open devnull: $!";

my @warnings;
for my $lib (@module_files)
{
    # see L<perlfaq8/How can I capture STDERR from an external command?>
    my $stderr = IO::Handle->new;

    my $pid = open3($stdin, '>&STDERR', $stderr, $^X, $inc_switch, '-e', "require q[$lib]");
    binmode $stderr, ':crlf' if $^O eq 'MSWin32';
    my @_warnings = <$stderr>;
    waitpid($pid, 0);
    is($?, 0, "$lib loaded ok");

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
    my @flags = $1 ? split(' ', $1) : ();

    my $stderr = IO::Handle->new;

    my $pid = open3($stdin, '>&STDERR', $stderr, $^X, $inc_switch, @flags, '-c', $file);
    binmode $stderr, ':crlf' if $^O eq 'MSWin32';
    my @_warnings = <$stderr>;
    waitpid($pid, 0);
    is($?, 0, "$file compiled ok");

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


