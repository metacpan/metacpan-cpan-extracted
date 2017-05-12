package TestHelpers;
use strict;
use warnings;
use 5.006000;
use Test::Expect;
use Sub::Exporter -setup => {
    exports => [qw(e_value e_defined)],
};

sub e_value {
    my ($name,$expected,$note) = @_;
    expect_send($name);
    expect_like(qr/^\Q$expected\E$/m,$note);
}
sub e_defined {
    my ($name,$defined,$note) = @_;
    expect_send("defined($name)?'ok':'not'");
    my $r = $defined ? qr/^ok$/m : qr/^not$/m;
    expect_like($r,$note);
}

1;
