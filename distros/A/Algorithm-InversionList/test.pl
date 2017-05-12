use Test;

BEGIN
{
 @strings = (
	     ['' => 1],
	     ['Random data here' => 1],
	     [(chr(0x0) x 200 . '1' x 200) => 20],
	     [(chr(0xff) x 200 . chr(0x0) x 200) => 20],
	    );
 
 plan tests => 2 * scalar @strings
};

use Algorithm::InversionList;

do_test($_->[0], $_->[1]) foreach @strings;

sub do_test
{
 my $data = shift @_;
 my $reps = shift @_ || 1;
# print 'Test pattern   ', unpack("b*", $data), "\n";

 $data x= $reps;
 
 my $inv = invlist($data);
# print "Inversion list: @$inv\n";
 ok(scalar @$inv || !length($data));
 my $out = data_from_invlist($inv);
# print 'Output pattern ', unpack("b*", $out), "\n";
 ok($out, $data);
}
