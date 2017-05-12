use 5.008;
use strict;
use warnings;

package Data::Conveyor::Value::Ticket::Status;
BEGIN {
  $Data::Conveyor::Value::Ticket::Status::VERSION = '1.103130';
}
# ABSTRACT: Stage-based conveyor-belt-like ticket handling system
use parent 'Data::Conveyor::Value::Enum';
sub get_valid_values_list { our $cache_values ||= $_[0]->delegate->TS }

sub send_notify_value_invalid {
    my ($self, $value) = @_;
    local $Error::Depth = $Error::Depth + 2;
    $self->exception_container->record(
        'Data::Conveyor::Exception::Ticket::NoSuchStatus',
        status => $value,);
}

# Apply a new status to the value object's existing status. When called by the
# payload methods this method makes sure that the resulting status is the
# worst of all exception's associated status's. That is, if there are only
# exceptions with
#
# The status is encoded as a character, but we can map each status to a
# numeric value and perform the same operation as in apply_rc(). The following
# op table holds:
#
# Again we use an op table. Here, 'RUN' stands for 'TS_RUNNING', 'HOLD' for
# 'TS_HOLD', and 'ERR' for 'TS_ERROR'. TS_PENDING is like TS_HOLD. We haven't
# decided yet what to do if a ticket has both a TS_HOLD and a TS_PENDING
# exception because we don't really use TS_HOLD anymore.
#
#    rhs |
# lhs    |  RUN   HOLD    ERR
# -------+----------------------------
# RUN    |  RUN   HOLD    ERR
# HOLD   | HOLD   HOLD    ERR
# ERR    |  ERR    ERR    ERR
sub add {
    my ($status1, $status2) = @_;
    $status1 > $status2 ? $status1 : $status2;
}

sub num_cmp {
    my ($status1, $status2) = @_;
    my $delegate          = Data::Conveyor::Environment->getenv;
    my $get_status_number = sub {
        return 0 if $_[0] eq $delegate->TS_RUNNING;
        return 1 if $_[0] eq $delegate->TS_HOLD;
        return 1 if $_[0] eq $delegate->TS_PENDING;
        return 2 if $_[0] eq $delegate->TS_ERROR;
        return 0;
    };
    $get_status_number->($status1) <=> $get_status_number->($status2);
}
1;


__END__
=pod

=head1 NAME

Data::Conveyor::Value::Ticket::Status - Stage-based conveyor-belt-like ticket handling system

=head1 VERSION

version 1.103130

=head1 METHODS

=head2 add

FIXME

=head2 get_valid_values_list

FIXME

=head2 num_cmp

FIXME

=head2 send_notify_value_invalid

FIXME

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Data-Conveyor>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<http://search.cpan.org/dist/Data-Conveyor/>.

The development version lives at L<http://github.com/hanekomu/Data-Conveyor>
and may be cloned from L<git://github.com/hanekomu/Data-Conveyor>.
Instead of sending patches, please fork this project using the standard
git and github infrastructure.

=head1 AUTHORS

=over 4

=item *

Marcel Gruenauer <marcel@cpan.org>

=item *

Florian Helmberger <fh@univie.ac.at>

=item *

Achim Adam <ac@univie.ac.at>

=item *

Mark Hofstetter <mh@univie.ac.at>

=item *

Heinz Ekker <ek@univie.ac.at>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

