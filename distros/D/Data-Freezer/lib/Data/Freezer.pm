package Data::Freezer ;

use warnings ;

=head1 NAME

Data::Freezer - A namespace aware object freezer based on Pixie.

=head1 SYNOPSIS

    use Pixie ;
    use Data::Freezer ;
    
    my $pixie = ... ; # Make a Pixie storage engine (See Pixie ).

    #  EXAMPLE: use Pixie with memory storage
    #  my $pixie = Pixie->connect('memory');
    # 
   
    use Data::Freezer { debug => [0|1] };
    my $freezer = Data::Freezer->new($pixie);

    # OR DO ONCE AT THE BEGINING OF APP:
    Data::Freezer->instance()->pixie($pixie);
    # AND THEN
    $freezer = Data::Freezer->instance();

    $freezer->insert( new Carot(...) , 'vegies');
    $freezer->insert( new Rabbit(...)  , 'meat' );
    $freezer->insert( new Tomato(...) , 'vegies');
    $freezer->insert( new RumSteak(..) , 'meat' );

=head1 REQUIREMENTS

Pixie release version 2.06
Class::AutoAccess 0.02

=cut

use Carp ;
use strict ;

use Pixie ;
#use base qw/Class::AutoAccess/ ;

use Data::Freezer::FreezingBag ;


our $VERSION = '0.02' ;

no strict ;
my $debug = 0 ;
sub import{
    my ($class, $arg) = @_ ;
    
    $debug = $arg->{'debug'} || 0 ;
    
}

my $instance = Data::Freezer->new();

=head2 instance

Class method.  Returns a global unique instance of a freezer.

=cut

sub instance{
    my ($class , $i )  = @_ ;
    if( $i ){
	$instance = $i ;
    }
    return $instance ;
}
use strict ;

=head2 new

Returns a newly created freezer.
You can give a pixie storage engine here.

Usage:
    my $f = Data::Freezer->new();
    or
    my $f = Data::Freezer->new($pixie);

=cut

sub new{
    my ($class, $pixie) = @_ ;
    my $self = bless {} , $class ;
    if( $pixie ) { $self->pixie($pixie); }
    return $self ;
}

=head2 pixie

Gets/Sets the Pixie storage engine

=cut

sub pixie{
    my ($self, $pixie) = @_ ;
    if( ! $pixie ){ return $self->{'pixie'} ;}
    
    $self->{'pixie'} = $pixie ;
   
    print "Binding namespace hash\n" if $debug ;
    if ( ! defined $pixie->get_object_named("_hNameSpaces_") ){
	$pixie->bind_name("_hNameSpaces_" =>  bless( {} , "NameSpaces" ) );
    }
}


=head2 getNameSpaces

Returns a reference on a list of all namespaces available in this storage

usage:

    my $nameSpaces = $store->getNameSpaces(); 


=cut
    
sub getNameSpaces{
    my ($self) = @_ ;
    print "Getting namespace hash\n" if $debug ;
    my $h = $self->pixie()->get_object_named("_hNameSpaces_");
    print "Retrieved hash is: ".$self->pixie()->get_object_named("_hNameSpaces_")."\n" if $debug;
    
    my %realH = %{$h} ;
    #while( my ($k, $v ) = each %realH ){
    #print $k." -> ".$v."\n";
    
    #}
    
    my @res = keys %realH ;
    return \@res ;
}

=head2 insert

Inserts an object into given name space storage.

Object must be Pixie friendly. ( See Pixie::Complicity in CPAN ).
Usage:

    my $o = ... ;
    my $nameSpace = ... ;
    
    my $cookie = $this->insert($o, $nameSpace);


=cut

sub insert{
    my ($self, $o , $nameSpace ) = @_ ;
    
    $self->_assumeNameSpace($nameSpace);
    
    print "Inserting $o\n" if $debug ;
    my $bag = Data::Freezer::FreezingBag->new();
    $bag->content($o);
    my $cookie = $self->pixie()->insert($bag);
    $self->_addToNameSpace($nameSpace, $cookie);
  
    return $cookie ;
}


=head2 _assumeNameSpace

Assumes that given namespace exists.
INTERNAL USAGE

Usage:

    $self->_assumeNameSpace($nameSpace);

=cut

