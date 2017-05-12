package Foo;

use strict;
use warnings;

use App::Environ;
use App::Environ::Config;
use Carp qw( croak );

App::Environ::Config->register( qw( foo.json ) );

App::Environ->register( __PACKAGE__,
  initialize       => sub { __PACKAGE__->_initialize(@_) },
  reload           => sub { __PACKAGE__->_reload(@_) },
  'pre_finalize:r' => sub { __PACKAGE__->_pre_finalize(@_) },
  'finalize:r'     => sub { __PACKAGE__->_finalize(@_) },
);

my $INSTANCE;


sub instance {
  unless ( defined $INSTANCE ) {
    croak __PACKAGE__ . ' must be initialized first';
  }

  return $INSTANCE;
}

sub _initialize {
  my $class = shift;
  my @args  = @_;

  my $foo_config = App::Environ::Config->instance->{'foo'};

  $INSTANCE = {
    config    => $foo_config,
    init_args => \@args,
    reloads   => 0,
  };

  return;
}

sub _reload {
  my $class     = shift;
  my $raise_err = shift;

  die "Some error.\n" if ($raise_err);

  $INSTANCE->{config} = App::Environ::Config->instance->{'foo'};
  $INSTANCE->{reloads}++;

  return;
}

sub _pre_finalize {
  my $class     = shift;
  my $raise_err = shift;
  my $cb        = shift;

  if ($raise_err) {
    $cb->('Some error.');
    return;
  }

  $cb->();

  return;
}

sub _finalize {
  undef $INSTANCE;
  return;
}

1;
