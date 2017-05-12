use Test::Simple 'no_plan';
use strict;
use lib './lib';
use Alister::Base::Sums ':all';
use Cwd;
use vars qw($_part $cwd);
$cwd = cwd();

my @valid_sums = qw/
f946d965d6fc77b0b8d12e5e0e5da6f5
f946d965d6fc77b0b8aa2e5e0e5da6f5
f946d445d6fc77b0b8d12e5e0e5da6f5
/;


my @invalid_sums = (
'p946d965d6fc77b0b8d12e5e0e5da6f5', # has letter p
'f946d965d6fc77b0b8aa2e5e0e5da6f', # 31 chars instead of 32
'f946d445d6fc77b0b8d12e5e0 e5da6f5', # spaces not allowed
undef,
);


for (@valid_sums){
   ok( validate_argument_sum($_), 'validate_argument_sum()' );
}

for (@invalid_sums){
   ok( ! validate_argument_sum($_), 'validate_argument_sum()' );
}

for (qw/1 2 3 345 25/){
   ok( validate_argument_id($_), 'validate_argument_id()');
}


for ( '', 'a', 0, 'a5', '5a', '4 3' ){
   ok( ! validate_argument_id($_), 'validate_argument_id()');
}








sub ok_part {
   printf STDERR "\n\n===================\nPART %s %s\n==================\n\n",
      $_part++, "@_";
}


