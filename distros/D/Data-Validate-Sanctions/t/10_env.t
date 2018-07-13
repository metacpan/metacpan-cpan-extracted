use strict;
use YAML::XS qw(Dump);
use Path::Tiny qw(tempfile);
use Test::Exception;
use Test::More;

my ($tmpa, $tmpb);

BEGIN {
    $tmpa = tempfile;
    $tmpa->spew(
        Dump({
                test1 => {
                    updated => time,
                    names   => ['TMPA']}}));
    $tmpb = tempfile;
    $tmpb->spew(
        Dump({
                test1 => {
                    updated => time,
                    names   => ['TMPB']}}));
    $ENV{SANCTION_FILE} = "$tmpa";
}
use Data::Validate::Sanctions;

ok Data::Validate::Sanctions::is_sanctioned(qw(tmpa)), "get sanction file from ENV";
lives_ok { Data::Validate::Sanctions::set_sanction_file("$tmpb"); };
ok Data::Validate::Sanctions::is_sanctioned(qw(tmpb)), "file from args override env";

done_testing;
