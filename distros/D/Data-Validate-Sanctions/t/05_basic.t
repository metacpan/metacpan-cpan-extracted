use strict;
use Class::Unload;
use Data::Validate::Sanctions;
use YAML::XS qw(Dump);
use Path::Tiny qw(tempfile);
use Test::Exception;
use Test::More;

ok Data::Validate::Sanctions::is_sanctioned(qw(sergei ivanov)), "Sergei Ivanov is_sanctioned for sure";
ok !Data::Validate::Sanctions::is_sanctioned(qw(chris down)),   "Chris is a good guy";

throws_ok { Data::Validate::Sanctions::set_sanction_file() } qr/sanction_file is needed/, "sanction file is required";

my $tempfile = Path::Tiny->tempfile;
$tempfile->spew(
    Dump({
            test1 => {
                updated => time,
                names   => ['CHRISDOWN']}}));
lives_ok { Data::Validate::Sanctions::set_sanction_file("$tempfile"); };
is(Data::Validate::Sanctions::get_sanction_file(), "$tempfile", "get sanction file ok");

ok !Data::Validate::Sanctions::is_sanctioned(qw(sergei ivanov)), "Sergei Ivanov is a good boy now";
ok Data::Validate::Sanctions::is_sanctioned(qw(chris down)),     "Chris is a bad boy now";

done_testing;
