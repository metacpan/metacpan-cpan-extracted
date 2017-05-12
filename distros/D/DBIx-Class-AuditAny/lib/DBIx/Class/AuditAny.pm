package DBIx::Class::AuditAny;
use strict;
use warnings;

# ABSTRACT: Flexible change tracking framework for DBIx::Class

our $VERSION = '0.200100';

use 5.010;

use Moo;
use MooX::Types::MooseLike::Base 0.19 qw(:all);

use Class::MOP;
use Class::MOP::Class;
use DateTime;
use DBIx::Class::AuditAny::Util;
use DBIx::Class::AuditAny::Util::BuiltinDatapoints;
use DBIx::Class::AuditAny::Role::Schema;

use Term::ANSIColor qw(:constants);

has 'time_zone', is => 'ro', isa => Str, default => sub{'local'};
sub get_dt { DateTime->now( time_zone => (shift)->time_zone ) }

has 'schema', is => 'ro', required => 1, isa => InstanceOf['DBIx::Class::Schema']; #<--- This won't go back to Moose
has 'track_immutable', is => 'ro', isa => Bool, default => sub{0};
has 'track_actions', is => 'ro', isa => ArrayRef, default => sub { [qw(insert update delete)] };
has 'allow_multiple_auditors', is => 'ro', isa => Bool, default => sub{0};

has 'source_context_class', is => 'ro', default => sub{'AuditContext::Source'};
has 'change_context_class', is => 'ro', default => sub{'AuditContext::Change'};
has 'changeset_context_class', is => 'ro', default => sub{'AuditContext::ChangeSet'};
has 'column_context_class', is => 'ro', default => sub{'AuditContext::Column'};
has 'default_datapoint_class', is => 'ro', default => sub{'DataPoint'};
has 'collector_class', is => 'ro', isa => Str;

around $_ => sub { 
	my $orig = shift; my $self = shift; 
	resolve_localclass $self->$orig(@_);
} for qw(
 source_context_class change_context_class
 changeset_context_class column_context_class
 default_datapoint_class collector_class
);

has 'collector_params', is => 'ro', isa => HashRef, default => sub {{}};
has 'primary_key_separator', is => 'ro', isa => Str, default => sub{'|~|'};
has 'datapoint_configs', is => 'ro', isa => ArrayRef[HashRef], default => sub {[]};
has 'auto_include_user_defined_datapoints', is => 'ro', isa => Bool, default => sub{1};
has 'rename_datapoints', is => 'ro', isa => Maybe[HashRef[Str]], default => sub{undef};
has 'disable_datapoints', is => 'ro', isa => ArrayRef, default => sub {[]};
has 'record_empty_changes', is => 'ro', isa => Bool, default => sub{0};

has 'datapoints', is => 'ro', isa => ArrayRef[Str], 
 default => sub{[qw(
  change_ts
  action
  source
  pri_key_value
  column_name
  old_value
  new_value
)]};

has 'collector', is => 'ro', lazy => 1, default => sub {
	my $self = shift;
	return ($self->collector_class)->new(
		%{$self->collector_params},
		AuditObj => $self
	);
};

# Any sources within the tracked schema that the collector is writing to; these
# sources are not allowed to be tracked because it would create infinite recursion:
has 'log_sources', is => 'ro', isa => ArrayRef[Str], lazy => 1, init_arg => undef, default => sub {
	my $self = shift;
	return $self->collector->writes_bound_schema_sources;
};

has 'tracked_action_functions', is => 'ro', isa => HashRef, default => sub {{}};
has 'tracked_sources', is => 'ro', isa => HashRef[Str], default => sub {{}};
has 'calling_action_function', is => 'ro', isa => HashRef[Bool], default => sub {{}};
has 'active_changeset', is => 'rw', isa => Maybe[Object], default => sub{undef};
has 'auto_finish', is => 'rw', isa => Bool, default => sub{0};

has 'track_init_args', is => 'ro', isa => Maybe[HashRef], default => sub{undef};
has 'build_init_args', is => 'ro', isa => HashRef, required => 1;

around BUILDARGS => sub {
	my $orig = shift;
	my $class = shift;
	my %opts = (ref($_[0]) eq 'HASH') ? %{ $_[0] } : @_; # <-- arg as hash or hashref

	die 'Cannot specify build_init_args in new()' if (exists $opts{build_init_args});
	$opts{build_init_args} = { %opts };
	return $class->$orig(%opts);
};

