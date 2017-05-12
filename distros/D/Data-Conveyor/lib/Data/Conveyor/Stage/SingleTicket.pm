use 5.008;
use strict;
use warnings;

package Data::Conveyor::Stage::SingleTicket;
BEGIN {
  $Data::Conveyor::Stage::SingleTicket::VERSION = '1.103130';
}
# ABSTRACT: Stage-based conveyor-belt-like ticket handling system

# Base class for stages handling a single ticket (i.e., policy or delegation,
# but not queue).
#
# To use it, create an object of this class, set the ticket and
# call run(). You can then read the status the stage's ticket and act on it.
use Error::Hierarchy::Util 'assert_defined';
use parent 'Data::Conveyor::Stage';
__PACKAGE__->mk_framework_object_accessors(
    ticket         => 'ticket',
    stage_delegate => 'stage_delegate',
)->mk_scalar_accessors(qw(expected_stage log_max_level_previous));

sub MUNGE_CONSTRUCTOR_ARGS {
    my ($self, @args) = @_;
    @args = $self->SUPER::MUNGE_CONSTRUCTOR_ARGS(@args);
    push @args =>
      (stage_delegate => $self->delegate->make_delegate('stage_delegate'));
    @args;
}

sub main {
    my ($self, %args) = @_;
    $self->SUPER::main(%args);
    assert_defined $self->expected_stage, 'called without set expected_stage.';
    assert_defined $self->ticket,         'called without set ticket.';

    # Remember the log's previous max_level settings and temporarily (until
    # the end of the ticket stage) set the log's max_level to the one
    # indicated by the ticket. This mechanism can be used to increase a faulty
    # ticket's log level from the regsh so that verbose information can be
    # seen in the log. But only override with the ticket's log level if it is
    # higher than the current log level; we don't want a ticket to actually
    # reduce the current log level.
    $self->log_max_level_previous($self->log->max_level);
    if ($self->ticket->get_log_level > $self->log->max_level) {
        $self->log->max_level($self->ticket->get_log_level);
    }
    unless ($self->ticket->stage->name eq $self->expected_stage) {
        throw Data::Conveyor::Exception::Ticket::InvalidStage(
            stage => $self->ticket->stage,);
    }
}

sub end {
    my $self = shift;

    # After handling all exceptions, if the ticket status is anything else
    # than TS_RUNNING, but the rc is RC_ERROR, set the status to TS_RUNNING so
    # that the ticket gets passed on to the notify stage.
    #
    # The reason is that we don't want erroneous tickets to be left on hold.
    # If there's a reason it would normally go on hold and another reason it's
    # erroneous, the error takes precedence.
    $self->ticket->status($self->delegate->TS_RUNNING)
      if $self->ticket->rc eq $self->delegate->RC_ERROR;
    $self->stage_delegate->handle_stage_end($self);

    # restore the log's previous max_level setting.
    $self->log->max_level($self->log_max_level_previous);
    $self->ticket->store;
}
1;


__END__
=pod

=head1 NAME

Data::Conveyor::Stage::SingleTicket - Stage-based conveyor-belt-like ticket handling system

=head1 VERSION

version 1.103130

=head1 METHODS

=head2 end

FIXME

=head2 main

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

