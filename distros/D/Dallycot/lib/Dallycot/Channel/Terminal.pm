package Dallycot::Channel::Terminal;
our $AUTHORITY = 'cpan:JSMITH';

# ABSTRACT: Term::ReadLine-based i/o channel

use utf8;
use Moose;
extends 'Dallycot::Channel';

use Promises qw(deferred);
use Term::ReadLine;

has term => (
  is      => 'ro',
  default => sub {
    Term::ReadLine->new('Dallycot Terminal');
  }
);

has completion_provider => (
  is       => 'ro'
);

sub BUILD {
  my($self) = @_;

  $self->term->Attribs->{completion_function} = sub {
    $self -> symbol_completions(@_);
  };
}

sub symbol_completions {
  my($self, $text, $line, $start) = @_;

  if($self -> completion_provider) {
    return $self -> completion_provider -> symbol_completions($text, $line, $start);
  }
}

sub can_send {
  my ($self) = @_;

  return defined( $self->term->OUT );
}

sub can_receive {
  my ($self) = @_;

  return defined( $self->term->IN );
}

sub has_history { return 1 }

sub send_data {
  my ( $self, @stuff ) = @_;

  # For now, this is synchronous

  my $OUT = $self->term->OUT;
  return unless defined $OUT;

  print $OUT @stuff;

  return;
}

sub receive_data {
  my ( $self, %options ) = @_;

  my $d = deferred;

  if ( $self->can_receive ) {
    my $prompt = $options{'prompt'};
    my $line;
    if ( defined $prompt ) {
      $prompt = $prompt->value;
      $line   = $self->term->readline($prompt);
    }
    else {
      $line = $self->term->readline;
    }
    if ( defined $line ) {
      $d->resolve( Dallycot::Value::String->new($line) );
    }
    else {
      $d->resolve( Dallycot::Value::Undefined->new );
    }
  }
  else {
    $d->reject('Unable to read');
  }

  return $d->promise;
}

sub add_history {
  my ( $self, $line ) = @_;

  $self->term->addhistory( $line->value );
  return;
}

__PACKAGE__ -> meta -> make_immutable;

1;
