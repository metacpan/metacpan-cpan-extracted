# ============================================================================
package DBIx::Class::DeleteAction;
# ============================================================================
use strict;
use warnings;

use base qw(DBIx::Class);

use version;
our $AUTHORITY = 'cpan:MAROS';
our $VERSION = version->new("1.05");

=encoding utf8

=head1 NAME

DBIx::Class::DeleteAction - Define delete triggers

=head1 SYNOPSIS

 # Actor DBIC class
 package Your::Schema::Actor;
 use strict;
 use warnings;
 
 use base 'DBIx::Class';

 __PACKAGE__->load_components("DeleteAction","PK","Core");
 
 __PACKAGE__->table("actor");
 __PACKAGE__->add_columns(qw/id name/);
 __PACKAGE__->set_primary_key('id');
 
 __PACKAGE__->has_many(
    'actorroles' => 'MyDB::Schema::ActorRole',
    { 'foreign.actor' => 'self.id' },
    { delete_action => 'delete' }
 );
 
 # Actor Role DBIC class
 package Your::Schema::ActorRole;
 use strict;
 use warnings;
 
 use base 'DBIx::Class';
 
 __PACKAGE__->load_components("DeleteAction","PK","Core");
 
 __PACKAGE__->table("actor_role");
 __PACKAGE__->add_columns(qw/id name actor production/);
 __PACKAGE__->set_primary_key('id');
 
 __PACKAGE__->belongs_to(
    'actor' => 'MyDB::Schema::Actor',
    { 'foreign.id' => 'self.actor' },
    { delete_action => 
        sub {
            my ($self,$params) = @_;
            # Do something special
        } 
    }
 );
 
 __PACKAGE__->belongs_to(
    'production' => 'MyDB::Schema::Production',
    { 'foreign.id' => 'self.production' },
    { delete_action => 'deny' }
 );
 
 # Somewhere else
 $schema->txn_do(sub {
    $actor->delete();    
 });
 # Deletes all related actorroles only if they don't have a production
 # Finally deletes the actor itself (Always use transactions!!!)
 
 $schema->txn_do(sub {
    $actor_role->delete();    
 });
 # Calls custom subroutine on actor
 # Denies deletion if a production is related

=head1 DESCRIPTION

With this DBIx::Class component you can specify actions that should be
triggered on a row delete. A delete action is specified by adding the
'delete_action' key to the optional attribute HASH reference when specifing
a new relation (see L<DBIx::Class::Relationship>).

The following delete actions are supported:

=over

=item * null

Set all columns in related rows pointing to this record to NULL. Only works
on 'has_many' relationships.

=item * delete OR cascade

Delete all related records one by one. This can trigger further delete 
actions.

=item * deleteall

Delete all related records in a single step. This does not trigger further 
delete actions.

Only works on 'has_many' relationships.

=item * deny

Deny deletion if this record is being referenced from other rows.

=item * CODE reference

Executes the code referece on delete. The current L<DBIx::Class::Row> object 
and the name of the relation are passed to the code reference.

=item * STRING

Execute a method with the given name. The method will be called on the current
L<DBIx::Class::Row> object and will be passed the name of the relation.

=item * ignore

Do nothing

=back

=head2 Custom delete handlers

If you set the C<delete_action> to execute a method or a code reference the
method will be called with the following parameters:

=over

=item * $self

The L<DBIx::Class::Row> object the delete action has been called upon.

=item * HASHREF

A hashref of named parameters

=over

=item * relationship

The name of the relationship that is currently being processed.

=item * related

The related object(s) for the given object and relationship.

Depending on the type of the relationship this can either be a 
L<DBIx::Class::Row> or a L<DBIx::Class::ResultSet> object.

=item * seen 

An arraryref with object identifiers which have already been processed.
If you want to call another L<delete> method from your code you MUST
pass on this variable so that we can ensure that each object/row is handled
only once. 

=item * Extra values

Any other values that you pass to 'delete'.

=back

=back

=head2 delete

 $object->delete();
 OR
 $object->delete(HASHREF);

This method overdrives the L<DBIx::Class::Row> delete method. You can
add arbitrary data as HASHREF which will be passed to your custom
delete handles. 

