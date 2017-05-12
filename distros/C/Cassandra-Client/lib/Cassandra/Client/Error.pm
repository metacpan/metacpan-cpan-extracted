package Cassandra::Client::Error;
use 5.010;
use strict;
use warnings;

sub new { my $class= shift; bless { code => -1, message => "An unknown error occurred", @_ }, $class }
use overload '""' => sub { "Error $_[0]{code}: $_[0]{message}" };
sub code { $_[0]{code} }
sub message { $_[0]{message} }

# XXX This class needs serious refactoring
# Important things we pass :
#  * is_timeout
#  * do_retry

1;
