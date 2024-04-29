#----------------------------------------------------------------------
package DBIx::DataModel::Schema;
#----------------------------------------------------------------------

# see POD doc at end of file
# version : see DBIx::DataModel

use warnings;
use strict;
use DBIx::DataModel::Meta::Utils   qw/does/;
use DBIx::DataModel::Source::Table;
use DBIx::DataModel::Carp;

use Scalar::Util                   qw/blessed/;
use Data::Structure::Util;           # for calling unbless(), fully qualified
use Module::Load                   qw/load/;
use Params::Validate               qw/validate_with SCALAR ARRAYREF CODEREF UNDEF
                                                    OBJECT BOOLEAN/;
use SQL::Abstract::More 1.41;
use Try::Tiny;
use Devel::StackTrace;
use mro                            qw/c3/;

use namespace::clean;

my $schema_attributes_spec = {
  dbh                       => {type => OBJECT|ARRAYREF, optional => 1                                        },
  debug                     => {type => OBJECT|SCALAR,   optional => 1                                        },
  sql_abstract              => {type => OBJECT,          optional => 1,         isa   => 'SQL::Abstract::More'},
  dbi_prepare_method        => {type => SCALAR,          default  => 'prepare'                                },
  placeholder_prefix        => {type => SCALAR,          default  => '?:'                                     },
  select_implicitly_for     => {type => SCALAR,          default  => ''                                       },
  autolimit_firstrow        => {type => BOOLEAN,         optional => 1                                        },
  db_schema                 => {type => SCALAR,          optional => 1                                        },
  auto_show_error_statement => {type => BOOLEAN,         default  => 1                                        },
  frame_filter              => {type => CODEREF,         optional => 1                                        },
  handleError_policy        => {type => SCALAR,          default  => 'combine', regex => qr(^(if_absent
                                                                                             |combine
                                                                                             |override
                                                                                             |none)$)x        },
};


sub new {
  my $class = shift;

  my %args = @_;
  my $dbh = delete $args{dbh}; # this arg needs special treatment

  # setup metaclass
  my $metadm = $class->metadm;
  not $metadm->{singleton}
    or croak "$class is already used in single-schema mode, can't call new()";

  # validate params and create $self
  my $self = validate_with(
    params      => [%args],
    spec        => $schema_attributes_spec,
    allow_extra => 0,
   );
  bless $self, $class;

  # default SQLA
  $self->{sql_abstract} ||= $metadm->sql_abstract_class->new($metadm->sql_abstract_args);

  # from now on, singleton mode will be forbidden
  $metadm->{singleton} = undef;

  # initial dbh if it was passed within %args;
  $self->dbh($dbh) if $dbh;

  return $self;
}


# install simple-minded rw accessors for schema attributes
foreach my $accessor (grep {$_ ne 'dbh'} keys %$schema_attributes_spec) {
  no strict 'refs';
  *$accessor = sub {
    my $self = shift;
    ref $self or $self = $self->singleton;

    if (@_) {
      if (not defined $_[0]) { # $schema->$attribute(undef) means deleting that attribute in $schema
        delete $self->{$accessor};
      }
      else {
        my ($new_val) = validate_with(params      => \@_,
                                      spec        => [ $schema_attributes_spec->{$accessor} ],
                                      allow_extra => 0,
                                      called      => $accessor,
                                     );
        $self->{$accessor} = $new_val;
      }
    }
    return $self->{$accessor};
  };
}






# proxy methods, forwarded to the meta-schema
foreach my $method (qw/Table View Association Composition Type/) {
  no strict 'refs';
  *{$method} = sub {
    my $class = shift;
    not ref $class or croak "$method() is a class method";
    $class->metadm->$method(@_);
  }
}


sub singleton {
  my $class = shift;
  my $metadm = $class->metadm;

  if (!$metadm->{singleton}) {
    not exists $metadm->{singleton}
      or croak "attempt to call a class method in single-schema mode after "
             . "Schema::new() has been called; instead, use an instance "
             . "method : \$schema->table(\$name)->method(...)";
    $metadm->{singleton} = $class->new(@_);
    $metadm->{singleton}{is_singleton} = 1;
  }
  elsif (@_) {
    croak "can't pass args to ->singleton(..) after first call"; 
  }
  return $metadm->{singleton};
}



#----------------------------------------------------------------------
# RUNTIME METHODS
#----------------------------------------------------------------------

