package Algorithm::FloodControl::Backend;

use utf8;
use strict;
use warnings;

use base 'Class::Accessor::Fast';
__PACKAGE__->mk_accessors( qw/storage prefix expires/ );

=head2 get_info

=cut

sub get_info {
    my $self   = shift;
    my $attempts = shift;
    my $size   = 0;
    my $number = $self->_last_number;
    if ( ! defined $number ) {
        return { 
            size => $size,
            timeout => 0
        };
    }
    my $last_timeout;
    my $timeout;
    while ( defined ( $timeout = $self->get_item($number) ) ){
        if ( ! $attempts || $size < $attempts ) {
            $last_timeout = $timeout;
        }
        $size++;
        $number--;
    }
    return { 
        size => $size, 
        timeout => $last_timeout ? $last_timeout - time : 0
    };
}

1;
__END__

=head1 NAME

Algorithm::FloodControl::Backend

=head1 DESCRIPTION

Base class for all backends

=head1 BUGS

=head1 NOTES

=head1 AUTHOR

Andrey Kostenko (), <andrey@kostenko.name>

=head1 COMPANY

Rambler Internet Holding

=head1 CREATED

06.11.2008 18:32:34 MSK

=cut

use strict;
use warnings;



