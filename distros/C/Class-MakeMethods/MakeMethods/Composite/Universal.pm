=head1 NAME

Class::MakeMethods::Composite::Universal - Composite Method Tricks

=head1 SYNOPSIS

  Class::MakeMethods::Composite::Universal->make_patch(
    -TargetClass => 'SomeClass::OverYonder',
    name => 'foo',
    pre_rules => [ 
      sub { 
	my $method = pop; 
	warn "Arguments for foo:", @_ 
      } 
    ]
    post_rules => [ 
      sub { 
	warn "Result of foo:", Class::MakeMethods::Composite->CurrentResults 
      } 
    ]
  );

=head1 DESCRIPTION

The Composite::Universal suclass of MakeMethods provides some generally-applicable types of methods based on Class::MakeMethods::Composite.

=cut

package Class::MakeMethods::Composite::Universal;

$VERSION = 1.000;
use strict;
use Class::MakeMethods::Composite '-isasubclass';
use Carp;

########################################################################

=head1 METHOD GENERATOR TYPES

=head2 patch

The patch ruleset generates composites whose core behavior is based on an existing subroutine.

Here's a sample usage:

  sub foo {
    my $count = shift;
    return 'foo' x $count;
  }
  
  Class::MakeMethods::Composite::Universal->make(
    -ForceInstall => 1,
    patch => {
      name => 'foo',
      pre_rules => [
	sub { 
	  my $method = pop @_;
	  if ( ! scalar @_ ) {
	    @{ $method->{args} } = ( 2 );
	  }
	},
	sub { 
	  my $method = pop @_;
	  my $count = shift;
	  if ( $count > 99 ) {
	    Carp::confess "Won't foo '$count' -- that's too many!"
	  }
	},
      ],
      post_rules => [
	sub { 
	  my $method = pop @_;
	  if ( ref $method->{result} eq 'SCALAR' ) {
	    ${ $method->{result} } =~ s/oof/oozle-f/g;
	  } elsif ( ref $method->{result} eq 'ARRAY' ) {
	    map { s/oof/oozle-f/g } @{ $method->{result} };
	  }
	} 
      ],
    },
  );

=cut

use vars qw( %PatchFragments );

sub patch {
  (shift)->_build_composite( \%PatchFragments, @_ );
}

%PatchFragments = (
  '' => [
    '+init' => sub {
	my $method = pop @_;
	my $origin = ( $Class::MethodMaker::CONTEXT{TargetClass} || '' ) . 
			'::' . $method->{name};
	no strict 'refs';
	$method->{patch_original} = *{ $origin }{CODE}
	    or croak "No subroutine $origin() to patch";  
      },
    'do' => sub {
	my $method = pop @_;
	my $sub = $method->{patch_original};
	&$sub( @_ );
      },
  ],
);

=head2 make_patch

A convenient wrapper for C<make()> and the C<patch> method generator.

Provides the '-ForceInstall' flag, which is required to ensure that the patched subroutine replaces the original.

For example, one could add logging to an existing method as follows:

  Class::MakeMethods::Composite::Universal->make_patch(
    -TargetClass => 'SomeClass::OverYonder',
    name => 'foo',
    pre_rules => [ 
      sub { 
	my $method = pop; 
	warn "Arguments for foo:", @_ 
      } 
    ]
    post_rules => [ 
      sub { 
	warn "Result of foo:", Class::MakeMethods::Composite->CurrentResults 
      } 
    ]
  );

=cut

sub make_patch {
  (shift)->make( -ForceInstall => 1, patch => { @_ } );
}


########################################################################

=head1 SEE ALSO

See L<Class::MakeMethods> for general information about this distribution. 

See L<Class::MakeMethods::Composite> for more about this family of subclasses.

=cut

1;
