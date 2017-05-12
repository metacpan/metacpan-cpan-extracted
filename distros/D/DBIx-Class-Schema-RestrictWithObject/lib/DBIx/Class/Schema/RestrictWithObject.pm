package DBIx::Class::Schema::RestrictWithObject;

our $VERSION = '0.0002';

use DBIx::Class::Schema::RestrictWithObject::RestrictComp::Schema;
use DBIx::Class::Schema::RestrictWithObject::RestrictComp::Source;

# (c) Matt S Trout 2006, all rights reserved
# this is free software under the same license as perl itself

=head1 NAME

DBIx::Class::Schema::RestrictWithObject - Automatically restrict resultsets

=head1 SYNOPSYS

In your L<DBIx::Class::Schema> class:

    __PACKAGE__->load_components(qw/Schema::RestrictWithObject/);

In the L<DBIx::Class> table class for your users:

    #let's pretend a user has_many notes, which are in ResultSet 'Notes'
    sub restrict_Notes_resultset {
      my $self = shift; #the User object
      my $unrestricted_rs = shift;

      #restrict the notes viewable to only those that belong to this user
      #this will, in effect make the following 2 equivalent
      # $user->notes $schema->resultset('Notes')
      return $self->related_resultset('notes');
    }

     #it could also be written like this
    sub restrict_Notes_resultset {
      my $self = shift; #the User object
      my $unrestricted_rs = shift;
      return $unrestricted_rs->search_rs( { user_id => $self->id } );
    }

Wherever you connect to your database

    my $schema = MyApp::Schema->connect(...);
    my $user = $schema->resultset('User')->find( { id => $user_id } );
    $resticted_schema = $schema->restrict_with_object( $user, $optional_prefix);

In this example we used the User object as the restricting object, but please
note that the restricting object need not be a DBIC class, it can be any kind of
object that provides the adequate methods.

=cut

=head1 DESCRIPTION

This L<DBIx::Class::Schema> component can be used to restrict all resultsets through
an appropriately-named method in a user-supplied object. This allows you to
automatically prevent data from being accessed, or automatically predefine options
and search clauses on a schema-wide basis. When used to limit data sets, it allows
simplified security by limiting any access to the data at the schema layer. Please
note however that this is not a silver bullet and without careful programming it is
still possible to expose unwanted data, so this should not be regarded as a
replacement for application level security.

=head1 PUBLIC METHODS

=head2 restrict_with_object $restricting_obj, $optional_prefix

Will restrict resultsets according to the methods available in $restricting_obj and
return a restricted copy of itself. ResultSets will be restricted if methods
in the form  of C<restrict_${ResultSource_Name}_resultset> are found in
$restricting_obj. If the optional prefix is included it will attempt to use
C<restrict_${prefix}_${ResultSource_Name}_resultset>, if that does not exist, it
will try again without the prefix, and if that's not available the resultset
will not be restricted.

=cut

sub restrict_with_object {
  my ($self, $obj, $prefix) = @_;
  my $copy = $self->clone;
  $copy->make_restricted;
  $copy->restricting_object($obj);
  $copy->restricted_prefix($prefix) if $prefix;
  return $copy;
}

=head1 PRIVATE METHODS

=head2 make_restricted

Restrict the Schema class and ResultSources associated with this Schema

=cut

sub make_restricted {
  my ($self) = @_;
  my $class = ref($self);
  my $r_class = $self->_get_restricted_schema_class($class);
  bless($self, $r_class);
  foreach my $moniker ($self->sources) {
    my $source = $self->source($moniker);
    my $class = ref($source);
    my $r_class = $self->_get_restricted_source_class($class);
    bless($source, $r_class);
  }
}

=head2 _get_restricted_schema_class $target_schema

Return the class name for the restricted schema class;

=cut

sub _get_restricted_schema_class {
  my ($self, $target) = @_;
  return $self->_get_restricted_class(Schema => $target);
}

=head2 _get_restricted_source_class $target_source

Return the class name for the restricted ResultSource class;

=cut

sub _get_restricted_source_class {
  my ($self, $target) = @_;
  return $self->_get_restricted_class(Source => $target);
}

=head2 _get_restrictedclass $type, $target

Return an appropriate class name for a restricted class of type $type.

=cut

sub _get_restricted_class {
  my ($self, $type, $target) = @_;
  my $r_class = join('::', $target, '__RestrictedWithObject');
  my $r_comp = join(
    '::', 'DBIx::Class::Schema::RestrictWithObject::RestrictComp', $type
  );
  unless ($r_class->isa($r_comp)) {
    $self->inject_base($r_class, $r_comp, $target);
  }
  return $r_class;
}

1;

__END__;

=head1 SEE ALSO

L<DBIx::Class>, L<DBIx::Class::Schema::RestrictWithObject::RestrictComp::Schema>,
L<DBIx::Class::Schema::RestrictWithObject::RestrictComp::Source>,

=head1 AUTHORS

Matt S Trout (mst) <mst@shadowcatsystems.co.uk>

With contributions from
Guillermo Roditi (groditi) <groditi@cpan.org>

=head1 LICENSE

You may distribute this code under the same terms as Perl itself.

=cut
