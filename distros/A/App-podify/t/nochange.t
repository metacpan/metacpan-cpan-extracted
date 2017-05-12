use strict;
use warnings;
use Test::More;
use App::podify;

my $podify = do 'script/podify.pl' or die $@;

$podify->{perl_module} = $INC{"App/podify.pm"};
$podify->init;
$podify->parse;
$podify->post_process;

open my $OUT, '>', \my $out;
$podify->generate($OUT);
my @out = map {"$_\n"} split /\n/, $out;

open my $EXPECTED, '<', $podify->{perl_module} or die "Read expected: $!";
while (<$EXPECTED>) {
  my $desc = $_;
  $desc =~ s![^-=\w.]! !g;
  is shift(@out), $_, "line $. ($desc)" or last;
}

done_testing;
