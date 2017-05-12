package Dancer2::Plugin::Pg::Core;

use Moo;
use DBI;

has 'dbh' => (
    is => 'ro',
    writer => 'set_dbh'
);

has ['host', 'base', 'port', 'username', 'password'] => (
    is => 'ro'
);

has 'options' => (
    is => 'ro',
    default => sub {
        {AutoCommit => 1, AutoInactiveDestroy => 1, PrintError => 0, RaiseError => 1}
    }
);

has ['table', 'returning'] => (
    is => 'rw'
);

has ['keys', 'values', 'type', 'reference'] => (
    is => 'rw',
    default => sub {
        []
    }
);

sub BUILD {
    my $self = shift;
    
    my $dsn = 'dbi:Pg:';
    $dsn .= 'dbname=' . $self->base if $self->base;
    $dsn .= ';host=' . $self->host if $self->host;
    $dsn .= ';port=' . $self->port if $self->port;
    
    my $dbh = DBI->connect($dsn, $self->username, $self->password, $self->options) || die $DBI::errstr;
    $self->set_dbh($dbh);
    return $self;
}

sub query {
    my $self = shift;
    
    my $sql = shift;
    my $sth = $self->dbh->prepare($sql);
    die $self->dbh->errstr if $self->dbh->err;
    $sth->execute(@_);
    return $sth;
}

sub selectOne {
    my $self = shift;
    
    my $result = $self->dbh->selectrow_arrayref(shift, undef, @_);
    die $self->dbh->errstr if $self->dbh->err;
    return $result->[0];
}

sub selectRow {
    my $self = shift;
    
    my $result = $self->dbh->selectrow_hashref(shift, undef, @_);
    die $self->dbh->errstr if $self->dbh->err;
    return $result;
}

sub selectAll {
    my $self = shift;
    
    my $result = $self->dbh->selectall_arrayref(shift, {Slice=>{}}, @_);
    die $self->dbh->errstr if $self->dbh->err;
    return [] unless $result;
    return [$result] unless ref($result) eq 'ARRAY';
    return $result;
}

sub column {
    my ($self, $key, $value) = @_;
    
    push(@{$self->keys}, $key);
    if (ref($value) eq 'HASH') {
        push(@{$self->type}, keys %{$value});
        push(@{$self->values}, values %{$value});
    }else{
        push(@{$self->type}, undef);
        push(@{$self->values}, $value);
    }
    push(@{$self->reference}, '?');
}

sub insert {
    my $self = shift;
    
    my $sql = 'INSERT INTO ' . $self->table . ' (';
    $sql .= join(',',@{$self->keys});
    $sql .= ') VALUES (';
    $sql .= join(',', @{$self->reference});
    $sql .= ')';
    $sql .= ' RETURNING ' . $self->returning if $self->returning;
    my $sth = $self->query($sql, @{$self->values});
    $self->_clean unless $self->returning;
    return 0 unless $sth;
    if ($self->returning && $sth->rows > 0) {
        return $self->_getReturning($sth, $self->returning);
    }else{
        $self->_clean;
    }
    return $sth || 1;
}

