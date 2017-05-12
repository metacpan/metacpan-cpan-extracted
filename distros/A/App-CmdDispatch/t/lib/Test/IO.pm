package Test::IO;

use warnings;
use strict;

sub new
{
    my ($class, $input) = (@_, '');
    my $self = {
        output => '',
        input => [ map { "$_\n" } split /\n/, $input ],
    };
    return bless $self, $class;
}

sub print
{
    my $self = shift;
    $self->{output} .= join( '', @_ );
    return 1;
}

sub readline
{
    my ($self) = @_;
    return shift @{$self->{input}};
}

sub prompt
{
    my $self = shift;
    $self->print( @_ );
    return $self->readline();
}

sub output
{
    my ($self) = @_;
    return $self->{output};
}

sub clear
{
    my ($self) = @_;
    $self->{output} = '';
    return;
}

1;
