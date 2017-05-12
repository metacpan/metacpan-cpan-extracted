package    #hide
  My::User;
use base qw(My);
use strict;
use warnings;
use utf8;

sub TABLE   {'users'}
sub COLUMNS { [qw(id group_id login_name login_password disabled)] }
sub WHERE   { {disabled => 1} }

#See Params::Check
my $_CHECKS = {
  id       => {allow => qr/^\d+$/x},
  group_id => {allow => qr/^\d+$/x, default => 1},
  disabled => {
    default => 1,
    allow   => sub {
      return $_[0] =~ /^[01]$/x;
      }
  },
  login_name     => {allow => qr/^\p{IsAlnum}{4,12}$/x},
  login_password => {
    required => 1,
    allow    => sub { $_[0] =~ /^[\w\W]{8,20}$/x; }
    }

#...
};
sub CHECKS {$_CHECKS}

sub id {
  my ($self, $value) = @_;
  if (defined $value) {    #setting value
    $self->{data}{id} = $self->_check(id => $value);

#make it chainable
    return $self;
  }
  $self->{data}{id} //= $self->CHECKS->{id}{default};    #getting value
}

1;
