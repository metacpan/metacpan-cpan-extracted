package TestServer;
use strict;
use vars qw($VERSION); $VERSION = sprintf("%d.%02d", q$Revision: 1.1 $ =~ /(\d+)\.(\d+)/);

my ($MinValue, $MaxValue);

sub new {
    my $cls = shift;
    ($MinValue, $MaxValue) = (999999,0);
    my @ary = Loop(@_);
    return Loop(@_);
}

sub Loop {
    my $self = shift;
    map { Max($_) } @_;
    map { Min($_) } @_;
    return ($MinValue, $MaxValue) if wantarray;
    return [$MinValue, $MaxValue];
}

sub Max {
    $MaxValue = ($MaxValue > $_[0])?$MaxValue:$_[0];
    return $MaxValue;
}

sub Min {
    $MinValue = ($MinValue < $_[0])?$MinValue:$_[0];
    return $MinValue;
}

1;