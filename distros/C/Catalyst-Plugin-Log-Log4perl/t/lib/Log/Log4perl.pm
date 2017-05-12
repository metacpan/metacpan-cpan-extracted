package Log::Log4perl;

use strict;
use warnings;

use Test::More;


sub init {
  is( $_[1], 'init', 'Log::Log4perl->init()' );
}

sub init_and_watch {
  is( $_[1], 'init_and_watch', 'Log::Log4perl->init_and_watch()' );
  is( $_[2], 'delay', 'Log::Log4perl->init_and_watch()' );
}


1
__END__
