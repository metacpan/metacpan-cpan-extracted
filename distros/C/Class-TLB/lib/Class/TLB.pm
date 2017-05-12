package Class::TLB;

use warnings;
use strict;

use Carp;

#use Time::HiRes ;
use List::PriorityQueue ;

=head1 NAME

Class::TLB - Transparent load balancing for any resource class.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    my $tlb = Class::TLB->new() ;

build a set of resource (dummy for instance) and register them

    foreach my $i ( 1 .. 3 ){
      $tlb->tlb_register(Class::TLB::Dummy->new($i)) ;
    }

You can now use the object $tlb the same way you would use a single instance of resource.

=head2 Example with instances of Class::TLB::Dummy:

    # doSomething, oneFail and doFail are implemented in the Dummy class.
    $tlb->doSomething() ;

The $tlb object will automatically balance the usage on the set of resources given and will avoid temporary resource failures:

    $tlb->oneFail() ; # This call is ok because only one resource will fail.

    $tlb->doFail()  ; # This call will confess an error because there is an 
                      # implementation error in the resource that makes it fail all the time.


=head2 Usage scenario:

You can use a Class::TLB wrapper to balance the usage of a set of similar distant resources.

In case the distant connection breaks in one of them, your client code will not suffer from it since
Class::TLB will avoid single resources failures.

For this to work, your resource must die or confess in case of disconnection.

In case there is a logical flaw in a resource method, Class::TLB will die with the error when you call it.

Because Class::TLB will attempt to use each resource instance and fail if all of them are failing.

=head1 BEST PRACTICES

=head2 Fail, but fail fast

If your resources represent a distant service accessed through the network, make sure that the connection failure dies quickly.

Long connection timeouts can cause waiting queries to accumulate in your application and can lead to an interruption of service, even if the other resources of the pool are perfectly healthy.

In particular, if your resources use cURL to connect to the distant service, make sure you set a short CURLOPT_CONNECTTIMEOUT (or CURLOPT_CONNECTTIMEOUT_MS) option.

=head1 CAVEATS

Your managed resources can not implement any of the methods implemented in Class::TLB.

All Class::TLB methods are prefixed with 'tlb_', making a collision very unlikely.

=head1 FUNCTIONS

=head2 new

=cut

sub new {
    my ( $class , $opts ) = @_ ;
    $opts ||= {} ;
    my $self = {
        '_tlb_queue' => List::PriorityQueue->new(), # The queue
        '_tlb_class' => undef , # The class of objects managed by this
        '_tlb_prototype' => undef , # The prototype of a resource. Typically the first instance given.
        '_tlb_usecount' => {} , # The usage count of each register object
        '_tlb_rcount' => 0 ,
        '_tlb_failpenalty' =>  $opts->{'failpenalty'} || 2 , # Delay a failed resource by 2 seconds
    } ;
    return bless $self , $class ;
}

=head2 isa

Overrides the UNIVERSAL::isa method to allow client code to transparently call isa method
on balanced resources.

Usage:
    if ( $this->isa('Class::TLB::Dummy')){
        ...
    }

=cut

sub isa{
    my $o  = shift;
    unless( ref $o ){
        return UNIVERSAL::isa($o , @_ );
    }
    if ( $o->tlb_prototype() ){
        return $o->tlb_prototype()->isa(@_);
    }
    return UNIVERSAL::isa($o , @_ );
}

=head2 can

Overrides the UNIVERSAL::can method to allow client code to transparently call can method
on balanced resources.

Usage:
    if ( $this->can('doSomething')){
        ...
    }

=cut

sub can{
    my $o  = shift;
    unless( ref $o ){
        return UNIVERSAL::can($o , @_ );
    }
    if ( $o->tlb_prototype() ){
        return $o->tlb_prototype()->can(@_);
    }
    return UNIVERSAL::can($o , @_ );
}




=head2 tlb_class

Returns the class of resources being load balanced.

usage:
    my $class = $tlb->tlb_class() ;

=cut

sub tlb_class{
    my ($self) =@_ ;
    return $self->{'_tlb_class'} ;
}

=head2 tlb_prototype

Returns an instance of resources being load balanced.

=cut

sub tlb_prototype{
    my ($self) = @_ ;
    return $self->{'_tlb_prototype'} ;
}

=head2 tlb_usecount

Returns the usage statistic hash of all sources.

usage:
    my $hcount = $tlb->tlb_usecount() ;

=cut

sub tlb_usecount{
    my ($self) = @_ ;
    return $self->{'_tlb_usecount'} ;
}


=head2 tlb_register

Registers a new resource to be managed by this load balancer.

The first call of this methods records the expected resource class.
Subsequent calls will fail if the given resource is from a different class.


Usage:
    $tlb->tlb_register($resource);

=cut

sub tlb_register{
    my ( $self , $resource ) = @_ ;
    unless( $resource ){
        confess("Please give a resource");
    }

    my $rclass = ref $resource ;
    unless( $rclass ){
        confess( $resource." must be a reference");
    }
    eval "require $rclass;";
    if ( $@ ){
        confess( $rclass." cannot be required: $@");
    }
    # Register the class
    unless( $self->{'_tlb_class'} ){
        $self->{'_tlb_class'} = $rclass ;
        $self->{'_tlb_prototype'} = $resource ;
    }else{
        # Check it is the same class of resource
        unless( $resource->isa($self->{'_tlb_class'}) ){
            confess( $rclass." invalid. Please provide only ".$self->{'_tlb_class'}."'s");
        }
    }

    # All is fine
    # The new resource is given the highest priority
    $self->{'_tlb_queue'}->insert($resource, 0 );
    $self->{'_tlb_usecount'}->{$resource} = 0 ;
    $self->{'_tlb_rcount'} ++ ;
    return $resource ;
}



our $AUTOLOAD;
sub AUTOLOAD{
    my  $self  = shift ;
    my @args = @_ ;
    # Avoid implicit overriding of destroy method.
    return if $AUTOLOAD =~ /::DESTROY$/ ;

    my $mname = $AUTOLOAD;
    $mname =~ s/.*::// ;

    my $res = undef ;
    my $error = undef ;

    my $ntry = $self->{'_tlb_rcount'} ;
    my $tried = {} ;


    while( keys %$tried < $ntry ){
        # Pick a resource
        my $r = $self->{'_tlb_queue'}->pop();
        $tried->{$r} = 1 ;

        my $penalty = 0 ;
        # Call the method with the rest of arguments
        eval{
            $res = $r->$mname(@args);
        };
        if ( $@ ){
            $error = $@ ;
            $penalty = $self->{'_tlb_failpenalty'} ;
        }else{
            $error = undef ;
        }

        my $calltime = time()  + $penalty ;

        $self->{'_tlb_usecount'}->{$r}++ ;

        $self->{'_tlb_queue'}->insert($r ,  $calltime);
        unless( $error ){
            return $res ;
        }
    }
    # If we reach this without returning the result, it means an error has occured on all resources.
    confess( $error ) ;
}




=head1 AUTHOR

Jerome Eteve, C<< <jerome at eteve.net> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-class-tlb at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Class-TLB>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Class::TLB

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Class-TLB>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Class-TLB>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Class-TLB>

=item * Search CPAN

L<http://search.cpan.org/dist/Class-TLB>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2010 Jerome Eteve, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Class::TLB
