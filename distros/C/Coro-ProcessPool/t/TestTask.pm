package t::TestTask;

sub new {
    my ($class, @args) = @_;
    return bless {}, $class;
}

sub run {
    return 42;
}

1;
