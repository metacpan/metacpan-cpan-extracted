#!/usr/bin/perl

use Test;
BEGIN { plan tests => 6 }

use Class::MakeMethods;

package Class::MakeMethods::UpperCase;
use Class::MakeMethods::Template '-isasubclass';

# Alias to another type of meta-method
sub regular_scalar { return 'Template::Hash:scalar' }

# Structured meta-method definition
sub uc_scalar {
  return { 
    'interface' => { 
      default => { '*'=>'uc_get_set' } 
    },
    'behavior' => {
      'uc_get_set' => sub { my $m_info = $_[0]; sub {
	  my $self = shift;
	  if ( scalar @_ ) { $self->{ $m_info->{'name'} } = uc shift }
	  $self->{ $m_info->{'name'} };
      }},
    }
  }
}

sub auto_detect { 
  my $mm_class = shift;
  my @rewrite = ( [ 'Template::Hash:scalar' ], [ 'UpperCase:uc_scalar' ] );
  foreach ( @_ ) {
    push @{ $rewrite[ ( $_ eq uc($_) ? 1 : 0 ) ] }, $_
  }
  return @rewrite;
}

package MyObject;

Class::MakeMethods::UpperCase->import(
  'Template::Hash:new'	=> [ 'new' ],
  'regular_scalar'	=> [ 'name' ],
  'uc_scalar'		=> [ 'id' ],
  'auto_detect'		=> [ 'foo', 'Bar', 'BAZ' ],
);

package main;

my $obj;
ok do { $obj = MyObject->new( 
  name=>'Alice', id=>'al01', foo=>'Foozle', Bar=>'Barrel', BAZ=>'Bazillion'
) };
ok( $obj->id() eq 'AL01' ); #1
ok( $obj->foo() eq "Foozle" ); #2
ok( $obj->Bar("Bamboozle") ); #3
ok( $obj->Bar() eq 'Bamboozle' ); #4
ok( $obj->BAZ() eq uc('Bazillion') ); #5

