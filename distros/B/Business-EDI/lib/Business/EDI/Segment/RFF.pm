package Business::EDI::Segment::RFF;

use strict;
use warnings;
use Carp;

use base qw/Business::EDI::Segment/;

our $VERSION = 0.02;

our $debug = 0;
our $top   = 'C506';
our @codes = (
    'C506',
#   1153,
#   1154,
#   1156,
#   1060,
#   4000,
);
our @required_codes = (1153);

sub carp_error {
    carp __PACKAGE__ . ' : ' . shift;
    return;   
}

sub new {
    my $class = shift;
    my $body  = shift;
    unless ($body) {
        return carp_error " new() called with EMPTY 1st argument";
    }
    my $obj = $class->SUPER::unblessed($body, \@codes, $debug);
    unless ($obj) {
        carp "Unblessed object creation failed";
        return;
    }
    my $self = bless($obj, $class);
    $self->spec or $self->spec('default');
    $self->{code}  = 'RFF';
    $self->{label} = 'REFERENCE';
    $self->{_permitted}->{label} = 1;
    $self->{_permitted}->{code}  = 1;
    # print "blessed: " , Dumper($self);  use Data::Dumper;
    foreach (@required_codes) {
        unless (defined $obj->part($top)->part($_)) {
            return carp_error "Required field $top/$_ not populated";
        }
    }
    return $self;
}

1;
__END__

THIS MODULE IS DEPRECATED.  Use Business::EDI->segment('RFF', $body)
