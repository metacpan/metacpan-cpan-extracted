#!/usr/bin/perl -w

use strict;

use Test::More;

BEGIN {
   eval { require Sub::Name } or
      plan skip_all => "No Sub::Name";
}

use CPS qw( kloop kforeach gkforeach );

plan tests => 3;

sub callers
{
   my @pkgs;
   my $i = 1;
   push @pkgs, (caller $i)[3] and $i++ while (caller $i)[3];
   @pkgs;
}

my $count = 0;
my @callers;
kloop( sub {
   my ( $knext, $klast ) = @_;
   push @callers, [ callers ];
   ++$count == 3 ? $klast->() : $knext->();
}, sub {} );

is_deeply( \@callers,
           [
              [ 'main::__ANON__', 'CPS::Governor::enter', 'CPS::gkloop' ],
              [ 'main::__ANON__', 'CPS::Governor::enter', 'CPS::gkloop' ],
              [ 'main::__ANON__', 'CPS::Governor::enter', 'CPS::gkloop' ],
           ],
           '@callers after kloop' );

@callers = ();
kforeach( [ 1 .. 3 ], sub {
   my ( $i, $knext ) = @_;
   push @callers, [ callers ];
   $knext->();
}, sub {} );

is_deeply( \@callers,
           [
              [ 'main::__ANON__', 'CPS::Governor::enter', 'CPS::gkloop', 'CPS::gkforeach' ],
              [ 'main::__ANON__', 'CPS::Governor::enter', 'CPS::gkloop', 'CPS::gkforeach' ],
              [ 'main::__ANON__', 'CPS::Governor::enter', 'CPS::gkloop', 'CPS::gkforeach' ],
           ],
           '@callers after kforeach' );

my $gov = TestGovernor->new;

@callers = ();
gkforeach( $gov, [ 1 .. 3 ], sub {
   my ( $i, $knext ) = @_;
   push @callers, [ callers ];
   $knext->();
}, sub {} );

$gov->poke while $gov->pending;

is_deeply( \@callers,
           [
              [ 'main::__ANON__', 'TestGovernor::poke' ],
              [ 'main::__ANON__', 'TestGovernor::poke' ],
              [ 'main::__ANON__', 'TestGovernor::poke' ],
           ],
           '@callers after gkforeach on deferred governor' );

package TestGovernor;
use base qw( CPS::Governor );

sub again
{
   my $self = shift;
   my ( $code, @args ) = @_;
   $self->{code} = $code;
   $self->{args} = \@args;
}

sub pending
{
   my $self = shift;
   return defined $self->{code};
}

sub poke
{
   my $self = shift;

   my $code = delete $self->{code} or die;
   $code->( @{ delete $self->{args} } );
}