sub dbh {
  my ($self, $dbh, %dbh_options) = @_;

  ref $self or $self = $self->singleton;

  # if some args, then this is a "setter" (updating the dbh)
  if (@_ > 1) {

    # also support syntax ->dbh([$dbh, %dbh_options])
    ($dbh, %dbh_options) = @$dbh 
      if does($dbh, 'ARRAY') && ! keys %dbh_options;

    # forbid change of dbh while doing a transaction
    not $self->{dbh} or $self->{dbh}[0]{AutoCommit}
      or croak "cannot change dbh(..) while in a transaction";

    if ($dbh) {
      # $dbh must be a database handle
      $dbh->isa('DBI::db')
        or croak "invalid dbh argument";

      # only accept $dbh with RaiseError set
      $dbh->{RaiseError} 
        or croak "arg to dbh(..) must have RaiseError=1";

      # set ShowErrorStatement if necessary
      $dbh->{ShowErrorStatement} or !$self->auto_show_error_statement
        or $dbh->{ShowErrorStatement} = 1;

      # decide if we should install a HandleError attribute so that error reporting goes through Carp::Object
      my $HE_policy      = $self->handleError_policy;
      my $prev_handler   = $dbh->{HandleError};
      my $should_install = $HE_policy eq 'none'      ? 0
                         : $HE_policy eq 'if_absent' ? !$prev_handler
                         : $HE_policy eq 'combine'   ? 1
                         : $HE_policy eq 'override'  ? 1
                         : die "unexpected value for 'handleError_policy': $HE_policy";

      # actually, no need to re8install if the previous handler on this $dbh was already installed by the present module
      $should_install  &&= 0 if ($prev_handler || -1) == ($dbh->{private_dbix_datamodel_handle_error} || -2);      

      # install the handler
      if ($should_install) {
        my $must_combine    = $prev_handler && $HE_policy eq 'combine';
        my $new_handler     = $must_combine ? sub {my $was_handled = $prev_handler->(@_);
                                                   die $self->_handle_SQL_error(@_) if !$was_handled; }
                                            : sub {die $self->_handle_SQL_error(@_)};
        $dbh->{HandleError} = $new_handler;
        $dbh->{private_dbix_datamodel_handle_error} = $new_handler;
      }

      # default values for $dbh_options{returning_through}
      if (not exists $dbh_options{returning_through}) {
        for ($dbh->{Driver}{Name}) {
          /^Oracle/ and do {$dbh_options{returning_through} = 'INOUT'; last};
          /^Pg/     and do {$dbh_options{returning_through} = 'FETCH'; last};
        }
      }

      # store the dbh
      $self->{dbh} = [$dbh, %dbh_options];
    }
    else {
      # $dbh was explicitly undef, so remove previous dbh
      delete $self->{dbh};
    }
  }

  my $return_dbh = $self->{dbh} || [];
  return wantarray ? @$return_dbh : $return_dbh->[0];
}


sub _handle_SQL_error {
  my ($self, $dbi_errstr, $dbh, $unused) = @_;

  # skip intermediate ORM stack frames so that errors are reported from the caller's perspective
  local %DBIx::DataModel::Carp::CARP_OBJECT_CONSTRUCTOR = (frame_filter => sub {
    my ($frame_ref) = @_; 
    my $pkg = $frame_ref->{caller}[0];
    return 0  if $pkg =~ /^DBIx::DataModel/ or $pkg =~ /^SQL::Abstract/;   # skip packages used by DBIx::DataModel
    return $self->{frame_filter}->($frame_ref) if $self->{frame_filter};   # skip packages specified by client
    return 1;                                                              # otherwise, don't skip
   });

  # clear the DBI error, to make sure that upper levels like DBIx::RetryOverDisconnects will use
  # our $dbi_errstr and not DBI->errstr
  $dbh->set_err(undef, "");

  croak $dbi_errstr;
}

  

sub with_db_schema {
  my ($self, $db_schema) = @_;
  ref $self or $self = $self->singleton;

  # return a shallow copy of $self with db_schema set to the given arg
  return bless { %$self, db_schema => $db_schema}, ref $self;
}


my @default_state_components = qw/dbh debug select_implicitly_for
                                  dbi_prepare_method db_schema/;

sub localize_state {
  my ($self, @components) = @_; 
  ref $self or $self = $self->singleton;

  @components = @default_state_components unless @components;

  my %saved_state;
  $saved_state{$_} = $self->{$_} foreach @components;

  return DBIx::DataModel::Schema::_State->new($self, \%saved_state);
}




sub do_after_commit {
  my ($self, $coderef) = @_;
  ref $self or $self = $self->singleton;

  $self->{transaction_dbhs}
    or croak "do_after_commit() called outside of a transaction";
  push @{$self->{after_commit_callbacks}}, $coderef;
}


