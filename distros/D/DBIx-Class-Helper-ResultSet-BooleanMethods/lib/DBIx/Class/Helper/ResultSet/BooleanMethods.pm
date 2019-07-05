package DBIx::Class::Helper::ResultSet::BooleanMethods;

use 5.008;
use utf8;
use strictures 2;

our $VERSION = '0.03';

=head1 NAME

DBIx::Class::Helper::ResultSet::BooleanMethods - Automatically create search methods for boolean columns.

=head1 VERSION

Version 0.03

=cut

use Package::Variant 'importing' => ['Moo::Role'];

sub make_variant {
	my ($class, $target_package, $resultset) = @_;

	my $result = $resultset;
	$result =~ s/::ResultSet::/::Result::/oms;

	my $columns_info = $result->result_source_instance->columns_info;

	$resultset->load_components('Helper::ResultSet::Me');

	for my $method (keys %{$columns_info}) {
		my $detail = $columns_info->{$method};

		if ('boolean' ne $detail->{'data_type'}) {
			next;
		}

		install "${method}" => sub {
			my $self = shift;

			return $self->search(
				{
					$self->me($method) => 'true'
				}
			);
		};

		install "not_${method}" => sub {
			my $self = shift;

			return $self->search(
				{
					$self->me($method) => 'false'
				}
			);
		};
	}

	return;
}

=head1 SYNOPSIS

This module automatically creates search method helpers for boolean columns.

In your ResultSet class, add:

    use Role::Tiny::With qw(with);
    use DBIx::Class::Helper::ResultSet::BooleanMethods;

    with(BooleanMethods(__PACKAGE__));

=head1 METHODS

Say your table has a boolean column named "paid", using this role will act as if you added these methods:

    sub paid {
    	my $self = shift;
    
    	return $self->search(
    		{
    			'paid' => 'true',
    		}
    	);
    };
    
    sub not_paid {
    	my $self = shift;
    
    	return $self->search(
    		{
    			'not_paid' => 'false',
    		}
    	);
    };

=head1 AUTHOR

Mathieu Arnold, C<< <mat at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dbix-class-helper-resultset-booleanmethods at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=DBIx-Class-Helper-ResultSet-BooleanMethods>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DBIx::Class::Helper::ResultSet::BooleanMethods

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=DBIx-Class-Helper-ResultSet-BooleanMethods>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DBIx-Class-Helper-ResultSet-BooleanMethods>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/DBIx-Class-Helper-ResultSet-BooleanMethods>

=item * Search CPAN

L<https://metacpan.org/release/DBIx-Class-Helper-ResultSet-BooleanMethods>

=back


=head1 ACKNOWLEDGEMENTS

Thanks to the people of #dbix-class, they were very helpful in pointing me to the right direction.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2019 by Mathieu Arnold.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1;
