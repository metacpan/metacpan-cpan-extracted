package Array::Objectify;

use 5.006;
use strict;
use warnings;
our $VERSION = '0.03';
use Array::Objectify::Tie;

use overload '@{}' => sub { ${$_[0]}->{array}; }, fallback => 1;
 
sub new {
        my ($class, @params) = @_;
 
        my $self = \{
                array => [],
        };
 
        tie @{${$self}->{array}}, 'Array::Objectify::Tie', @params;
 
        bless $self, $class;
}

1;

__END__

=head1 NAME

Array::Objectify - objectify an array

=head1 VERSION

Version 0.03

=cut

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

	use Array::Objectify;

	my $array = Array::Objectify->new(
		'abc', 
		{ 
			a => 1, 
			b => 2, 
			c => 3 
		}, 
		[ 
			{ 
				a => 1 
			}, 
			{
				b => 2
			}, 
			{
				c => 3
			} 
		]
	);

	$array->[0] # 'abc';
	$array->[1]->a; # 1
	$array->[2]->[1]->b; # 2;
	
	scalar @{$array}; # 3;
	push @{$array}, { d => 1 };
	$array->[3]->d # 1;

	...
	
	use Array::Objectify::Tie;

	tie my @array, 'Array::Objectify::Tie', 'abc', { a => 1, b => 2, c => 3}, [ { a => 1 }, { b => 2 }, { c => 3 } ];

	$array[0] # 'abc';
	$array[1]->a; # 1
	$array[2]->[1]->b; # 2;
	
	scalar @array; # 3;
	push @array, { d => 1 };
	$array->[3]->d # 1;


=head1 Methods

=cut

=head2 new

Instantiate a new Array::Objectify object which is a wrapper arround Array::Objectify::Tie.

	Array::Objectify->new(...);

=cut

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-array-objectify at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Array-Objectify>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Array::Objectify


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Array-Objectify>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Array-Objectify>

=item * Search CPAN

L<https://metacpan.org/release/Array-Objectify>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2021 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Array::Objectify
