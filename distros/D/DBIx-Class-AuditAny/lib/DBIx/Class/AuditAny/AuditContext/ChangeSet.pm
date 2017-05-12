package DBIx::Class::AuditAny::AuditContext::ChangeSet;
use strict;
use warnings;

# ABSTRACT: Default 'ChangeSet' context object class for DBIx::Class::AuditAny

use Moo;
use MooX::Types::MooseLike::Base qw(:all);
extends 'DBIx::Class::AuditAny::AuditContext';

=head1 NAME

DBIx::Class::AuditAny::AuditContext::ChangeSet - Default 'ChangeSet' context object 
class for DBIx::Class::AuditAny

=head1 DESCRIPTION

This object class represents a "set" of changes grouped together, typically all applied within
the scope of a single transaction. The changes can span across multiple individual changes, 
which can also represent changes to multiple different columns.

This class is used internally and should not be used directly.

=cut

use Time::HiRes qw(gettimeofday tv_interval);

sub _build_tiedContexts { [] }
sub _build_local_datapoint_data { 
	my $self = shift;
	return { map { $_->name => $_->get_value($self) } $self->get_context_datapoints('set') };
}

=head1 ATTRIBUTES

Docs regarding the API/purpose of the attributes and methods in this class still TBD...

=head2 changes

=head2 finished

=head2 changeset_ts

=head2 start_timeofday

=head2 changeset_finish_ts

=head2 changeset_elapsed

=cut

has 'changes', is => 'ro', isa => ArrayRef, default => sub {[]};
has 'finished', is => 'rw', isa => Bool, default => sub{0}, init_arg => undef;

has 'changeset_ts', is => 'ro', isa => InstanceOf['DateTime'], lazy => 1, default => sub { (shift)->get_dt };
has 'start_timeofday', is => 'ro', default => sub { [gettimeofday] };

has 'changeset_finish_ts', is => 'rw', isa => Maybe[InstanceOf['DateTime']], default => sub{undef};
has 'changeset_elapsed', is => 'rw', default => sub{undef};

sub BUILD {
	my $self = shift;
	
	# Init
	$self->changeset_ts;
}

=head1 METHODS

=head2 all_changes

=head2 count_changes

=head2 all_column_changes

=head2 add_changes

=head2 finish

=cut

sub all_changes { @{(shift)->changes} }
sub count_changes { scalar(@{(shift)->changes}) }
sub all_column_changes { map { $_->all_column_changes } (shift)->all_changes }

sub add_changes {
	my ($self, @ChangeContexts) = @_;
	
	die "Cannot add_changes to finished ChangeSet!" if ($self->finished);
	
	foreach my $ChangeContext (@ChangeContexts) {
	
		# New: It is now possible that there is no attached ChangeSet yet, since ChangeContext
		# is now created -before- the action operation is executed, and thus before
		# a changeset is automatically started (we do this so we don't have to worry
		# about exceptions). But by the time ->record() is called, we know the operation
		# has succeeded, and we also know that a new changeset has been created if the
		# operation was not already wrapped in a transaction. Se we just set it now:
		$ChangeContext->ChangeSetContext($self) unless ($ChangeContext->ChangeSetContext);
		
		# Extra check for good measure:
		die "Attempted to add changes attached to a different changeset!"
			unless ($self == $ChangeContext->ChangeSetContext);
	
		push @{$self->changes}, $ChangeContext;
	}
}


sub finish {
	my $self = shift;
	return if ($self->finished);
	
	$self->changeset_finish_ts($self->get_dt);
	$self->changeset_elapsed(tv_interval($self->start_timeofday));
	
	return $self->finished(1);
}

1;

__END__

=head1 SEE ALSO

=over

=item *

L<DBIx::Class::AuditAny>

=item *

L<DBIx::Class>

=back

=head1 SUPPORT
 
IRC:
 
    Join #rapidapp on irc.perl.org.

=head1 AUTHOR

Henry Van Styn <vanstyn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012-2015 by IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