sub do_transaction { 
  my ($self, $coderef, @new_dbh) = @_; 
  ref $self or $self = $self->singleton;

  does($coderef, 'CODE')
    or croak 'first arg to $schema->do_transaction(...) should be a coderef';

  my $transaction_dbhs = $self->{transaction_dbhs} ||= [];

  # localize the dbh and its options, if so requested. 
  my $local_state = $self->localize_state(qw/dbh/)
    and
        delete($self->{dbh}),  # cheat so that dbh() does not complain
        $self->dbh(@new_dbh)   # and now update the dbh
    if @new_dbh; # postfix "if" because $local_state must not be in a block

  # check that we have a dbh
  my $dbh = $self->dbh
    or croak "no database handle for transaction";

  # how to call and how to return will depend on context
  my $want = wantarray ? "array" : defined(wantarray) ? "scalar" : "void";
  my $in_context = {
    array  => do {my @array;
                  {call   => sub {@array = $coderef->()}, 
                   return => sub {return @array}}},
    scalar => do {my $scalar;
                  {call   => sub {$scalar = $coderef->()}, 
                   return => sub {return $scalar}}},
    void   =>     {call   => sub {$coderef->()}, 
                   return => sub {return}}
   }->{$want};


  my $begin_work_and_exec = sub {
    # make sure dbh is in transaction mode
    if ($dbh->{AutoCommit}) {
      $dbh->begin_work; # will set AutoCommit to false
      push @$transaction_dbhs, $dbh;
    }

    # do the real work
    $in_context->{call}->();
  };

  if (@$transaction_dbhs) { # if in a nested transaction, just exec
    $begin_work_and_exec->();
  }
  else { # else try to execute and commit in an eval block

    # support for DBIx::RetryOverDisconnects: decide how many retries
    my $n_retries = 1;
    if ($dbh->isa('DBIx::RetryOverDisconnects::db')) {
      $n_retries = $dbh->{DBIx::RetryOverDisconnects::PRIV()}{txn_retries};
    }

    # try to do the transaction, maybe several times in cas of disconnection
  RETRY:
    for my $retry (1 .. $n_retries) {
      no warnings 'exiting'; # because "last/next" are in Try::Tiny subroutines
      try {
        # check AutoCommit state
        $dbh->{AutoCommit}
          or croak "dbh was not in Autocommit mode before initial transaction";

        # execute the transaction
        $begin_work_and_exec->();

        # commit all dbhs and then reset the list of dbhs
        $_->commit foreach @$transaction_dbhs;
        delete $self->{transaction_dbhs};

        last RETRY; # transaction successful, get out of the loop
      }
      catch {
        my $err = $_;

        # if this was a disconnection ..
        if ($dbh->isa('DBIx::RetryOverDisconnects::db') 
              # $dbh->can() is broken on DBI handles, so use ->isa() instead
              && $dbh->is_trans_disconnect) {
          $transaction_dbhs = [];
          next RETRY if $retry < $n_retries;   # .. try again
          $self->exc_conn_trans_fatal->throw;  # .. or no hope (and no rollback)
        }

        # otherwise, for regular SQL errors, try to rollback and then throw
        my @rollback_errs;
        foreach my $dbh (reverse @$transaction_dbhs) {
          try   {$dbh->rollback}
            catch {push @rollback_errs, $_};
        }
        delete $self->{transaction_dbhs};
        delete $self->{after_commit_callbacks};
        DBIx::DataModel::Schema::_Exception->throw($err, @rollback_errs);
      };
    }
  }

  # execute the after_commit callbacks
  my $callbacks = delete $self->{after_commit_callbacks} || [];
  $_->() foreach @$callbacks;

  return $in_context->{return}->();
}


sub unbless {
  my $class = shift;
  Data::Structure::Util::unbless($_) foreach @_;

  return wantarray ? @_ : $_[0];
}


# accessors to connected sources (tables or joins) from the current schema
#                   local method     metadm method
#                   ============     =============
my %accessor_map = (table         => 'table',
                    join          => 'define_join',
                    db_table      => 'db_table');
while (my ($local, $remote) = each %accessor_map) {
  no strict 'refs';
  *$local = sub {
    my $self = shift;
    ref $self or $self = $self->singleton;

    my $meta_source = $self->metadm->$remote(@_) or return;
    my $obj = bless {__schema => $self}, $meta_source->class;
    return $obj;
  }
}

#----------------------------------------------------------------------
# UTILITY FUNCTIONS (PRIVATE)
#----------------------------------------------------------------------


sub _debug { # internal method to send debug messages
  my ($self, $msg) = @_;
  my $debug = $self->debug;
  if ($debug) {
    if (ref $debug && $debug->can('debug')) { $debug->debug($msg) }
    else                                    { carp $msg; }
  }
}





#----------------------------------------------------------------------
# PRIVATE CLASS FOR LOCALIZING STATE (see L</localizeState> method
#----------------------------------------------------------------------

