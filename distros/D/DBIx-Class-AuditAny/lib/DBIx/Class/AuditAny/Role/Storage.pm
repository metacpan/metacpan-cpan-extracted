package DBIx::Class::AuditAny::Role::Storage;
use strict;
use warnings;

# ABSTRACT: Role to apply to tracked DBIx::Class::Storage objects

use Moo::Role;
use MooX::Types::MooseLike::Base qw(:all);

## TODO:
##  1. track rekey in update
##  2. track changes in FK with cascade


=head1 NAME

DBIx::Class::AuditAny::Role::Storage - Role to apply to tracked DBIx::Class::Storage objects

=head1 DESCRIPTION

This role adds the hooks to the DBIC Storage object to be able to sniff and collect change data
has it happens in real time.

=cut

use strict;
use warnings;
use Try::Tiny;
use DBIx::Class::AuditAny::Util;
use Term::ANSIColor qw(:constants);


=head1 REQUIRES

=head2 txn_do

=head2 insert

=head2 update

=head2 delete

=head2 insert_bulk

=cut
requires 'txn_do';
requires 'insert';
requires 'update';
requires 'delete';
requires 'insert_bulk';

=head1 ATTRIBUTES

head2 auditors

List of Auditor objects which we are collecting data for. Typically there will be only one
Auditor, but there can be many, allowing for data to be logged to a file by one, logged in
a database by another, and then some other random watcher which takes some action when a 
certain event is detected. All of these can run simultaneously, and receive the sniffed data
which we will collect only once.
=cut
has 'auditors', is => 'ro', lazy => 1, default => sub {[]};


=head1 METHODS

=head2 all_auditors

Returns a list of all configured Auditor objects
=cut
sub all_auditors { @{(shift)->auditors} }

=head2 auditor_count

The number of configured auditors
=cut
sub auditor_count { scalar (shift)->all_auditors }

=head2 add_auditor

Adds a new Auditor object(s) to report to
=cut
sub add_auditor { push @{(shift)->auditors},(shift) }


before 'txn_begin' => sub {
	my $self = shift;
  return if ($ENV{DBIX_CLASS_AUDITANY_SKIP});
	$_->start_unless_changeset for ($self->all_auditors);
};

# txn_commit
# Note that we're hooking into -before- txn_commit rather than
# -after- which would conceptually make better sense. The reason
# is that we provide for the ability for collectors that store
# their change data within the same schema being tracked, which
# means the stored data will end up being a part of the same 
# transaction, thus hooking into after on the outermost commit
# could cause deep recursion. 
# TODO/FIXME: What about collectors that
# *don't* do this, and an exception occurring within that final
# commit??? It could possibly lead to recording a change that
# didn't actually happen (i.e. was rolled back). I think the way
# to handle this is for the collector to declare if it is storing
# to the tracked schema or not, and handle each case differently
before 'txn_commit' => sub {
	my $self = shift;
	
	# Only finish in the outermost transaction
	if($self->transaction_depth == 1) {
		$_->finish_if_changeset for ($self->all_auditors);
	}
};

around 'txn_rollback' => sub {
	my ($orig, $self, @args) = @_;
	
	my @ret;
	my $want = wantarray;
	try {
		#############################################################
		# ---  Call original - scalar/list/void context agnostic  ---
		@ret = !defined $want ? do { $self->$orig(@args); undef }
			: $want ? $self->$orig(@args)
				: scalar $self->$orig(@args);
		# --- 
		#############################################################
	}
	catch {
		my $err = shift;
		$_->_exception_cleanup($err) for ($self->all_auditors);
		die $err;
	};
	
	# Should never get here because txn_rollback throws an exception
	# per-design. But, we still handle the case for good measure:
	$_->_exception_cleanup('txn_rollback') for ($self->all_auditors);
	
	return $want ? @ret : $ret[0];
};