sub update {
    my ($self, %wheres) = @_;
    
    my $sql = undef;
    for(my $i=0; $i<scalar(@{$self->keys}); $i++){
        unless($sql){
            $sql = 'UPDATE ' . $self->table . ' SET ';
            if (${$self->type}[$i]) {
                $sql .= ${$self->keys}[$i] . ' ' . ${$self->type}[$i] . ' ?';
            }else{
                $sql .= ${$self->keys}[$i] . ' = ?';
            }
        }else{
            if (${$self->type}[$i]) {
                $sql .= ', ' . ${$self->keys}[$i] . ' ' . ${$self->type}[$i] . ' ?';
            }else{
                $sql .= ', ' . ${$self->keys}[$i] . ' = ?';
            }
        }
    }
    my $where = '';
    foreach(keys %wheres){
        if ($_ =~ /and|or/i) {
            foreach my $key (keys %{$wheres{$_}}){
                $where .= ' ' . uc($_) if $where;
                if (ref($wheres{$_}{$key}) eq 'HASH') {
                    $where .= ' ' . $key;
                    $where .= ' ' . $_ . ' ?' for(keys %{$wheres{$_}{$key}});
                    push(@{$self->values}, values %{$wheres{$_}{$key}});
                }else{
                    $where .= ' ' . $key . ' = ?';
                    push(@{$self->values}, $wheres{$_}{$key});
                }
            }
        }else{
            $where .= ' AND' if $where;
            if (ref($wheres{$_}) eq 'HASH') {
                $where .= ' ' . $_;
                $where .= ' ' . $_ . ' ?' for(keys %{$wheres{$_}});
                push(@{$self->values}, values %{$wheres{$_}});
            }else{
                $where .= ' ' . $_ . ' = ?';
                push(@{$self->values}, $wheres{$_});
            }
        }
    }
    $sql .= ' WHERE' . $where;
    $sql .= ' RETURNING ' . $self->returning if $self->returning;
    my $sth = $self->query($sql, @{$self->values});
    $self->_clean unless $self->returning;
    return 0 unless $sth;
    if ($self->returning && $sth->rows > 0) {
        return $self->_getReturning($sth, $self->returning);
    }else{
        $self->_clean;
    }
    return $sth || 1;
}

sub delete {
    my ($self, %wheres) = @_;
    
    my $sql = 'DELETE FROM ' . $self->table;
    my $where = '';
    foreach(keys %wheres){
        if ($_ =~ /and|or/i) {
            foreach my $key (keys %{$wheres{$_}}){
                $where .= ' ' . uc($_) if $where;
                if (ref($wheres{$_}{$key}) eq 'HASH') {
                    $where .= ' ' . $key;
                    $where .= ' ' . $_ . ' ?' for(keys %{$wheres{$_}{$key}});
                    push(@{$self->values}, values %{$wheres{$_}{$key}});
                }else{
                    $where .= ' ' . $key . ' = ?';
                    push(@{$self->values}, $wheres{$_}{$key});
                }
            }
        }else{
            $where .= ' AND' if $where;
            if (ref($wheres{$_}) eq 'HASH') {
                $where .= ' ' . $_;
                $where .= ' ' . $_ . ' ?' for(keys %{$wheres{$_}});
                push(@{$self->values}, values %{$wheres{$_}});
            }else{
                $where .= ' ' . $_ . ' = ?';
                push(@{$self->values}, $wheres{$_});
            }
        }
    }
    $sql .= ' WHERE' . $where;
    $sql .= ' RETURNING ' . $self->returning if $self->returning;
    my $sth = $self->query($sql, @{$self->values});
    $self->_clean unless $self->returning;
    return 0 unless $sth;
    if ($self->returning && $sth->rows > 0) {
        return $self->_getReturning($sth, $self->returning);
    }else{
        $self->_clean;
    }
    return $sth || 1;
}

sub lastInsertID {
    my $self = shift;
    
    my $last_insert_id = $self->dbh->last_insert_id(undef, undef, shift||undef, shift||undef);
    die $self->dbh->errstr if $self->dbh->err;
    return $last_insert_id;
}

sub _getReturning {
    my ($self, $sth, $columns) = @_;
    
    my @keys = split(/\,/, $columns);
    my @values = @{$sth->fetch};
    my %hash;
    for(my $i=0; $i<scalar(@keys); $i++){
        $keys[$i] =~ s/\s//g;
        $hash{$keys[$i]} = $values[$i];
    }
    $self->_clean;
    return \%hash;
}

sub _clean {
    my $self = shift;
    
    $self->table('');
    $self->returning('');
    $self->keys([]);
    $self->values([]);
    $self->type([]);
    $self->reference([]);
}

1;

__END__

=encoding utf8
 
=head1 NAME

Dancer2::Plugin::Pg::Core

=head1 SYNOPSIS

see L<Dancer2::Plugin::Pg>

=head1 AUTHOR
 
Lucas Tiago de Moraes, C<< <lucastiagodemoraes@gmail.com> >>

=head1 LICENSE AND COPYRIGHT
 
This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.
 
See http://dev.perl.org/licenses/ for more information.