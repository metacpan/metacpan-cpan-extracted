package Apache2::BalanceLogic::Plugin;

use strict;
use warnings;

sub new {
    my ( $class, $conf ) = @_;
    my $self = bless { conf => $conf, }, $class;
    return $self;
}

1;