sub track {
	my $class = shift;
	my %opts = (ref($_[0]) eq 'HASH') ? %{ $_[0] } : @_; # <-- arg as hash or hashref
	die "track cannot be called on object instances" if (ref $class);
	
	# Record the track init arguments:
	$opts{track_init_args} = { %opts };
	
	my $sources = exists $opts{track_sources} ? delete $opts{track_sources} : undef;
	die 'track_sources must be an arrayref' if ($sources and ! ref($sources) eq 'ARRAY');
	my $track_all = exists $opts{track_all_sources} ? delete $opts{track_all_sources} : undef;
	die "track_sources and track_all_sources are incompatible" if ($sources && $track_all);
	
	my $init_sources = exists $opts{init_sources} ? delete $opts{init_sources} : undef;
	die 'init_sources must be an arrayref' if ($init_sources and ! ref($init_sources) eq 'ARRAY');
	my $init_all = exists $opts{init_all_sources} ? delete $opts{init_all_sources} : undef;
	die "init_sources and init_all_sources are incompatible" if ($init_sources && $init_all);
	
	my $collect = exists $opts{collect} ? delete $opts{collect} : undef;
	if ($collect) {
		die "'collect' cannot be used with 'collector_params', 'collector_class' or 'collector'"
			if ($opts{collector_params} || $opts{collector_class} || $opts{collector});
			
		$opts{collector_class} = 'Collector::Code';
		$opts{collector_params} = { collect_coderef => $collect };
	}
	
	if($opts{collector}) {
		die "'collector' cannot be used with 'collector_params', 'collector_class' or 'collect'"
			if ($opts{collector_params} || $opts{collector_class} || $opts{collect});
	}
	
	my $self = $class->new(%opts);
	
	$self->track_sources(@$sources) if ($sources);
	$self->track_all_sources if ($track_all);
	
	$self->init_sources(@$init_sources) if ($init_sources);
	$self->init_all_sources if ($init_all);
	return $self;
}


sub _get_datapoint_configs {
	my $self = shift;
	
	my @configs = DBIx::Class::AuditAny::Util::BuiltinDatapoints->all_configs;
	
	# strip out any being redefined:
	my %cust = map {$_->{name}=>1} @{$self->datapoint_configs};
	@configs = grep { !$cust{$_->{name}} } @configs;
	
	# Set flag to mark the configs that were user defined
	$_->{user_defined} = 1 for (@{$self->datapoint_configs});
	
	push @configs, @{$self->datapoint_configs};
	
	return @configs;
}

has '_datapoints', is => 'ro', isa => HashRef, default => sub {{}};
has '_datapoints_context', is => 'ro', isa => HashRef, default => sub {{}};

# Also index datapoints by 'original_name' which will be different from 'name'
# whenever 'rename_datapoints' has been applied
has '_datapoints_orig_names', is => 'ro', isa => HashRef, default => sub {{}};
sub get_datapoint_orig { (shift)->_datapoints_orig_names->{(shift)} }

sub add_datapoints {
	my $self = shift;
	my $class = $self->default_datapoint_class;
	foreach my $cnf (@_) {
		die "'$cnf' not expected ref" unless (ref $cnf);
		$class = delete $cnf->{class} if ($cnf->{class});
		my $DataPoint = ref($cnf) eq $class ? $cnf : $class->new($cnf);
		die "Error creating datapoint object" unless (ref($DataPoint) eq $class);
		die "Duplicate datapoint name '" . $DataPoint->name . "'" if ($self->_datapoints->{$DataPoint->name});
		$self->_datapoints->{$DataPoint->name} = $DataPoint;
		$self->_datapoints_context->{$DataPoint->context}->{$DataPoint->name} = $DataPoint;
		$self->_datapoints_orig_names->{$DataPoint->original_name} = $DataPoint;
	}
}
sub all_datapoints { values %{(shift)->_datapoints} }

sub get_context_datapoints {
	my $self = shift;
	my @contexts = grep { exists $self->_datapoints_context->{$_} } @_;
	return map { values %{$self->_datapoints_context->{$_}} } @contexts;
}

sub get_context_datapoint_names {
	my $self = shift;
	return map { $_->name } $self->get_context_datapoints(@_);
}


sub local_datapoint_data { (shift)->base_datapoint_values }
has 'base_datapoint_values', is => 'ro', isa => HashRef, lazy => 1, default => sub {
	my $self = shift;
	return { map { $_->name => $_->get_value($self) } $self->get_context_datapoints('base') };
};

