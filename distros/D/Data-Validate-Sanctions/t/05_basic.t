use strict;
use Test::More;
use Test::Exception;
use Path::Tiny qw(tempfile);
use Class::Unload;
use Data::Validate::Sanctions;

ok Data::Validate::Sanctions::is_sanctioned(qw(sergei ivanov)), "Sergei Ivanov is_sanctioned for sure";
ok !Data::Validate::Sanctions::is_sanctioned(qw(chris down)),   "Chris is a good guy";

throws_ok { Data::Validate::Sanctions::set_sanction_file() } qr/sanction_file is needed/, "sanction file is required";

my $tempfile = Path::Tiny->tempfile;
$tempfile->spew(qw(CHRISDOWN));
lives_ok { Data::Validate::Sanctions::set_sanction_file("$tempfile"); };
is(Data::Validate::Sanctions::get_sanction_file(), "$tempfile", "get sanction file ok");

ok !Data::Validate::Sanctions::is_sanctioned(qw(sergei ivanov)), "Sergei Ivanov is a good boy now";
ok Data::Validate::Sanctions::is_sanctioned(qw(chris down)),     "Chris is a bad boy now";

done_testing;
