package Cat;

use strict;
use warnings;

use App::Environ;
use App::Environ::Config;
use Carp qw( croak );

App::Environ::Config->register( qw( cat.json ) );

App::Environ->register( __PACKAGE__,
  initialize   => sub { __PACKAGE__->_initialize(@_) },
  reload       => sub { __PACKAGE__->_reload(@_) },
  'finalize:r' => sub { __PACKAGE__->_finalize(@_) },
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

  my $cat_config = App::Environ::Config->instance->{'cat'};

  $INSTANCE = {
    config    => $cat_config,
    init_args => [@_],
  };

  print __PACKAGE__ . " initialized\n";

  return;
}

sub _reload {
  $INSTANCE->{config} = App::Environ::Config->instance->{'cat'};

  print __PACKAGE__ . " reloaded\n";

  return;
}

sub _finalize {
  undef $INSTANCE;

  print __PACKAGE__ . " finalized\n";

  return;
}

1;
