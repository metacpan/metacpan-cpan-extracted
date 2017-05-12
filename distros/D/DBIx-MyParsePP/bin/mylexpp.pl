use strict;

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl simple.t'

#########################

use DBIx::MyParsePP::Lexer;

my $lexer = DBIx::MyParsePP::Lexer->new(string => $ARGV[0]);

use Data::Dumper;
while (1) {
	my $token = $lexer->yylex();
	print Dumper \$token;
	last if $token->[0] eq 'END_OF_INPUT';
}
