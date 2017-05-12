use strict;
use Test::More;
use Data::Validate::Sanctions;
use Path::Tiny qw(tempfile);
use Class::Unload;

my $validator = Data::Validate::Sanctions->new;

ok $validator->is_sanctioned(qw(sergei ivanov)), "Sergei Ivanov is_sanctioned for sure";
ok !$validator->is_sanctioned(qw(chris down)), "Chris is a good guy";

my $tmpa = tempfile;
$tmpa->spew(qw(TMPA));
my $tmpb = tempfile;
$tmpb->spew(qw(TMPB));
$validator = Data::Validate::Sanctions->new(sanction_file => "$tmpa");
ok !$validator->is_sanctioned(qw(sergei ivanov)), "Sergei Ivanov not is_sanctioned";
ok $validator->is_sanctioned(qw(tmpa)), "now sanction file is tmpa";

Class::Unload->unload('Data::Validate::Sanctions');
local $ENV{SANCTION_FILE} = "$tmpb";
require Data::Validate::Sanctions;
$validator = Data::Validate::Sanctions->new;
ok $validator->is_sanctioned(qw(tmpb)), "get sanction file from ENV";
$validator = Data::Validate::Sanctions->new(sanction_file => "$tmpa");
ok $validator->is_sanctioned(qw(tmpa)), "get sanction file from args";
done_testing;
