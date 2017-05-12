package CPANTS::Kwalitee::Report::Indicator;

$CPANTS::Kwalitee::Report::Indicator::VERSION   = '0.07';
$CPANTS::Kwalitee::Report::Indicator::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

CPANTS::Kwalitee::Report::Indicator - Interface to Kwalitee Indicator.

=head1 VERSION

Version 0.07

=cut

use 5.006;
use Data::Dumper;
use List::Util qw(any);

use Moo;
use namespace::clean;

use overload q{""} => 'as_string', fallback => 1;

has 'name'    => (is => 'ro', required => 1);
has 'types'   => (is => 'ro');
has 'error'   => (is => 'ro');
has 'remedy'  => (is => 'ro');
has 'verbose' => (is => 'rw', default => sub { 0 });

=head1 DESCRIPTION

It represents Kwalitee Indicator.

=head1 SYNOPSIS

    use strict; use warnings;
    use CPANTS::Kwalitee::Report;

    my $report     = CPANTS::Kwalitee::Report->new;
    my $generators = $report->generators;
    my $indicators = $generators->[0]->indicators;

    print sprintf("Name       : %s\n", $indicators->[0]->name);
    print sprintf("Description: %s\n", $indicators->[0]->description);

=head1 METHODS

=head2 name()

Returns indicator name.

=head2 description()

Returns indicator name with types.

=cut

sub description {
    my ($self) = @_;

    my $types = $self->types;
    if (scalar(@$types)) {
        return sprintf("%s (%s)", $self->name, join(", ", @$types));
    }
    else {
        return $self->name;
    }
}

=head2 category()

Returns the indicator's category i.e core, optional or experimental.

=cut

sub category {
    my ($self) = @_;

    if ($self->is_optional) {
        return 'optional';
    }
    elsif ($self->is_experimental) {
        return 'experimental';
    }
    else {
        return 'core';
    }
}

=head2 is_core()

Returns true/false depending if the indicator is core.

=cut

sub is_core {
    my ($self) = @_;

    return (!$self->is_optional && !$self->is_experimental);
}

=head2 is_optional()

Returns true/false depending if the indicator is optional.

=cut

sub is_optional {
    my ($self) = @_;

    return any { /is_extra/ } @{$self->types};
}

=head2 is_experimental()

Returns true/false depending if the indicator is experimental.

=cut

sub is_experimental {
    my ($self) = @_;

    return any { /is_experimental/ } @{$self->types};
}

=head2 types()

Returns an array ref of indiator types like below:

=over 4

=item * is_extra

=item * is_experimental

=item * needs_db

=back

=head2 error()

Returns indicator error string.

=head2 remedy()

Returns indicator error remedy.

=cut

sub as_string {
    my ($self) = @_;

    my $description = $self->description;
    my $error       = $self->error  || 'N/A';
    my $remedy      = $self->remedy || 'N/A';
    my $verbose     = $self->verbose;

    if ($verbose) {
        if (defined $error && defined $remedy) {
            return sprintf("%s\n  error: %s\n  remedy: %s", $description, $error, $remedy);
        }
        else {
            if (defined $error) {
                return sprintf("%s\n  error: %s", $description, $error);
            }
            elsif (defined $remedy) {
                return sprintf("%s\n  remedy: %s", $description, $remedy);
            }
        }
    }
    else {
        return $description;
    }
}

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/CPANTS-Kwalitee-Report>

=head1 BUGS

Please report any bugs or feature requests to C<bug-cpants-kwalitee-report at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CPANTS-Kwalitee-Report>.
I will  be notified and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CPANTS::Kwalitee::Report::Indicator

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=CPANTS-Kwalitee-Report>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/CPANTS-Kwalitee-Report>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/CPANTS-Kwalitee-Report>

=item * Search CPAN

L<http://search.cpan.org/dist/CPANTS-Kwalitee-Report/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2017 Mohammad S Anwar.

This program  is  free software; you can redistribute it and / or modify it under
the  terms  of the the Artistic License (2.0). You may obtain  a copy of the full
license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any  use,  modification, and distribution of the Standard or Modified Versions is
governed by this Artistic License.By using, modifying or distributing the Package,
you accept this license. Do not use, modify, or distribute the Package, if you do
not accept this license.

If your Modified Version has been derived from a Modified Version made by someone
other than you,you are nevertheless required to ensure that your Modified Version
 complies with the requirements of this license.

This  license  does  not grant you the right to use any trademark,  service mark,
tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge patent license
to make,  have made, use,  offer to sell, sell, import and otherwise transfer the
Package with respect to any patent claims licensable by the Copyright Holder that
are  necessarily  infringed  by  the  Package. If you institute patent litigation
(including  a  cross-claim  or  counterclaim) against any party alleging that the
Package constitutes direct or contributory patent infringement,then this Artistic
License to you shall terminate on the date that such litigation is filed.

Disclaimer  of  Warranty:  THE  PACKAGE  IS  PROVIDED BY THE COPYRIGHT HOLDER AND
CONTRIBUTORS  "AS IS'  AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED
WARRANTIES    OF   MERCHANTABILITY,   FITNESS   FOR   A   PARTICULAR  PURPOSE, OR
NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW. UNLESS
REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL,  OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE
OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of CPANTS::Kwalitee::Report::Indicator
