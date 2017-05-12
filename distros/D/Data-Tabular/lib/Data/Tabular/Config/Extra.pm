# Copyright (C) 2003-2007, G. Allen Morris III, all rights reserved
use strict;

package Data::Tabular::Config::Extra;

sub new
{
    my $class = shift;
    my $self = bless { @_ }, $class;
    $self;
}

sub output
{
die;
    my $ret = $_[0]->{output};
    $_[0]->{output} = $_[1] if $_[1];
    $ret;
}

1;
