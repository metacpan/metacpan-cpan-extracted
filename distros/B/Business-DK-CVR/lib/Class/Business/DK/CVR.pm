package Class::Business::DK::CVR;

use strict;
use warnings;
use Class::InsideOut qw( private register id );
use Carp qw(croak);
use English qw(-no_match_vars);

use Business::DK::CVR qw(validate);

our $VERSION = '0.12';

private number => my %number;    # read-only accessor: number()

sub new {
    my ( $class, $number ) = @_;

    my $self = {};

    bless $self, $class;

    register($self);

    if ($number) {
        $self->set_number($number);
    } else {
        croak 'You must provide a CVR number';
    }

    return $self;
}

sub number { my $self = shift; return $number{ id $self } }

sub get_number { my $self = shift; return $number{ id $self } }

sub set_number {
    my ( $self, $unvalidated_cvr ) = @_;

    my $rv;

    if ($unvalidated_cvr) {
        eval { $rv = validate($unvalidated_cvr); 1; } or 0;

        if ( $EVAL_ERROR or not $rv ) {
            croak 'Invalid CVR number parameter';

        } else {
            $number{ id $self } = $unvalidated_cvr;
            return 1;

        }
    } else {
        croak 'You must provide a CVR number';
    }
}

1;

__END__

=pod

=head1 NAME

Class::Business::DK::CVR - Danish CVR number class

=head1 VERSION

The documentation describes version 0.12 of Class::Business::DK::CVR

=head1 SYNOPSIS

    use Class::Business::DK::CVR;

    my $cvr = Class::Business::DK::CVR->new(27355021);

    my $cvr_no = $cvr->get_number();

    my $cvr_no = $cvr->number();

    $cvr->set_number(27355021);

=head1 DESCRIPTION

This is an OOP implementation for handling Danish CVR numbers. The class gives
you an CVR object, which is validated according to the CVR rules, see:
L<Business::DK::CVR>.

=head1 SUBROUTINES AND METHODS

=head2 new

This is the constructor, it takes a single mandatory parameter, which should be
a valid CVR number, if the parameter provided is not valid, the constructor
dies.

=head2 get_number

This method/accessor returns the CVR number associated with the object.

=head2 number

Alias for the L</get_number> accessor, see above.

=head2 set_number

This method/mutator sets the a CVR number for a given CVR object, it takes a
single mandatory parameter, which should be a valid CVR number, returns true (1)
upon success else it dies.

=head1 DIAGNOSTICS

=over

=item * You must provide a CVR number, thrown by L</set_number> and L</new> if
no argument is provided.

=item * Invalid CVR number parameter, thrown by L</new> and L</set_number> if
the provided argument is not a valid CVR number.

=back

=head1 CONFIGURATION AND ENVIRONMENT

The module requires no special configuration or environment to run.

=head1 DEPENDENCIES

=over

=item * L<Class::InsideOut>

=item * L<Business::DK::CVR>

=back

=head1 INCOMPATIBILITIES

The module has no known incompatibilities.

=head1 BUGS AND LIMITATIONS

The module has no known bugs or limitations

=head1 TEST AND QUALITY

Coverage of the test suite is at 98.3%

=head1 TODO

=over

=item * Please refer to the TODO file

=back

=head1 SEE ALSO

=over

=item * L<Business::DK::CVR>

=back

=head1 BUG REPORTING

Please report issues via CPAN RT:

  http://rt.cpan.org/NoAuth/Bugs.html?Dist=Business-DK-CVR

or by sending mail to

  bug-Business-DK-CVR@rt.cpan.org

=head1 AUTHOR

Jonas B. Nielsen, (jonasbn) - C<< <jonasbn@cpan.org> >>

=head1 COPYRIGHT

Business-DK-CVR and related is (C) by Jonas B., (jonasbn) 2006-2020

=head1 LICENSE

Business-DK-CVR and related is released under the Artistic License 2.0

=cut
