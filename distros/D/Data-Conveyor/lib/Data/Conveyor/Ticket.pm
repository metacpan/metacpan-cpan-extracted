use 5.008;
use strict;
use warnings;

package Data::Conveyor::Ticket;
BEGIN {
  $Data::Conveyor::Ticket::VERSION = '1.103130';
}
# ABSTRACT: Stage-based conveyor-belt-like ticket handling system

use Data::Miscellany 'is_defined';
use Error::Hierarchy;
use Error::Hierarchy::Util qw/assert_defined assert_is_integer assert_getopt/;
use Data::Dumper;    # needed for service method 'data_dump'
use Error ':try';
use Hash::Flatten;
use Class::Value::Exception::NotWellFormedValue;
use parent 'Class::Scaffold::Storable';
__PACKAGE__->mk_abstract_accessors(qw(request_as_string))
  ->mk_framework_object_accessors(
    ticket_payload      => 'payload',
    ticket_facets       => 'facets',
    value_ticket_stage  => 'stage',
    value_ticket_rc     => 'rc',
    value_ticket_status => 'status',
  )->mk_scalar_accessors(qw(ticket_no origin type received_date));
sub key { $_[0]->ticket_no }

sub assert_ticket_no {
    my $self = shift;
    local $Error::Depth = $Error::Depth + 1;
    assert_defined $self->ticket_no, 'called without defined ticket number';
}

sub read {
    my $self = shift;
    $self->assert_ticket_no;
    $self->storage->ticket_read_from_object($self);
}

# generates new ticket
sub gen_ticket_no {
    my $self      = shift;
    my $ticket_no = $self->storage->generate_ticket_no;
    try {
        $self->ticket_no($ticket_no);
    }
    catch Class::Value::Exception::NotWellFormedValue with {
        throw Data::Conveyor::Exception::Ticket::GenFailed(
            ticket_no => $ticket_no);
    };

    # don't return $ticket_no; the value object might have normalized the
    # value
    $self->ticket_no;
}

# opens (sets the stage on 'aktiv_[% stage %]') either given ticket or
# the oldest ticket in given stage. sets $self->ticket_no on success
# or throws Data::Conveyor::Exception::Ticket::NoSuchTicket otherwise.
#
# if a ticket has been opened, it will be read.
#
# NOTE: this method commits (but respects the rollback flag).
#
# accepts one parameter:
#     stage_name [mandatory]
#
# fails if stage isn't given.
sub open {
    my ($self, $stage_name) = @_;
    assert_defined $stage_name, 'called without stage name.';
    my ($new_stage, $ticket_no) =
      $self->storage->ticket_open($stage_name, $self->ticket_no);
    if (is_defined($ticket_no)) {
        $self->stage($new_stage);
        $self->ticket_no($ticket_no);
        $self->read;
        $self->reset_default_rc_and_status;
    } else {
        $self->log->debug('HINT: Does the ticket have all required fields?');
        throw Data::Conveyor::Exception::Ticket::NoSuchTicket(
            ticket_no => $self->ticket_no || 'n/a',
            stage => $stage_name,
        );
    }
}

sub try_open {
    my $self = shift;
    assert_defined $self->$_, sprintf "called without %s argument.", $_
      for qw/ticket_no stage rc status/;
    my $ticket_no = $self->storage->ticket_set_active($self);
    return unless defined $ticket_no && $ticket_no eq $self->ticket_no;
    $self->read;
    $self->reset_default_rc_and_status;
    1;
}

# stores the whole ticket.
sub store {
    my $self = shift;
    $self->assert_ticket_no;
    $self->update_calculated_values;
    $self->storage->ticket_store($self);
    $self->storage->facets_store($self);
}

# Store everything about the ticket. Used by test code when we want to make
# sure everything we specified in the YAML test files gets stored. Here we
# just store the ticket itself; subclasses can add their things.
sub store_full {
    my $self = shift;
    $self->store;
}

