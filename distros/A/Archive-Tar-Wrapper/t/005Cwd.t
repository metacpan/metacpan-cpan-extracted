######################################################################
# Test suite for Archive::Tar::Wrapper
# by Mike Schilli <cpan@perlmeister.com>
######################################################################

use warnings;
use strict;
use File::Temp qw(tempfile);
use Cwd;

use Test::More tests => 4;
BEGIN { use_ok('Archive::Tar::Wrapper') };

my $cwd = getcwd();
my $evaled = eval {
  my $arch = Archive::Tar::Wrapper->new();
  my(undef, $filename) = tempfile(UNLINK => 1);
  unlink $filename; # OPEN => 0 gave a stupid warning
  # attempt to generate error from tar by not adding any files
  $arch->write($filename, 9);
  1;
};
is $@, '', 'no error';
is $evaled, 1, 'survived eval';
is getcwd(), $cwd, 'still in original directory';