Make sure that you ALWAYS call C<delete> always inside a TRANSACTION 
block. 

If you call another C<delete> from within a custom delete handler always pass 
on the C<seen> parameter.

=cut

sub _delete_action_identifier {
    my $self = shift;
    my @primary = $self->primary_columns;
    return ref($self) . join '|',map { $self->get_column($_) || '' } @primary;
}

sub delete {
    my ($self,$params) = @_;

    $params ||= {};
    $params->{seen} ||= [];
    
    # Ignore Class deletes. DBIx::Class::Relationship::CascadeActions
    # does too so why should I bother?
    return $self->next::method($params) 
        unless ref $self && $self->isa('DBIx::Class::Row');

    my $debug = $self->result_source->storage->debug();
    
    my $identifier = $self->_delete_action_identifier;
       
    # Check for identifier
    return if (grep { $identifier eq $_ } @{$params->{seen}});
    
    push @{$params->{seen}},$identifier;

    # Check if item is in the database before we proceed
    $self->throw_exception( "Not in database" ) 
        unless $self->in_storage;
    
    my $source = $self->result_source;

    # Loop all relations
    RELATIONSHIP: foreach my $relationship ($source->relationships) {
        my $relationship_info = $source->relationship_info($relationship);
         
        # Ignore relation with no 'delete_action' key set
        next RELATIONSHIP
            unless $relationship_info->{attrs}{delete_action};
         
        # Unset DBIC key cascade_delete attribute, so that we do not
        # work twice
        $relationship_info->{attrs}{cascade_delete} = 0;
          
        # Get delete action parameter value
        my $delete_action = $relationship_info->{attrs}{delete_action};

        next RELATIONSHIP 
            if $delete_action eq 'ignore';
        
        my $related;
        # Only get relations with data
        if ($relationship_info->{attrs}{accessor} eq 'multi') {
            $related = $self->search_related($relationship);
            next RELATIONSHIP
                unless $related;
        } else {
            CONDITIONS:
            foreach my $condition (values %{$relationship_info->{cond}}) {
                if ($condition =~ m/^self\.(.+)/) {
                    my $column = $1;
                    next RELATIONSHIP
                        unless $self->get_column($column);
#                    unless ($self->has_column_loaded($column)) {
#                        warn("LOAD $column");
#                        $self = $self->get_from_storage();
#                        next RELATIONSHIP
#                            unless $self->get_column($column);
#                        last CONDITIONS;
#                    }
                }
            }

            $related = $self->$relationship;
            next RELATIONSHIP
                unless $related;
        }

        # This would be much nicer with 5.10s given/when/default        
        # Action: NULL
        if ($delete_action eq 'null') {
            warn('DeleteAction: NULL '.$self.'->'.$relationship) if $debug;
            if ($related->isa('DBIx::Class::ResultSet')) {
                my $update = {};
                foreach my $key (keys %{$relationship_info->{cond}} ) {
                    next RELATIONSHIP
                        unless $key =~ /^foreign\.(.+)$/;
                    $update->{$1} = undef;    
                }
                $related->update($update);
            } else {
                warn("Delete action 'null' does not work with ".$relationship_info->{attrs}{accessor}." relations");
            }
        # Action: DELETE
        } elsif ($delete_action eq 'delete' || $delete_action eq 'cascade') {
            warn('DeleteAction: DELETE '.$self.'->'.$relationship) if $debug;
            if ($related->isa('DBIx::Class::ResultSet')) {
                while (my $item = $related->next) {
                    $item->delete($params);
                }
            } else {
                $related->delete($params);
            }
        # Action: DELETEALL
        } elsif ($delete_action eq 'deleteall') {
            warn('DeleteAction: DELETEALL '.$self.'->'.$relationship) if $debug;
            if ($related->isa('DBIx::Class::ResultSet')) {
                $related->delete();
            } else {
                warn("Delete action 'null' does not work with ".$relationship_info->{attrs}{accessor}." relations");
            }
        } else {
            if ($related->isa('DBIx::Class::ResultSet')
                && $related->count == 0) {
                next RELATIONSHIP;
            }    
            
            # Action: DENY
            if ($delete_action eq 'deny') {
                warn('DeleteAction: DENY '.$self.'->'.$relationship) if $debug;
                if ($related->isa('DBIx::Class::ResultSet')) {
                    while (my $item = $related->next) {
                        my $compare_identifier = $item->_delete_action_identifier;
                        next if grep {$compare_identifier eq $_} @{$params->{seen}};
                        $self->throw_exception("Can't delete the object because it is still referenced from other records");
                    }
                } else {
                    my $compare_identifier = $related->_delete_action_identifier;
                    unless (grep {$compare_identifier eq $_} @{$params->{seen}}) {
                        $self->throw_exception("Can't delete the object because it is still referenced from other records");
                    }
                }
            # Action: CODE
            } elsif (ref $delete_action eq 'CODE') {
                warn('DeleteAction: CODE '.$self.'->'.$relationship) if $debug;
                $delete_action->($self,{
                    relationship    => $relationship,
                    related         => $related,
                    %{$params},
                });
            # Action: METHOD    
            } elsif ($self->can($delete_action)) {
                warn('DeleteAction: METHOD '.$self.'->'.$relationship.':'.$delete_action) if $debug;
                $self->$delete_action({
                    relationship    => $relationship,
                    related         => $related,
                    %{$params},
                });
            # Fallback
            } else {
                $self->throw_exception("Invalid delete action '$delete_action'")
            }
        }
    }

    warn('DeleteAction: FINISH '.$self) if $debug;

    # Run delete
    return $self->next::method($params);
}