# Writes the ticket's stage, status, and rc to the database, and ensures that
# the new stage is the end_* version of the current stage.
sub close {
    my $self = shift;
    $self->assert_ticket_no;
    assert_defined $self->stage,  'called without set stage.';
    assert_defined $self->rc,     'called without set returncode.';
    assert_defined $self->status, 'called without set status.';
    unless ($self->stage->is_active) {
        throw Data::Conveyor::Exception::Ticket::InvalidStage(
            stage => $self->stage,);
    }
    $self->stage->set_end;
    $self->close_basic;
}

# Sets only stage, rc and status.
# Low-level method that can be called instead of close() when you want to set
# the ticket to some other stage, rc and status than close() would mandate.
sub close_basic {
    my $self = shift;
    $self->storage->ticket_close($self);
}

# Does this ticket ignore the given exception?
# Fails if the exception name isn't provided.
sub ignores_exception {
    my ($self, $exception) = @_;

    # we ignore it if it is acknowledged
    if (ref $exception && UNIVERSAL::can($exception, 'acknowledged')) {
        return 1 if $exception->acknowledged;
    }
}

# XXX: could this, along with wrote_billing_lock and other methods, be
# forwarded directly to $self->payload->common->* ?
sub set_log_level {
    my ($self, $log_level) = @_;
    assert_is_integer($log_level);
    $self->payload->common->log_level($log_level);
}

sub get_log_level {
    my $self = shift;
    $self->payload->common->log_level || 1;
}

# shifts a ticket to the next stage.
#
# fails if the ticket_no isn't defined.
sub shift_stage {
    my $self = shift;
    $self->assert_ticket_no;

    # Can't shift to an undefined stage -> do nothing in this case. Could
    # happen if a ticket has RC_INTERNAL_ERROR, for example.
    # get_next_stage() now returns an arrayref with [ stage-object,
    # status-constant-name ] so the special stati E,D can be supported by
    # shift at the end of the ticket lifecycle.  status is undefined if
    # nothing was specified in the memory storage's mapping.
    if (my $transition =
        $self->delegate->make_obj('ticket_transition')
        ->get_next_stage($self->stage, $self->rc)) {
        my $status = $transition->[1];
        $self->stage($transition->[0]);
        $self->status($self->delegate->$status) if defined $status;
        $self->storage->ticket_update_stage($self);
    }
}

# service method
sub object_tickets {
    my ($self, $object, $limit) = @_;
    $self->delegate->make_obj('service_result_tabular')->set_from_rows(
        limit  => $limit,
        fields => [
            qw/ticket_no stage status ticket_type origin
              real effective cdate mdate/
        ],
        rows => scalar $self->storage->get_object_tickets($object, $limit,),
    );
}

sub sif_dump {
    my ($self, %opt) = @_;
    assert_getopt $opt{ticket}, 'Called without ticket number.';
    $self->ticket_no($opt{ticket});
    $self->read;
    my $dump = $opt{raw} ? Dumper($self) : scalar($self->dump_comparable);
    $self->delegate->make_obj('service_result_scalar', result => $dump);
}

sub sif_ydump {
    my ($self, %opt) = @_;
    assert_getopt $opt{ticket}, 'Called without ticket number.';
    $self->ticket_no($opt{ticket});
    $self->read;
    $self->delegate->make_obj('service_result_scalar',
        result => $self->yaml_dump_comparable);
}

sub sif_exceptions {
    my ($self, %opt) = @_;
    assert_getopt $opt{ticket}, 'Called without ticket number.';
    $self->ticket_no($opt{ticket});
    $self->read;
    local $Data::Dumper::Indent = 1;
    my $container = $self->payload->get_all_exceptions;
    $self->delegate->make_obj('service_result_scalar',
        result => $opt{raw} ? Dumper($container) : "$container\n");
}

