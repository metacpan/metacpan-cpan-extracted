#!perl -w
BEGIN{ $ENV{APVM_DEBUG} = 'trace' }
use strict;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use Acme::Perl::VM::Run;

sub Foo::hello{
    my(undef, $msg) = @_;

    print "Hello, $msg world!\n";
}

for(my $i = 1; $i <= 1; $i++){
    Foo->hello('APVM');
}