sub _init_datapoints {
	my $self = shift;
	
	my @configs = $self->_get_datapoint_configs;
	
	if($self->rename_datapoints) {
		my $rename = $self->rename_datapoints;
		
		@{$self->datapoints} = map { $rename->{$_} || $_ } @{$self->datapoints};
		
		foreach my $cnf (@configs) {
			next unless (exists $rename->{$cnf->{name}});
			$cnf->{original_name} = $cnf->{name};
			$cnf->{name} = $rename->{$cnf->{name}};
		}
	}
	
	my %seen = ();
	$seen{$_}++ and die "Duplicate datapoint name '$_'" for (@{$self->datapoints});
	
	my %disable = map {$_=>1} @{$self->disable_datapoints};
	my %activ = map {$_=>1} grep { !$disable{$_} } @{$self->datapoints};
	
	if($self->auto_include_user_defined_datapoints) {
		$activ{$_->{name}} = 1 for(grep { $_->{name} && $_->{user_defined} } @configs);
	}
	
	foreach my $cnf (@configs) {
		# Do this just to throw the exception for no name:
		$self->add_datapoints($cnf) unless ($cnf->{name});
		
		next unless $activ{$cnf->{name}};
		delete $activ{$cnf->{name}};
		$self->add_datapoints({%$cnf, AuditObj => $self});
	}
	
	die "Unknown datapoint(s) specified (" . join(',',keys %activ) . ')'
		if (scalar(keys %activ) > 0);
}


sub BUILD {
	my $self = shift;
	
	# init all classes first:
	$self->change_context_class;
	$self->changeset_context_class;
	$self->source_context_class;
	$self->column_context_class;
	$self->default_datapoint_class;
	
	$self->_init_datapoints;
	$self->_bind_schema;
	
	# init collector object:
	$self->collector;
}


sub _init_apply_schema_class {
	my $self = shift;
	die "schema is not a reference" unless (ref $self->schema);
	
	Moo::Role->apply_roles_to_object($self->schema,'DBIx::Class::AuditAny::Role::Schema')
		unless try{$self->schema->does('DBIx::Class::AuditAny::Role::Schema')};
	
	# Important!
	$self->schema->_apply_storage_role;
}





sub _bind_schema {
	my $self = shift;
	$self->_init_apply_schema_class;
	
	die "Supplied Schema instance already has a bound Auditor - to allow multple " .
	 "Auditors, set 'allow_multiple_auditors' to true"
		if($self->schema->auditor_count > 0 and ! $self->allow_multiple_auditors);
	
	$_ == $self and return for($self->schema->auditors);
	
	return $self->schema->add_auditor($self);
}




sub track_sources {
	my ($self,@sources) = @_;
	
	foreach my $name (@sources) {
		my $Source = $self->schema->source($name) or die "Bad Result Source name '$name'";
		
		my $class = $self->source_context_class;
		my $AuditSourceContext = $class->new( 
			AuditObj			=> $self, 
			ResultSource	=> $Source
		);
		
		my $source_name = $AuditSourceContext->source;
		
    my %log_sources = map {$_=>1} @{$self->log_sources};
		die "The Log Source (" . $source_name . ") cannot track itself!!"
			if ($log_sources{$source_name});

		# Skip sources we've already setup:
		return if ($self->tracked_sources->{$source_name});
		
		$self->_add_row_trackers_methods($AuditSourceContext);
		$self->tracked_sources->{$source_name} = $AuditSourceContext;
	}
}

sub track_all_sources {
	my ($self,@exclude) = @_;
	#$class->_init;
	
	push @exclude, @{$self->log_sources};
		
	my %excl = map {$_=>1} @exclude;
	return $self->track_sources(grep { !$excl{$_} } $self->schema->sources);
}

# This is the original, Row-based solution for initializing existing data. This
# is going to be refactored and replaced, but with what has not been decided yet
# See also _add_additional_row_methods() below
sub init_sources {
	my ($self,@sources) = @_;
	
	$self->schema->txn_do(sub {
	
		foreach my $name (@sources) {
			my $SourceContext = $self->tracked_sources->{$name} 
				or die "Source '$name' is not being tracked";
			
			print STDERR "\n";
			
			my $msg = "Initializing Audit Records for $name: ";
			print STDERR $msg . "\r";
			
			my $Rs = $SourceContext->ResultSource->resultset;
			my $total = $Rs->count;
			my $count = 0;
			foreach my $Row ($Rs->all) {
				print STDERR $msg . ++$count . '/' . $total . "\r";
				$Row->audit_init($self);
			}
		}
		
		print STDERR "\n\n";
	});
}

sub init_all_sources {
	my $self = shift;
	$self->init_sources(keys %{$self->tracked_sources});
}


our $NESTED_CALL = 0;
sub _add_row_trackers_methods {
	my $self = shift;
	my $AuditSourceContext = shift;
	
	my $source_name = $AuditSourceContext->source;
	my $result_class = $self->schema->class($source_name);
	
	foreach my $action (@{$self->track_actions}) {
		my $func_name = $source_name . '::' . $action;
		return if $self->tracked_action_functions->{$func_name}++;
	}
	
	$self->_add_additional_row_methods($result_class);
}



