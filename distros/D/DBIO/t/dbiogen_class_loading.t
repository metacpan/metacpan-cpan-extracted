use strict;
use warnings;

use Test::More;

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

is system("$^X -c -Ilib bin/dbiogen >/dev/null 2>&1"), 0, 'dbiogen compiles';

done_testing;