sub sif_clear_exceptions {
    my ($self, %opt) = @_;
    assert_getopt $opt{ticket}, 'Called without ticket number.';
    $self->ticket_no($opt{ticket});
    $self->read;
    $self->payload->clear_all_exceptions;
    $self->store;
    $self->delegate->make_obj('service_result_scalar', result => 'OK');
}

sub sif_exceptions_structured {
    my ($self, %args) = @_;
    $self->ticket_no($args{ticket});
    $self->read;
    my $res = {};
    for my $ot ($args{object} || $self->delegate->OT, 'common') {
        my $item_count = 1;
        for my $item (
              $ot eq 'common'
            ? $self->payload->common
            : $self->payload->get_list_for_object_type($ot)
          ) {
            my $h_item = sprintf "%s.%s", $ot, $item_count++;
            $res->{$h_item} = [];
            for my $E ($item->exception_container->items) {
                my $ex = {
                    class => ref $E,
                    uuid  => $E->uuid,
                    attrs => { map { $_ => $E->$_ } $E->get_properties }
                };
                push(@{ $res->{$h_item} }, $ex);
            }
        }
    }
    $self->delegate->make_obj('service_result_scalar', result => $res);
}

sub sif_delete_exception {
    my ($self, %args) = @_;
    $self->ticket_no($args{ticket});
    $self->read;
    $self->payload->delete_by_uuid($args{uuid});
    $self->store;
    $self->delegate->make_obj('service_result_scalar');
}

sub sif_journal {
    my ($self, %opt) = @_;
    assert_getopt $opt{ticket}, 'Called without ticket number.';
    $self->ticket_no($opt{ticket});
    $self->delegate->make_obj('service_result_tabular')->set_from_rows(
        rows   => scalar $self->storage->get_ticket_journal($self),
        fields => [qw/stage status rc ts osuser oshost/],
    );
}

# This is a service method, which doesn't just set the state attribute, so it
# gets its own method (as opposed to just setting state() from within a
# service interface).
#
# FIXME: Doesn't write sif log yet.
sub sif_set_stage {
    my ($self, %opt) = @_;
    assert_getopt $opt{ticket}, 'Called without ticket number.';
    assert_getopt $opt{stage},  'Called without stage.';
    $self->ticket_no($opt{ticket});
    $self->read;
    my $prev_stage = $self->stage;
    $self->stage($opt{stage});
    $self->store;
    $self->delegate->make_obj(
        'service_result_scalar',
        result =>
          sprintf "Ticket [%s]: Previous stage [%s]\n",
        $self->ticket_no, $prev_stage
    );
}

sub sif_get_ticket_payload {
    my ($self, %args) = @_;
    my $ticket = $self->delegate->make_obj('ticket',);
    my $res    = {};
    $ticket->ticket_no($args{ticket});
    $ticket->read;
    for my $object_type ($self->delegate->OT) {
        next if $object_type eq $self->delegate->OT_LOCK;
        next if $object_type eq $self->delegate->OT_TRANSACTION;
        for my $payload_item (
            $ticket->payload->get_list_for_object_type($object_type)) {
            my $pref = $payload_item->comparable(1);
            $pref = Hash::Flatten::flatten $pref;
            $res->{$object_type} = $pref;
        }
    }
    foreach
      my $facet (qw/authoritative_registrar ignore_exceptions_as_registrar/) {
        $res->{facets}->{$facet} =
          sprintf("%s", $ticket->facets->$facet->protocol_id);
    }
    $res->{protokoll_id} = $ticket->registrar->protocol_id;
    $self->delegate->make_obj('service_result_scalar', result => $res);
}