sub _assumeNameSpace{
    my ($self, $nameSpace ) = @_ ;
    
    # get the hash of nameSpaces
    print "Getting namespace hash\n" if $debug ;
    my $h = $self->pixie()->get_object_named("_hNameSpaces_");
    if( ! $h->{$nameSpace} ){
	$h->{$nameSpace} = 1 ;
	print "Updating namespace hash with $nameSpace\n" if $debug ;
	$self->pixie()->bind_name("_hNameSpaces_" => $h );
	$self->pixie()->bind_name($nameSpace => bless([] , "CookieArray") );
    }
}

=head2  _addToNameSpace

Adds given cookie to given namespace.
INTERNAL USAGE

  Usage:
    $self->_addToNameSpace($nameSpace, $cookie);

=cut

sub _addToNameSpace{
    my ($self, $nameSpace , $cookie ) = @_ ;
    my $list = $self->pixie()->get_object_named($nameSpace) ;
    push @$list , $cookie ;
    print "Adding $cookie to namespace $nameSpace\n" if $debug ;
    $self->pixie()->bind_name($nameSpace , $list );
}

=head2 _removeFromNameSpace

Removes given cookie from namespace. Dies if this cookie does not belongs to this namespace

Usage:
    $self->_removeFromNameSpace($nameSpace, $cookie);

=cut

sub _removeFromNameSpace{
    my ($self, $nameSpace , $cookie ) = @_ ;
    my $list = $self->pixie()->get_object_named($nameSpace) ;
    print "Cookie is ".$cookie."\n" if $debug;
    print "LIST IS ".$list."\n" if $debug;
    my @arr = @$list ;
    print "ARRAY IS ".join(":",@arr)."\n" if $debug ;
    my @arr2 = grep  ! ($_ eq  $cookie)  , @arr ;
    print "ARRAY2 : ".join(':',@arr2)."\n" if $debug ;
    if (  @arr2  ==  @arr ){
	confess("No cookie $cookie in namespace ".$nameSpace);
    }
    $self->pixie()->bind_name($nameSpace , bless ( \@arr2 , 'CookieArray' )); 
}



=head2 getCookies

Gets the cookies associated with the given nameSpace.
return undef if nameSpace does not exist.

Usage:
  
    my $cookies = $this->getCookies($nameSpace);

=cut

sub getCookies{
    my ($self, $nameSpace ) = @_ ;
    print "Getting cookies for NameSpace $nameSpace\n" if $debug ;
    
    my $a = $self->pixie()->get_object_named($nameSpace) ;
    print " Stored in : ".$a."\n" if $debug;
    my @realA = @{$a} ;
    
    return \@realA ;
}


=head2 delete

Removes given cookie from given namespace.
USER FUNCTION.
Dies if cookie does not exist in given namespace


Usage:
    $this->delete($cookie, $namespace);


=cut

sub delete{
    my ($self, $cookie , $nameSpace) = @_ ;
    print "Deleting cookie :".$cookie." from namespace ".$nameSpace."\n" if $debug ;
    $self->_removeFromNameSpace($nameSpace , $cookie);
    $self->pixie()->delete($cookie);
}


=head2 get

Gets the object associated with the given cookie.
Undef is object not here.

Usage:

    my $o = $this->get($cookie);

=cut

sub get{
    my ($self , $cookie ) = @_ ;

    print "Getting object for cookie: $cookie\n" if $debug ;
    my $o = $self->pixie()->get($cookie) ;
    if( ! $o ){
	return undef ;
    }
    
    print " Retrived $o\n" if $debug ;
    print "Contains: ".$o->content()."\n" if $debug ;
    
    my $ret = $o->content();
    if( $ret->can('px_restore') ){
	$ret = $ret->px_restore();
    }
    return $ret ;
}


=head2 getObjects

Gets all objects associated to the given namespace.
Undef if namespace does not exists.

Usage :
    my $objects = $this->getObjects($nameSpace);

=cut

sub getObjects{
    my ($self , $nameSpace ) = @_ ;
    
    my $cookies = $self->getCookies($nameSpace);
    if ( ! defined $cookies ){ return undef ;} 
    
    my @res = map { $self->get($_) ; }  @$cookies ;
    return \@res ;
}

=head1 AUTHOR

Jerome Eteve, C<< <jerome@eteve.net> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-data-freezer@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-Freezer>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2005 Jerome Eteve, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut


1;
