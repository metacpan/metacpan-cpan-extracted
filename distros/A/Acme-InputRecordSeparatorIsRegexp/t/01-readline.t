use Test::More;
use Acme::InputRecordSeparatorIsRegexp;
use Symbol;
use strict;
use warnings;

open my $f1, '>', 't/test01.txt';
print $f1 1..99999;
close $f1;

my $z = open my $fh, '<', 't/test01.txt';
ok($z, 'file opened');
#my $fh = Symbol::gensym;
my $t = tie *$fh, 'Acme::InputRecordSeparatorIsRegexp', $fh, '120|12|345';
ok($t, 'tie successful');
undef $t;      # prevent untie gotcha

my @x = <$fh>;
ok(scalar(@x), 'list readline');
ok(0 < grep( /120$/, @x ), 'some lines end in "120"');
ok(0 < grep( /12$/, @x ), 'some lines end in "12"');
ok(0 < grep( /345$/, @x ), 'some lines end in "345"');
my @not = grep( !/120?$/ && !/345$/, @x );
ok(@not == 1, 'one line does not end in 120, 12, 345');
ok($not[0] eq $x[-1], '... and that is the last line');
close $fh;


$z = open $fh, '<', 't/test01.txt';
ok($z, 'OPEN ok');
$t = tied *$fh;
ok($t, '\$fh still tied after open');
my $u1 = $t->input_record_separator;
my $u2 = $t->input_record_separator( qr/12|120|345/ );
ok($u2 eq '(?^:12|120|345)' ||       # $] >= 5.014
   $u2 eq '(?-xism:12|120|345)',     # $] <  5.014
   'input record separator regexp correct');
ok($u1 ne $u2, 'input record separator updated');
undef $t;

@x = <$fh>;
ok(0 == grep( /120$/, @x ), 'no lines end in "120" anymore');
ok(0 < grep( /12$/, @x ), 'some lines end in "12"');
ok(0 < grep( /345$/, @x ), 'some lines end in "345"');
@not = grep( !/120?$/ && !/345$/, @x );
ok(@not == 1, 'one line does not end in 120, 12, 345');
ok($not[0] eq $x[-1], '... and that is the last line');
close $fh;

unlink 't/test01.txt';


done_testing();
