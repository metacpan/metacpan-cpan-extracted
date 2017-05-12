use 5.008;
use strict;
use warnings;

package Data::Conveyor::Monitor;
BEGIN {
  $Data::Conveyor::Monitor::VERSION = '1.103130';
}

# ABSTRACT: Stage-based conveyor-belt-like ticket handling system
use parent 'Class::Scaffold::Storable';

sub sort_by_stage_order {
    my ($self, @activity) = @_;
    my %stage_order;
    my $order = 1;
    $stage_order{$_} = sprintf "%02d" => $order++
      for map { "$_" }
      map {
        $self->delegate->make_obj('value_ticket_stage')->new_start($_),
          $self->delegate->make_obj('value_ticket_stage')->new_active($_),
          $self->delegate->make_obj('value_ticket_stage')->new_end($_),
      } $self->delegate->STAGE_ORDER;
    my @sorted =
      map  { $_->[0] }
      sort { $a->[1] cmp $b->[1] }
      map {
        [ $_, ($stage_order{ $_->{stage} } || '00') . ($_->{status} || ' ') ]
      } @activity;
    wantarray ? @sorted : \@sorted;
}

sub sif_top {
    my ($self, %opt) = @_;
    my $result = $self->delegate->make_obj('service_result_container');
    my @activity =
        $opt{all}
      ? $self->get_activity
      : $self->get_activity_running;
    $result->result_push(
        $self->delegate->make_obj('service_result_tabular')->set_from_rows(
            fields => [qw/count stage status rc oticket ochanged/],
            rows   => [ $self->sort_by_stage_order(@activity) ],
        )
    );
    $result->result_push(
        $self->delegate->make_obj(
            'service_result_scalar',
            result =>
              sprintf("%d open regtransfers\n", $self->count_open_regtransfers)
        )
    );
    $result;
}

sub get_activity {
    my $self = shift;
    $self->storage->get_activity;
}

sub get_activity_running {
    my $self = shift;
    $self->storage->get_activity_running;
}

sub count_open_regtransfers {
    my $self = shift;
    $self->storage->count_open_regtransfers;
}
1;


__END__
=pod

=head1 NAME

Data::Conveyor::Monitor - Stage-based conveyor-belt-like ticket handling system

=head1 VERSION

version 1.103130

=head1 METHODS

=head2 sif_top

FIXME

=head2 sort_by_stage_order

FIXME

=head2 count_open_regtransfers

FIXME

=head2 get_activity

FIXME

=head2 get_activity_running

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

