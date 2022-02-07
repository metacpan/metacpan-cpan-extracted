use strict;
use warnings;

use App::Cme::Command::run;
use Test::More;

my $content = <<'EOS';
app:  popcon
---var
$var{change_it} = qq{
s/^(a)a+/ # comment
\$1.\\"$args{fooname}\\" x2
/xe}
---
load: ! MY_HOSTID=~"$change_it"
EOS

my %user_args = (fooname => 'foo');

my $data = App::Cme::Command::run::parse_script('test', $content, \%user_args);

is($data->{load}[0], '! MY_HOSTID=~" s/^(a)a+/  $1.\"foo\" x2 /xe"', "test parsed script");

done_testing;
