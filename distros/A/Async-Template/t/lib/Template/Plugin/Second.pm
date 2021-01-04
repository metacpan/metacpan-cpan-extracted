package Template::Plugin::Second;

#! @file
#! @author: Serguei Okladnikov <oklaspec@gmail.com>
#! @date 01.10.2012

use strict;
use warnings;
use base 'Template::Plugin';
use AnyEvent;
use Time::HiRes;

our $VERSION = 0.01;
our $DYNAMIC = 0 unless defined $DYNAMIC;


sub load {
        my ($class, $context) = @_;
        return $class;
}

sub new {
   my $class = shift;
   my $context = shift;
   bless {
      _CONTEXT => $context,
   }, $class
}

sub now {
  scalar Time::HiRes::time();
}

sub start {
   my $cb = pop @_;
   my ( $self, $second, $value ) = @_;
   $value = 'ok' if 2 == scalar @_;

   # notify system with error message if somthing wrong
   if ( $second < 0 ) {
      $cb->( { error => "second($second) is must be positive" } );
      return;
   }

   my $started_at = now;

   my $on_timer; $on_timer = sub {
      # workaround timer cb called too earlier
      my $remaining = $second - (now() - $started_at);
      if( $remaining > 0 ) {
        $self->{tm} = AE::timer $remaining, 0, $on_timer;
        return;
      }

      # notify system that event done with result any data at param
      $cb->( { result => $value } );
   };

   # start the event with specific on_event handler
   $self->{tm} = AE::timer $second, 0, $on_timer;
}

1;

