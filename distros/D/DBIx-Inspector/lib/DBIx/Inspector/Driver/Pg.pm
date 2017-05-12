package DBIx::Inspector::Driver::Pg;
use strict;
use warnings;
use utf8;
use base qw/DBIx::Inspector::Driver::Base/;
use DBIx::Inspector::ForeignKey::Pg;
use DBIx::Inspector::Table::Pg;
use DBIx::Inspector::Column::Pg;
use DBIx::Inspector::Iterator::Null;

sub new {
    my ($class, @args) = @_;

    my $self = $class->SUPER::new(@args);

    # default schema name for Pg is 'public'
    if (not exists $self->{schema}) {
        $self->{schema} = 'public';
    }

    return $self;
}

sub foreign_keys {
    my ($self, @args) = @_;

    my $sth = $self->dbh->foreign_key_info(@args);
    unless (defined $sth) {
        # DBD::Pg's foreign_key_info returns undef at sometime
        return wantarray ? ( ) : DBIx::Inspector::Iterator::Null->new( );
    }
    my $iter = DBIx::Inspector::Iterator->new(
        callback => sub { DBIx::Inspector::ForeignKey::Pg->new(inspector => $self, %{$_[0]}) },
        sth =>$sth,
    );
    return wantarray ? $iter->all : $iter;
}

sub tables {
    my ($self, $table) = @_;

    my $sth = $self->{dbh}->table_info( $self->catalog, $self->schema, $table, my $type='TABLE' );

    my $iter = DBIx::Inspector::Iterator->new(
        callback => sub { DBIx::Inspector::Table::Pg->new(inspector => $self, %{$_[0]}) },
        sth =>$sth,
    );
    return wantarray ? $iter->all : $iter;
}

sub primary_key {
    my ($self, $table) = @_;

    my $sth = $self->dbh->primary_key_info( $self->catalog, $self->schema, $table );
    unless (defined $sth) {
        return wantarray ? ( ) : DBIx::Inspector::Iterator::Null->new( );
    }
    my $iter = DBIx::Inspector::Iterator->new(
        callback => sub { DBIx::Inspector::Column::Pg->new(inspector => $self, %{$_[0]}) },
        sth =>$sth,
    );
    return wantarray ? $iter->all : $iter;
}

sub columns {
    my ($self, $table, $column) = @_;
    $column = '%' if not defined $column;

    my $sth = $self->dbh->column_info( $self->catalog, $self->schema, $table, $column );
    my $iter = DBIx::Inspector::Iterator->new(
        callback =>
          sub { DBIx::Inspector::Column::Pg->new( table => $self, %{ $_[0] } ) },
        sth => $sth,
    );
    return wantarray ? $iter->all : $iter;
}


1;

