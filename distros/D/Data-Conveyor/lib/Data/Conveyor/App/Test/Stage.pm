use 5.008;
use strict;
use warnings;

package Data::Conveyor::App::Test::Stage;
BEGIN {
  $Data::Conveyor::App::Test::Stage::VERSION = '1.103130';
}
# ABSTRACT: Stage-based conveyor-belt-like ticket handling system
use YAML::Active 'Dump';
use String::FlexMatch::Test;
use Test::More;
use Data::Dumper;
use parent 'Class::Scaffold::App::Test::YAMLDriven';
$Data::Dumper::Indent = 1;
__PACKAGE__->mk_scalar_accessors(
    qw(
      ticket ticket_no stage expected_stage_const
      )
);
use constant DEFAULTS => (runs => 2,);

sub expected_stage {
    my $self   = shift;
    my $method = $self->expected_stage_const;
    $self->delegate->$method;
}

sub execute_test_def {
    my ($self, $testname) = @_;
    if ($self->should_skip_testname($testname)) {
        $self->SUPER::execute_test_def($testname);
    } else {
        $self->make_ticket($testname);
        $self->SUPER::execute_test_def($testname);

        # During the test run it's not really necessary to delete the ticket
        # because we'll rollback anyway, and deleting a ticket is expensive.
        # $self->ticket->delete;
    }
}

sub make_ticket {
    my ($self, $testname) = @_;

    # No support for phases at this time - we don't need them and Reload() is
    # expensive.
    # $self->test_def($testname,
    #     Reload($self->test_def($testname), $self->delegate->YAP_MAKE_TICKET)
    # );
    my $ticket =
      $self->delegate->make_obj('test_ticket')
      ->make_whole_ticket(%{ $self->test_def($testname)->{make_whole_ticket} });
    $self->gen_tx_item_ref($ticket->payload);
    $ticket->store_full;

    # Set up some accessors so other methods can refer to them.
    $self->ticket_no($ticket->ticket_no);
}

sub gen_tx_item_ref {
    my ($self, $payload) = @_;
    for my $payload_tx ($payload->transactions) {
        my $item_spec = $payload_tx->transaction->payload_item;
        next if ref $item_spec;
        if ($item_spec =~ /^(\w+)\.(\d+)$/) {
            my ($accessor, $index) = ($1, $2 - 1);
            $payload_tx->transaction->payload_item(
                eval "\$payload->$accessor\->[$index]");
            die $@ if $@;
        }
        unless (ref $payload_tx->transaction->payload_item) {
            throw Error::Hierarchy::Internal::CustomMessage(
                custom_message => sprintf 'No such payload item [%s]',
                $item_spec,
            );
        }
    }
}

sub make_stage_object {
    my $self = shift;
    $self->stage($self->delegate->make_stage_object($self->expected_stage, @_));
}

# subclasses can do preparatory things here
sub before_stage_hook { }

sub run_subtest {
    my $self = shift;

    # At this point, set any local configuration the test yaml file might have
    # asked for.
    local %Property::Lookup::Local::opt = (
        %Property::Lookup::Local::opt,
        %{ $self->current_test_def->{opt} || {} },
    );
    my $ticket =
      $self->delegate->make_obj('ticket', ticket_no => $self->ticket_no);
    $ticket->open($self->expected_stage);
    $self->before_stage_hook($ticket);
    $self->stage($self->make_stage_object(ticket => $ticket));
    $self->stage->run;
    $ticket->store if $ticket->rc eq $self->delegate->RC_INTERNAL_ERROR;
    $ticket->close;

    # The ticket that we test our expectations against is a fresh ticket
    # object where we read the ticket we just wrote. Note that we read(), not
    # open() the ticket, because after the stage run, it will still be in
    # an 'active_*' stage, and open() wouldn't find it.
    $self->ticket(
        $self->delegate->make_obj('ticket', ticket_no => $self->ticket_no,));
    $self->ticket->read;
    $self->test_expectations;

    # To prepare for the next run, reset the ticket to the stage start and an
    # ok status and rc, just as you'd do manually when rerunning the ticket in
    # the regsh. Note that this is the same as would happen in the regsh when
    # given the command 'set_stage -g starten_<stagename>'
    for ($self->ticket) {
        $_->stage->new_start($self->expected_stage);
        $_->status($self->delegate->TS_RUNNING);
        $_->rc($self->delegate->RC_OK);
        $_->close_basic;
    }
}

# so subclasses can call SUPER::
sub test_expectations { }

sub plan_ticket_expected_container {
    my ($self, $test, $run) = @_;
    my $plan = 2;    # rc, status

    # The expected exceptions look like this in the YAML files:
    #
    #    exceptions:
    #      person:
    #        -
    #          # expect the following exceptions for the first person
    #          - ref: Registry::Exception::Person::InvalidEmail
    #            handle: ...
    #            email: ...
    #          - ref: Registry::Exception::Person::InvalidName
    #            handle: ...
    #            name ...
    #        -
    #          # expect the following exceptions for the second person
    #          - ref: ...
    #            ...
    #      domains:
    #        -
    #          # expect the following exceptions for the first domain
    #          - ref: ...
    #            ...
    #
    # Usually, we expect two tests per exception per run (one for the
    # exception's type and for for its message). There's a special
    # case that complicates the thing a bit: Some policies actually alter the
    # ticket. For example, if, in a person, we detect an alias name for a
    # country (e.g., 'Oesterreich', which is mapped to the normal name,
    # 'Austria'), the policy actually replaces the country name with the
    # normal name. So the second time around, the country name will be the
    # normal one and no exception is thrown.
    while (my ($object_type, $spec) =
        each %{ $test->{expect}{exceptions} || {} }) {
        for my $payload_item (@$spec) {
            for my $exception (
                ref $payload_item eq 'ARRAY'
                ? @$payload_item
                : $payload_item
              ) {
                next unless ref($exception) eq 'HASH';
                next
                  if $run > 1
                      && $exception->{ref} =~ /Replace(Fax|Phone)No$/;
                $plan += 2;
            }
        }
    }
    $plan;
}

