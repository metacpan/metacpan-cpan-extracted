package DBIx::EAV::Table;

use Moo;
use SQL::Abstract;
use constant {
    SQL_DEBUG => $ENV{DBIX_EAV_TRACE}
};

my $sql = SQL::Abstract->new;

has '_dbh', is => 'ro', required => 1, init_arg => 'dbh';
has 'name', is => 'ro', required => 1;
has 'columns', is => 'ro', required => 1;
has 'tenant_id', is => 'ro';


sub BUILD {
    my $self = shift;

    die sprintf "Error instantiating table '%s': tenant_id is required!"
        if $self->has_column('tenant_id') && !defined $self->tenant_id;
}



sub has_column {
    my ($self, $name) = @_;
    foreach (@{$self->columns}) {
        return 1 if $_ eq $name;
    }
    0;
}

sub select {
    my ($self, $where) = @_;
    $where //= {};
    $where = $self->_mangle_where($where);

    my ($stmt, @bind) = $sql->select($self->name.' AS me', $self->columns, $where);
    my ($rv, $sth) = $self->_do($stmt, \@bind);
    $sth;
}

sub select_one {
    my ($self, $where) = @_;
    $self->select($where)->fetchrow_hashref;
}

sub insert {
    my ($self, $data) = @_;

    $data->{tenant_id} = $self->tenant_id
        if $self->has_column('tenant_id');

    my ($stmt, @bind) = $sql->insert($self->name, $data);
    my ($rv, $sth) = $self->_do($stmt, \@bind);

    if ($rv == 1) {
        return $self->_dbh->last_insert_id(undef, undef, undef, undef) || 1;
    }
    else {
        $rv;
    }

}

sub update {
    my ($self, $data, $where) = @_;
    $where = $self->_mangle_where($where);

    my ($stmt, @bind) = $sql->update($self->name, $data, $where);
    my ($rv, $sth) = $self->_do($stmt, \@bind);
    $rv;
}

sub delete {
    my ($self, $where, $opts) = @_;
    $opts //= {};

    my $stmt = $opts->{join} ? sprintf("DELETE me FROM %s AS me", $self->name)
                             : sprintf("DELETE FROM %s", $self->name);

    # JOIN
    while (my ($table, $spec) = each %{ $opts->{join} || {} }) {

        my ($join_criteria, @bind) = $sql->where($spec);
        while ( (my $offset = index($join_criteria, '?')) > -1) {
            my $val = shift @bind;
            substr($join_criteria, $offset, 1, $val);
        }
        $join_criteria =~ s/^\s*WHERE//;
        $join_criteria =~ s/\btheir\./$table./g;
        $stmt .= " INNER JOIN $table ON $join_criteria";
    }

    # WHERE
    my ($where_part, @bind);
    if ($where) {
        $where = $self->_mangle_where($where);
        ($where_part, @bind) = $sql->where($where);
        $stmt .= " $where_part";
    }

    my ($rv, $sth) = $self->_do($stmt, \@bind);
    $rv;
}

sub _mangle_where {
    my ($self, $where) = @_;

    return $where unless $self->has_column('tenant_id');

    if (ref $where eq 'HASH') {
        $where->{tenant_id} = $self->tenant_id;
    }
    else {
        $where = { -and => [ tenant_id => $self->tenant_id, $where ] };
    }

    $where;
}



sub _do {
    my ($self, $stmt, $bind) = @_;

    if (SQL_DEBUG) {
        my $i = 0;
        printf STDERR "$stmt: %s\n",
            join('  ', map { $i++.'='.$_ } @$bind);
    }

    my $sth = $self->_dbh->prepare($stmt);
    my $rv = $sth->execute(ref $bind eq 'ARRAY' ? @$bind : ());
    die $sth->errstr unless defined $rv;

    return ($rv, $sth);
}





1;

__END__

=encoding utf-8

=head1 NAME

DBIx::EAV::Table - Abstracts common operations on a database table.

=head1 SYNOPSIS

    my $table = DBIx::EAV::Table->new(
        dbh     => $dbh,
        name    => 'eav_entities',
        columns => [qw/ id entity_type_id ... /],
        tenant_id => ... # optional
    )

=head1 DESCRIPTION

This class provides a simple abstraction for the most common operations on a database table.
You probably will never need to use this class (or objects) directly.

=head1 TENANT ID

=head1 METHODS

=head2 new

=head2 name

=head2 tenant_id

=head2 columns

=head2 has_column

=head2 select

=head2 select_one

=head2 insert

=head2 update

=head2 delete

=head1 LICENSE

Copyright (C) Carlos Fernando Avila Gratz.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Carlos Fernando Avila Gratz E<lt>cafe@kreato.com.brE<gt>

=cut
