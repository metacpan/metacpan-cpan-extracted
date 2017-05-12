package Authen::Simple::Logger;

use strict;
use warnings;
use base 'Authen::Simple::Adapter';

sub check {
    my ( $self, $username, $password ) = @_;
    
    $self->log->debug('just calling');
    $self->log->info('just calling');
    $self->log->error('just calling');
    $self->log->warn('just calling');
    
    return ($username eq $password);
}
1;

