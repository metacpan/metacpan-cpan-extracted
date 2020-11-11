use 5.008008;
use strict;
use warnings;

package Ask::Question;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.015';

use Moo;
use Scalar::Util 'blessed';

use overload (
	'&{}'    => sub { shift->coderef },
	fallback => 1,
);

sub ask { shift->coderef->() }

has backend  => ( is => 'lazy' );
has type     => ( is => 'rwp', predicate => 1 );
has spec     => ( is => 'rwp', predicate => 1 );
has title    => ( is => 'rwp', predicate => 1 );
has text     => ( is => 'rwp', predicate => 1 );
has multiple => ( is => 'rwp' );
has choices  => ( is => 'rwp' );
has coderef  => ( is => 'lazy', init_arg  => undef );
has default  => ( is => 'rwp',  predicate => 1 );
has method   => ( is => 'rwp' );

sub _build_backend {
	require Ask;
	'Ask'->instance;
}

sub BUILDARGS {
	my ( $class, @args ) = ( shift, @_ );
	@args == 1 and ref $args[0] and return $args[0];
	unshift @args, 'text' if @args % 2;
	+{@args};
}

sub isa {    # trick Moose
	return 1 if $_[1] eq __PACKAGE__;
	return 1 if $_[1] eq 'Class::MOP::Method';
	return 1 if $_[1] eq 'Moo::Object';
	return 1 if $_[1] eq 'UNIVERSAL';
	return 0;
}

