use strict;
use Test::More;
use Test::Exception;
use Path::Tiny qw(tempfile);

my ($tmpa, $tmpb);

BEGIN {
    $tmpa = tempfile;
    $tmpa->spew(qw(TMPA));
    $tmpb = tempfile;
    $tmpb->spew(qw(TMPB));
    $ENV{SANCTION_FILE} = "$tmpa";
}
use Data::Validate::Sanctions;

ok Data::Validate::Sanctions::is_sanctioned(qw(tmpa)), "get sanction file from ENV";
lives_ok { Data::Validate::Sanctions::set_sanction_file("$tmpb"); };
ok Data::Validate::Sanctions::is_sanctioned(qw(tmpb)), "file from args override env";

done_testing;