=head1 EXAMPLE

=head2 Tree example

This example shows a very simple tree schema, where each node points to its
parent node. Once you delete an item from the tree, all child nodes will be
appended to the parent node of the deleted node.

 package MyApp::Treenode;
 use strict;
 use warnings;
 
 use parent qw(DBIx::Class);
 
 __PACKAGE__->load_components(
   "+DBIx::Class::DeleteAction",
   "PK",
   "Core",
 );
 
 __PACKAGE__->table("treenode");
 __PACKAGE__->add_columns(qw/id name parent/);
 __PACKAGE__->set_primary_key("id");
 
 # Do not delete parent node
 __PACKAGE__->might_have(
    'parent' => 'MyApp::Treenode',
    { "foreign.id" => "self.parent" },
    { delete_action => 'ignore' },
 );
 
 # Update all child nodes
 __PACKAGE__->has_many(
    'children' => 'MyApp::Treenode',
    { "foreign.parent" => "self.id" },
    { delete_action => sub {
        my ($self,$params) = @_;
        $params->{related}->update({
            parent  => $self->get_column('parent'), 
        });
    } },
 );

=head2 Debugging

Use C<DBIC_TRACE=1> or set C<__PACKAGE__->storage->debug(1);> to see what
is exactly going on.

=head1 CAVEATS

Note that the C<delete> method in L<DBIx::Class::ResultSet> will not run 
DeleteAction triggers. See C<delete_all> if you need triggers to run.

Any database-level cascade, restrict or trigger will be performed AFTER 
DBIx-Class-DeleteAction based triggers.

Always use transactions, or else you might end up with inconsistent data.

=head1 SUPPORT

Please report any bugs or feature requests to 
L<bug-dbix-class-deleteaction@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/Public/Bug/Report.html?Queue=DBIx::Class::DeleteAction>.
I will be notified, and then you'll automatically be notified of progress on 
your report as I make changes.

=head1 AUTHOR

    Maroš Kollár
    CPAN ID: MAROS
    maros [at] k-1.com
    L<http://www.revdev.at>

=head1 ACKNOWLEDGEMENTS 

This module was written for Revdev L<http://www.revdev.at>, a nice litte
software company I run with Koki and Domm (L<http://search.cpan.org/~domm/>).

=head1 COPYRIGHT

DBIx::Class::DeleteAction is Copyright (c) 2008-9 Maroš Kollár 
- L<http://www.revdev.at>

This program is free software; you can redistribute it and/or modify it under 
the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

"Delete me .... NAAAT";