package Net::LDAP;
use strict;
use warnings;

our $VERSION          = '0.1';
our $CONSTRUCTOR_FAIL = undef;
our $BIND_CODE        = undef;
our $BIND_ERROR       = undef;

sub new {
  my ($class, @args) = @_;
  if($CONSTRUCTOR_FAIL) {
    return;
  }

  my $self = {
	      constructor_args => \@args,
	     };
  bless $self, $class;
  return $self;
}

sub bind {
  my ($self, @args) = @_;
  $self->{bind_args} = \@args;
  my $bind_msg = {};
  bless $bind_msg, 'Net::LDAP::bind_msg';

  {
    no warnings;
    *{Net::LDAP::bind_msg::code}  = sub { return $BIND_CODE; };
    *{Net::LDAP::bind_msg::error} = sub { return $BIND_ERROR; };
  }

  return $bind_msg;
}

1;
