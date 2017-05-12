package TestApp;
use strict;
use warnings;
use Config::Micro;

sub new {
    my ($class, %opts) = @_;
    my $conf_file = Config::Micro->file(%opts);
    my $conf = require "$conf_file";
    return bless +{ config => $conf }, $class;
}

sub foo {
    my $self = shift;
    return $self->{config}{env};
}

1;
