package DBIx::DataModel::Compatibility::V1;
use strict;
use warnings;
no strict   'refs';
no warnings 'once';

use DBIx::DataModel::ConnectedSource;
use DBIx::DataModel::Meta;
use DBIx::DataModel::Meta::Schema;
use DBIx::DataModel::Meta::Source;
use DBIx::DataModel::Meta::Utils;
use DBIx::DataModel::Schema;
use DBIx::DataModel::Source;
use DBIx::DataModel::Source::Table;
use DBIx::DataModel::Statement;
use DBIx::DataModel::Statement::JDBC;
use SQL::Abstract::More;

my $tmp; # used for various renaming loops

# utility fonction for replacing 'camelCase' keys in hashs by 'camel_case'
sub _rename_camelCase_keys {
  my $hashref = shift;
  foreach my $key (keys %$hashref) {
    my $new_key = $key;
    $new_key =~ s/([a-z])([A-Z])/$1_\L$2\E/g 
      and $hashref->{$new_key} = delete $hashref->{$key};
  }

  # an exception for -postSQL
  $tmp = delete $hashref->{-post_sQL} and $hashref->{-post_SQL} = $tmp;
}

#----------------------------------------------------------------------
package DBIx::DataModel;
#----------------------------------------------------------------------
use strict;
use warnings;
no warnings 'redefine';
my $orig_Schema = \&Schema;

*Schema = sub {
  my ($class, $schema_class_name, %args) = @_;

  # convert args received as camelCase
  DBIx::DataModel::Compatibility::V1::_rename_camelCase_keys(\%args);

  # extract args that should go to DBIDM::Schema and not DBIDM::Meta::Schema
  my %singleton_args;
  foreach my $key (qw/dbh debug  dbi_prepare_method
                      sql_abstract sql_dialect/) {
    $tmp = delete $args{$key} and $singleton_args{$key} = $tmp;
  }

  # view_parent is now join_parent (not 100% correct, but the best we can do)
  if (my $vp = delete $args{view_parent}) {
    $args{join_parent} ||= [];
    $args{join_parent} = [$args{join_parent}] unless ref $args{join_parent};
    push @{$args{join_parent}}, @$vp;
  }

  # create the Meta::Schema
  my $schema_class = $class->$orig_Schema($schema_class_name, %args);

  # also create a Schema singleton, if needed
  if (%singleton_args) {

    # recuperate existing SQLA instance, if any
    my %sqlam_args; 
    if (my $sqla = delete $singleton_args{sql_abstract}) {
      # create a fake SQLA object in order to know how many builtin ops it has
      my $fake_sqla = SQL::Abstract->new;

      # surgery: remove builtin ops from our $sqla object
      for my $op_name (qw/special_ops unary_ops/) {
        my $n_builtin_ops = @{$fake_sqla->{$op_name}};
        splice @{$sqla->{$op_name}}, -$n_builtin_ops;
      }

      # now inject the remaining stuff in $sqla as argument for a SQLAM object
      %sqlam_args = %$sqla  if $sqla;
    }

    # sql_dialect, previously passed to Schema, is now passed to SQLAM
    if (my $dialect = delete $singleton_args{sql_dialect}) {
      if (ref $dialect) {
        DBIx::DataModel::Compatibility::V1::_rename_camelCase_keys($dialect);
        $sqlam_args{$_} = $dialect->{$_} foreach keys %$dialect;
      }
      else {
        $dialect =~ s/^MySQL/MySQL_old/;
        $sqlam_args{sql_dialect} = $dialect;
      }
    }


    # create a new SQLAM instance
    $singleton_args{sql_abstract} = SQL::Abstract::More->new(%sqlam_args);

    # create the singleton
    my $singleton = $schema_class->singleton(%singleton_args);
  }

  return $schema_class;
};



#----------------------------------------------------------------------
package DBIx::DataModel::ConnectedSource;
#----------------------------------------------------------------------
use strict;
use warnings;

sub ColumnType {
  my ($self, $typeName, @args) = @_;
  $self->{meta_source}->define_column_type($typeName, @args);
}

sub AutoExpand {
  my ($self, @roles) = @_;
  $self->{meta_source}->define_auto_expand(@roles);
}


#----------------------------------------------------------------------
package DBIx::DataModel::Meta::Schema;
#----------------------------------------------------------------------
use strict;
use warnings;
no warnings 'redefine';

my $orig_Type = \&Type;
*Type = *ColumnType = sub {
  my ($self, $type_name, %handlers) = @_;
  my $tmp;
  $tmp = delete $handlers{fromDB} and $handlers{from_DB} = $tmp;
  $tmp = delete $handlers{toDB}   and $handlers{to_DB}   = $tmp;
  $self->$orig_Type($type_name, %handlers);
};