# TODO/FIXME: This needs to be refactored to use a cleaner API. Probably 
# totally different (this code is leftover from before the switch to the
# Storage Role API)
sub _add_additional_row_methods {
	my $self = shift;
	my $result_class = shift;
	
	my $meta = Class::MOP::Class->initialize($result_class);
	my $immutable = $meta->is_immutable;
	
	die "Won't add tracker/modifier method to immutable Result Class '$result_class' " .
	 '(hint: did you forget to remove __PACKAGE__->meta->make_immutable ??)' .
	 ' - to force/override, set "track_immutable" to true.'
		if ($immutable && !$self->track_immutable);
	
	# Tempory turn mutable back on, saving any immutable_options, first:
	my %immut_opts = ();
	if($immutable) {
		%immut_opts = $meta->immutable_options;
		$meta->make_mutable;
	}
	
	return if ($meta->has_method('audit_take_snapshot'));
	
	$meta->add_method( audit_take_snapshot => sub {
		my $Row = shift;
		my $AuditObj = shift or die "AuditObj not supplied in argument.";
		
		my $Auditors = $Row->result_source->schema->auditors || [];
		my $found = 0;
		$_ == $AuditObj and $found = 1 for (@$Auditors);
		die "Supplied AuditObj is not an active Auditor on this Row's schema instance"
			unless ($found);
		
		my $source_name = $Row->result_source->source_name;
		my $SourceContext = $AuditObj->tracked_sources->{$source_name}
			or die "Source '$source_name' is not being tracked by the supplied Auditor";
		
		unless ($AuditObj->active_changeset) {
			$AuditObj->start_changeset;
			$AuditObj->auto_finish(1);
		}
		
		my $class = $AuditObj->change_context_class;
		my $ChangeContext = $class->new(
			AuditObj				=> $AuditObj,
			SourceContext		=> $SourceContext,
			ChangeSetContext	=> $AuditObj->active_changeset,
			Row 					=> $Row,
      new_columns   => { $Row->get_columns },
			action				=> 'select'
		);
		$ChangeContext->record;
		$AuditObj->record_changes($ChangeContext);
		return $Row;
	});
	
	$meta->add_method( audit_init => sub {
		my $Row = shift;
		my $AuditObj = shift or die "AuditObj not supplied in argument.";
		
		my $Auditors = $Row->result_source->schema->auditors || [];
		my $found = 0;
		$_ == $AuditObj and $found = 1 for (@$Auditors);
		die "Supplied AuditObj is not an active Auditor on this Row's schema instance"
			unless ($found);
			
		my $Collector = $AuditObj->collector;
		return $Row->audit_take_snapshot($AuditObj) unless ($Collector->has_full_row_stored($Row));
		return $Row;
	});
	
	# Restore immutability to the way to was:
	$meta->make_immutable(%immut_opts) if ($immutable);
}


##########
##########

# Starts a new changeset if there isn't one active:
sub start_unless_changeset {
	my $self = shift;
	return $self->active_changeset ? undef : $self->start_changeset;
}

sub start_changeset {
	my $self = shift;
	die "Cannot start_changeset because a changeset is already active" if ($self->active_changeset);
	
	my $class = $self->changeset_context_class;
	$self->active_changeset($class->new( AuditObj => $self ));
	return $self->active_changeset;
}

sub finish_if_changeset {
	my $self = shift;
	return $self->active_changeset ? $self->finish_changeset : undef;
}

has '_finishing_changeset', is => 'rw', isa => Bool, default => sub{0};
sub finish_changeset {
	my $self = shift;
	die "Cannot finish_changeset because there isn't one active" unless ($self->active_changeset);
	
	# Protect against deep recursion. This is needed for cases where the collector
	# is writing to tables within the tracked schema
	return if ($self->_finishing_changeset);
	$self->_finishing_changeset(1);
	
	unless($self->record_empty_changes) {
		my $count_cols = 0;
		$count_cols = $count_cols + scalar($_->all_column_changes) 
			for (@{$self->active_changeset->changes});
		unless ($count_cols > 0) {
			$self->clear_changeset;
			return 1;
		}
	}
	
	$self->active_changeset->finish;
	
	#####
	$self->collector->record_changes($self->active_changeset);
	#####
	
	$self->clear_changeset;
	return 1;
}

sub _exception_cleanup {
	my $self = shift;
	my $err = shift;
	$self->clear_changeset;
	$self->_current_change_group([]);
}

sub clear_changeset {
	my $self = shift;
	$self->active_changeset(undef);
	$self->auto_finish(0);
	$self->_finishing_changeset(0);
}

sub record_changes {
	my ($self, @ChangeContexts) = @_;
	
	my $local_changeset = $self->start_unless_changeset;
	
	$self->active_changeset->add_changes($_) for (@ChangeContexts);
	
	$self->finish_changeset if ($local_changeset);
}


