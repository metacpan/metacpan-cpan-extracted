package Catalyst::Plugin::Session::Manager::Client;
use strict;
use warnings;

sub new { bless { config => $_[1] || {} }, $_[0] }
sub get { }
sub set { }

1;
__END__
