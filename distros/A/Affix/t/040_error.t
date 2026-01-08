use v5.40;
use lib '../lib', 'lib';
use blib;
use Test2::Tools::Affix;
use Affix qw[:all];

# We need a function that is guaranteed to fail and set errno/GetLastError.
# 'remove' (unlink) on a non-existent file is a classic choice.
my $remove       = wrap libc, 'remove', [String] => Int;
my $missing_file = 'non_existent_file_' . int( rand 100000 ) . '.txt';

# Ensure it doesn't exist
unlink $missing_file if -e $missing_file;

# Call C function, expect failure (-1)
my $ret = $remove->($missing_file);
is $ret, -1, 'remove() returned -1 for missing file';

# Check the system error
my $err = errno();

# On POSIX, removing a missing file is ENOENT (2).
# On Windows, it is typically ERROR_FILE_NOT_FOUND (2).
ok int($err) > 0, 'Got positive numeric error code: ' . int($err);
#
diag $err;
ok length("$err") > 0, "Got error message string: '$err'";
like "$err", qr/\w/, 'Error message contains text';
#
is $err + 0,  int($err), 'Scalar acts as number in numeric context';
is $err . "", "$err",    'Scalar acts as string in string context';
#
done_testing;
