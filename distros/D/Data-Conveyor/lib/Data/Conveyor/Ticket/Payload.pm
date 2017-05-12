use 5.008;
use strict;
use warnings;

package Data::Conveyor::Ticket::Payload;
BEGIN {
  $Data::Conveyor::Ticket::Payload::VERSION = '1.103130';
}
# ABSTRACT: Stage-based conveyor-belt-like ticket handling system

# ptags: DCTP
#
# This class houses the ticket payload objects
use Error::Hierarchy::Util 'assert_defined';
use Data::Miscellany 'flatten';
use once;
use parent qw(
  Class::Scaffold::Storable
  Class::Scaffold::HierarchicalDirty
);
__PACKAGE__->mk_scalar_accessors(qw(version))
  ->mk_framework_object_accessors(payload_common => 'common')
  ->mk_framework_object_array_accessors(
    payload_transaction => 'transactions',
    payload_lock        => 'locks',
  );

# Generate add_* methods for each payload item. The method can be called in
# various ways:
#
# 1) Without any arguments: will push a new and empty payload item into the
# according payload item list.
#
# 2) With an payload item data object (eg. a Registry::Person) as first
# argument: will push the given object into the according payload item list.
#
# 3) With any number of arguments of which the first one isn't a reference:
# will create a new payload item with given arguments passed to the
# constructor. This item is pushed into the according payload item list.
sub generate_add_method {
    my ($self, $object_type, $method, $payload_object_type, $push_method) = @_;

    # FIXME: these PTAGS aren't going to work, as the methods are only
    # generated when the application is really running, not when ptags
    # loads the module.
    no strict 'refs';
    $::PTAGS && $::PTAGS->add_tag($method, __FILE__, __LINE__ + 1);
    *$method = sub {
        my $self           = shift;
        my $payload_object = $self->delegate->make_obj($payload_object_type);

        # If at least one argument is given, check if it's a reference. If
        # it is, use it as our object to set, Otherwise create a new
        # payload item supplying all the arguments we might have gotten.
        my $object =
          defined $_[0] && ref $_[0]
          ? $_[0]
          : $self->delegate->make_obj($object_type, @_);
        $payload_object->$object_type($object);
        $self->$push_method($payload_object);
        return $payload_object;
      }
}

sub init {
    my $self = shift;
    $self->SUPER::init(@_);
    ONCE {
        for my $object_type ($self->delegate->OT) {
            my $add_method          = sprintf("add_%s",        $object_type);
            my $add_unique_method   = sprintf("add_unique_%s", $object_type);
            my $payload_object_type = sprintf("payload_%s",    $object_type);
            my $push_method         = sprintf("%ss_push",      $object_type);
            my $set_push_method     = sprintf("%ss_set_push",  $object_type);
            $self->generate_add_method(
                $object_type,         $add_method,
                $payload_object_type, $push_method
            );
            $self->generate_add_method(
                $object_type,         $add_unique_method,
                $payload_object_type, $set_push_method
            );
        }
    };
}

sub LIST_ACCESSOR_FOR_OBJECT_TYPE {
    local $_ = $_[0]->delegate;
    (   $_->OT_LOCK        => 'locks',
        $_->OT_TRANSACTION => 'transactions',
    );
}

sub get_list_name_for_object_type {
    my ($self, $object_type) = @_;
    my $list_accessor = $self->every_hash('LIST_ACCESSOR_FOR_OBJECT_TYPE');
    assert_defined my $method = $list_accessor->{$object_type},
      "unknown payload object type [$object_type]";
    $method;
}

sub get_list_for_object_type {
    my ($self, $object_type) = @_;
    our %cache_list_name_for_object_type;
    my $method = $cache_list_name_for_object_type{$object_type} ||=
      $self->get_list_name_for_object_type($object_type);
    $self->$method;
}

# Take a list of payload items and add it to the appropriate array slots in
# the payload object
sub add_items_from_list {
    my $self = shift;
    for my $item (flatten(@_)) {
        (my $factory_type = $item->get_my_factory_type) =~ s/^payload_//;
        if ($factory_type eq 'common') {
            $self->common($item);
            next;
        }
        my $list_accessor = $self->get_list_name_for_object_type($factory_type);
        my $push_method   = $list_accessor . '_push';
        $self->$push_method($item);
    }
}

sub get_transactions_with_data_object_type {
    my ($self, $object_type) = @_;
    grep { $_->data->object_type eq $object_type } $self->transactions;
}

sub get_transactions_with_data_object_type_and_cmd {
    my ($self, $object_type, $cmd) = @_;
    grep { $_->data->command eq $cmd }
      $self->get_transactions_with_data_object_type($object_type);
}

sub check {
    my ($self, $ticket) = @_;

    # check object limits; also check the payload items while we're at it
    for my $object_type ($self->delegate->OT) {
        my $limit =
          $self->delegate->get_object_limit($ticket->type, $object_type);
        my $index;
        for my $item ($self->get_list_for_object_type($object_type)) {
            $index++;

            # Ask the business object to check itself, accumulating exceptions
            # into the business object's exception container.
            $item->check($ticket);
            next if $index <= $limit;
            $item->exception_container->record(
                'Data::Conveyor::Exception::ObjectLimitExceeded',
                ticket_type => $ticket->type,
                object_type => $object_type,
                limit       => $limit,
            );
        }
    }
    $self->common->check($ticket);
}

