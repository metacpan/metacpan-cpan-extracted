package DBIx::MoCo::Column::MyColumn;

sub MyColumn {
    my $self = shift;
    return "My Column $$self";
}

1;
