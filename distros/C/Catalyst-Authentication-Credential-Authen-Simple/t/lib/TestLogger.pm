package TestLogger;

use Test::More;

sub new {
    return(bless {}, $_[0]);
}

sub info {
    my ($self, $message) = @_;
    cmp_ok($message, 'eq', 'just calling', 'got correct log info');
    ok(1, 'info method got called');
}

sub debug {
    my ($self, $message) = @_;
    cmp_ok($message, 'eq', 'just calling', 'got correct log info');
    ok(1, 'debug method got called');
}

sub error {
    my ($self, $message) = @_;
    cmp_ok($message, 'eq', 'just calling', 'got correct log info');
    ok(1, 'error method got called');
}

sub warn {
    my ($self, $message) = @_;
    cmp_ok($message, 'eq', 'just calling', 'got correct log info');
    ok(1, 'warn method got called');
}

1;
