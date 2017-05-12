use 5.008;
use strict;
use warnings;

package Data::Conveyor::Value::Ticket::RC;
BEGIN {
  $Data::Conveyor::Value::Ticket::RC::VERSION = '1.103130';
}
# ABSTRACT: Stage-based conveyor-belt-like ticket handling system
use parent 'Data::Conveyor::Value::Enum';
sub get_valid_values_list { our $cache_values ||= $_[0]->delegate->RC }

sub send_notify_value_invalid {
    my ($self, $value) = @_;
    local $Error::Depth = $Error::Depth + 2;
    $self->exception_container->record(
        'Data::Conveyor::Exception::Ticket::NoSuchRC',
        rc => $value,);
}

# Apply a new rc to the value object's existing rc. When called by the payload
# methods this method makes sure that the resulting rc is the worst of all
# exception's associated rc's. That is, if there are only exceptions with
# RC_ERROR, the whole ticket will have RC_ERROR as its rc. But if one of those
# exceptions is associated with RC_INTERNAL_ERROR, the whole ticket will have
# RC_INTERNAL_ERROR.
#
# We use an op table for "$ticket_rc * $rc". Here, 'OK' stands for
# 'RC_OK', 'ERR' for 'RC_ERROR' and 'INT' for 'RC_INTERNAL_ERROR'.
#
#    rhs |
# lhs    |  OK    ERR    INT
# -------+---------------------------
# OK     |  OK    ERR    INT
# ERR    | ERR    ERR    INT
# INT    | INT    INT    INT
#
# The following simple code relies on the fact that RC_* are encoded as
# numbers that increase with increasing severity. If that premise doesn't
# hold anymore, we'll probably have to implement a real ops table.
sub add {
    my ($rc1, $rc2) = @_;
    $rc1 > $rc2 ? $rc1 : $rc2;
}

sub num_cmp {
    my ($rc1, $rc2) = @_;
    "$rc1" <=> "$rc2";
}
1;


__END__
=pod

=head1 NAME

Data::Conveyor::Value::Ticket::RC - Stage-based conveyor-belt-like ticket handling system

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

