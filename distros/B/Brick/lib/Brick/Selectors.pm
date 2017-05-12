package Brick::Selectors;
use strict;

use base qw(Exporter);
use vars qw($VERSION);

$VERSION = '0.227';

package Brick::Bucket;
use strict;

=encoding utf8

=head1 NAME

Brick::Selectors - Connect the input data to the closures in the pool

=head1 SYNOPSIS

	use Brick::Selectors;

=head1 DESCRIPTION

Selectors test a condition, but they don't fail if the test doesn't
work. Instead of die-ing, they return C<0>. Composers can
use selectors to decide if they want to continue with the rest of the
composition or simply skip it and try something else. This requires
something like C<Brick::Composers::__compose_pass_or_skip> or
C<Brick::Composers::__compose_pass_or_stop> that are designed to
handle selectors.

The basic use goes like this. I'll make up the completely fake situation
where I have to validate a number from user input. If it's odd, It has
to be greater than 11 and prime. If it's even, it has to be less than
20 and it has to be a tuesday. Here's the tree of decisions:

							some value
                              /    \
                             /      \
                           odd       even
                          /  |       |  \
       _is_prime  -------+   |       |   +----- _is_tueday
                             |       |
                            /         \
                           /           \
                        > 11          < 20


Now, I have to compose subroutines that will do the right thing. The
first step is to decide which side of the tree to process. I'll make
some selectors. These won't die if they don't pass:

	my $even_selector = $bucket->_is_even_number;
	my $odd_selector  = $bucket->_is_even_number;

I put the selectors together with the subroutines that should run if
that selector is true. The selector tells C<__compose_pass_or_stop>
to skip the rest of the subroutines without die-ing. The branch
effectively turns into a null operation.

	my $even_branch = $brick->__compose_pass_or_stop(
		$even_selector,
		$brick->_is_tuesday,
		);

	my $odd_branch  = $brick->__compose_pass_or_stop(
		$odd_selector,
		$brick->_is_prime( { field => 'number_field_name' } ),
		);

I put the branches together, perhaps with C<__compose_pass_or_skip>. When
the first branch runs, if the value isn't even then the selector stops
the subroutine in C<$even_branch> and control skips to C<$odd_branch>.

	my $tester      = $brick->__compose_pass_or_skip(
		$even_branch,
		$odd_branch,
		);

=head2 Sample selectors

=over 4

=item _is_even_number

Returns an anonymous subroutine that returns true it's argument is an
even number, and return the empty list otherwise.

The anonymous subroutine takes a hash reference as an argument and
tests the value with the key C<field>.

=cut

sub _is_even_number
	{
	sub{ $_[0]->{field} % 2 ? 0 : 1 };
	}

=item _is_odd_number

Returns an anonymous subroutine that returns true if it's argument is
odd, and return the empty list otherwise.

The anonymous subroutine takes a hash reference as an argument and
tests the value with the key C<field>.

=cut

sub _is_odd_number
	{
	sub{ $_[0]->{field} % 2 ? 1 : 0 };
	}

=item _is_tuesday

Returns an anonymous subroutine that returns true if the system time
indicates it's Tuesday, and return the empty list otherwise.

=cut

sub _is_tuesday
	{
	sub { (localtime)[6] == 2 ? 1 : 0 };
	}

=back

=head2 Selector factories



=cut

=pod

sub __normalize_var_name
	{
	my $field = shift;

	$field =~ s/\W/_/g;

	return $field;
	}

=over 4

=item __field_has_string_value( FIELD, VALUE )

 =cut

sub __field_has_string_value
	{
	my( $bucket, $setup ) = @_;


	my $sub = sub {
		$_[0]->{ $setup->{field} } == $setup->{value} ? 1 : ();
		};


	$bucket->__field_has_value( $setup, $sub );
	}

=item __field_has_numeric_value( FIELD, VALUE )

 =cut

sub __field_has_numeric_value
	{
	my( $bucket, $setup ) = @_;


	my $sub = sub {
		$_[0]->{ $setup->{field} } == $setup->{value} ? 1 : ();
		};


	$bucket->__field_has_value( $setup, $sub );
	}

sub __field_has_value
	{
	my( $bucket, $setup, $sub ) = @_;

	my $sub_field = __normalize_var_name( $setup->{field} );
	my $sub_value = __normalize_var_name( $setup->{value} );

	my $bucket_class = Brick->bucket_class;

	my $method_name  = "_${sub_field}_is_${sub_value}";


	{
	no strict 'refs';
	*{$method_name} = $sub;
	}


	$bucket->add_to_bucket(
		{
		name        => $method_name,
		description => "Field [$$setup{field}] has value [$$setup{value}]",
		code        => $sub,
		}
		);

	}

=cut

=back

=head1 TO DO

TBA

=head1 SEE ALSO

L<Brick::Composers>

There are selectors in the examples in C<t/use_cases>.

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
