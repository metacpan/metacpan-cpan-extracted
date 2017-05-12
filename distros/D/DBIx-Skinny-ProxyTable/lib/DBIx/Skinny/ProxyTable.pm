package DBIx::Skinny::ProxyTable;
use strict;
use warnings;
our $VERSION = '0.10';
use DBIx::Skinny::ProxyTable::Rule;
use Carp;
use DBIx::Skinny::Util qw();

sub new {
    my ($class, $skinny) = @_;
    my $self = { skinny => $skinny };
    bless $self, $class;
    return $self;
}

sub skinny {
    my $self = $_[0];
    $self->{skinny};
}

sub set {
    my ($self, $from, $to) = @_;

    $self->_validate($from);
    $self->_validate($to);

    my $skinny = $self->skinny;
    my $schema = $skinny->schema;
    my $_schema_info = $schema->schema_info;
    $_schema_info->{$to} = $_schema_info->{$from};

    $self;
}

# This method is safety net for creating wrong table name or executing SQL injection.
sub _validate {
    my ($self, $str) = @_;
    if ( $str !~ /^[a-zA-Z0-9_]+$/ ) {
        Carp::croak("$str should be normal character");
    }
}

sub copy_table {
    my ($self, $from, $to) = @_;

    $self->_validate($from);
    $self->_validate($to);
    my $dbd = $self->skinny->dbd && ref $self->skinny->dbd;
    if ( $dbd && $dbd =~ /^DBIx::Skinny::DBD::(.+)$/ ) {
        $dbd = $1;
        if ( $dbd eq 'mysql' ) {
            $self->skinny->dbh->do(sprintf(q{ CREATE TABLE IF NOT EXISTS %s LIKE %s }, $to, $from));
        } elsif ( $dbd eq 'SQLite' ) {
            my $record = $self->skinny->dbh->selectcol_arrayref(q{
                SELECT sql FROM
                    ( SELECT * FROM sqlite_master UNION ALL
                    SELECT * FROM sqlite_temp_master)
                WHERE type != 'meta' and tbl_name = ?
            }, {}, $from)->[0]
                or Carp::croak("Can't find table $from in sqlite_master or sqlite_temp_master");
            my $sql = $record;
            $sql =~ s/TABLE $from \(/TABLE IF NOT EXISTS $to (/;
            $self->skinny->dbh->do($sql);
        } else {
            die "DBIx::Skinny::DBD::$dbd is not supported";
        }
    }
}

sub rule {
    my ($self, $base, @args) = @_;
    return DBIx::Skinny::ProxyTable::Rule->new($self, $base, @args);
}

1;
__END__

=head1 NAME

DBIx::Skinny::ProxyTable - handling dynamic table for DBIx::Skinny

=head1 SYNOPSIS

  package Proj::DB;
  use DBIx::Skinny;
  use DBIx::Skinny::Mixin modules => [qw(ProxyTable)];

  package Proj::DB::Schema;
  use DBIx::Skinny::Schema;
  use DBIx::Skinny::Schema::ProxyTableRule;

  install_table 'access_log' => shcema {
    proxy_table_rule 'named_strftime', 'access_log_%Y%m', 'accessed_on';

    pk 'id';
    columns qw/id/;
  };

  package main;

  my $rule = Proj::DB->proxy_table->rule('access_log', accessed_on => DateTime->today);
  $rule->table_name; #=> "access_log_200901"
  $rule->copy_table;

  my $iter = Proj::DB->search($rule->table_name, { foo => 'bar' });

  # or you can call manually. ( NOT RECOMMEND )
  Proj::DB->proxy_table->set(access_log => "access_log_200901");
  Proj::DB->proxy_table->copy_table(access_log => "access_log_200901");

=head1 DESCRIPTION

DBIx::Skinny::ProxyTable is DBIx::Skinny::Mixin for partitioning table.

=head1 METHOD

=head2 set($from, $to)

set schema information for table that name is $to based on $from to your project skinny's schema.
I don't recommend to call this method directly because of distributing naming rule.

see also rule method.

=head2 copy_table($from, $to)

copy table from $from to $to if it $to is not exist.
SQLite and MySQL only support.

=head2 rule($from, @args)

create DBIx::Skinny::ProxyTable::Rule object.
@args is followed by your project skinny's schema definition.

see also L<DBIx::Skinny::ProxyTable::Rule>

=head1 AUTHOR

Keiji Yoshimi E<lt>walf443 at gmail dot comE<gt>

=head1 SEE ALSO

L<DBIx::Skinny>, L<DBIx::Class::ProxyTable>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
