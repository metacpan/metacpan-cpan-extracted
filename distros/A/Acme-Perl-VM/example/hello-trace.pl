#!perl -w
BEGIN{ $ENV{APVM_DEBUG} = 'trace' }
use strict;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use Acme::Perl::VM::Run;

my $x = 'APVM';
print "Hello, $x world!\n";
