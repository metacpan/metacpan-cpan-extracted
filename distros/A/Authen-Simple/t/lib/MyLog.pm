package MyLog;

use strict;
use warnings;
use base 'Authen::Simple::Log';

{
    no warnings 'redefine';
    no strict   'refs';
    
    foreach my $level ( qw( debug error info warn ) ) {
        *$level = sub { shift->_log( $level, @_ ) }
    }
}

sub new {
    my $class = shift;
    return bless( [], $class );
}

sub _output {
    my $self    = shift;
    my $message = "@_";
    push( @{$self}, $message );
}

sub messages {
    my $self = shift;
    return ( wantarray ) ? @{$self} : $self;
}

1;
