package Mock::BarValidator;
use base qw(Exporter);

use vars qw( @EXPORT );

@EXPORT = qw( _is_odd _is_even );

sub _is_odd
	{
	my( $bucket, $hash ) = @_;

	$bucket->add_to_bucket( {
		description => "The number is odd",
		args        => [ $hash ],
		fields      => [ $hash->{field} ],
		code        => sub { $_[0] % 2 or die
			{
			message => "$_[0] was not an odd number",
			handler => "_is_odd_number",
			} },
		} );
	}

sub _is_even
	{
	my( $bucket, $hash ) = @_;

	$bucket->add_to_bucket( {
		description => "The number is even",
		args        => [ $hash ],
		fields      => [ $hash->{field} ],
		code        => sub { $_[0] % 2 and die
			{
			message => "$_[0] was not an even number",
			handler => "_is_even_number",
			} },
		} );
	}

1;