## Change 'group' vs Change 'set'
#
# I am using the term 'group' (to distinguish from 'set') to represent a group
# of changes (rows) that are being changed within a single query/sql statement.
# (vs. set which is any number of query/sql statements grouped in a transaction)
# This should only happen from making changes via ResultSet objects instead of
# Row objects, and in these cases we normalize these into individual (row) changes
# TODO: should ChangeGroup be made into a 6th Context? For now, I think no because
# it is overkill.
##

# -- This is a glorified tmp variable used just to allow groups of changes
# to be associated with the correct auditor. TODO: This is probably a 
# poor solution to a complex scoping problem. This exposes us to the 
# risk of processing stale data, so we have to be sure (manually) to keep 
# this clear/empty outside its *very* short lifespan, by regularly resetting it
has '_current_change_group', is => 'rw', isa => ArrayRef[Object], default => sub{[]};
# --

sub _start_current_change_group {
	my ($self, $Source, $nested, $action, @changes) = @_;
	
	my $Group = $self->_current_change_group || [];
	$Group = [] unless ($nested);
	
	$self->_current_change_group($Group); # just for good measure
	
	my $source_name = $Source->source_name;
	my $func_name = $source_name . '::' . $action;
	
	return () unless ($self->tracked_action_functions->{$func_name});
	
	my @ChangeContexts = map {
		$self->_new_change_context(
			AuditObj				=> $self,
			SourceContext		=> $self->tracked_sources->{$source_name},
			ChangeSetContext	=> $self->active_changeset, # could be undef
			action				=> $action,
			$self->_validated_change_hash($_)
		)
	} @changes;
	
	push @$Group, @ChangeContexts;
	$self->_current_change_group($Group);
	return @ChangeContexts;
}

sub _validated_change_hash {
	my ($self, $data) = @_;
	
	require Data::Dumper::Concise;
	
	die "change data must be a HashRef:\n" . 
		Data::Dumper::Concise::Dumper($data) unless (ref($data) eq 'HASH');
	
	my %allowed_keys = map {$_=>1} qw(old_columns to_columns new_columns);
	
	$allowed_keys{$_} && ref($data->{$_}) eq 'HASH' or 
		die "Bad data in change hash:\n" . Data::Dumper::Concise::Dumper($data)
			for (grep { $_ ne 'condition' } keys %$data);

	return %$data;
}


sub _finish_current_change_group {
	my $self = shift;
	$self->record_changes(@{$self->_current_change_group || []});
	$self->_current_change_group([]); #<-- critical to reset!
}

# factory-like helper:
sub _new_change_context {
	my $self = shift;
	my $class = $self->change_context_class;
	return $class->new(@_);
}



1;


__END__

=head1 NAME

DBIx::Class::AuditAny - Flexible change tracking framework for L<DBIx::Class>

=begin HTML

<a href='https://coveralls.io/r/vanstyn/DBIx-Class-AuditAny?branch=master'>
  <img 
       src='https://coveralls.io/repos/vanstyn/DBIx-Class-AuditAny/badge.svg?branch=master' 
       alt='Coverage Status' 
   />
</a>

=end HTML

=head1 SYNOPSIS

 my $schema = My::Schema->connect(@connect);

 use DBIx::Class::AuditAny;

 my $Auditor = DBIx::Class::AuditAny->track(
   schema => $schema, 
   track_all_sources => 1,
   collector_class => 'Collector::AutoDBIC',
   collector_params => {
     sqlite_db => 'db/audit.db',
   }
 );

=head1 DESCRIPTION

This module provides a generalized way to track changes to DBIC databases. The aim is 
to provide quick/turn-key options to be able to hit the ground running, while also 
being highly flexible and customizable with sane APIs. 

C<DBIx::Class::AuditAny> wants to be a general framework on top of which other Change 
Tracking modules for DBIC can be written, while also providing fully fleshed, end-user
solutions that can be dropped in and work out-of-the-box.

=head2 Background

This module was originally written in 2012 for an internal client project, and the process
of getting it released open-source as a stand-alone, general-purpose module was started in
2013. However, I got busy with other projects and wasn't able to complete a CPAN release at 
that time (mainly due to missing docs and minor loose ends). I finally came back to this 
project (May 2015) to actually get a release out to CPAN. So, even though the release date 
is in 2015, the majority of the code is actually several years old (and has been running 
perfectly in production for several client apps the whole time).


=head2 API and Usage

AuditAny uses a different API than typical DBIC components. Instead of loading at the 
schema/result class level with C<load_components>, AuditAny is used by attaching an 
"Auditor" to an existing schema I<object> instance:

 my $schema = My::Schema->connect(@connect);
 
 my $Auditor = DBIx::Class::AuditAny->track(
   schema => $schema, 
   track_all_sources => 1,
   collector_class => 'Collector::AutoDBIC',
   collector_params => {
     sqlite_db => 'db/audit.db',
   }
 );