# rc and status are only updated from the payload; call this before storing
# the ticket whenever you change the payload's exception containers. This way,
# when you remove an exception (e.g., via a service interface), it has a
# direct effect on the ticket's rc and status.
#
# The ticket is passed to the payload method so it can pass it to the methods
# it calls; eventually the exception container will ask the ticket whether to
# ignore each exception it processes (cf. ignores_exception).
sub update_calculated_values {
    my $self = shift;
    $self->payload->update_transaction_stati($self);
    $self->calculate_status;    # calculates rc as well
}

sub calculate_rc {
    my $self = shift;
    $self->rc($self->payload->rc($self));
}

sub calculate_status {
    my $self = shift;
    $self->calculate_rc;        # since status depends on the rc
    my $status = sprintf "%s", $self->payload->status($self);
    if ($self->stage eq $self->delegate->FINAL_TICKET_STAGE) {
        $status =
            $self->rc eq $self->delegate->RC_ERROR
          ? $self->delegate->TS_ERROR
          : $self->delegate->TS_DONE;
    }
    $self->status($status);
}

sub set_default_rc {
    my ($self, $rc) = @_;
    assert_defined $rc, 'called without rc.';
    $self->payload->common->default_rc($rc);
}

sub set_default_status {
    my ($self, $status) = @_;
    assert_defined $status, 'called without status.';
    $self->payload->common->default_status($status);
}

sub reset_default_rc_and_status {
    my $self       = shift;
    my $new_common = $self->delegate->make_obj('payload_common');
    $self->payload->common->default_rc($new_common->default_rc);
    $self->payload->common->default_status($new_common->default_status);
}

sub check {
    my $self = shift;
    $self->payload->check($self);
    $self->facets->check($self);
}

sub filter_exceptions_by_rc {
    my ($self, @filter) = @_;
    $self->payload->filter_exceptions_by_rc($self, @filter);
}

sub filter_exceptions_by_status {
    my ($self, @filter) = @_;
    $self->payload->filter_exceptions_by_status($self, @filter);
}

sub delete {
    my $self = shift;
    $self->assert_ticket_no;
    $self->storage->ticket_delete($self);
}

sub store_facets {
    my $self = shift;
    $self->facets->store($self);
}

sub read_facets {
    my $self = shift;
    $self->facets->read($self);
    $self->facets;
}

# don't call this delete_facets, because framework_object already generates a
# 'delete_*' method.
sub remove_facets {
    my $self = shift;
    $self->facets->delete($self);
}
1;


__END__
=pod

=head1 NAME

Data::Conveyor::Ticket - Stage-based conveyor-belt-like ticket handling system

=head1 VERSION

version 1.103130

=head1 METHODS

=head2 assert_ticket_no

FIXME

=head2 calculate_rc

FIXME

=head2 calculate_status

FIXME

=head2 check

FIXME

=head2 close

FIXME

=head2 close_basic

FIXME

=head2 delete

FIXME

=head2 filter_exceptions_by_rc

FIXME

=head2 filter_exceptions_by_status

FIXME

=head2 gen_ticket_no

FIXME

=head2 get_log_level

FIXME

=head2 ignores_exception

FIXME

=head2 key

FIXME

=head2 object_tickets

FIXME

=head2 open

FIXME

=head2 read

FIXME

=head2 read_facets

FIXME

=head2 remove_facets

FIXME

=head2 reset_default_rc_and_status

FIXME

=head2 set_default_rc

FIXME

=head2 set_default_status

FIXME

=head2 set_log_level

FIXME

=head2 shift_stage

FIXME

=head2 sif_clear_exceptions

FIXME

=head2 sif_delete_exception

FIXME

=head2 sif_dump

FIXME

=head2 sif_exceptions

FIXME

=head2 sif_exceptions_structured

FIXME

=head2 sif_get_ticket_payload

FIXME

=head2 sif_journal

FIXME

=head2 sif_set_stage

FIXME

=head2 sif_ydump

FIXME

=head2 store

FIXME

=head2 store_facets

FIXME

=head2 store_full

FIXME

=head2 try_open

FIXME

=head2 update_calculated_values

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

