package Unknown::Module;
use Mojo::Base -base;

our $VERSION = '0.01';

has replace_me => sub { };

sub replace_me {
  my $self = shift;
}

1;
