package Brick::Constraints;
use base qw(Exporter);
use vars qw($VERSION);

$VERSION = '0.227';

package Brick::Bucket;
use strict;

use subs qw();

use Carp qw(croak carp);

=encoding utf8

=head1 NAME

Brick::Constraints - Connect the input data to the closures in the pool

=head1 SYNOPSIS

	use Brick;

=head1 DESCRIPTION

=over 4

=item __make_constraint( CODEREF, INPUT_HASH_REF )

Turn a closure into a constraint by providing the bridge between the
input hash and code reference.

Call this in your top level generator after you have composed all the
pieces you want.

=cut

sub __make_constraint # may need to change name to make generic
	{
	my( $bucket, $validator, $setup ) = @_;

	$setup ||= {};

	my @callers = $bucket->__caller_chain_as_list();

	#print STDERR Data::Dumper->Dump( [\@callers], [qw(callers)] ); use Data::Dumper;

	if( $#callers >= 1 and exists $callers[1]{'sub'} and  $callers[1]{'sub'} =~ m/^_/ )
		{
		carp "$callers[1]{'sub'} called from sub with leading underscore. Are you sure you want that?";
		}

	my $name = $setup->{name} || $callers[1]{'sub'} || 'Anonymous';
	print STDERR "Constraint name is $name\n" if $ENV{DEBUG};

	unless(
		eval { $validator->isa( ref sub {} ) }    ||
		UNIVERSAL::isa( $validator, ref sub {} )
		)
		{
		croak( "Argument to $callers[1]{'sub'} must be a code reference [$validator]: $@" );
		}

	my $constraint = $bucket->add_to_bucket( {
		name        => $name,
		description => "Brick constraint sub for $name",

		code        => sub {
			my $input_hash = shift;

			my $result = eval{ $validator->( $input_hash ) };
			die if $@;

			return 1;
			},
		} );

	$bucket->comprise( $constraint, $validator );

    return $constraint;
	}


=item __make_dfv_constraint

Adapter for Data::FormValidator

=cut

=pod

sub __make_dfv_constraint # may need to change name to make generic
	{
    my( $bucket, $validator, $hash ) = @_;

	$hash ||= {};

 	my @callers = main::__caller_chain_as_list();

	my $name = $hash->{profile_name} || $callers[-1]{'sub'} || 'Anonymous';

 	unless(
 		eval { $validator->isa( ref sub {} ) }    or
 		UNIVERSAL::isa( $validator, ref sub {} )
 		)
    	{
    	carp( "Argument to $callers[1]{'sub'} must be a code reference [$validator]: $@" );
    	return $bucket->add_to_bucket( { code => sub {}, name => "Null subroutine",
    		description => "This sub does nothing, because something didn't happen correctly."
    		} );
		}

    my $constraint = $bucket->add_to_bucket( {
    	name        => $name,
    	description => "Data::FormValidator constraint sub for $callers[-1]{'sub'}",

    	code        => sub {
			my( $dfv ) = @_;

			$dfv->name_this( $callers[-1]{'sub'} );
			my( $field, $value ) = map {
				$dfv->${\ "get_current_constraint_$_"}
				} qw(field value);

			my $hash_ref = $dfv->get_filtered_data;

			return unless $validator->( $hash_ref );

			return $field;
			},
		} );

    $bucket->comprise( $constraint, $validator );

    return $constraint;
	}

=back

=head1 TO DO

TBA

=head1 SEE ALSO

TBA

=head1 SOURCE AVAILABILITY

This source is in Github:

	https://github.com/briandfoy/brick

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT

Copyright (c) 2007-2014, brian d foy, All Rights Reserved.

You may redistribute this under the same terms as Perl itself.

=cut

1;
