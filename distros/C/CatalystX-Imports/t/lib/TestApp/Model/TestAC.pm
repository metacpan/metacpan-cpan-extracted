package TestApp::Model::TestAC;
use warnings;
use strict;

sub new {
    my $class = shift;
    return bless { @_ }, $class;
}

sub ACCEPT_CONTEXT {
    my ($class, $c, @args) = @_;
    $class->new( list => \@args );
}

sub join {
    my ($self, $sep) = @_;
    $sep ||= ', ',
    return join $sep, @{ $self->{list} || [] };
}

1;
