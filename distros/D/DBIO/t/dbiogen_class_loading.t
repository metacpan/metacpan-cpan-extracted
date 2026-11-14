use strict;
use warnings;

use Test::More;
use File::Spec;

use DBIO::Util qw(file_path slurp_file);

# bin/dbiogen (karr k393) loads the introspector class named on the command
# line through ensure_class_loaded, which takes a class name and throws for
# anything else (karr k380). The command line is never evaluated as a string.

my $src = slurp_file(file_path('bin', 'dbiogen'));
$src =~ s/^=.*?^=cut\s*$//msg;    # POD

unlike $src, qr/\beval\s*(?:"|'|qq|q\b|\$)/,
  'dbiogen holds no string eval';
like $src, qr/ensure_class_loaded\(\$introspect_class\)/,
  'the introspector class is loaded through ensure_class_loaded';

{
  open my $null_out, '>', File::Spec->devnull or die "cannot open devnull: $!";
  open my $saved_out, '>&', \*STDOUT or die $!;
  open my $saved_err, '>&', \*STDERR or die $!;
  open STDOUT, '>&', $null_out or die $!;
  open STDERR, '>&', $null_out or die $!;
  my $rc = system $^X, '-c', '-Ilib', 'bin/dbiogen';
  open STDOUT, '>&', $saved_out or die $!;
  open STDERR, '>&', $saved_err or die $!;
  is $rc, 0, 'dbiogen compiles';
}

done_testing;
