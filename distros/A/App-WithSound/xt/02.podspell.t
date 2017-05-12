#!perl

use strict;
use warnings;
use FindBin;
use File::Spec::Functions qw/catfile/;

use Test::More;
eval "use Test::Spelling";

plan skip_all => "Test::Spelling is not installed."
  if $@;

add_stopwords( map { /(\w+)/g } <DATA> );
$ENV{LANG} = 'C';

my @targets = ('lib', catfile($FindBin::Bin, '..', 'with-sound'));
all_pod_files_spelling_ok(@targets);

# done_testing;
__DATA__
moznion
Maruyama
Shinpei
Syohei
YOSHIDA
MERCHANTABILITY
MP
mpg
soundrc
afplay
pre
