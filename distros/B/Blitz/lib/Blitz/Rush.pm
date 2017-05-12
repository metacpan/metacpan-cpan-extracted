package Blitz::Rush;

use strict;
use warnings;

use Blitz::Exercise;
use base qw(Blitz::Exercise);

=head1 NAME

Blitz::Sprint - Perl module for executing sprints on Blitz.io
Subclass of Blitz::Exercise

=head1 SUBROUTINES/METHODS

=head2 new

create a new sprint object

=cut

sub new {
    my $class = shift;
    
    my $return = $class->SUPER::new(@_);
    $return->{test_type} = 'rush';
    return $return;
}

return 1;