sub _build_coderef {
	my ( $self ) = ( shift );
	
	# Avoid closing over $self
	my $ask      = $self->backend;
	my $type     = $self->type;
	my $choices  = $self->choices;
	my $multiple = $self->multiple;
	my $spec     = $self->spec || {};
	my $default  = $self->has_default ? $self->default : $spec->{default};
	my $text     = $self->has_text    ? $self->text    : $spec->{documentation};
	my $method   = $self->method;
	my $title    = $self->title;
	
	undef $default if ( blessed $default and $default == $self );
	
	return sub {
		my @args = @_;
		my ( $instance ) = ( @args );
		
		my $local_text = $text;
		if ( ref $local_text ) {
			$local_text = $local_text->( @args );
		}
		if ( not defined $local_text ) {
			$local_text = '?';
		}
		
		my $local_default = $default;
		if ( ref $local_default ) {
			$local_default = $local_default->( @args );
		}
		
		unless ( blessed($ask) and $ask->DOES('Ask::API') ) {
			$ask = $ask->();
		}
		
		my $local_type = $type;
		if ( not ref $local_type ) {
		
			$local_type ||= $spec->{type};
			
			if ( defined $local_type and not ref $local_type ) {
				require Type::Utils;
				$local_type = Type::Utils::dwim_type(
					$local_type,
					for => ref( $instance ),
				);
			}
			
			elsif ( defined $spec->{'isa'} and not ref $local_type ) {
				$local_type =
					ref( $spec->{'isa'} )
					? $spec->{'isa'}
					: do {
					require Type::Utils;
					Type::Utils::dwim_type(
						$spec->{'isa'},
						for      => ref( $instance ),
						fallback => ['make_class_type'],
					);
					};
			} #/ elsif ( defined $spec->{'isa'...})
			
			elsif ( defined $spec->{'does'} and not ref $local_type ) {
				$local_type =
					ref( $spec->{'does'} )
					? $spec->{'does'}
					: do {
					require Type::Utils;
					Type::Utils::dwim_type(
						$spec->{'does'},
						for      => ref( $instance ),
						fallback => ['make_role_type'],
					);
					};
			} #/ elsif ( defined $spec->{'does'...})
		} #/ if ( not ref $local_type)
		
		my $local_multiple = $multiple;
		if ( blessed $local_type and not defined $local_multiple ) {
			require Types::Standard;
			$local_multiple = ( $local_type <= Types::Standard::ArrayRef() );
		}
		
		my $local_choices = $choices;
		if ( defined $local_type
			and blessed $local_type
			and not defined $local_choices )
		{
			my $map = sub { [ map [ $_ x 2 ], @{ +shift } ] };
			require Types::Standard;
			if ( $local_type->isa( 'Type::Tiny::Enum' ) ) {
				$local_choices = $map->( $local_type->unique_values );
			}
			elsif ( $local_type->isa( 'Moose::Meta::TypeConstraint::Enum' ) ) {
				$local_choices = $map->( $local_type->values );
			}
			elsif ( $local_type <= Types::Standard::ArrayRef()
				and $local_type->is_parameterized )
			{
				my $tp = $local_type->type_parameter;
				if ( $tp->isa( 'Type::Tiny::Enum' ) ) {
					$local_choices = $map->( $tp->unique_values );
				}
				elsif ( $tp->isa( 'Moose::Meta::TypeConstraint::Enum' ) ) {
					$local_choices = $map->( $tp->values );
				}
			} #/ elsif ( $local_type <= Types::Standard::ArrayRef...)
		} #/ if ( defined $local_type...)
		
		my $is_bool;
		if ( defined $local_type and blessed $local_type ) {
			require Types::Standard;
			$is_bool = !!( $local_type <= Types::Standard::Bool() );
		}
		
		my ( $is_path, $is_dir, $is_abs );
		if ( defined $local_type and blessed $local_type ) {
		
			if ( eval { require Types::Path::Tiny } ) {
				$is_path = !!( $local_type <= Types::Path::Tiny::Path() );
				my $path_type = $is_path ? $local_type : undef;
				
				require Types::Standard;
				if ( !$is_path
					and $local_type <= Types::Standard::ArrayRef()
					and $local_type->is_parameterized )
				{
					my $tp = $local_type->type_parameter;
					if ( $tp <= Types::Path::Tiny::Path() ) {
						$is_path        = 1;
						$local_multiple = 1;
						$path_type      = $tp;
					}
				} #/ if ( !$is_path and $local_type...)
				
				if ( $is_path ) {
					$is_dir = ( $path_type <= Types::Path::Tiny::Dir() )
						|| ( $path_type <= Types::Path::Tiny::AbsDir() );
					$is_abs =
						( $path_type <= Types::Path::Tiny::AbsPath() )
						|| ( $path_type <= Types::Path::Tiny::AbsFile() )
						|| ( $path_type <= Types::Path::Tiny::AbsDir() );
				}
			} #/ if ( eval { require Types::Path::Tiny...})
		} #/ if ( defined $local_type...)
		
		my @common = (
			text => $local_text,
			defined( $title )         ? ( title   => $title )         : (),
			defined( $local_default ) ? ( default => $local_default ) : (),
		);
		
		my $get_answer = sub {
		
			if ( $method ) {
				my $str = $ask->$method(
					choices  => $choices,
					multiple => $multiple,
					@common,
				);
				chomp $str;
				return $str;
			}
			
			elsif ( $local_multiple and $local_choices ) {
				my @values = $ask->multiple_choice( @common, choices => $local_choices );
				return \@values;
			}
			
			elsif ( $local_choices ) {
				return $ask->single_choice( @common, choices => $local_choices );
			}
			
			elsif ( $local_multiple and $is_path ) {
				require Path::Tiny;
				my @paths = map( 'Path::Tiny'->new( $_ ),
					$ask->file_selection( @common, directory => $is_dir, multiple => 1 ),
				);
				if ( $is_abs ) {
					@paths = map $_->absolute, @paths;
				}
				return \@paths;
			} #/ elsif ( $local_multiple and...)
			
			elsif ( $is_path ) {
				require Path::Tiny;
				my $path = 'Path::Tiny'->new(
					$ask->file_selection( @common, directory => $is_dir, multiple => 0 ),
				);
				return $is_abs ? $path->absolute : $path;
			}
			
			elsif ( $is_bool ) {
				return $ask->question( @common, ok_label => 'TRUE', cancel_label => 'FALSE' );
			}
			
			elsif ( $local_multiple ) {
				my @strings;
				STRING: while ( 1 ) {
					chomp( my $str = $ask->entry( @common ) );
					if ( length $str ) {
						push @strings, $str;
					}
					else {
						last STRING;
					}
					return if @strings >= 100;
				} #/ STRING: while ( 1 )
				return \@strings;
			} #/ elsif ( $local_multiple )
			
			else {
				chomp( my $str = $ask->entry( @common ) );
				return $str;
			}
			
		};    # sub $get_answer
		
		my $answer;
		my $tries = 0;
		TRY: while ( !defined $answer ) {
		
			$answer = $get_answer->();
			++$tries;
			
			if ( blessed $local_type ) {
				my $okay = $local_type->check( $answer );
				
				if ( !$okay
					and $local_type->can( 'has_coercion' )
					and $local_type->has_coercion )
				{
					$answer = $local_type->coerce( $answer );
					$okay   = $local_type->check( $answer );
				}
				
				if ( not $okay ) {
					$ask->error( text => $local_type->get_message( $answer ) );
					$answer = undef;
				}
			} #/ if ( blessed $local_type)
			
			elsif ( ref $local_type ) {
				local $@;
				my $okay = eval { $local_type->( $answer ); 1 };
				if ( not $okay ) {
					$ask->error( text => $@ );
					$answer = undef;
				}
			}
			
			if ( $tries >= 3 and not defined $answer ) {
				$ask->error( text => 'Too many retries!' );
				last TRY;
			}
		} #/ TRY: while ( !defined $answer )
		
		return $answer if defined $answer;
		return $local_default;
	};    # built sub
} #/ sub _build_coderef

