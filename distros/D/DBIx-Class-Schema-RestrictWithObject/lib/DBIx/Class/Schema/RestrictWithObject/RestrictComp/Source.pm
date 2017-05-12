package DBIx::Class::Schema::RestrictWithObject::RestrictComp::Source;

use strict;
use warnings;

=head1 DESCRIPTION

For general usage please see L<DBIx::Class::Schema::RestrictWithObject>, the information
provided here is not meant for general use and is subject to change. In the interest
of transparency the functionality presented is documented, but all methods should be
considered private and, as such, subject to incompatible changes and removal.

=head1 PRIVATE METHODS

=head2 resultset

Intercept call to C<resultset> and return restricted resultset

=cut

#TODO:
# - We should really be caching method name hits to avoid the can()
#   unless it really is necessary. This would be done at the restrictor
#   class level. {$source_name} => $restricting_method (undef if n/a)

sub resultset {
  my $self = shift;
  my $rs = $self->next::method(@_);
  my $obj = $self->schema->restricting_object;
  return $rs unless $obj;

  my $s = $self->source_name;
  $s =~ s/::/_/g;
  #if a prefix was set, try that first
  if(my $pre = $self->schema->restricted_prefix) {
    if(my $coderef = $obj->can("restrict_${pre}_${s}_resultset")) {
      return $obj->$coderef($rs);
    }
  }
  #should this be an elsif?!
  if(my $coderef = $obj->can("restrict_${s}_resultset")) {
    return $obj->$coderef($rs);
  }
  return $rs;
}

1;

=head1 SEE ALSO

L<DBIx::Class::Schema::RestrictWithObject>,

=cut
