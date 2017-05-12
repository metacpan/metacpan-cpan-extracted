package DBIx::DataModel::Compatibility::V0;
use strict;
use warnings;
no strict 'refs';
no warnings 'once';

require DBIx::DataModel::Schema;
require DBIx::DataModel::Statement;

#----------------------------------------------------------------------
package DBIx::DataModel;
#----------------------------------------------------------------------
no warnings 'redefine';
my $orig_Schema = \&Schema;

*Schema = sub {
  my ($class, $schema_class_name, @args) = @_;

  # transform ->Schema('Foo', $dbh) into ->Schema('Foo', dbh => $dbh)
  unshift @args, 'dbh' if @args == 1;
  $class->$orig_Schema(@args);
};

#----------------------------------------------------------------------
package DBIx::DataModel::Schema;
#----------------------------------------------------------------------
*ViewFromRoles = \&join;

#----------------------------------------------------------------------
package DBIx::DataModel::Source;
#----------------------------------------------------------------------

*selectFromRoles = \&join;
*MethodFromRoles 
  = \&DBIx::DataModel::Meta::Source::Table::define_navigation_method;
*table           = \&db_from;

#----------------------------------------------------------------------
package DBIx::DataModel::Statement;
#----------------------------------------------------------------------

use overload

  # overload the coderef operator ->() for backwards compatibility
  # with previous "selectFromRoles" method. 
  '&{}' => sub {
    my $self = shift;
    carp "selectFromRoles is deprecated; use ->join(..)->select(..)";
    return sub {$self->select(@_)};
  };

my $orig_refine = \&refine;
*refine = sub {
  my ($self, %args) = @_;
  $args{-post_bless} = delete $args{-postFetch} if $args{-postFetch};
  $self->$orig_refine(%args);
}


1;

__END__


=head1 NAME

DBIx::DataModel::Compatibility::V0 - compatibility with previous versions 0.*

=head1 SYNOPSIS

Do not C<use> this package directly; use indirectly through

  use DBIx::DataModel -compatibility => 0.1;

=head1 DESCRIPTION

Version 2 of C<DBIx::DataModel> was a major refactoring from versions
1.* and 0.*, with a number of incompatible changes in the API (classes
renamed, arguments renamed or reorganized, etc..).

The present package injects a compatibility layer between your application
and C<DBIx::DataModel> : that layer intercepts the calls and modifies
the arguments and/or return values so that the API is compatible with
prior versions C<0.*>. 
The L<DBIx::DataModel::Compatibility::V1|DBIx::DataModel::Compatibility::V1> 
layer will also be loaded.

The C<V0> API was deprecated in 2008, so it is B<strongly> recommended
to update your applications instead of using the present module.

=head1 SEE ALSO

L<DBIx::DataModel>

