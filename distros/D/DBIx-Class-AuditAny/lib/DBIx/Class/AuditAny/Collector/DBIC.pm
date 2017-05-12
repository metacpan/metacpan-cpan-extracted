package DBIx::Class::AuditAny::Collector::DBIC;
use strict;
use warnings;

# ABSTRACT: Collector class for recording AuditAny changes in DBIC schemas

use Moo;
use MooX::Types::MooseLike::Base qw(:all);
with 'DBIx::Class::AuditAny::Role::Collector';

=head1 NAME

DBIx::Class::AuditAny::Collector::DBIC - Collector class for recording AuditAny 
changes in DBIC schemas

=head1 DESCRIPTION

This Collector facilitates recording ChangeSets, Changes, and Column Changes within a
clean relational structure into a DBIC schema.

If you don't want to handle the details of configuring this yourself, see 
L<DBIx::Class::AuditAny::Collector::AutoDBIC> which is a subclass of us, but handles
most of the defaults for you w/o fuss.

=head1 ATTRIBUTES

Docs regarding the API/purpose of the attributes and methods in this class still TBD...

=head2 target_schema

=head2 target_source

=head2 change_data_rel

=head2 column_data_rel

=cut

has 'target_schema', is => 'ro', isa => Object, lazy => 1, default => sub { (shift)->AuditObj->schema };
has 'target_source', is => 'ro', isa => Str, required => 1;
has 'change_data_rel', is => 'ro', isa => Maybe[Str];
has 'column_data_rel', is => 'ro', isa => Maybe[Str];


# the top level source; could be either change or changeset
has 'targetSource', is => 'ro', isa => Object, 
 lazy => 1, init_arg => undef, default => sub {
	my $self = shift;
	my $Source = $self->target_schema->source($self->target_source) 
		or die "Bad target_source name '" . $self->target_source . "'";
	return $Source;
};

has 'changesetSource', is => 'ro', isa => Maybe[Object], 
 lazy => 1, init_arg => undef, default => sub {
	my $self = shift;
	return $self->change_data_rel ? $self->targetSource : undef;
};

has 'changeSource', is => 'ro', isa => Object, 
 lazy => 1, init_arg => undef, default => sub {
	my $self = shift;
	my $SetSource = $self->changesetSource or return $self->targetSource;
	my $Source = $SetSource->related_source($self->change_data_rel)
		or die "Bad change_data_rel name '" . $self->change_data_rel . "'";
	return $Source;
};

has 'columnSource', is => 'ro', isa => Maybe[Object], 
 lazy => 1, init_arg => undef, default => sub {
	my $self = shift;
	return undef unless ($self->column_data_rel);
	my $Source = $self->changeSource->related_source($self->column_data_rel)
		or die "Bad column_data_rel name '" . $self->column_data_rel . "'";
	return $Source;
};

has 'changeset_datapoints', is => 'ro', isa => ArrayRef[Str],
 lazy => 1, default => sub {
	my $self = shift;
	return [] unless ($self->changesetSource);
	my @DataPoints = $self->AuditObj->get_context_datapoints(qw(base set));
	my @names = map { $_->name } @DataPoints;
	$self->enforce_source_has_columns($self->changesetSource,@names);
	return \@names;
};

has 'change_datapoints', is => 'ro', isa => ArrayRef[Str],
 lazy => 1, default => sub {
	my $self = shift;
	my @contexts = qw(source change);
	push @contexts,(qw(base set)) unless ($self->changesetSource);
	my @DataPoints = $self->AuditObj->get_context_datapoints(@contexts);
	my @names = map { $_->name } @DataPoints;
	$self->enforce_source_has_columns($self->changeSource,@names);
	return \@names;
};

has 'column_datapoints', is => 'ro', isa => ArrayRef[Str],
 lazy => 1, default => sub {
	my $self = shift;
	return [] unless ($self->columnSource);
	my @DataPoints = $self->AuditObj->get_context_datapoints(qw(column));
	my @names = map { $_->name } @DataPoints;
	$self->enforce_source_has_columns($self->columnSource,@names);
	return \@names;
};

