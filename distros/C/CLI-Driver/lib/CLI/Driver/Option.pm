package CLI::Driver::Option;

use Modern::Perl;
use Moose;
use namespace::autoclean;
use Kavorka '-all';
use Data::Printer alias => 'pdump';

use Getopt::Long 'GetOptionsFromArray';
Getopt::Long::Configure('no_ignore_case');
Getopt::Long::Configure('pass_through');

with 'CLI::Driver::CommonRole';

###############################
###### PUBLIC ATTRIBUTES ######
###############################

has class => (
    is => 'rw',
    isa => 'Str',
);

has cli_arg => (
    is  => 'rw',
    isa => 'Str'
);

has method_arg => (
    is  => 'rw',
    isa => 'Str|Undef'
);

has required => (
    is  => 'rw',
    isa => 'Bool'
);

has hard => (
    is => 'rw',
    isa => 'Bool',
);

has flag => (
    is => 'rw',
    isa => 'Bool',
);

###############################################

method get_signature {

    my %sig;
    my $val = $self->get_val;

    if ( defined $val ) {
        $sig{ $self->method_arg } = $val;
    }

    return %sig;
}

method is_required {
    
    if ($self->required) {
        return 1;    
    }    
    
    return 0;
}

method is_flag {
    
    if ($self->flag) {
        return 1;    
    }    
    
    return 0;
}

method is_optional {
    
    if (!$self->required) {
       return 1; 
    }    
    
    return 0;
}

method is_hard {
    
    if ($self->hard) {
        return 1;    
    }    
    
    return 0;
}

method is_soft {
    
    if (!$self->hard) {
        return 1;    
    }    
    
    return 0;
}

method get_val {

    my $arg  = $self->cli_arg;
    my $val;

    if ( $self->is_boolean ) {
        #
        # deprecated in favor of self->is_flag
        #
        my $success = GetOptionsFromArray( \@ARGV, "$arg" => \$val, );

        if ($success) {
            my $val = $val ? 1 : 0;
            return $val;
        }

        confess "something went sideways?";
    }
    elsif ($self->is_flag) {
        # - just a cli switch
        # - never required from cmdline
        
        my $success = GetOptionsFromArray( \@ARGV, "$arg" => \$val, );

        if ($success) {
            my $val = $val ? 1 : 0;
            return $val;
        }

        confess "something went sideways?"; 
    }
    else {

        # get "-arg <val>" from cmdline if exists

        my $success = GetOptionsFromArray( \@ARGV, "$arg=s" => \$val, );
        if ($success) {
            return $val;
        }

        # we didn't find it in @ARGV
        if ( $self->required ) {
            $self->fatal("failed to get arg $arg from argv");
        }
    }

    return;
}

method is_boolean {

    if (length $self->cli_arg > 1) {
        return 1;    
    }
    
    return 0;
}

1;
