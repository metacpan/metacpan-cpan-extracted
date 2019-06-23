package DBIx::Handler;
use strict;
use warnings;
our $VERSION = '0.15';

use DBI 1.605;
use DBIx::TransactionManager 1.09;
use Carp ();

our $TxnTraceLevel = 0;

sub _noop {}

{
    no warnings qw/once/;
    *connect = \&new;
}

sub new {
    my $class = shift;

    my $opts = scalar(@_) == 5 ? pop @_ : +{};
    bless {
        _connect_info    => [@_],
        _pid             => undef,
        _dbh             => undef,
        trace_query      => $opts->{trace_query}      || 0,
        trace_ignore_if  => $opts->{trace_ignore_if}  || \&_noop,
        result_class     => $opts->{result_class}     || undef,
        on_connect_do    => $opts->{on_connect_do}    || undef,
        on_disconnect_do => $opts->{on_disconnect_do} || undef,
        no_ping          => $opts->{no_ping}          || 0,
        dbi_class        => $opts->{dbi_class}        || 'DBI',
        prepare_method   => $opts->{prepare_method}   || 'prepare',
    }, $class;
}

sub _connect {
    my $self = shift;

    my $dbh = $self->{_dbh} = $self->{dbi_class}->connect(@{$self->{_connect_info}});
    my $attr = @{$self->{_connect_info}} > 3 ? $self->{_connect_info}->[3] : {};

    if (DBI->VERSION > 1.613 && !exists $attr->{AutoInactiveDestroy}) {
        $dbh->STORE(AutoInactiveDestroy => 1);
    }

    if (!exists $attr->{RaiseError} && !exists $attr->{HandleError}) {
        $dbh->STORE(RaiseError => 1);
    }

    if ($dbh->FETCH('RaiseError') && !exists $attr->{PrintError}) {
        $dbh->STORE(PrintError => 0);
    }

    $self->{_pid} = $$;

    $self->_run_on('on_connect_do', $dbh);

    $dbh;
}

sub dbh {
    my $self = shift;
    $self->_seems_connected or $self->_connect;
}

sub _ping {
    my ($self, $dbh) = @_;
    $self->{no_ping} || $dbh->ping;
}

sub _seems_connected {
    my $self = shift;

    my $dbh = $self->{_dbh} or return;

    if ( $self->{_pid} != $$ ) {
        $dbh->STORE(InactiveDestroy => 1);
        $self->_in_txn_check;
        delete $self->{txn_manager};
        return;
    }

    unless ($dbh->FETCH('Active') && $self->_ping($dbh)) {
        $self->_in_txn_check;
        $self->_disconnect;
        return;
    }

    $dbh;
}

sub disconnect {
    my $self = shift;

    $self->_seems_connected or return;
    $self->_disconnect;
}

sub _disconnect {
    my $self = shift;
    my $dbh = delete $self->{_dbh} or return;
    delete $self->{txn_manager};
    $self->_run_on('on_disconnect_do', $dbh);
    $dbh->STORE(CachedKids => {});
    $dbh->disconnect;
}

sub _run_on {
    my ($self, $mode, $dbh) = @_;
    if ( my $on_connect_do = $self->{$mode} ) {
        if (not ref($on_connect_do)) {
            $dbh->do($on_connect_do);
        } elsif (ref($on_connect_do) eq 'CODE') {
            $on_connect_do->($dbh);
        } elsif (ref($on_connect_do) eq 'ARRAY') {
            $dbh->do($_) for @$on_connect_do;
        } else {
            Carp::croak("Invalid $mode: ".ref($on_connect_do));
        }
    }
}

sub DESTROY { $_[0]->disconnect }

sub result_class {
    my ($self, $result_class) = @_;
    $self->{result_class} = $result_class if $result_class;
    $self->{result_class};
}

sub trace_query {
    my ($self, $flag) = @_;
    $self->{trace_query} = $flag if defined $flag;
    $self->{trace_query};
}

sub trace_ignore_if {
    my ($self, $callback) = @_;
    $self->{trace_ignore_if} = $callback if defined $callback;
    $self->{trace_ignore_if};
}