sub plan_ticket_tx {
    my ($self, $test) = @_;
    exists $test->{expect}{tx};
}

sub check_ticket_rc_status {
    my $self = shift;
    is($self->ticket->rc, $self->expect->{rc} || $self->delegate->RC_OK, 'rc');
    is($self->ticket->status,
        $self->expect->{status} || $self->delegate->TS_RUNNING, 'status');
}

sub check_ticket_tx {
    my $self = shift;
    return unless exists $self->expect->{tx};
    my @tx_status =
      map { $_->transaction->status } $self->ticket->payload->transactions;

    # Dump as YAML on failure, so we see the stringified values, not the value
    # objects.
    ok(eq_array_flex(\@tx_status, $self->expect->{tx}), 'resulting tx status')
      or print Dump \@tx_status;
}

sub check_ticket_expected_container {
    my $self = shift;
    $self->check_ticket_rc_status($self->ticket);
    for my $object_type ($self->delegate->OT) {
        my $item_index = 0;
        for my $payload_item (
            $self->ticket->payload->get_list_for_object_type($object_type)) {
            $self->compare_exceptions(
                $object_type,
                $payload_item,
                (   $self->expect->{exceptions}{$object_type}[ $item_index++ ]
                      || []
                ),
            );
        }
    }
    $self->compare_exceptions(
        'common',
        $self->ticket->payload->common,
        ($self->expect->{exceptions}{common} || []),
    );
}

sub compare_exceptions {
    my ($self, $object_type, $payload_item, $expected_exceptions) = @_;
    my $exception_index = 0;
    return unless ref $expected_exceptions eq 'ARRAY';

    # Impose an order on the exceptions, namely the way they stringify for the
    # benefit of the yaml test files.
    for my $got_exception (sort { "$a" cmp "$b" }
        $payload_item->exception_container->items) {
        unless (exists $expected_exceptions->[$exception_index]) {
            fail(
                sprintf
                  "Unexpected exception on [%s] of type [%s], message [%s]",
                $object_type, ref($got_exception), $got_exception
            );
            print Dumper $got_exception;
            next;
        }

        # Ok, we did expect an exception, so check whether it's the
        # right one.
        my $expected_exception = $expected_exceptions->[$exception_index];
        isa_ok($got_exception, $expected_exception->{ref});

        # FIXME
        # hack for Class::Value::Exception::InvalidValue, which has a property
        # called 'ref'. But the test definition of the expected exception also
        # has a 'ref' property to indicate what type of exception we expect.
        # So the test def's 'p_ref' is munged to become the 'ref' of
        # Class::Value::Exception::InvalidValue. Solution: call the exception
        # property something else.
        #
        # Example:
        #
        # exceptions:
        #   person:
        #     -
        #       -
        #         ref: Class::Value::Exception::InvalidValue
        #         p_ref: Registry::NICAT::Value::Person::Handle
        #         value: *HANDLE
        my %expected_properties = %$expected_exception;
        delete $expected_properties{ref};
        $expected_properties{ref} = delete $expected_properties{p_ref}
          if $expected_properties{p_ref};
        is_deeply_flex(scalar($got_exception->properties_as_hash),
            \%expected_properties, 'exception properties')
          or print Dumper $got_exception;

        # Following the same logic as commented in
        # plan_ticket_expected_container(), eliminate those exceptions
        # from the expected list after the first run that would only
        # occur in the first run, i.e. Replace* exceptions. That way,
        # we won't even see them in the list of expected exceptions in
        # the second and subsequent runs.
        if (   $self->run_num == 1
            && defined($expected_exception)
            && $expected_exception->{ref} =~ /Replace(Fax|Phone)No$/) {
            splice @$expected_exceptions, $exception_index, 1;
        }
    } continue {
        $exception_index++;
    }

    # Now we check whether there are further expected exceptions -
    # this would be ones we expected but didn't get.
    while (defined(my $extra = $expected_exceptions->[ $exception_index++ ])) {
        fail(sprintf "Didn't see expected exception of type [%s]",
            $extra->{ref},);
    }
}

sub is_deep_set {
    my ($self, $got, $expect, $test_name) = @_;
    $got    = [ sort _by_dump @{ $got    || [] } ];
    $expect = [ sort _by_dump @{ $expect || [] } ];
    is_deeply_flex($got, $expect, $test_name)
      or print YAML::Active::Dump($got, ForceBlock => 0),
      YAML::Active::Dump($expect, ForceBlock => 0);
}
sub _by_dump { YAML::Active::Dump($a) cmp YAML::Active::Dump($b) }
1;


__END__
=pod

=head1 NAME

Data::Conveyor::App::Test::Stage - Stage-based conveyor-belt-like ticket handling system

=head1 VERSION

version 1.103130

=head1 METHODS

=head2 before_stage_hook

FIXME

=head2 check_ticket_expected_container

FIXME

=head2 check_ticket_rc_status

FIXME

=head2 check_ticket_tx

FIXME

=head2 compare_exceptions

FIXME

=head2 expected_stage

FIXME

=head2 gen_tx_item_ref

FIXME

=head2 is_deep_set

FIXME

=head2 make_stage_object

FIXME

=head2 make_ticket

FIXME

=head2 plan_ticket_expected_container

FIXME

=head2 plan_ticket_tx

FIXME

=head2 run_subtest

FIXME

=head2 test_expectations

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