my $orig_new = \&new;
*new = sub { 
  my ($class, %options)  = @_; 

  $class->$orig_new(sql_no_inner_after_left_join => 1, %options);
};


sub tables { # return classname instead of metadm instance
  my $self = shift;
  return map {$_->class} values %{$self->{table}};
}

sub views {
  my $self = shift;
  return map {$_->class} values %{$self->{table}};
}


#----------------------------------------------------------------------
package DBIx::DataModel::Schema;
#----------------------------------------------------------------------
use strict;
use warnings;
no warnings 'redefine';
use Carp;


*_createPackage  = \&DBIx::DataModel::Meta::Utils::define_class;
*doTransaction   = \&do_transaction;

sub _defineMethod {
  my ($class, $target, $method_name, $body, $is_silent) = @_;
  my %args = (
    class => $target,
    name  => $method_name,
    body  => $body,
   );
  $args{check_override} = 0 if $is_silent;
  DBIx::DataModel::Meta::Utils->define_method(%args);
}

sub ColumnType {
  my $self = shift;
  $self->metadm->Type(@_);
}


sub Autoload { # installs or desinstalls an AUTOLOAD
  my ($class, $toggle) = @_;

  DBIx::DataModel::Source::Table->Autoload($toggle);
}

sub autoInsertColumns {
  my $class = shift; 
  return $class->metadm->auto_insert_columns;
}

sub autoUpdateColumns {
  my $class = shift; 
  return $class->metadm->auto_update_columns;
}

sub noUpdateColumns {
  my $class = shift; 
  my %no_update_column = $class->metadm->no_update_column;
  return keys %no_update_column;
}

sub AutoInsertColumns {
  my ($class, %handlers) = @_;
  $class->metadm->{auto_insert_columns} = \%handlers;
}

sub AutoUpdateColumns {
  my ($class, %handlers) = @_;
  $class->metadm->{auto_update_columns} = \%handlers;
}

sub NoUpdateColumns {
  my ($class, @columns) = @_;
  $class->metadm->{no_update_columns} = {map {$_ => 1} @columns};
}


sub tables {
  my $class = shift;
  $class->metadm->tables;
}


sub selectImplicitlyFor {
  my $self = shift;
  $self->select_implicitly_for(@_);
}

sub classData {
  my $class = shift;
  return $class->singleton;
}

sub localizeState {
  my $class = shift;
  return $class->localize_state;
}


#----------------------------------------------------------------------
package DBIx::DataModel::Source;
#----------------------------------------------------------------------
use strict;
use warnings;
no warnings 'redefine';
use Carp;

*primKey        = \&primary_key;

sub MethodFromJoin {
  my $self = shift;
  $self->metadm->define_navigation_method(@_);
}

sub createStatement {
  my $class = shift;

  carp "->createStatement() is obsolete, use "
     . "->select(.., -resultAs => 'statement')";

  return $class->select(@_, -resultAs => 'statement');
}

sub selectImplicitlyFor {
  my $self = shift;

  carp "HACK: obsolete method \$source->selectImplicitlyFor() is delegated "
     . "to \$schema->select_implicitly_for(); the semantics is not exactly "
     . "identical";
  $self->metadm->schema->class->select_implicitly_for(@_);
}

sub _autoloader {
  my $self = shift;
  my $class = ref($self) || $self;
  my $attribute = our $AUTOLOAD;
  $attribute =~ s/^.*:://;
  return if $attribute eq 'DESTROY'; # won't overload that one!

  return $self->{$attribute} if ref($self) and exists $self->{$attribute};

  croak "no $attribute method in $class"; # otherwise
}

sub Autoload { # installs or desinstalls an AUTOLOAD in $package
  my ($class, $toggle) = @_;

  not ref($class)  or croak "Autoload is a class method";
  defined($toggle) or croak "Autoload : missing toggle value";

  no strict 'refs';
  if ($toggle) {
    *{"${class}::AUTOLOAD"} = \&_autoloader;
  }
  else {
    delete ${"${class}::"}{AUTOLOAD};
  }
}



#----------------------------------------------------------------------
package DBIx::DataModel::Source::Table;
#----------------------------------------------------------------------
use strict;
use warnings;
no warnings 'redefine';

sub DefaultColumns {
  my ($class, $columns) = @_;
  $class->metadm->default_columns($columns);
}

sub ColumnType {
  my ($class, $typeName, @args) = @_;
  $class->metadm->define_column_type($typeName, @args);
}

sub ColumnHandlers {
  my ($class, $columnName, %handlers) = @_;
  $class->metadm->define_column_handlers($columnName, %handlers);
}

sub AutoExpand {
  my ($class, @roles) = @_;
  $class->metadm->define_auto_expand(@roles);
}