sub no_ping {
    my ($self, $enable) = @_;
    $self->{no_ping} = $enable if defined $enable;
    $self->{no_ping};
}

sub prepare_method {
    my ($self, $prepare_method) = @_;
    $self->{prepare_method} = $prepare_method if $prepare_method;
    $self->{prepare_method};
}

sub query {
    my ($self, $sql, @args) = @_;

    my $bind;
    if (ref($args[0]) eq 'HASH') {
        ($sql, $bind) = $self->replace_named_placeholder($sql, $args[0]);
    }
    else {
        $bind = ref($args[0]) eq 'ARRAY' ? $args[0] : \@args;
    }

    $sql = $self->trace_query_set_comment($sql);

    my $sth;
    eval {
        my $prepare_method = $self->{prepare_method};
        $sth = $self->dbh->$prepare_method($sql);
        $sth->execute(@{$bind || []});
    };
    if (my $error = $@) {
        Carp::croak($error);
    }

    my $result_class = $self->result_class;
    $result_class ? $result_class->new($self, $sth) : $sth;
}

sub replace_named_placeholder {
    my ($self, $sql, $args) = @_;

    my %named_bind = %{$args};
    my @bind;
    $sql =~ s{:(\w+)}{
        Carp::croak("$1 does not exists in hash") if !exists $named_bind{$1};
        if ( ref $named_bind{$1} && ref $named_bind{$1} eq "ARRAY" ) {
            push @bind, @{ $named_bind{$1} };
            my $tmp = join ',', map { '?' } @{ $named_bind{$1} };
            "($tmp)";
        } else {
            push @bind, $named_bind{$1};
            '?'
        }
    }ge;

    return ($sql, \@bind);
}

sub trace_query_set_comment {
    my ($self, $sql) = @_;
    return $sql unless $self->trace_query;

    my $i = 1;
    while ( my (@caller) = caller($i++) ) {
        next if ( $caller[0]->isa( __PACKAGE__ ) );
        next if $self->trace_ignore_if->(@caller);
        my $comment = "$caller[1] at line $caller[2]";
        $comment =~ s/\*\// /g;
        $sql = "/* $comment */ $sql";
        last;
    }

    $sql;
}

sub run {
    my ($self, $coderef) = @_;
    my $wantarray = wantarray;

    my @ret = eval {
        my $dbh = $self->dbh;
        $wantarray ? $coderef->($dbh) : scalar $coderef->($dbh);
    };
    if (my $error = $@) {
        Carp::croak($error);
    }

    $wantarray ? @ret : $ret[0];
}

# --------------------------------------------------------------------------------
# for transaction
sub txn_manager {
    my $self = shift;

    my $dbh = $self->dbh;
    $self->{txn_manager} ||= DBIx::TransactionManager->new($dbh);
}

sub in_txn {
    my $self = shift;
    return unless $self->{txn_manager};
    return $self->{txn_manager}->in_transaction;
}

sub _in_txn_check {
    my $self = shift;

    my $info = $self->in_txn;
    return unless $info;

    my $caller = $info->{caller};
    my $pid    = $info->{pid};
    Carp::confess("Detected transaction during a connect operation (last known transaction at $caller->[1] line $caller->[2], pid $pid). Refusing to proceed at");
}

sub txn_scope {
    my @caller = caller($TxnTraceLevel);
    shift->txn_manager->txn_scope(caller => \@caller, @_);
}

sub txn {
    my ($self, $coderef) = @_;

    my $wantarray = wantarray;
    my $txn = $self->txn_scope(caller => [caller($TxnTraceLevel)]);

    my @ret = eval {
        my $dbh = $self->dbh;
        $wantarray ? $coderef->($dbh) : scalar $coderef->($dbh);
    };

    if (my $error = $@) {
        $txn->rollback;
        Carp::croak($error);
    } else {
        eval { $txn->commit };
        Carp::croak($@) if $@;
    }

    $wantarray ? @ret : $ret[0];
}

sub txn_begin    { $_[0]->txn_manager->txn_begin    }
sub txn_rollback { $_[0]->txn_manager->txn_rollback }
sub txn_commit   { $_[0]->txn_manager->txn_commit   }

1;

__END__

