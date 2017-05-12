#------------------------------------------------------------------------------
# DBO test skeleton: drop table and disconnect.
#------------------------------------------------------------------------------

test {
  foreach my $table (@{$schema->{tables}}) {
    $dbh->dosql("DROP TABLE $table->{name}");
  }
};

test { $dbh->disconnect or die "Failed to disconnect ". $dbh->errstr };

1;
