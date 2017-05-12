# vim: filetype=perl :
use strict;
use warnings;

use Test::More tests => 2; # last test to print
use Data::Dumper;

use lib qw< t >;
use ASTest;

use App::Sets::Sort qw< sort_filehandle internal_sort_filehandle >;
my $lista = locate_file('lista1');
my $expected = do {
   open my $fh, '<', $lista;
   join '', sort <$fh>;
};

$ENV{SETS_MAX_RECORDS} = 3;
$ENV{SETS_MAX_FILES} = 2;

{
   my $fh = internal_sort_filehandle($lista);
   my $got = join '', <$fh>;
   is $got, $expected, 'internal sort';
}

{
   my $fh = sort_filehandle($lista);
   my $got = join '', <$fh>;
   is $got, $expected, 'sort';
}

done_testing();