# insert is the most simple. Always applies to exactly 1 row:
around 'insert' => sub {
	my ($orig, $self, @args) = @_;
  return $self->$orig(@args) if ($ENV{DBIX_CLASS_AUDITANY_SKIP});
  
	my ($Source, $to_insert) = @args;
	
	# Start new insert operation within each Auditor and get back
	# all the created ChangeContexts from all auditors. The auditors
	# will keep track of their own changes temporarily in a "group":
	my @ChangeContexts = map { 
		$_->_start_current_change_group($Source, 0,'insert',{
			to_columns => $to_insert 
		})
	} $self->all_auditors;
	
	my @ret;
	my $want = wantarray;
	try {
		#############################################################
		# ---  Call original - scalar/list/void context agnostic  ---
		@ret = !defined $want ? do { $self->$orig(@args); undef }
			: $want ? $self->$orig(@args)
				: scalar $self->$orig(@args);
		# --- 
		#############################################################
	}
	catch {
		my $err = shift;
		$_->_exception_cleanup($err) for ($self->all_auditors);
		die $err;
	};
	
	# Update each ChangeContext with the result data:
	$_->record($ret[0]) for (@ChangeContexts);
	
	# Tell each auditor that we're done and to record the change group
	# into the active changeset:
	$_->_finish_current_change_group for ($self->all_auditors);
	
	return $want ? @ret : $ret[0];
};


### TODO: ###
# insert_bulk is a tricky case. It exists for the purpose of performance,
# and skips reading back in the inserted row(s). BUT, we need to read back
# in the inserted row, and we have no safe way of doing that with a bulk
# insert (auto-generated auto-inc keys, etc). DBIC was already designed with
# with this understanding, and so insert_bulk is already only called when 
# no result is needed/expected back: DBIx::Class::ResultSet->populate() called
# in *void* context. 
#
# Based on this fact, I think that the only rational way to be able to
# Audit the inserted rows is to override and convert any calls to insert_bulk()
# into calls to regular calls to insert(). Interfering with the original
# flow/operation is certainly not ideal, but I don't see any alternative.
around 'insert_bulk' => sub {
	my ($orig, $self, @args) = @_;
  return $self->$orig(@args) if ($ENV{DBIX_CLASS_AUDITANY_SKIP});
  
	my ($Source, $cols, $data) = @args;
	
	#
	# TODO ....
	#
	
	my @ret;
	my $want = wantarray;
	try {
		#############################################################
		# ---  Call original - scalar/list/void context agnostic  ---
		@ret = !defined $want ? do { $self->$orig(@args); undef }
			: $want ? $self->$orig(@args)
				: scalar $self->$orig(@args);
		# --- 
		#############################################################
	}
	catch {
		my $err = shift;
		$_->_exception_cleanup($err) for ($self->all_auditors);
		die $err;
	};

	return $want ? @ret : $ret[0];
};


has '_change_contexts', is => 'rw', isa => ArrayRef[Object], lazy => 1, default => sub {[]};
sub _add_change_contexts { push @{shift->_change_contexts},@_ }

sub _follow_row_changes($$) {
  my $self = shift;
  my $cnf = shift;
  
  my $Source = $cnf->{Source};
  my $change = $cnf->{change};
  my $cond = $cnf->{cond};
  my $action = $cnf->{action};
  
  my $orig = $cnf->{method};
  my $args = $cnf->{args} || [];
  my $want = $cnf->{want} || wantarray;
  my $rows = $cnf->{rows};
  my $nested = $cnf->{nested} || 0;
  
  my $source_name = $Source->source_name;
  
  $self->_change_contexts([]) unless ($nested);
  
  # Get the current rows if they haven't been supplied and a
  # condition has been supplied ($cond):
  $rows = get_raw_source_rows($Source,$cond)
    if (!defined $rows && defined $cond);

	my @change_datam = map {{
		old_columns => $_,
		to_columns => $change,
		condition => $cond
	}} @$rows;
	
	
  # Start new change operation within each Auditor and store the 
	# created ChangeContexts (from all auditors) in the _change_contexts. 
  # attribute to be updated and recorded at the end of the update. The 
  # auditors will keep track of their own changes temporarily in a "group":
  $self->_add_change_contexts(
    map {
      $_->_start_current_change_group($Source, $nested, $action, @change_datam)
    } $self->all_auditors
  );
  
  # -----
  # Recursively follow effective changes in other tables that will 
  # be caused by any db-side cascades defined in relationships:
  $self->_follow_relationship_cascades($Source,$cond,$change);
  # -----
  
	# Run the original/supplied method:
	my @ret;
  if($orig) {
    try {
      #############################################################
      # ---  Call original - scalar/list/void context agnostic  ---
      @ret = !defined $want ? do { $self->$orig(@$args); undef }
        : $want ? $self->$orig(@$args)
          : scalar $self->$orig(@$args);
      # --- 
      #############################################################
    }
    catch {
      my $err = shift;
      $_->_exception_cleanup($err) for ($self->all_auditors);
      die $err;
    };
  }
  
	# Tell each auditor that we're done and to record the change group
	# into the active changeset (unless the action we're following is nested):
  unless ($nested) {
    $self->_record_change_contexts;
    $_->_finish_current_change_group for ($self->all_auditors);
  }
	
	return $want ? @ret : $ret[0];
}