# determines the overall payload rc
sub rc {
    my ($self, $ticket) = @_;

    # Start with RC_OK; if a stage wants to use another default rc, it can do
    # so by setting the common payload item's default_rc.
    my $rc =
      $self->delegate->make_obj('value_ticket_rc', $self->delegate->RC_OK) +
      $self->common->rc($ticket);
    for my $object_type ($self->delegate->OT) {
        $rc += $_->rc($ticket)
          for $self->get_list_for_object_type($object_type);
    }
    $rc;
}

# determines the overall payload status
sub status {
    my ($self, $ticket) = @_;

    # Start with TS_RUNNING; if a stage wants to use another default status,
    # it can do so by setting the common payload item's default_status.
    my $status =
      $self->delegate->make_obj('value_ticket_status',
        $self->delegate->TS_RUNNING) + $self->common->status($ticket);
    for my $object_type ($self->delegate->OT) {
        $status += $_->status($ticket)
          for $self->get_list_for_object_type($object_type);
    }
    $status;
}

sub update_transaction_stati {
    my ($self, $ticket) = @_;
    $_->transaction->update_status($ticket) for $self->transactions;
}

sub filter_exceptions_by_rc {
    my ($self, $ticket, @filter) = @_;
    my $result = $self->delegate->make_obj('exception_container');
    for my $object_type ($self->delegate->OT) {
        for my $payload_item ($self->get_list_for_object_type($object_type)) {
            $result->items_push(
                $payload_item->exception_container->filter_exceptions_by_rc(
                    $ticket, @filter
                )
            );
        }
    }
    $result->items_push(
        $self->common->exception_container->filter_exceptions_by_rc(
            $ticket, @filter
        )
    );
    $result;
}

sub filter_exceptions_by_status {
    my ($self, $ticket, @filter) = @_;
    my $result = $self->delegate->make_obj('exception_container');
    for my $object_type ($self->delegate->OT) {
        for my $payload_item ($self->get_list_for_object_type($object_type)) {
            $result->items_push(
                $payload_item->exception_container->filter_exceptions_by_status(
                    $ticket, @filter
                )
            );
        }
    }
    $result->items_push(
        $self->common->exception_container->filter_exceptions_by_status(
            $ticket, @filter
        )
    );
    $result;
}

sub get_all_exceptions {
    my $self   = shift;
    my $result = $self->delegate->make_obj('exception_container');
    for my $object_type ($self->delegate->OT) {
        for my $payload_item ($self->get_list_for_object_type($object_type)) {
            $result->items_push($payload_item->exception_container->items);
        }
    }
    $result->items_push($self->common->exception_container->items);
    $result->delete_duplicate_exceptions;  # returns $result
}

sub clear_all_exceptions {
    my $self = shift;
    for my $object_type ($self->delegate->OT) {
        for my $payload_item ($self->get_list_for_object_type($object_type)) {
            $payload_item->exception_container->clear_items;
        }
    }
}

# Iterates over all payload items and deletes all exceptions whose uuid is one
# of those given in the argument list
sub delete_exceptions_by_uuid {
    my ($self, @uuid) = @_;
    for my $object_type ($self->delegate->OT) {
        for my $payload_item ($self->get_list_for_object_type($object_type)) {
            $payload_item->exception_container->delete_by_uuid(@uuid);
        }
    }
}

sub delete_implicit_items {
    my $self = shift;
    for my $object_type ($self->delegate->OT) {
        my $list_name = $self->get_list_name_for_object_type($object_type);
        $self->$list_name([ grep { !$_->implicit } $self->$list_name ]);
    }
}

sub prepare_comparable {
    my $self = shift;
    $self->SUPER::prepare_comparable(@_);
    $self->version($self->delegate->PAYLOAD_VERSION);

    # Touch various accessors that will autovivify hash keys so we can be sure
    # they exist, which is a kind of normalization for the purpose of
    # comparing two objects of this class.
    $self->common;
    $self->transactions;
    $self->locks;

    # Touch the items of all exception containers so comparsions work (if the
    # ticket is stored, the items of all exception containers at least exist).
    $self->get_all_exceptions;
    for my $object_type ($self->delegate->OT) {
        my $list_name = $self->get_list_name_for_object_type($object_type);
        $self->$list_name;
    }
}

sub apply_instruction_containers {
    my $self = shift;
    for my $object_type ($self->delegate->OT) {
        for my $payload_item ($self->get_list_for_object_type($object_type)) {
            $payload_item->apply_instruction_container;
        }
    }
}

# Override this method to handle different payload versions: A payload may
# have been written months ago, but in the meantime the code might have
# changed. Therefore the old payload needs to be adapted to work with the new
# code.
sub upgrade { }
1;


__END__
=pod

=for stopwords rc

=head1 NAME

Data::Conveyor::Ticket::Payload - Stage-based conveyor-belt-like ticket handling system

=head1 VERSION

version 1.103130

=head1 METHODS

=head2 LIST_ACCESSOR_FOR_OBJECT_TYPE

FIXME

=head2 add_items_from_list

FIXME

=head2 apply_instruction_containers

FIXME

=head2 check

FIXME

=head2 clear_all_exceptions

FIXME

=head2 delete_exceptions_by_uuid

FIXME

=head2 delete_implicit_items

FIXME

=head2 filter_exceptions_by_rc

FIXME

=head2 filter_exceptions_by_status

FIXME

=head2 generate_add_method

FIXME

=head2 get_all_exceptions

FIXME

=head2 get_list_for_object_type

FIXME

=head2 get_list_name_for_object_type

FIXME

=head2 get_transactions_with_data_object_type

FIXME

=head2 get_transactions_with_data_object_type_and_cmd

FIXME

=head2 prepare_comparable

FIXME

=head2 rc

FIXME

=head2 status

FIXME

=head2 update_transaction_stati

FIXME

=head2 upgrade

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

