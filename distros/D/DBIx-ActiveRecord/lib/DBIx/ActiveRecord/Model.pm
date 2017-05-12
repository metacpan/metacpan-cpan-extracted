package DBIx::ActiveRecord::Model;
use strict;
use warnings;
use Carp;

use POSIX;

use DBIx::ActiveRecord::Arel;
use DBIx::ActiveRecord;
use DBIx::ActiveRecord::Relation;
use DBIx::ActiveRecord::Scope;

use constant INSERT_RECORD_TIMESTAMPS => [qw/created_at updated_at/];
use constant UPDATE_RECORD_TIMESTAMPS => [qw/updated_at/];
use constant MAIN_TABLE_ALIAS => 'me';

sub dbh {DBIx::ActiveRecord->dbh}

sub _global {
    my $self = shift;
    my $p = ref $self || $self;
    $DBIx::ActiveRecord::GLOBAL{$p} ||= {};
}

sub table {
    my ($self, $table_name) = @_;
    return $self->_global->{table} if !$table_name;
    $self->_global->{table} = $table_name;
    $self->_global->{arel} = DBIx::ActiveRecord::Arel->create($table_name);
}

sub columns {
    my $self = shift;
    push @{$self->_global->{columns}}, @_;
}

sub primary_keys {
    my $self = shift;
    push @{$self->_global->{primary_keys}}, @_;
}

sub belongs_to {
    my ($self, $name, $package, $opt) = @_;

    $self->_global->{belongs_to} ||= [];
    push @{$self->_global->{belongs_to}}, [$name, $package, $opt];
}

sub has_one {
    my ($self, $name, $package, $opt) = @_;
    $self->_add_has_relation($name, $package, $opt, 1);
}

sub has_many {
    my ($self, $name, $package, $opt) = @_;
    $self->_add_has_relation($name, $package, $opt, 0);
}

sub _add_has_relation {
    my ($self, $name, $package, $opt, $has_one) = @_;

    $self->_global->{has_relation} ||= [];
    push @{$self->_global->{has_relation}}, [$name, $package, $opt, $has_one];
}

sub default_scope {
    my ($self, $coderef) = @_;
    $self->_global->{default_scope} = $coderef;
}

sub scope {
    my ($self, $name, $coderef) = @_;
    $self->_global->{scopes}->{$name} = $coderef;
}

our $AUTOLOAD;
sub AUTOLOAD {
    my $self = shift;
    $AUTOLOAD =~ /([^:]+)$/;
    my $m = $1;
    my $s = $self->_global->{scopes}->{$m};
    croak "method missing $AUTOLOAD" if !$s;
    $s->($self->scoped, @_);
}
sub DESTROY{}

sub arel {shift->_global->{arel}->clone->as(MAIN_TABLE_ALIAS)}

sub transaction {
    my $self = shift;
    DBIx::ActiveRecord->transaction(@_);
}

sub all {DBIx::ActiveRecord::Scope::all(@_)}
sub first {DBIx::ActiveRecord::Scope::first(@_)}
sub last {DBIx::ActiveRecord::Scope::last(@_)}

sub scoped {
    my ($self) = @_;
    my $r = DBIx::ActiveRecord::Relation->new($self);
    my $ds = $self->_global->{default_scope};
    $r = $ds->($r) if $ds;
    $r;
}

sub unscoped {
    my ($self) = @_;
    DBIx::ActiveRecord::Relation->new($self);
}

sub new {
    my ($self, $hash) = @_;
    bless {-org => {}, -set => $hash || {}, in_storage => 0}, $self;
}

sub _new_from_storage {
    my ($self, $hash) = @_;
    bless {-org => $hash, -set => {}, in_storage => 1}, $self;
}

sub get_column {
    my ($self, $name) = @_;
    exists $self->{-set}->{$name} ? $self->{-set}->{$name} : $self->{-org}->{$name};
}

sub set_column {
    my ($self, $name, $value) = @_;
    $self->{-set}->{$name} = $value;
}

sub to_hash {
    my $self = shift;
    my %h;
    foreach (keys %{$self->{-org}}, keys %{$self->{-set}}) {
        $h{$_} = $self->get_column($_);
    }
    \%h;
}

sub in_storage { shift->{in_storage} }

sub create {
    my ($self, $hash) = @_;
    my $o = $self->new($hash);
    $o->save;
    $o;
}

sub save {
    my $self = shift;
    my $res = $self->in_storage ? $self->update(@_) : $self->insert(@_);
    $self->{in_storage} = 1;
    %{$self->{-org}} = (%{$self->{-org}}, %{$self->{-set}});
    $self->{-set} = {};
    $res;
}

sub insert {
    my ($self) = @_;
    return if $self->in_storage;

    my $s = $self->scoped;
    $self->_record_timestamp(INSERT_RECORD_TIMESTAMPS);
    my $arel = $s->{arel}->insert($self->to_hash, $self->_global->{columns});
    my $sth = $self->dbh->prepare($arel->to_sql);
    my $res = $sth->execute($arel->binds) || croak $sth->errstr;

    my $insert_id = $sth->{'insertid'} || $self->dbh->{'mysql_insertid'};
    $self->{-set}->{$self->_global->{primary_keys}->[0]} = $insert_id if $insert_id;
    $res;
}

sub update {
    my ($self) = @_;
    return if !%{$self->{-set}};
    return if !$self->in_storage;

    my $s = $self->_pkey_scope;
    $self->_record_timestamp(UPDATE_RECORD_TIMESTAMPS);
    my $arel = $s->{arel}->update($self->{-set}, $self->_global->{columns});
    my $sth = $self->dbh->prepare($arel->to_sql);
    $sth->execute($arel->binds) || croak $sth->errstr;
}

sub delete {
    my ($self) = @_;
    return if !$self->in_storage;

    my $s = $self->_pkey_scope;
    my $arel = $s->{arel}->delete;
    my $sth = $self->dbh->prepare($arel->to_sql);
    $sth->execute($arel->binds) || croak $sth->errstr;
}

sub count { shift->scoped->count }

sub _record_timestamp {
    my ($self, $columns) = @_;
    my %cs = map {$_ => 1} @{$self->_global->{columns}};
    my $now = POSIX::strftime("%Y-%m-%d %H:%M:%S", localtime);
    foreach (@$columns) {
        $self->{-set}->{$_} = $now if $cs{$_};
    }
}

sub _pkey_scope {
    my $self = shift;
    my $s = $self->unscoped;
    $s = $s->eq($_ => $self->{-org}->{$_} || croak 'no primary key') for @{$self->_global->{primary_keys}};
    $s;
}

sub instantiates_by_relation {
    my ($self, $relation) = @_;
    my $sth = $self->dbh->prepare($relation->to_sql);
    $sth->execute($relation->_binds) || croak $sth->errstr;
    my @all;
    while (my $row = $sth->fetchrow_hashref) {
        push @all, $self->_new_from_storage($row);
    }
    \@all;
}

1;
