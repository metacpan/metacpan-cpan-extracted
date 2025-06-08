package DBIx::QuickORM::Schema;
use strict;
use warnings;

our $VERSION = '0.000011';

use Carp qw/confess croak/;
use Scalar::Util qw/blessed/;

use DBIx::QuickORM::Util qw/merge_hash_of_objs column_key/;

use DBIx::QuickORM::Link;

use DBIx::QuickORM::Util::HashBase qw{
    <name
    +tables
    <created
    <compiled
    <row_class
    <sql
    +_links
};

sub init {
    my $self = shift;

    delete $self->{+NAME} unless defined $self->{+NAME};

    $self->{+ROW_CLASS} //= 'DBIx::QuickORM::Row';

    $self->resolve_links;

    for my $table ($self->tables) {
        my $autofill = $table->row_class_autofill or next;
        $autofill->define_autorow($table->row_class, $table);
    }
}

sub tables      { values %{$_[0]->{+TABLES}} }
sub table       { $_[0]->{+TABLES}->{$_[1]} or croak "Table '$_[1]' is not defined" }
sub maybe_table { return $_[0]->{+TABLES}->{$_[1]} // undef }
sub _links      { delete $_[0]->{+_LINKS} }

sub add_table {
    my $self = shift;
    my ($name, $table) = @_;

    croak "Table '$name' already defined" if $self->{+TABLES}->{$name};

    return $self->{+TABLES}->{$name} = $table;
}

sub merge {
    my $self = shift;
    my ($other, %params) = @_;

    $params{+TABLES}    //= merge_hash_of_objs($self->{+TABLES}, $other->{+TABLES});
    $params{+NAME}      //= $self->{+NAME} if $self->{+NAME};
    $params{+ROW_CLASS} //= $other->{+ROW_CLASS};
    $params{+SQL}       //= $other->{+SQL};

    return ref($self)->new(%$self, %$other, %params);
}

sub clone {
    my $self   = shift;
    my %params = @_;

    $params{+TABLES}  //= {map { $_ => $self->{+TABLES}->{$_}->clone } keys %{$self->{+TABLES}}};
    $params{+NAME}    //= $self->{+NAME} if $self->{+NAME};

    return blessed($self)->new(%$self, %params);
}

sub resolve_links {
    my $self = shift;

    my @links = @{$self->_links // []};
    push @links => @{$_->_links // []} for values %{$self->{+TABLES}};

    for my $link (@links) {
        my ($local_set, $other_set, $debug) = @$link;
        $debug //= 'unknown';

        my ($local_tname, $local_cols, $local_alias) = @$local_set;
        my ($other_tname, $other_cols, $other_alias) = @$other_set;

        my $local_table = $self->{+TABLES}->{$local_tname} or confess "Cannot find table '$local_tname' ($debug)";
        my $other_table = $self->{+TABLES}->{$other_tname} or confess "Cannot find table '$other_tname' ($debug)";

        my $local_unique //= $other_table->unique->{column_key(@{$other_cols})} ? 1 : 0;
        my $other_unique //= $local_table->unique->{column_key(@{$local_cols})} ? 1 : 0;

        push @{$local_table->links} => DBIx::QuickORM::Link->new(
            local_table   => $local_tname,
            local_columns => $local_cols,
            other_table   => $other_tname,
            other_columns => $other_cols,
            unique        => $local_unique,
            aliases       => [grep { $_ } $local_alias],
            created       => $debug,
        );

        push @{$other_table->links} => DBIx::QuickORM::Link->new(
            local_table   => $other_tname,
            local_columns => $other_cols,
            other_table   => $local_tname,
            other_columns => $local_cols,
            unique        => $other_unique,
            aliases       => [grep { $_ } $other_alias],
            created       => $debug,
        );
    }

    return;
}

1;

__END__

