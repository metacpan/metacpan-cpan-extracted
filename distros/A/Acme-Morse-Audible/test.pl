use Test;
use Config;
use strict;

BEGIN { plan tests => 5 };

for([<<TEST1],[<<TEST2,sub{-s 'test.tmp'==26037}],[<<TEST3,sub{open my $read,'<','test.tmp' or die "Can't open test.tmp - $!";((<$read>)[1],close $read)[0] eq "S\n"}]){
use Acme::Morse::Audible;
MThd      ` MTrk�    � �Y  �@�VP�� �V �@�VP�� �V �@�VP�@�V �@�VP�@�V �@�VP�� �V �@�VP�@�V �@�VP�� �V �@�VP�@�V �@�VP�@�V �@�VP�� �V �@�VP�@�V �@�VP�� �V �@�VP�@�V �@�VP�@�V �@�VP�@�V �@�VP�@�V  �/
TEST1
use Acme::Morse::Audible;
print <<Message;
"For there is no enchantment against Jacob, no divination against Israel; now it shall be said of Jacob and Israel, `What has God wrought!'"

	--Bible, Numbers 23:23
		
(The first telegraphic message. Dispatched by Samuel F. B. Morse on May 24, 1844 from Washington D.C. to Baltimore.)
Message
TEST2
no Acme::Morse::Audible;
MThd      ` MTrk�    � �Y  �@�VP�� �V �@�VP�� �V �@�VP�@�V �@�VP�@�V �@�VP�� �V �@�VP�@�V �@�VP�� �V �@�VP�@�V �@�VP�@�V �@�VP�� �V �@�VP�@�V �@�VP�� �V �@�VP�@�V �@�VP�@�V �@�VP�@�V �@�VP�@�V  �/
TEST3

open my $test,'>','test.tmp' or die "Can't open test.tmp - $!";
binmode($test);
print $test $$_[0];
close $test;

ok(!system "$Config{perlpath} -I".(join ' -I',@INC).' test.tmp');
ok($$_[1]) if $$_[1];
}
unlink 'test.tmp';
