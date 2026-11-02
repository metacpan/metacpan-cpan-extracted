use v5.14;
use warnings;
use utf8;

use Test::More;
use File::Temp qw(tempfile);
use Data::Dumper;

use lib '.';
use t::Util;

# --update must leave a real STDOUT in place while greple runs, so that
# a module that runs another command for its output, such as -Mtee,
# still works.
eval { require App::Greple::tee } or plan skip_all => 'App::Greple::tee is not installed';

my($fh, $file) = tempfile(SUFFIX => '.txt', UNLINK => 1);
print $fh slurp('t/SAMPLE.txt');
close $fh;

my $result = update(qw(-Mtee tr a-z A-Z -- --update fox), $file)->run;
is($result->{result}, 0, '-Mtee with --update exits 0');
unlike($result->{stderr}, qr/short response/, 'tee got its output back');
like(slurp($file), qr/FOX/, 'the file is updated with the output of the command');
unlike(slurp($file), qr/fox/, 'no match is left as it was');

done_testing;
