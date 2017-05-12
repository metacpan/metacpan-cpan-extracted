package TestApp::Model::HTML::FormFu;
use strict;
use base qw(Catalyst::Model::HTML::FormFu);
use POSIX qw(strftime);
our $seq = 1;

sub today {
    my ($self) = @_;
    join('-', strftime('%Y-%m-%d', localtime), $seq++);
}

1;