1;

__END__

=head1 NAME

Ask::Question - an object overloading coderefification to call Ask

=head1 SYNOPSIS

  use Ask::Question;
  use Types::Standard qw( ArrayRef Int );
  
  my $question = Ask::Question->new(
    text    => 'Enter numbers',
    type    => ArrayRef[Int],
    default => sub { [0..9] },
  );
  
  my $arrayref_of_numbers = $question->();
  my $more_numbers        = $question->ask();  # alternative way to call

These overloaded objects work nicely as L<Moose> and L<Moo> defaults:

  package Foo {
    use Moo;
    use Ask;
    
    has numbers => (
      is       => 'lazy',
      type     => ArrayRef[Int],
      default  => Ask::Q(
        text     => 'Enter numbers',
        type     => ArrayRef[Int],
        default  => sub { [0..9] },
      ),
    );
  }

Note C<< Ask::Q(...) >> is a shortcut for C<< Ask::Question->new(...) >>.

=head1 DESCRIPTION

L<Ask::Question> provides an alternative approach to using Ask to request
information from a user.

L<Ask::Question> provides a fairly standard Moose-like constructor taking
a hash of attributes. There's also a shortcut for it in the L<Ask> package.
If there are an odd number of arguments passed to the constructor, it is
assumed the first one if the C<text> attribute.

  my $question  = Ask::Question->new( $text, %attributes );
  my $question  = Ask::Question->new(        %attributes );
  my $question  = Ask::Question->new(       \%attributes );
  my $question  = Ask::Q( $text, %attributes );
  my $question  = Ask::Q(        %attributes );
  my $question  = Ask::Q(       \%attributes );

=head2 Attributes

=over

=item C<< text >> I<< Str|CodeRef >>

The text of the question. If a coderef is given, that coderef will be
forwarded any of the arguments to C<< $question->(...) >>.

=item C<< backend >> I<< Object >>

A blessed object implementing L<Ask::API>. Defaults to the result of
C<< Ask->detect >>.

=item C<< title >> I<< Str >>

A title to use for question prompts, used by certain Ask backends.

=item C<< type >> I<< TypeTiny >>

A type constraint to check answers against. If the answer provided by the
user fails a type check (after coercion, if the type has a coercion), they
will be prompted to answer again.

=item C<< spec >> I<< HashRef >>

If this Ask::Question is being used as the default for an attrbute spec,
this can be used to hold the specification hash for the attribute, and
Ask::Question will attempt to find missing information like C<type> from
the spec hash.

=item C<< multiple >> I<< Bool >>

Indicates that you want to return an arrayref of answers. If C<type> is a
subtype of B<< ArrayRef >>, this will be inferred.

=item C<< choices >> I<< ArrayRef[Str] >>

List of valid choices if the question has a list of valid answers.

  my $question = Ask::Question->new(
    "What size t-shirt would you like?",
    choices => [qw( XS S M L XL XXL )],
  );

If C<type> is a parameterize B<< Enum >> or B<< ArrayRef[Enum] >>, then
this will be automatic.

=item C<< coderef >> I<< CodeRef >>

Generating this coderef is the entire point of Ask::Question. You cannot
provide this to the constructor.

=item C<< default >> I<< CodeRef|~Ref >>

A fallback to use if no interaction with the user is possible.

=item C<< method >> I<< Str >>

The method name to call on the backend, such as C<question> or C<entry>.
See L<Ask::API>. Generally speaking, Ask::Question will figure this out
by itself.

=back

=head2 Methods

=over

=item C<< ask() >>

C<< $question->ask(...) >> is a shortcut for C<< $question->coderef->(...) >>.

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Ask>.

=head1 SEE ALSO

L<Ask>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2020 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
