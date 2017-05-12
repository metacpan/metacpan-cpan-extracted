use 5.008;
use strict;
use warnings;

package Data::Conveyor::Storage::Memory;
BEGIN {
  $Data::Conveyor::Storage::Memory::VERSION = '1.103130';
}
# ABSTRACT: Stage-based conveyor-belt-like ticket handling system

use Error::Hierarchy::Util 'assert_defined';
use Class::Scaffold::Exception::Util 'assert_object_type';
use parent qw(
  Data::Storage::Memory
  Data::Conveyor::Storage
);
use constant TRANSITION_TABLE => '';

sub parse_table {
    my ($self, $table) = @_;
    for (split /\n/ => $table) {
        next if /^\s*#/o;
        next if /^\s*$/o;
        s/#.*$//o;
        s/^\s+|\s+$//go;
        my ($from, $rc, $to, $status, $shift) = split /\s+/;
        assert_defined $_, 'syntax error in transition table'
          for ($from, $rc, $to, $status, $shift);
        for my $value ($from, $to) {

            # blow up on garbled input.
            # note: the object knows sh** about valid stage names (?).
            $self->delegate->make_obj('value_ticket_stage')->value($value);
        }
        my $state = sprintf '%s-%s' => $from, $self->delegate->$rc;

        # check supplied status value
        $self->delegate->$status if $status ne '-';
        (our $transition_cache)->{$state} = {
            stage => $to,
            shift => $shift eq 'Y' ? 1 : 0,
            ($status eq '-' ? () : (status => $status)),
        };
    }
}

# This method parses and caches the transition table. This method is called
# from get_next_stage(), so the transition table is built on-demand. It is not
# built during the storage's init() because parse_table() calls
# make_obj('value_ticket_stage'), and if the 'value_ticket_stage' object is
# also handled by the memory storage, it would cause a deep recursion.
sub assert_transition_cache {
    my $self = shift;
    our $transition_cache;
    return if (ref $transition_cache eq 'HASH') && (keys %$transition_cache);
    $self->parse_table($self->TRANSITION_TABLE);
}

sub get_next_stage {
    my ($self, $stage, $rc) = @_;
    assert_object_type $stage, 'value_ticket_stage';
    assert_defined $rc,        'called without return code';
    $self->assert_transition_cache;
    my $state = sprintf '%s-%s' => $stage, $rc;

    # return undef if the transition is not defined.
    return unless (my $target = (our $transition_cache)->{$state});
    return unless $target->{shift};
    [   $self->delegate->make_obj('value_ticket_stage')
          ->value($target->{stage}),
        $target->{status}
    ];
}
1;


__END__
=pod

=head1 NAME

Data::Conveyor::Storage::Memory - Stage-based conveyor-belt-like ticket handling system

=head1 VERSION

version 1.103130

=head1 METHODS

=head2 assert_transition_cache

FIXME

=head2 get_next_stage

FIXME

=head2 parse_table

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

