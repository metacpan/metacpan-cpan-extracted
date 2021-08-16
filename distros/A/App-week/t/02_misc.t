use v5.14;
use warnings;
use utf8;
use Test::More;
use File::Spec;
use Data::Dumper;

use lib '.';
use t::Util;
$Script::lib    = File::Spec->rel2abs('lib');
$Script::script = File::Spec->rel2abs('script/week');

sub compare {
    my($result, $compare, $comment) = @_;
    if (ref $compare eq 'Regexp'){
	like $result, $compare, $comment;
    } else {
	is   $result, $compare, $comment;
    }
}

sub week {
    Script->new([@_])->run->result;
}

{
    local %ENV = %ENV;
    $ENV{LANG} = $ENV{LC_ALL} = 'C';

    compare week(qw(--colordump)), qr/\Aoption --changeme/, "--colordump";
    compare week(qw(--help)),      qr/\AUsage:/,            "--help";
    compare week(qw(--version)),   qr/\AVersion:/,          "--version";
}

done_testing;
