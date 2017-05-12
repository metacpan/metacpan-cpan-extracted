package DBIx::PgLink::Types;

use strict;
use Moose::Util::TypeConstraints;
use DBIx::PgLink::Local;

subtype 'StrNull' # nullable string
  => as 'Item'
  => where { !defined || ! ref };


enum 'Action' => qw/S I U D/;

our %action_name = (
  'S' => 'SELECT',
  'I' => 'INSERT',
  'U' => 'UPDATE',
  'D' => 'DELETE',
);

subtype 'PostgreSQLArray'
  => as 'ArrayRef';

coerce 'PostgreSQLArray'
  => from 'Str'
     => via {
       my @a = pg_dbh->pg_to_perl_array($_);
       return \@a;
     };


subtype 'PostgreSQLHash'
  => as 'HashRef';

coerce 'PostgreSQLHash'
  => from 'Str'
     => via { pg_dbh->pg_to_perl_hash($_) };


subtype TypeMap
  => as 'HashRef'
  => where {
       exists $_->{remote_type} # Str
    && exists $_->{local_type}  # Str
  };


# NOTE: column metadata is just hashref, not an object
subtype 'ColumnsMetadata'
  => as 'ArrayRef'
  => where {
    for my $c (@{$_}) {
      return 0 unless ref $c eq 'HASH';
    }
    return 1;
  };


1;
