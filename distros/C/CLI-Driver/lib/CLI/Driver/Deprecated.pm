package CLI::Driver::Deprecated;

use Modern::Perl;
use Moose;
use namespace::autoclean;
use Kavorka '-all';
use Data::Printer alias => 'pdump';
use CLI::Driver::Option;

with
  'CLI::Driver::CommonRole',
  'CLI::Driver::ArgParserRole';

###############################
###### PUBLIC ATTRIBUTES ######
###############################

has status => (
    is  => 'rw',
    isa => 'Bool',
    default => 0,
);

has replaced_by => (
    is  => 'rw',
    isa => 'Str|Undef',
);

############################
###### PUBLIC METHODS ######
############################

method is_true {
    
    if ($self->status) {
        return 1;    
    }    
    
    return 0;
}

method parse (HashRef :$href!) {

    if ( !defined $href->{status} ) {
        $self->warn("failed to find deprecated status");
        return 0;    # failed
    }
    else {
        my $status = $href->{status};
        my $bool_status = $self->str_to_bool($status);
        $self->status($bool_status);
    }

    if ( $href->{'replaced-by'} ) {
        $self->replaced_by( $href->{'replaced-by'} );
    }

    return 1;
}

method get_usage_modifier {

    if ($self->status) {
        my $msg = 'DEPRECATED';
        if ($self->replaced_by) {
            $msg.= " by " . $self->replaced_by;    
        }        
        
        return $msg;
    }    
    
    return '';
}

########################################################

__PACKAGE__->meta->make_immutable;

1;