has 'write_sources', is => 'ro', isa => ArrayRef[Str], lazy => 1, default => sub {
	my $self = shift;
	my @sources = ();
	push @sources, $self->changesetSource->source_name if ($self->changesetSource);
	push @sources, $self->changeSource->source_name if ($self->changeSource);
	push @sources, $self->columnSource->source_name if ($self->columnSource);
	return \@sources;
};

has '+writes_bound_schema_sources', default => sub {
	my $self = shift;
	return $self->target_schema == $self->AuditObj->schema ? 
		$self->write_sources : [];
};

sub BUILD {
	my $self = shift;
	
	$self->validate_target_schema;

}

=head1 METHODS

=head2 validate_target_schema

=cut
sub validate_target_schema {
	my $self = shift;
	
	$self->changeset_datapoints;
	$self->change_datapoints;
	$self->column_datapoints;
	
}

=head2 enforce_source_has_columns

=cut
sub enforce_source_has_columns {
	my $self = shift;
	my $Source = shift;
	my @columns = @_;
	
	my @missing = ();
	$Source->has_column($_) or push @missing, $_ for (@columns);
	
	return 1 unless (scalar(@missing) > 0);
	
	die "Source '" . $Source->source_name . "' missing required columns: " . 
		join(',',map { "'$_'" } @missing);
}

=head2 get_add_create_change

=cut
sub get_add_create_change {
	my $self = shift;
	my $ChangeContext = shift;
	
	my $create = $ChangeContext->get_datapoints_data($self->change_datapoints);
	
	my $relname = $self->column_data_rel;
	if($relname) {
		my @ColChanges = $ChangeContext->all_column_changes;
		$create->{$relname} = [
			map { $_->get_datapoints_data($self->column_datapoints) } @ColChanges
		];
	}
	
	return $create;
}

=head2 add_change_row

=cut
sub add_change_row {
	my $self = shift;
	my $ChangeContext = shift;
	my $create = $self->get_add_create_change($ChangeContext);
	return $self->changeSource->resultset->create($create);
}

=head2 add_changeset_row

=cut
sub add_changeset_row {
	my $self = shift;
	my $ChangeSetContext = shift;
	
	my $create = $ChangeSetContext->get_datapoints_data($self->changeset_datapoints);
	
	my $relname = $self->change_data_rel;
	if($relname) {
		my @Changes = $ChangeSetContext->all_changes;
		$create->{$relname} = [ map { $self->get_add_create_change($_) } @Changes ];
	}
	
	return $self->changesetSource->resultset->create($create);
}


######### Public API #########

=head2 record_changes

=cut
sub record_changes {
	my $self = shift;
	my $ChangeSet = shift;
	
	return $self->add_changeset_row($ChangeSet) if ($self->changesetSource);
	my @Changes = $ChangeSet->all_changes;
	$self->add_change_row($_) for (@Changes);
	
	return 1;
}

=head2 has_full_row_stored

=cut
sub has_full_row_stored {
	my $self = shift;
	my $Row = shift;
	
	my $Rs = $self->changeSource->resultset 
		or die "No changeSource in this collector";
	
	my $source_name = $Row->result_source->source_name;
	my $SourceContext = $self->AuditObj->tracked_sources->{$source_name} 
		or die "Source '$source_name' is not being tracked by the Auditor!";
	
	my $pri_key_value = $SourceContext->get_pri_key_value($Row);
	
	my $rename = $self->AuditObj->rename_datapoints || {};
	
	my $pri_key_row = $rename->{pri_key_value} || 'pri_key_value';
	my $source = $rename->{source} || 'source';
	my $action = $rename->{action} || 'action';
	
	$Rs = $Rs->search_rs({
		$pri_key_row => $pri_key_value,
		$source => $source_name,
		$action => [ 'select','insert' ]
	},{ limit => 1 });
	
	return $Rs->count;
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
