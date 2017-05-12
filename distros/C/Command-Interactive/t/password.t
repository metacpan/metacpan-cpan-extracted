#!/usr/bin/perl -w -I../../../lib/

use strict;
use warnings;

use lib 'lib';
use File::Temp ();
use Test::More (tests => 3);
use Test::NoWarnings;
use Test::Exception;
use Command::Interactive;;

my $password = Command::Interactive::Interaction->new({
        expected_string => 'password:',
        response        => 'secret',
        is_required     => 1,
});

my $response = Command::Interactive::Interaction->new({
        expected_string => 'Password accepted',
        is_required     => 1,
});

my $command = Command::Interactive->new({interactions => [$password, $response],});

my ($tempfh, $tempfile) = File::Temp::tempfile(
    CLEANUP => 1,
    SUFFIX  => '.pl'
);
is(defined($tempfh), 1, "Able to create temporary perl script");

$tempfh->print(
    q~
#!/usr/bin/perl

use strict;
use warnings;

use Term::ReadLine;
my $term = Term::ReadLine->new('Simple password checker');
my $prompt = 'Please enter your password:';
my $OUT = $term->OUT || \*STDOUT;
my $result = $term->readline($prompt);
if($result eq 'secret')
{
    print "Password accepted.\n";
}
else
{
    print "Password not accepted.\n";
}
~
);
$tempfh->close;

my $result = $command->run("perl $tempfile");
is($result, undef, "Ran password script and got acceptable response");

1;