The rationale of this approach is that change tracking isn't necessarily something that 
needs to be, or should be, defined as a built-in attribute of the schema class. 
Additionally, because of the object-based approach, it is possible to attach multiple 
Auditors to a single schema object with multiple calls to DBIx::Class::AuditAny->track.

=head1 DATAPOINTS

As changes occur in the tracked schema, information is collected in the form of 
I<datapoints> at various stages - or I<contexts> - before being passed to the
configured Collector. A datapoint has a globally unique name and code used to calculate
its value. Code is called at the stage defined by the I<context> of the datapoint. 
The available contexts are:

=over 4

=item set

=over 5

=item base

=back

=item change

=over 5

=item source

=back

=item column


=back

B<set> (AKA changeset) datapoints are specific to an entire set of changes - insert/
update/delete statements grouped in a transaction. Example changeset datapoints include
C<changeset_ts> and other broad items. B<base> datapoints are logically the same as 
B<set> but only need to be calculated once (instead of with every change set). These 
include things like C<schema> and C<schema_ver>. 

B<change> datapoints apply to a specific C<insert>, C<update> or C<delete> statement, 
and range from simple items such as C<action> (one of 'insert', 'update' or 'delete') 
to more exotic and complex items like C<column_changes_json>. B<source> datapoints are 
logically the same as B<change>, but like B<base> datapoints, only need to be 
calculated once (per source). These include things like C<table_name> and C<source> 
(source name).

Finally, B<column> datapoints cover information specific to an individual column, such 
as C<column_name>, C<old_value> and C<new_value>.

There are a number of built-in datapoints (currently stored in 
L<DBIx::Class::AuditAny::Util::BuiltinDatapoints> which is likely to change), but custom
datapoints can also be defined. The Auditor config defines a specific set of datapoints to 
be calculated (built-in and/or custom). If no datapoints are specified, the default list is used 
(currently C<change_ts, action, source, pri_key_value, column_name, old_value, new_value>).

The list of datapoints is specified as an ArrayRef in the config. For example:

 datapoints => [qw(action_id column_name new_value)],

=head2 Custom Datapoints

Custom datapoints are specified as HashRef configs with 3 parameters:

=over 4

=item name

The unique name of the datapoint. Should be all lowercase letters, numbers and 
underscore and must be different from all other datapoints (across all contexts).

=item context

The context of the datapoint: base, source, set, change or column.

=item method

CodeRef to calculate and return the value. The CodeRef is called according to the 
context, and a different context object is supplied for each context. Each context has 
its own context object type except B<base> which is supplied the Auditor object itself.
See Audit Context Objects below.

=back


Custom datapoints are defined in the C<datapoint_configs> param. After defining a new 
datapoint config it can then be used like any other datapoint. For example:

 datapoints => [qw(action_id column_name new_value client_ip)],
 datapoint_configs => [
   {
     name => 'client_ip',
     context => 'set',
     method => sub {
       my $contextObj = shift;
       my $c = some_func(...);
       return $c->req->address; 
     }
   }
 ]

=head2 Datapoint Names

Datapoint names must be unique, which means all the built-in datapoint names are 
reserved. However, if you really want to use an existing datapoint name, or if you want
 a built-in datapoint to use a different name, you can rename any datapoints like so:

 rename_datapoints => {
   new_value => 'new',
   old_value => 'old',
   column_name => 'column',
 },

=head1 COLLECTORS

Once the Auditor calculates the configured datapoints it passes them to the configured 
I<Collector>. There are several built-in Collectors provided, but writing a custom Collector
is a trivial matter. All you need to do is write a L<Moo>-compatible class which consumes
the L<DBIx::Class::AuditAny::Role::Collector> role and implement a C<record_changes()> method.
This method is called with a L<ChangeSet|DBIx::Class::AuditAny::AuditContext::ChangeSet> object
supplied as the argument at the end of every database transaction which performs a write operation. 

