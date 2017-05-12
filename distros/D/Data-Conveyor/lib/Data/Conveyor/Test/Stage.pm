use 5.008;
use strict;
use warnings;

package Data::Conveyor::Test::Stage;
BEGIN {
  $Data::Conveyor::Test::Stage::VERSION = '1.103130';
}
# ABSTRACT: Stage-based conveyor-belt-like ticket handling system
use Test::More;
use Error::Hierarchy::Util 'assert_defined';
use Class::Scaffold::ConstantImporter qw(RC_OK TS_RUNNING);
use parent qw(
  Test::Class
  Class::Scaffold::Delegate::Mixin
  Class::Accessor::Complex
);
__PACKAGE__->mk_scalar_accessors(qw(test_name stage ticket ticket_no run));

sub opt {
    my $self = shift;
    $::app->opt(@_);
}

sub run_stage_test {
    my ($self, %args) = @_;
    assert_defined $args{$_}, "called without '$_' argument" for qw(name code);
    my $runs = $self->opt('runs');
    for my $run (1 .. $runs) {
        $self->run($run);
        my $subtest_name = sprintf '%s run %s of %s', $args{name}, $run, $runs;
        subtest $subtest_name, sub {
            note ref $self;
            $self->run_subtest_code($args{code});
            done_testing;
        };
    }
}

sub run_subtest_code {
    my ($self, $code) = @_;
    $code->($self);

    # To prepare for the next run, reset the ticket to the stage start and an
    # ok status and rc, just as you'd do manually when rerunning the ticket in
    # the regsh. Note that this is the same as would happen in the regsh when
    # given the command 'set_stage -g starten_<stagename>'
    for ($self->ticket) {
        $_->stage->new_start($self->stage);
        $_->status(TS_RUNNING);
        $_->rc(RC_OK);
        $_->close_basic;
    }
}

sub run_ticket_in_stage {
    my $self = shift;
    my $ticket =
      $self->delegate->make_obj('ticket', ticket_no => $self->ticket_no);
    $ticket->open($self->stage);
    $self->delegate->make_stage_object($self->stage, ticket => $ticket)->run;
    $ticket->store if $ticket->rc eq $self->delegate->RC_INTERNAL_ERROR;
    $ticket->close;

    # The ticket that we test our expectations against is a fresh ticket
    # object where we read the ticket we just wrote. Note that we read(), not
    # open() the ticket, because after the stage run, it will still be in
    # an 'active_*' stage, and open() wouldn't find it.
    $self->ticket(
        $self->delegate->make_obj('ticket', ticket_no => $self->ticket_no));
    $self->ticket->read;
}

sub object_with {
    my ($self, $object_type, @args) = @_;
    my $object = $self->delegate->make_obj($object_type);
    while (my ($key, $value) = splice @args, 0, 2) {
        if ($key =~ /^\+(.*)$/) {
            my $composition = $1;
            while (my ($comp_key, $comp_value) = splice @$value, 0, 2) {
                $object->$composition->$comp_key($comp_value);
            }
        } else {
            $object->$key($value);
        }
    }
    $object;
}

sub make_payload {
    my ($self, @items) = @_;
    my $payload =
      $self->object_with('ticket_payload', add_items_from_list => \@items);
    $self->gen_tx_item_ref($payload);
    $payload;
}

sub make_test_ticket {
    my ($self, %args) = @_;
    my $ticket =
      $self->delegate->make_obj('test_ticket')->make_whole_ticket(%args);
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

sub make_exception_container {
    my ($self, @def) = @_;
    my $container = $self->delegate->make_obj('exception_container');
    for my $def (@def) {
        my %args  = %$def;
        my $class = delete $args{ref};
        $container->record($class, %args);
    }
    $container;
}

sub rc_is {
    my ($self, $rc) = @_;
    is $self->ticket->rc, $rc, 'rc';
}

sub status_is {
    my ($self, $status) = @_;
    is $self->ticket->status, $status, 'status';
}
1;


__END__
=pod

=head1 NAME

Data::Conveyor::Test::Stage - Stage-based conveyor-belt-like ticket handling system

=head1 VERSION

version 1.103130

=head1 METHODS

=head2 gen_tx_item_ref

FIXME

=head2 make_exception_container

FIXME

=head2 make_payload

FIXME

=head2 make_test_ticket

FIXME

=head2 object_with

FIXME

=head2 opt

FIXME

=head2 rc_is

FIXME

=head2 run_stage_test

FIXME

=head2 run_subtest_code

FIXME

=head2 run_ticket_in_stage

FIXME

=head2 status_is

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

