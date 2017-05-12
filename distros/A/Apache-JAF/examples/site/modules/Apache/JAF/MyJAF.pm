package Apache::JAF::MyJAF;
use strict;

use Apache::Constants qw(:common);

use JAF::MyJAF; # optional -- for database-driven site only
use Apache::JAF (handlers => 'auto', templates => 'auto');
our @ISA = qw(Apache::JAF);

# determine handler to call 
sub setup_handler {
  my ($self) = @_;
  # the page handler for every uri for sample site is 'do_index'
  # you should swap left and right || parts for real application
  my $handler = 'index' || shift @{$self->{uri}};
  return $handler;
}

sub site_handler {
  my ($self) = @_;
  # common stuff before handler is called
  # $self->{m} = JAF::MyJAF->new(); # create modeller -- if needed
  $self->SUPER::site_handler();
  # common stuff after handler is called
  return $self->{status}
}

1;