No matter how small or large the transaction, the ChangeSet object provides APIs to a nested 
structure to be able to access all information regarding what changed during the given transaction.
(See L<AUDIT CONTEXT OBJECTS|DBIx::Class::AuditAny#AUDIT_CONTEXT_OBJECTS> below).


=head2 Supplied Collector Classes

The following built-in collector classes are already provided:

=over

=item *

L<DBIx::Class::AuditAny::Collector::AutoDBIC>

=item *

L<DBIx::Class::AuditAny::Collector::DBIC>

=item *

L<DBIx::Class::AuditAny::Collector::Code>

=back

=head1 AUDIT CONTEXT OBJECTS

Inspired in part by the Catalyst Context object design, the internal machinery which captures and
organizes the change datapoints associated with a modifying transaction is wrapped in a nested 
structure of 3 kinds of "context" objects:

=over

=item *

L<DBIx::Class::AuditAny::AuditContext::ChangeSet>

=item *

L<DBIx::Class::AuditAny::AuditContext::Change>

=item *

L<DBIx::Class::AuditAny::AuditContext::Column>

=back

This provides a clean and straightforward API for which Collector classes are able to identify and 
act on the data in any manner they want, be it recording to a database, logging to a simple file, 
or taking any kind of programmatic action. Collectors can really be thought of as a structure for 
powerful external triggers.

=head1 ATTRIBUTES

Note: Documentation of all the individual attrs and methods of this class (shown below) is still 
TBD. However, most meaningful scenarios involving interacting with these is already covered above, 
or is covered further down in the L<Examples|DBIx::Class::AuditAny#EXAMPLES>.

=head2 datapoints

=head2 allow_multiple_auditors

=head2 auto_include_user_defined_datapoints

=head2 build_init_args

=head2 calling_action_function

=head2 change_context_class

=head2 changeset_context_class

=head2 collector_class

=head2 collector_params

=head2 column_context_class

=head2 datapoint_configs

=head2 default_datapoint_class

=head2 disable_datapoints

=head2 primary_key_separator

=head2 record_empty_changes

=head2 rename_datapoints

=head2 schema

=head2 source_context_class

=head2 time_zone

=head2 track_actions

=head2 track_immutable

=head2 track_init_args

=head2 tracked_action_functions

=head2 tracked_sources

=head1 METHODS

=head2 get_dt

=head2 track

=head2 get_datapoint_orig

=head2 add_datapoints

=head2 all_datapoints

=head2 get_context_datapoint_names

=head2 get_context_datapoints

=head2 local_datapoint_data

=head2 track_sources

=head2 track_all_sources

=head2 init_all_sources

Calls C<init_sources> with all tracked source names

=head2 init_sources

Special-purpose method to initialize rows for the case of starting auditing a database with
existing data. This will simulate changes with the special C<'select'> action. This is useful
to be able to use the audit database to follow changes backward to a starting point, and having
that state fully recorded, just as if auditing had been enabled when the rows were inserted.

This method accepts a list of source names and makes sure that every row of each source is 
initialized. So, be careful, as this can be a very heavy operation depending on the number
of rows. This is a tool that would generally only be used interactively during a new setup.

=head2 start_unless_changeset

=head2 start_changeset

=head2 finish_changeset

=head2 finish_if_changeset

=head2 clear_changeset

=head2 record_changes


=head1 EXAMPLES

=head3 simple dedicated audit db

Record all changes into a *separate*, auto-generated and initialized SQLite schema/db 
with default datapoints (Quickest/simplest usage - SYNOPSIS example):

Uses the Collector L<DBIx::Class::AuditAny::Collector::AutoDBIC>

 my $schema = My::Schema->connect(@connect);

 use DBIx::Class::AuditAny;

 my $Auditor = DBIx::Class::AuditAny->track(
   schema => $schema, 
   track_all_sources => 1,
   collector_class => 'Collector::AutoDBIC',
   collector_params => {
     sqlite_db => 'db/audit.db',
   }
 );

=head3 recording to the same db

Record all changes - into specified target sources within the *same*/tracked 
schema - using specific datapoints:

Uses the Collector L<DBIx::Class::AuditAny::Collector::DBIC>

 DBIx::Class::AuditAny->track(
   schema => $schema, 
   track_all_sources => 1,
   collector_class => 'Collector::DBIC',
   collector_params => {
     target_source => 'MyChangeSet',      # ChangeSet source name
     change_data_rel => 'changes',        # Change source, via rel within ChangeSet
     column_data_rel => 'change_columns', # ColumnChange source, via rel within Change
   },
   datapoints => [ # predefined/built-in named datapoints:
     (qw(changeset_ts changeset_elapsed)),
     (qw(change_elapsed action source pri_key_value)),
     (qw(column_name old_value new_value)),
   ],
 );
 

=head3 coderef collector to a file

Dump raw change data for specific sources (Artist and Album) to a file,
ignore immutable flags in the schema/result classes, and allow more than 
one DBIx::Class::AuditAny Auditor to be attached to the same schema object:

Uses 'collect' sugar param to setup a bare-bones CodeRef Collector 
(L<DBIx::Class::AuditAny::Role::Collector>)

 my $Auditor = DBIx::Class::AuditAny->track(
   schema => $schema, 
   track_sources => [qw(Artist Album)],
   track_immutable => 1,
   allow_multiple_auditors => 1,
   collect => sub {
     my $cntx = shift;      # ChangeSet context object
     require Data::Dumper;
     print $fh Data::Dumper->Dump([$cntx],[qw(changeset)]);
     
     # Do other custom stuff...
   }
 );

=head3 more customizations

Record all updates (but *not* inserts/deletes) - into specified target sources 
within the same/tracked schema - using specific datapoints, including user-defined 
datapoints and built-in datapoints with custom names:

 DBIx::Class::AuditAny->track(
   schema => CoolCatalystApp->model('Schema')->schema, 
   track_all_sources => 1,
   track_actions => [qw(update)],
   collector_class => 'Collector::DBIC',
   collector_params => {
     target_source => 'MyChangeSet',      # ChangeSet source name
     change_data_rel => 'changes',        # Change source, via rel within ChangeSet
     column_data_rel => 'change_columns', # ColumnChange source, via rel within Change
   },
   datapoints => [
     (qw(changeset_ts changeset_elapsed)),
     (qw(change_elapsed action_id table_name pri_key_value)),
     (qw(column_name old_value new_value)),
   ],
   datapoint_configs => [
     {
       name => 'client_ip',
       context => 'set',
       method => sub {
         my $c = some_func(...);
         return $c->req->address; 
       }
     },
     {
       name => 'user_id',
       context => 'set',
       method => sub {
         my $c = some_func(...);
         $c->user->id;
       }
     }
   ],
   rename_datapoints => {
     changeset_elapsed => 'total_elapsed',
     change_elapsed => 'elapsed',
     pri_key_value => 'row_key',
     new_value => 'new',
     old_value => 'old',
     column_name => 'column',
   },
 );


=head3 user-defined collector

Record all changes into a user-defined custom Collector class - using
default datapoints:

 my $Auditor = DBIx::Class::AuditAny->track(
   schema => $schema, 
   track_all_sources => 1,
   collector_class => '+MyApp::MyCollector',
   collector_params => {
     foo => 'blah',
     anything => $val
   }
 );

=head3 query the audit db

Access/query the audit db of Collector::DBIC and Collector::AutoDBIC collectors:

 my $audit_schema = $Auditor->collector->target_schema;
 $audit_schema->resultset('AuditChangeSet')->search({...});
 
 # Print the ddl that auto-generated and deployed with a Collector::AutoDBIC collector:
 print $audit_schema->resultset('DeployInfo')->first->deployed_ddl;

=head2 more examples

See the unit tests (which are extensive) for more examples.


=head1 TODO

=over

=item *

Enable tracking multi-primary-key sources (code currently disabled)

=item *

Write more tests 

=item *

Write more documentation

=item *

Add more built-in datapoints

=item *

Expand the Collector API to be able to provide datapoint configs

=item *

Separate set/change/column datapoints into 'pre' and 'post' stages

=item *

Add mechanism to enable/disable tracking (localizable global?)

=item *

Switch to use L<Types::Standard>

=back

=head1 SIMILAR MODULES

=head2 DBIx::Class::Journal

L<DBIx::Class::Journal> was the first DBIC change tracking module released to CPAN. It works,
but is inflexible and mandates a single mode of operation, which is not ideal in many ways.

=head2 DBIx::Class::AuditLog

L<DBIx::Class::AuditLog> takes a more casual approach than L<DBIx::Class::Journal>, which makes
it easier to work with. However, it still forces a narrow and specific manner in which it stores
the change history data which doesn't fit all workflows.

AuditAny was designed specifically for flexibility. By separating the I<Auditor> - which captures the
change data as it happens - from the I<Collector>, which handles storing the data, all sorts of 
different styles and manners of formatting and storing the audit data can be achieved. In fact,
L<DBIx::Class::AuditLog> could be written using AuditAny, and store the data in exactly the same 
manner by implementing a custom collector class.

=head2 DBIx::Class::Shadow

Shadow is a different animal. It is very sophisticated, and places accuracy above all else, with the
idea of being able to do things such as reliably "revive" the previous state of rows, etc. The 
downside of this is that it is also not flexible, in that it handles the entire change life cycle 
within its logic. This is different from AuditAny, which is more like a packet capture lib for DBIC 
(like tcpdump/libpcap is a packet capture lib for networks). Unlike the others, Shadow could B<not> 
be implemented using AuditAny, because the I<way> it captures the change data is specific and 
fundamentally different.

Unfortunately, DBIx::Class::Shadow is unfinished and has never been released to CPAN (as of the time
of this writing, in May 2015). Its current, unfinished status can be seen in GitHub:

=over

=item *

L<https://github.com/ribasushi/preshadow>

=back


=head1 SUPPORT
 
IRC:
 
    Join #rapidapp on irc.perl.org.

=head1 AUTHOR

Henry Van Styn <vanstyn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012-2016 by IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

