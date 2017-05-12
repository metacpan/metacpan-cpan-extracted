package Apache2::Log::Request;
use strict;
use warnings;

our $AUTOLOAD;

# Mock library for testing only.

sub new {
    my ( $class, %args ) = @_;
    my $self = \%args;
    bless $self, $class;
    return $self;
}

sub AUTOLOAD {
    my ( $self, @args ) = @_;
    my $called_name = $AUTOLOAD;
    if ( !exists $self->{$called_name} ) {
        $self->{$called_name} = [];
    }

    if (@args) {
        my $message = join( "\t", @args );
        push @{ $self->{$called_name} }, $message;
    }
    return $self->{$called_name};
}

1;
