use strict;
use warnings;

use Test::More tests => 4;

use_ok('Acme::Indent', qw(ai));

my $wmessage;
$SIG{'__WARN__'} = sub { $wmessage = $_[0]; };

$wmessage = '';

my $mini_prog1 = ai(q^
    my $token = 'B';
             
    print "Begin test $token\n";
    my $ph = {a => 'abc', z => 'xyz'};
    my @list = qw(a r z);

    while (@list) {
        my $key = shift @list;
        if ($ph->{$key})) {
            print $ph->{$key}, "\n";
        }
    }

    $token = 'E';
    print "End test $token\n";

^);

my $output1 = <<'EOT';
my $token = 'B';

print "Begin test $token\n";
my $ph = {a => 'abc', z => 'xyz'};
my @list = qw(a r z);

while (@list) {
    my $key = shift @list;
    if ($ph->{$key})) {
        print $ph->{$key}, "\n";
    }
}

$token = 'E';
print "End test $token\n";
EOT

is($wmessage,   '',       'Test1: no warnings');
is($mini_prog1, $output1, 'Test2: correct indentation');

$wmessage = '';

my $mini_prog2 = ai(q^
    TTTT;
 uu UUUU;
    VVVV;
^);

like($wmessage,   qr{\A Found \s+ characters \s* \(' .* '\) \s* in \s+ indentation \s+ zone}xms, 'Test3: warning via carp');
