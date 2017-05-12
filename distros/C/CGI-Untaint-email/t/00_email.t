use strict;
use Test::More tests => 4;

use CGI;
use CGI::Untaint;

my @ok  = (
    'miyagawa@cpan.org',
    'Tatsuhiko Miyagawa <miyagawa@cpan.org>',
);

my @not = (
    'miyagawa at cpan dot org',
);

my $count = 0;
my %hash = map { 'var' . $count++ => $_ } @ok, @not;
my $q = CGI->new(\%hash);

ok my $handler = CGI::Untaint->new($q->Vars), 'create the handler';

$count = 0;
for (@ok) {
    is $handler->extract(-as_email => 'var' . $count++), $_, 'Valid';
}

for (@not) {
    is $handler->extract(-as_email => 'var' . $count++), undef, 'Invalid';
}
