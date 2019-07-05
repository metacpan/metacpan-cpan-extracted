package DBIx::Class::Helper::ResultSet::EnumMethods;

use 5.008;
use utf8;
use strictures 2;

=head1 NAME

DBIx::Class::Helper::ResultSet::EnumMethods - Automatically create search methods for enum columns.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

# Le 'install' => 1 est pour Subroutines::ProhibitCallsToUndeclaredSubs.
use Package::Variant 'install' => 1, 'importing' => ['Moo::Role'];

sub make_variant {
	my ($class, $target_package, $resultset) = @_;

	my $result = $resultset;
	$result =~ s/::ResultSet::/::Result::/oms;

	my $columns_info = $result->result_source_instance->columns_info;

	for my $method (keys %{$columns_info}) {
		my $detail = $columns_info->{$method};

		if ('enum' ne $detail->{'data_type'} && $detail->{'extra'}{'list'}) {
			next;
		}

		for my $v (@{ $detail->{'extra'}{'list'} }) {

			install "${method}_${v}" => sub {
				my $self = shift;

				return $self->search(
					{
						$self->me($method) => $v
					}
				);
			};

			install "${method}_not_${v}" => sub {
				my $self = shift;

				return $self->search(
					{
						$self->me($method) => {
							q{!=} => $v,
						}
					}
				);
			};
		}
	}

	return;
}

=head1 SYNOPSIS

This module automatically creates search method helpers for enum columns.

In your ResultSet class, add:

    use Role::Tiny::With qw(with);
    use DBIx::Class::Helper::ResultSet::EnumMethods;

    with(EnumMethods(__PACKAGE__));

=head1 METHODS

Say your table has an enum column "payment_type", and the possible values for
the enum are "cash", "check", and "card", using this role will act as if you
added these methods:

    sub payment_type_cash {
        return shift->search( {
	    $self->me('payment_type') => 'cash'
	});
    };
    
    sub payment_type_not_cash {
        return shift->search( {
	    $self->me('payment_type') => {
		q{!=} => 'cash',
	    }
	});
    };
    
    sub payment_type_check {
        return shift->search( {
	    $self->me('payment_type') => 'check'
	});
    };
    
    sub payment_type_not_check {
        return shift->search( {
	    $self->me('payment_type') => {
		q{!=} => 'check',
	    }
	});
    };
    
    sub payment_type_card {
        return shift->search( {
	    $self->me('payment_type') => 'card'
	});
    };
    
    sub payment_type_not_card {
        return shift->search( {
	    $self->me('payment_type') => {
		q{!=} => 'card',
	    }
	});
    };

=head1 AUTHOR

Mathieu Arnold, C<< <mat at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dbix-class-helper-resultset-enummethods at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=DBIx-Class-Helper-ResultSet-EnumMethods>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DBIx::Class::Helper::ResultSet::EnumMethods


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=DBIx-Class-Helper-ResultSet-EnumMethods>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/DBIx-Class-Helper-ResultSet-EnumMethods>

=item * Search CPAN

L<https://metacpan.org/release/DBIx-Class-Helper-ResultSet-EnumMethods>

=back


=head1 ACKNOWLEDGEMENTS

People on #dbix-class for the original idea.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2019 by Mathieu Arnold.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1;
