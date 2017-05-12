use warnings;
use strict;

use Test::More tests => 69;

BEGIN { use_ok "Crypt::Eksblowfish::Bcrypt", qw(bcrypt); }

my @wrong_passwords = qw(foo quux supercalifragilisticexpialidocious);
while(<DATA>) {
	chomp;
	s/([^ ]+) ([^ ]+) *//;
	my($settings, $hash) = ($1, $2);
	is bcrypt($_, $settings), $settings.$hash;
	isnt bcrypt($_, $settings), $settings.$hash foreach (@wrong_passwords);
}

1;

__DATA__
$2$05$CCCCCCCCCCCCCCCCCCCCC. 7uG0VCzI2bS7j6ymqJi9CdcdxiRTWNy
$2$07$aba.............kC2SI. cbHK1ODT5F77pYUqRNV63bd/IDxsTXq 0
$2$07$abcdee..........kC2SI. HiVB5Ax/RkxnDF2P5lQk06NBgbF/xYO 0
$2$07$abcdefghijklmnopkC2SI. 7Q0nVrcMF4umRv5Pk5vDi0GlDI.lLE. 0
$2$07$abcdefghijklmnopqrstuu AgtOGDu2Z1DC3oOn6HzhbBE811IGUYu 0
$2$07$abcdefghijklmnopkC2SI. SY5XUDcstCvd.D7IsnwxqkBQmKD548W password
$2$04$abcdefghijklmnopkC2SI. q7Yf61ne/f5tu69iU.SIM68gT3LAaYy password
$2$10$abcdefghijklmnopkC2SI. /wsXFeTOFgHVzDjpY2cn9yyF85o0khS password
$2$04$...................... Ns4TWVMFumL/LG8wa/FMbZnvNs.EDBi password
$2$05$...................... bvpG2UfzdyW/S0ny/4YyEZrmczoJfVm password
$2$06$...................... h9TvqYVBoV1csDZEfDS/qeQHryfT7dm password
$2$07$...................... A.nYdZ8J7ihz9grv6aPNwWdqpEgHssm password
$2a$05$CCCCCCCCCCCCCCCCCCCCC. E5YPO9kmyuRGyh0XouQYb4YMJKvyOeW U*U
$2a$05$CCCCCCCCCCCCCCCCCCCCC. VGOzA784oUp/Z0DY336zx7pLYAy0lwK U*U*
$2a$05$XXXXXXXXXXXXXXXXXXXXXO AcXxm9kjPGEMsLznoKqmqw7tc8WCx4a U*U*U
$2a$05$CCCCCCCCCCCCCCCCCCCCC. 7uG0VCzI2bS7j6ymqJi9CdcdxiRTWNy
$2a$05$abcdefghijklmnopqrstuu 5s2v8.iXieOjg/.AySBTTZIIVFJeBui 0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789