sub _follow_relationship_cascades {
  my ($self, $Source, $cond, $change) = @_;
  
  ## IN PROGRESS.....
  
  # If any of these columns are being changed, we have to also watch the
  # corresponding relationhips for changes (from cascades) during the
  # course of the current database operation. This can be expensive, but
  # we prefer accuracy over speed
  my $cascade_cols = $self->_get_cascading_rekey_columns($Source);
  
  # temp: just get all of themfor now
  #  this should be limited to only rels associated with columns
  #  being changed
  my @rels = uniq(map { @{$cascade_cols->{$_}} } keys %$cascade_cols);
  
  foreach my $rel (@rels) {
    my $rinfo = $Source->relationship_info($rel);
    #my $rrinfo = $Source->reverse_relationship_info($rel);
    
    # Generate a virtual 'change' to describe what will happen in the related table
    my $map = &_cond_foreign_keymap($rinfo->{cond});
    my $rel_change = {};
    foreach my $col (keys %$change) {
      my $fcol = $map->{$col} or next;
      $rel_change->{$fcol} = $change->{$col};
    }
     
    # Only track related rows if there is at least one related change:
    if(scalar(keys %$rel_change) > 0) {
      # Get related rows that will be changed from the cascade:
      my $rel_rows = get_raw_source_related_rows($Source,$rel,$cond);
      
      # Follow these rows via special nested call:
      $self->_follow_row_changes({
        Source => $Source->related_source($rel),
        rows => $rel_rows,
        cond => {},
        nested => 1,
        action => 'update',
        change => $rel_change
      }) if(scalar @$rel_rows > 0);
    }
  }
}


# Builds a map that can be used to convert column names into
# their fk name on the other side of a relationship
sub _cond_foreign_keymap {
  my $cond = shift;
  my $alias = shift;
  
  my $map = {};
  
  # TODO: doesn't support all valid conditions, but *DOES*
  # support those that can express a valid db-side CASCADE, 
  # which is what this is for:
  foreach my $k (keys %$cond) {
    my @f = ($k,$cond->{$k});
    my $d = {};
    $d->{$_->[0]} = $_->[1] for (map {[split(/\./,$_,2)]} @f);
    
    die "error parsing condition" 
      unless (exists $d->{foreign} && exists $d->{self});
      
    $map->{$d->{self}} = $d->{foreign};
  }
  return $map;
}



sub _record_change_contexts {
  my $self = shift;
  
	# Fetch the new values for -each- row, independently. 
	# Build a condition specific to this row and fetch it, 
	# taking into account the change that was just made, and
	# then record the new columns in the ChangeContext:
	foreach my $ChangeContext (@{$self->_change_contexts}) {
    my $Source = $ChangeContext->SourceContext->ResultSource;
    # Get the primry keys, or all columns if there are none:
    my @pri_cols = $Source->primary_columns;
    @pri_cols = $Source->columns unless (scalar @pri_cols > 0);
    
    my $change = $ChangeContext->to_columns;
    my $old = $ChangeContext->old_columns;
		
    # TODO: cache the new columns to prevent duplicate fetches for multiple auditors
		my $new_rows = get_raw_source_rows($Source,{ map {
			$_ => (exists $change->{$_} ? $change->{$_} : $old->{$_})
		} @pri_cols });
		
		# TODO/FIXME: How should we handle it if we got back 
		# something other than exactly one row here?
		die "Unexpected error while trying to read updated row" 
			unless (scalar @$new_rows == 1);
			
		my $new = pop @$new_rows;
		$ChangeContext->record($new);
	}
  
  # Clear:
  $self->_change_contexts([]);
}


around 'update' => sub {
	my ($orig, $self, @args) = @_;
  return $self->$orig(@args) if ($ENV{DBIX_CLASS_AUDITANY_SKIP});
  
	my ($Source,$change,$cond) = @args;
  
  return $self->_follow_row_changes({
    Source => $Source,
    change => $change,
    cond => $cond,
    method => $orig,
    action => 'update',
    args => \@args,
    want => wantarray
  });
};

