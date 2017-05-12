package Asterisk::LCR::Object;
use warnings;
use strict;

sub new
{
    my $class = shift;
    my $self  = bless { @_ }, $class;
    $self->validate() && return $self;
    return;
}

sub validate
{
    return 1;
}


1;


__END__
