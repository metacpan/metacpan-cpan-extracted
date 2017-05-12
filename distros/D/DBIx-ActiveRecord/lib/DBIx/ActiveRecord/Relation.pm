package DBIx::ActiveRecord::Relation;
use strict;
use warnings;
use Carp;

use DBIx::ActiveRecord;
use DBIx::ActiveRecord::Scope;

use overload '@{}' => \&all;

sub new {
    my ($self, $model) = @_;
    bless {model => $model, arel => $model->arel}, $self;
}

sub scoped {
    my ($self) = @_;
    my $s = __PACKAGE__->new($self->{model});
    $s->{arel} = $self->{arel}->clone;
    $s;
}

sub to_sql {shift->{arel}->to_sql}
sub _binds {shift->{arel}->binds}

our $AUTOLOAD;
sub AUTOLOAD {
    my $self = shift;
    $AUTOLOAD =~ /([^:]+)$/;
    my $m = $1;
    my $s = $self->{model}->_global->{scopes}->{$m};
    croak "method missing $AUTOLOAD" if !$s;
    $s->($self->scoped, @_);
}

sub DESTROY{}

sub all {
    my $self = shift;
    $self->{cache}->{all} ||= DBIx::ActiveRecord::Scope::all($self, @_);
}

sub first {
    my $self = shift;
    return $self->{cache}->{all}->[0] if $self->{cache}->{all};
    return $self->{cache}->{first} if exists $self->{cache}->{first};
    $self->{cache}->{first} = DBIx::ActiveRecord::Scope::first($self, @_);
}

sub last {
    my $self = shift;
    return $self->{cache}->{all}->[-1] if $self->{cache}->{all};
    return $self->{cache}->{last} if exists $self->{cache}->{last};
    $self->{cache}->{last} = DBIx::ActiveRecord::Scope::last($self, @_);
}

sub count {
    my ($self) = @_;
    return $self->{cache}->{count} if exists $self->{cache}->{count};
    my $arel = $self->{arel}->count;
    my $sth = $self->{model}->dbh->prepare($arel->to_sql);
    $sth->execute($arel->binds) || croak $sth->errstr;
    my $row = $sth->fetchrow_arrayref;
    $self->{cache}->{count} = $row->[0];
}

1;