around 'delete' => sub {
	my ($orig, $self, @args) = @_;
  return $self->$orig(@args) if ($ENV{DBIX_CLASS_AUDITANY_SKIP});
  
	my ($Source, $cond) = @args;
	
	# Get the current rows that are going to be deleted:
	my $rows = get_raw_source_rows($Source,$cond);
	
	my @change_datam = map {{
		old_columns => $_,
		condition => $cond
	}} @$rows;
	
	###########################
	# TODO: find cascade deletes here
	###########################
	
	
	# Start new change operation within each Auditor and get back
	# all the created ChangeContexts from all auditors. Each auditor
	# will keep track of its own changes temporarily in a "group":
	my @ChangeContexts = map {
		$_->_start_current_change_group($Source, 0,'delete', @change_datam)
	} $self->all_auditors;
	
	
	# Do the actual deletes:
	my @ret;
	my $want = wantarray;
	try {
		#############################################################
		# ---  Call original - scalar/list/void context agnostic  ---
		@ret = !defined $want ? do { $self->$orig(@args); undef }
			: $want ? $self->$orig(@args)
				: scalar $self->$orig(@args);
		# --- 
		#############################################################
	}
	catch {
		my $err = shift;
		$_->_exception_cleanup($err) for ($self->all_auditors);
		die $err;
	};
	
	
	# TODO: should we go back to the db to make sure the rows are
	# now gone as expected?
	
	$_->record for (@ChangeContexts);
	
	# Tell each auditor that we're done and to record the change group
	# into the active changeset:
	$_->_finish_current_change_group for ($self->all_auditors);
	
	return $want ? @ret : $ret[0];
};



# _get_cascading_rekey_cols: gets a map of column names to relationships. These
# are the relationships that *could* be changed via a cascade when the column (fk)
# is changed.
# TODO: use 'cascade_rekey' attr from DBIx::Class::Shadow 
#  (DBIx::Class::Relationship::Cascade::Rekey) ?
sub _get_cascading_rekey_columns {
	my $self = shift;
	my $Source = shift;
	
	# cache for next time (should I even bother? since if rels are added to the ResultSource
	# later this won't get updated? Is that a bigger risk than the performance boost?)
	$self->_source_cascade_rekey_cols->{$Source->source_name} ||= do {
		my $rels = { map { $_ => $Source->relationship_info($_) } $Source->relationships };
		
		my $cascade_cols = {};
		foreach my $rel (keys %$rels) {
			# Only multi rels apply:
			next unless ($rels->{$rel}{attrs}{accessor} eq 'multi');
      
      # NEW: We can't currently do anything with CodeRef conditions
      next if ((ref($rels->{$rel}{cond})||'') eq 'CODE');
			
			# Get all the local columns that effect (i.e. might cascade to) this relationship:
			my @cols = $self->_parse_cond_cols_by_alias($rels->{$rel}{cond},'self');
			
			# Add the relationship to list for each column.
			#$cascade_cols->{$_} ||= [] for (@cols); #<-- don't need this
			push @{$cascade_cols->{$_}}, $rel for (@cols);
		}
	
		return $cascade_cols;
	};
	
	return $self->_source_cascade_rekey_rels->{$Source->source_name};
}

has '_source_cascade_rekey_cols', is => 'ro', isa => HashRef, lazy => 1, default => sub {{}};

sub _parse_cond_cols_by_alias {
	my $self = shift;
	my $cond = shift;
	my $alias = shift;
	
	# Get the string elements (keys and values)
	# (TODO: deep walk any hahs/array structure)
	my @elements = %$cond;
	
	ref($_) and die "Complex conditions aren't supported yet" for (@elements);
	
	my @cols = map { $_->[1] } # <-- 3. just the column names
		# 2. exclude all but the alias name we want
		grep { $_->[0] eq $alias } 
			# 1. Convert all the element strings into alias/column pairs
			map { [split(/\./,$_,2)] } @elements;
	
	return @cols;
}


=head2 changeset_do

TODO... currently is just a wrapper around a native txn_do call. Not sure what this is meant
to do...
=cut
sub changeset_do {
	my $self = shift;
	
	# TODO ...
	return $self->txn_do(@_);
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
