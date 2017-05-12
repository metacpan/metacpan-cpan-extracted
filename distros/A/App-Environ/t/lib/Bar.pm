package Bar;

use strict;
use warnings;

use App::Environ;
use App::Environ::Config;
use Carp qw( croak );

App::Environ::Config->register( qw( bar.yml ) );

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

  my $bar_config = App::Environ::Config->instance->{'bar'};

  $INSTANCE = {
    config    => $bar_config,
    init_args => \@args,
    reloads   => 0,
  };

  return;
}

sub _reload {
  $INSTANCE->{config} = App::Environ::Config->instance->{'bar'};
  $INSTANCE->{reloads}++;

  return;
}

sub _pre_finalize {
  my $class    = shift;
  my $need_err = shift;
  my $cb       = shift;

  $cb->();

  return;
}

sub _finalize {
  undef $INSTANCE;
  return;
}

1;
