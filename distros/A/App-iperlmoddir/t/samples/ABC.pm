package ABC;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(foo);

sub foo {
    return 6 * 7;
}

1;
