# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
#
# This file is part of DBIx-Schema-UpToDate
#
# This software is copyright (c) 2011 by Randy Stauner.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package
  Test_Schema;

require DBIx::Schema::UpToDate;
our @ISA = qw(DBIx::Schema::UpToDate);

sub updates {
  shift->{updates} ||= [
    # v1
    sub {
      my ($self) = @_;
      $self->dbh->do(q[CREATE TABLE tbl1 (fld1 text, fld2 int)]);
      $self->dbh->do(q[INSERT INTO tbl1 VALUES('goo', 1)]);
    },
    # v2
    sub {
      my ($self) = @_;
      $self->dbh->do(q[INSERT INTO tbl1 VALUES('ber', 2)]);
    },
  ];
}

# test with a table name that needs to be quoted
sub version_table_name {
  'schema version';
}

1;