package
  DBIx::DataModel::Schema::_State;

sub new {
  my ($class, $schema, $state) = @_;
  bless [$schema, $state], $class;
}


sub DESTROY { # called when the guard goes out of scope
  my ($self) = @_;

  # localize $@, in case we were called while dying - see L<perldoc/Destructors>
  local $@;

  my ($schema, $previous_state) = @$self;

  # must cleanup dbh so that ->dbh(..) does not complain if in a transaction
  delete $schema->{dbh} if exists $previous_state->{dbh};
    
  # invoke "setter" method on each state component
  while (my ($k, $v) = each %$previous_state) {
    $schema->$k($v) if $v;
  }
}


#----------------------------------------------------------------------
# PRIVATE CLASS FOR TRANSACTION EXCEPTIONS
#----------------------------------------------------------------------

package
  DBIx::DataModel::Schema::_Exception;
use strict;
use warnings;

use overload '""' => sub {
  my $self = shift;
  my $err             = $self->initial_error;
  my @rollback_errs   = $self->rollback_errors;
  my $rollback_status = @rollback_errs ? CORE::join(", ", @rollback_errs) : "OK";
  return "FAILED TRANSACTION: $err (rollback: $rollback_status)";
};


sub throw {
  my $class = shift;
  my $self = bless [@_], $class;
  die $self;
}

sub initial_error {
  my $self = shift;
  return $self->[0];
}

sub rollback_errors {
  my $self = shift;
  return @$self[1..$#{$self}];
}


1; 

__END__

=encoding ISO8859-1

=head1 NAME

DBIx::DataModel::Schema - Factory for DBIx::DataModel Schemas

=head1 DESCRIPTION

This is the parent class for all schema classes created through

  DBIx::DataModel->Schema($schema_name, ...);

=head1 CONSTRUCTOR

See L<DBIx::DataModel::Doc::Reference/Schema::new()>

=head1 ATTRIBUTES

See L<DBIx::DataModel::Doc::Reference/Schema attributes>

=head1 METHODS

See L<DBIx::DataModel::Doc::Reference/Other schema methods>.

=head2 Delegated methods

Methods delegated to L<DBIx::DataModel::Meta::Schema> :

=over

=item L<Table|DBIx::DataModel::Doc::Reference/Table>

=item L<View|DBIx::DataModel::Doc::Reference/View>

=item L<Association|DBIx::DataModel::Doc::Reference/Association>

=item L<Composition|DBIx::DataModel::Doc::Reference/Composition>

=item L<Type|DBIx::DataModel::Doc::Reference/Type>

=item L<table|DBIx::DataModel::Doc::Reference/table>

=item L<join|DBIx::DataModel::Doc::Reference/join>

=back



=head2 Implemented methods

Methods implemented in this module :

=over

=item L<singleton|DBIx::DataModel::Doc::Reference/singleton>

=item L<dbh|DBIx::DataModel::Doc::Reference/dbh>

=item L<debug|DBIx::DataModel::Doc::Reference/debug>

=item L<select_implicitly_for|DBIx::DataModel::Doc::Reference/select_implicitly_for>

=item L<dbi_prepare_method|DBIx::DataModel::Doc::Reference/dbi_prepare_method>

=item L<sql_abstract|DBIx::DataModel::Doc::Reference/sql_abstract>

=item L<placeholder_prefix|DBIx::DataModel::Doc::Reference/placeholder_prefix>

=item L<autolimit_firstrow|DBIx::DataModel::Doc::Reference/autolimit_firstrow>

=item L<db_schema|DBIx::DataModel::Doc::Reference/db_schema>

=item L<auto_show_error_statement|DBIx::DataModel::Doc::Reference/auto_show_error_statement>

=item L<frame_filter|DBIx::DataModel::Doc::Reference/frame_filter>

=item L<handleError_policy|DBIx::DataModel::Doc::Reference/handleError_policy>

=item L<localize_state|DBIx::DataModel::Doc::Reference/localize_state>

=item L<do_transaction|DBIx::DataModel::Doc::Reference/do_transaction>

=item L<unbless|DBIx::DataModel::Doc::Reference/unbless>

=back

=head1 PRIVATE SUBCLASSES

This module has two internal subclasses.

=head2 _State

A private class for localizing state (using a DESTROY method).

=head2 _Exception

A private class for exceptions during transactions
(see  L<do_transaction|DBIx::DataModel::Doc::Reference/do_transaction>).

=head1 AUTHOR

Laurent Dami, E<lt>laurent.dami AT etat  ge  chE<gt>

=head1 COPYRIGHT & LICENSE

Copyright 2006-2023 Laurent Dami.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