sub autoInsertColumns {
  my $self = shift; 
  $self->metadm->auto_insert_column;
}

sub autoUpdateColumns {
  my $self = shift; 
  $self->metadm->auto_update_column;
}

sub noUpdateColumns {
  my $self = shift; 
  my %no_update_columns = $self->metadm->no_update_column;
  return keys %no_update_columns;
}

sub componentRoles {
  my $self  = shift; 
  $self->metadm->components;
}

sub applyColumnHandler {
  my $class = shift;
  $class->apply_column_handler(@_);
}

sub AutoInsertColumns {
  my ($class, %handlers) = @_;
  $class->metadm->{auto_insert_columns} = \%handlers;
}

sub AutoUpdateColumns {
  my ($class, %handlers) = @_;
  $class->metadm->{auto_update_columns} = \%handlers;
}

sub NoUpdateColumns {
  my ($class, @columns) = @_;
  $class->metadm->{no_update_columns} = {map {$_ => 1} @columns};
}

sub blessFromDB {
  my $class = shift;
  $class->bless_from_DB(@_);
}

sub db_table {
  my $class = shift;
  return $class->metadm->db_from;
}

#----------------------------------------------------------------------
package DBIx::DataModel::Statement;
#----------------------------------------------------------------------
use strict;
use warnings;
no warnings 'redefine';
use Carp;
use Scalar::Util qw/reftype/;

my $orig_refine = \&refine;
*refine = sub {
  my $self = shift;

  # parse named or positional arguments
  my %args;
  if ($_[0] and not ref($_[0]) and $_[0] =~ /^-/) { # called with named args
    %args = @_;
  }
  else { # we were called with unnamed args (all optional!), so we try
         # to guess which is which from their datatypes.
    no warnings 'uninitialized';
    $args{-columns} = shift unless !@_ or reftype $_[0] eq 'HASH' ;
    $args{-where}   = shift unless !@_ or reftype $_[0] eq 'ARRAY';
    $args{-orderBy} = shift unless !@_ or reftype $_[0] eq 'HASH' ;
    croak "too many args for select()" if @_;
  }

  # camelCase keys
  DBIx::DataModel::Compatibility::V1::_rename_camelCase_keys(\%args);

  # -distinct => \@columns is now -columns => [-distinct => @columns]
  if (my $distinct = delete $args{-distinct}) {
    ref $distinct or $distinct = [$distinct];
    unshift @$distinct, '-distinct';
    $args{-columns} = $distinct;
  }

  # various old ways to require -result_as => 'statement'
  $args{-result_as} =~ s/^(cursor|iter(ator)?)/statement/i
    if $args{-result_as};

  # delegate to the real refine() method
  $self->$orig_refine(%args);
};

*{rowCount}       = \&row_count;
*{pageCount}      = \&page_count;
*{gotoPage}       = \&goto_page;
*{shiftPages}     = \&shift_pages;
*{nextPage}       = \&next_page;
*{pageBoundaries} = \&page_boundaries;
*{pageRows}       = \&page_rows;

#----------------------------------------------------------------------
package DBIx::DataModel::Statement::JDBC;
#----------------------------------------------------------------------
use strict;
use warnings;
no warnings 'redefine';
use Carp;

*{rowCount}       = \&row_count;


# simulate previous classes, now moved into the Source:: namespace, so that
# they can be inherited from
#----------------------------------------------------------------------
package DBIx::DataModel::Table;
#----------------------------------------------------------------------
$INC{"DBIx/DataModel/Table.pm"} = 1;
our @ISA = qw/DBIx::DataModel::Source::Table/;


#----------------------------------------------------------------------
package DBIx::DataModel::View;
#----------------------------------------------------------------------
$INC{"DBIx/DataModel/View.pm"} = 1;
our @ISA = qw/DBIx::DataModel::Source::Table/;

1;

__END__

=head1 NAME

DBIx::DataModel::Compatibility::V1 - compatibility with previous versions 1.*

=head1 SYNOPSIS

Do not C<use> this package directly; use indirectly through

  use DBIx::DataModel -compatibility => 1.0;

=head1 DESCRIPTION

Version 2 of C<DBIx::DataModel> was a major refactoring from versions
1.*, with a number of incompatible changes in the API (classes
renamed, arguments renamed or reorganized, etc..).

The present package injects a compatibility layer between your application
and C<DBIx::DataModel> : that layer intercepts the calls and modifies
the arguments and/or return values so that the API is compatible with
prior versions C<1.*>.

For versions prior to 2.20, this compatibility layer was automatically
activated, in order to automatically preserve backwards
compatibility. Now the compatibility layer is deprecated;
however it can still be loaded on demand, as shown above in the synopsis.

=head1 SEE ALSO

L<DBIx::DataModel>


=cut

