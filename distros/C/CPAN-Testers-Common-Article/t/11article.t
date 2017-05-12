#!/usr/bin/perl -w
use strict;

use lib 'lib';
use Test::More tests => 58;
use IO::File;

use_ok('CPAN::Testers::Common::Article');

# PASS report
my $article = readfile('t/nntp/126015.txt');
my $a = CPAN::Testers::Common::Article->new($article);
isa_ok($a,'CPAN::Testers::Common::Article');
ok($a->parse_report());
is($a->from, 'Jost.Krieger+perl@rub.de (Jost Krieger+Perl)');
is($a->postdate, '200403');
is($a->date, '200403081025');
is($a->status, 'PASS');
ok($a->passed);
ok(!$a->failed);
is($a->distribution, 'AI-Perceptron');
is($a->version, '1.0');
is($a->perl, '5.8.3');
is($a->osname, 'solaris');
is($a->osvers, '2.8');
is($a->archname, 'sun4-solaris-thread-multi');

# FAIL report
$article = readfile('t/nntp/125106.txt');
$a = CPAN::Testers::Common::Article->new($article);
isa_ok($a,'CPAN::Testers::Common::Article');
ok($a->parse_report());
is($a->from, 'cpansmoke@alternation.net');
is($a->postdate, '200403');
is($a->date, '200403030607');
is($a->status, 'FAIL');
ok(!$a->passed);
ok($a->failed);
is($a->distribution, 'Net-IP-Route-Reject');
is($a->version, '0.5_1');
is($a->perl, '5.8.0');
is($a->osname, 'linux');
is($a->osvers, '2.4.22-4tr');
is($a->archname, 'i586-linux');

ok(!$a->parse_upload());


# upload announcement
$article = readfile('t/nntp/1804993.txt');
$a = CPAN::Testers::Common::Article->new($article);
isa_ok($a,'CPAN::Testers::Common::Article');
ok($a->parse_upload());
is($a->from, 'upload@pause.perl.org (PAUSE)');
is($a->postdate, '200806');
is($a->date, '200806271438');
is($a->distribution, 'Test-CPAN-Meta');
is($a->version, '0.12');

ok(!$a->parse_report());


# in reply to
$article = readfile('t/nntp/1805500.txt');
$a = CPAN::Testers::Common::Article->new($article);
ok(!$a);

=pod

# base64
$article = readfile('t/nntp/1804993.txt');
$a = CPAN::Testers::Common::Article->new($article);
isa_ok($a,'CPAN::Testers::Common::Article');
ok(!$a->parse_upload());
ok($a->parse_report());
is($a->from, 'cpansmoke@alternation.net');
is($a->postdate, '200403');
is($a->date, '200403000000');
is($a->status, 'FAIL');
ok(!$a->passed);
ok($a->failed);
is($a->distribution, 'Net-IP-Route-Reject');
is($a->version, '0.5_1');
is($a->perl, '5.8.0');
is($a->osname, 'linux');
is($a->osvers, '2.4.22-4tr');
is($a->archname, 'i586-linux');

=cut

# quoted printable
$article = readfile('t/nntp/6000000.txt');
$a = CPAN::Testers::Common::Article->new($article);
isa_ok($a,'CPAN::Testers::Common::Article');
ok(!$a->parse_upload());
ok($a->parse_report());
is($a->from, 'bingos@cpan.org');
is($a->postdate, '200911');
is($a->date, '200911141527');
is($a->status, 'PASS');
ok($a->passed);
ok(!$a->failed);
is($a->distribution, 'DateTimeX-Format');
is($a->version, '1.03');
is($a->perl, '5.10.1');
is($a->osname, 'openbsd');
is($a->osvers, '4.5');
is($a->archname, 'OpenBSD.i386-openbsd');

like($a->raw,qr/AUTOMATED_TESTING\s+=3D\s+1/,'.. quoted printable in raw state');
unlike($a->cooked,qr/AUTOMATED_TESTING\s+=3D\s+1/,'.. quoted printable in cooked state');
like($a->cooked,qr/AUTOMATED_TESTING\s+=\s+1/,'.. quoted printable in cooked state');
like($a->body,qr/AUTOMATED_TESTING\s+=\s+1/);


sub readfile {
    my $file = shift;
    my $text;
    my $fh = IO::File->new($file)   or return;
    while(<$fh>) { $text .= $_ }
    $fh->close;
    return $text;
}