=for stopwords dbh dsn txn coderef sql

=head1 NAME

DBIx::Handler - fork-safe and easy transaction handling DBI handler

=head1 SYNOPSIS

  use DBIx::Handler;
  my $handler = DBIx::Handler->new($dsn, $user, $pass, $dbi_opts, $opts);
  my $dbh = $handler->dbh;
  $dbh->do(...);

=head1 DESCRIPTION

DBIx::Handler is fork-safe and easy transaction handling DBI handler.

DBIx::Handler provide scope base transaction, fork safe dbh handling, simple.

=head1 METHODS

=over 4

=item my $handler = DBIx::Handler->new($dsn, $user, $pass, $dbi_opts, $opts);

get database handling instance.

Options:

=over 4

=item on_connect_do : CodeRef|ArrayRef[Str]|Str

=item on_disconnect_do : CodeRef|ArrayRef[Str]|Str

Execute SQL or CodeRef when connected/disconnected.

=item result_class : ClassName

This is a C<query> method's result class.
If this value is defined, C<$result_class->new($handler, $sth)> is called in C<query()> and C<query()> returns the instance.

=item trace_query : Bool

Enables to inject a caller information as SQL comment.

=item trace_ignore_if : CodeRef

Ignore to inject the SQL comment when trace_ignore_if's return value is true.

=item no_ping : Bool

By default, ping before each executing query.
If it affect performance then you can set to true for ping stopping.

=item dbi_class : ClassName

By default, this module uses generally L<DBI> class.
For example, if you want to use another custom class compatibility with DBI, you can use it with this option.


=item prepare_method : Str

By default, this module uses generally L<prepare> method.
For example, if you want to use C<prepare_cached> method or other custom method compatibility with C<prepare> method, you can use it with this option.

=back

=item my $handler = DBIx::Handler->connect($dsn, $user, $pass, $opts);

connect method is alias for new method.

=item my $dbh = $handler->dbh;

get fork safe DBI handle.

=item $handler->disconnect;

disconnect current database handle.

=item my $txn_guard = $handler->txn_scope

Creates a new transaction scope guard object.

    do {
        my $txn_guard = $handler->txn_scope;
            # some process
        $txn_guard->commit;
    }

If an exception occurs, or the guard object otherwise leaves the scope
before C<< $txn->commit >> is called, the transaction will be rolled
back by an explicit L</txn_rollback> call. In essence this is akin to
using a L</txn_begin>/L</txn_commit> pair, without having to worry
about calling L</txn_rollback> at the right places. Note that since there
is no defined code closure, there will be no retries and other magic upon
database disconnection.

=item $txn_manager = $handler->txn_manager

Get the L<DBIx::TransactionManager> instance.

=item $handler->txn_begin

start new transaction.

=item $handler->txn_commit

commit transaction.

=item $handler->txn_rollback

rollback transaction.

=item $handler->in_txn

are you in transaction?

=item my @result = $handler->txn($coderef);

execute $coderef in auto transaction scope.

begin transaction before $coderef execute, do $coderef with database handle, after commit or rollback transaction.

  $handler->txn(sub {
      my $dbh = shift;
      $dbh->do(...);
  });

equals to:

  $handler->txn_begin;
      my $dbh = $handler->dbh;
      $dbh->do(...);
  $handler->txn_rollback;

=item my @result = $handler->run($coderef);

execute $coderef.

  my $rs = $handler->run(sub {
      my $dbh = shift;
      $dbh->selectall_arrayref(...);
  });

or

  my @result = $handler->run(sub {
      my $dbh = shift;
      $dbh->selectrow_array('...');
  });

=item my $sth = $handler->query($sql, [\@bind | \%bind]);

execute query. return database statement handler.

=item my $sql = $handler->trace_query_set_comment($sql);

inject a caller information as a SQL comment to C<$sql> when trace_query is true.

=back

=head2 ACCESSORS

The setters and the getters for options.

=over 4

=item result_class

=item trace_query

=item trace_ignore_if

=item no_ping

=item on_connect_do

=item on_disconnect_do

=back

=head1 AUTHOR

Atsushi Kobayashi E<lt>nekokak _at_ gmail _dot_ comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

