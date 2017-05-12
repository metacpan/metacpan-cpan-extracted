use strict;
use warnings;
use File::Temp qw/tempfile/;
use Test::More;

use Alien::Ditaa;

my ($fh, $in_fn) = tempfile;
my $out_fn = "$in_fn.png";

print $fh q{
  +-------------+
  | Hello world |
  +-------------+
};
close $fh;

my $ditaa = Alien::Ditaa->new;
ok $ditaa;
is $ditaa->last_run_output, undef;
is $ditaa->run_ditaa($in_fn, $out_fn), 0, 'Exit status 0';
isnt $ditaa->last_run_output, undef;
ok -r $out_fn, 'Can read $out_fn';

unlink $out_fn;
unlink $in_fn;

done_testing;

