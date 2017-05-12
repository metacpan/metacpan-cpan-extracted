use strict;
use warnings;
use Test::More 'no_plan';
use Acme::Crap;

like "This should be okay", qr/^This should be okay$/ => 'String literal';
like !"Nothing to see",     qr/^$/   => 'One ! string literal';
like !!"Nothing to see",    qr/^1$/  => 'Two ! string literal';
like !!!"Nothing to see",   qr/^$/   => 'Three ! string literal';
like !!!!"Nothing to see",  qr/^1$/  => 'Four ! string literal';
like !!!!!"Nothing to see", qr/^$/   => 'Five ! string literal';

{
    close *STDERR;
    open *STDERR, '>', \my $STDERR;
    crap "there was a problem";
    like $STDERR, qr{^there was a problem at \S+ line \d+} => 'Zero ! warning';
}

{
    close *STDERR;
    open *STDERR, '>', \my $STDERR;
    crap! "there was a problem";
    like $STDERR, qr{^There was a problem! at \S+ line \d+} => 'One ! warning';
}

{
    close *STDERR;
    open *STDERR, '>', \my $STDERR;
    crap!! "there was a problem";
    like $STDERR, qr{^There Was A Problem!! at \S+ line \d+} => 'Two ! warning';
}

{
    close *STDERR;
    open *STDERR, '>', \my $STDERR;
    crap!!! "there was a problem";
    like $STDERR, qr{^THERE WAS A PROBLEM!!! at \S+ line \d+} => 'Three ! warning';
}

{
    close *STDERR;
    open *STDERR, '>', \my $STDERR;
    crap!!!!! "there was a problem";
    like $STDERR, qr{^THERE WAS A PROBLEM!!!!! at \S+ line \d+} => 'Many ! warning';
}

