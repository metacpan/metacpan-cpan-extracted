#!perl
#
use strict;
use warnings;
use CLI::Helpers qw(:all);

my $v = prompt("Enter a number:", validate => { 'a number' => sub { /^\d+$/; }}, default => 1);
output("You selected: $v");

output( sprintf "pwprompt got %d bytes. ", length pwprompt() );

# Try requesting a password without calling pwprompt
output( sprintf "Password length is %d.", length prompt("password: ") );
output( sprintf "Password length is %d.", length prompt("passwd: ") );
output( sprintf "Password length is %d.", length prompt("Enter Your Password: ") );
