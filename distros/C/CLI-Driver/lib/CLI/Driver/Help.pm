package CLI::Driver::Help;

use Modern::Perl;
use Moose;
use namespace::autoclean;
use Kavorka '-all';
use Data::Printer alias => 'pdump';

with
  'CLI::Driver::CommonRole';

###############################
###### PUBLIC ATTRIBUTES ######
###############################

#has desc => ( is => 'rw' );

has args => (
    is      => 'rw',
    isa     => 'HashRef[Str]',
    default => sub { {} }
);

has examples => (
    is      => 'rw',
    isa     => 'ArrayRef[Str]',
    default => sub { [] }
);

method parse (HashRef|Undef :$href!) {
    
    # Don't fail if no help provided.
    return 1 if !defined $href;

    # self->args
    if( exists $href->{args} ){
       $self->args( { %{$href->{args}} } );
    }
    
    # self->examples
    if( exists $href->{examples} ){
       $self->examples( [ @{$href->{examples}} ] );
    }

    return 1;        # success
}

method get_help( $arg ) {

    if( exists $self->args->{$arg} ){
        return $self->args->{$arg};   
    }

    return "";
}

method has_examples(){
    if( @{$self->examples} ){
        return 1;
    }
    
    return 0;   
}

1;
