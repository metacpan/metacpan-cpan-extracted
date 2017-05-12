package Class::Business::DK::FI;

use strict;
use warnings;
use Class::InsideOut qw( private register id );
use Carp qw(croak);
use English qw(-no_match_vars);
use Try::Tiny;

use Business::DK::FI qw(validateFI);

our $VERSION = '0.09';

private number => my %number;    # read-only accessor: number()

sub new {
    my ( $class, $number ) = @_;

    ## no critic (Variables::ProhibitUnusedVariables)
    my $self = \( my $scalar );

    bless $self, $class;

    register($self);

    if ($number) {
        $self->set_number($number);
    }
    else {
        croak 'You must provide a FI number';
    }

    return $self;
}

## no critic (Subroutines::RequireFinalReturn)
sub number { $number{ id $_[0] } }

sub get_number { $number{ id $_[0] } }

sub set_number {
    my ( $self, $unvalidated_fi ) = @_;

    my $rv = 0;

    if ($unvalidated_fi) {

        try {
            $rv = validateFI($unvalidated_fi);

            if ( $rv == 0 ) {
                croak;
            }
        }
        catch {
            croak 'Invalid FI number parameter';
        };

        $number{ id $self } = $unvalidated_fi;

        return $rv;

    }
    else {
        croak 'You must provide a FI number';
    }
}

1;

__END__

=head1 NAME

Class::Business::DK::FI - class for Danish FI numbers

=head1 VERSION

The documentation describes version 0.09

=head1 SYNOPSIS

    use Class::Business::DK::FI;

    my $FI = Class::Business::DK::FI->new('026840149965328');


    #accessors
    my $fi_number = $FI->number();

    my $fi_number = $FI->get_number();

    #mutators
    my $fi_number = $FI->number('026840149965328')
        or die "Unable to set number\n";

    my $fi_number = $FI->get_number('026840149965328')
        or die "Unable to set number\n";

=head1 DESCRIPTION

This is an OOP implementation for handling FI numbers. The class gives you an FI number object, which is validated according to the FI specification, see: L<Business::DK::FI>.

=head1 SUBROUTINES AND METHODS

=head2 new

Constructor, takes a single parameter a valid FI number, object construction
is only successful if the number is valid.

If the provided number is invalid, the construction attempt results in a C<die>.

=head2 number

Accessor to get the FI number for a given Class::Business::DK::FI object, see also: L</get_number>.

=head2 get_number

Accessor to get the FI assigned to a FI object.

=head2 set_number

Mutator taking a single argument a 16 digit FI number. The number should be
valid. If not the method dies.

=head1 DIAGNOSTICS

All methods B<die> if their API is not respected. Method calls can with success be wrapped in L<Try::Tiny> or C<eval> blocks.

=over

=item * You must provide a FI number, thrown by L</set_number> and L</new> if
no argument is provided.

=item * Invalid FI number parameter, thrown by L</new> and L</set_number> if
the provided argument is not a valid FI number.

=back

=head1 CONFIGURATION AND ENVIRONMENT

The module requires no special configuration or environment.

=head1 DEPENDENCIES

=over

=item * L<Class::InsideOut>

=item * L<Carp>

=item * L<English>

=item * L<Business::DK::FI>

=back

=head1 INCOMPATIBILITIES

The module has no known incompatibilities.

=head1 BUGS AND LIMITATIONS

This module has no known bugs or limitations.

=head1 TEST AND QUALITY

=head2 TEST COVERAGE

    ---------------------------- ------ ------ ------ ------ ------ ------ ------
    File                           stmt   bran   cond    sub    pod   time  total
    ---------------------------- ------ ------ ------ ------ ------ ------ ------
    blib/lib/Business/DK/FI.pm    100.0  100.0    n/a  100.0  100.0   35.1  100.0
    ...b/Class/Business/DK/FI.pm  100.0  100.0   66.7  100.0  100.0   64.9   98.4
    Total                         100.0  100.0   66.7  100.0  100.0  100.0   99.3
    ---------------------------- ------ ------ ------ ------ ------ ------ ------

=head1 QUALITY AND CODING STANDARD

The code passes L<Perl::Critic> tests at severity 1 (I<brutal>) with a set of policies disabled. please see F<t/perlcriticrc> and the list below:

=over

=item * L<Perl::Critic::Policy::Variables::ProhibitUnusedVariables>, required due to L<Class::InsideOut> implementation

=item * L<Perl::Critic::Policy::Subroutines::RequireFinalReturn>, implementation is kept compact so some C<return> statements have been left out

=back

=head1 BUG REPORTING

Please report issues via CPAN RT:

=over

=item * L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Business-DK-FI>

=back

or by sending mail to

=over

=item * C<< <bug-Business-DK-FI@rt.cpan.org> >>

=back

=head1 TODO

Please see the distribution F<TODO> file also and the distribution road map at:
    L<http://logiclab.jira.com/browse/BDKFI#selectedTab=com.atlassian.jira.plugin.system.project%3Aroadmap-panel>

=head1 SEE ALSO

=over

=item * L<Try::Tiny>

=item * L<Business::DK::CVR>

=item * L<Business::DK::CPR>

=item * L<Business::DK::PO>

=item * L<Business::DK::Postalcode>

=item * L<Business::DK::Phonenumber>

=back

=head1 AUTHOR

Jonas B. Nielsen, (jonasbn) - C<< <jonasbn@cpan.org> >>

=head1 COPYRIGHT

Business-DK-FI and related is (C) by Jonas B. Nielsen, (jonasbn) 2009-2016

=head1 LICENSE

Business-DK-FI and related is released under the Artistic License 2.0

See the included license file for details

=cut
