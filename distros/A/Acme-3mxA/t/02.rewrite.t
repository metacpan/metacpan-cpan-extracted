#!perl
use utf8; use Acme::ǝmɔA;

if(!@ARGV) {
  eval q{ 
    use Test::More tests => 2;
    ok 1;
    ok run_again() =~ /alright!/;
  };
} else {
  print "alright!";
}

sub run_again {
  my $file = __FILE__;
  `$^X $file again`;
}

