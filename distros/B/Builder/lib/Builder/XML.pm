package Builder::XML;
use strict;
use warnings;
use Carp;
use Builder::Utils;
use Builder::XML::Utils;
our $VERSION = '0.06';
our $AUTOLOAD;


sub __new__ {
    my ( $class ) = shift;
    my %args = Builder::XML::Utils::get_args( @_ );
    
    bless { 
        %args,
        block_id => $args{ _block_id }, 
        stack    => $args{ _stack },
        context  => Builder::XML::Utils::build_context(),
    }, $class;
}

sub AUTOLOAD {
    my ( $self ) = shift;
    my @args = @_;

    if ( $AUTOLOAD =~ /.*::(.*)/ ) {
        my $elt = $1;
        my $attr = undef;
        
        # sub args get resent as callback
        if ( wantarray ) {
             return sub { $self->$elt( @args ) };
        }
        
        # if first arg is hasharray then its attributes!
        $attr = shift @args  if ref $args[0] eq 'HASH';
        
        if ( ref $args[0] eq 'CODE' ) { 
            $self->__element__( context => 'start', element => $elt, attr => $attr );
            for my $inner ( @args ) {
                if ( ref $inner eq 'CODE' ) { $inner->() }
                else { $self->__push__( sub { $inner } ) }
            }
            $self->__element__( context => 'end', element => $elt );
            return;
        }
        
        # bog standard element         
        $self->__element__( element => $elt, attr => $attr, text => "@args" );
    }
    
    $self;
}


######################################################
# methods

sub __render__ {
    my $self = shift;
    my $render;
    
    # render subs just for this block
    my @this_block = Builder::Utils::yank { $_->[0] == $self->{block_id} } @{ $self->{stack} };    
    while ( my $block = shift @this_block ) {
        my ( $block_id, $code ) = @$block;
        $render.= $code->();
    }
    return $render;
}

sub __element__ {
    my ( $self, %param ) = @_;
    $param{ text    } ||= '';
    $param{ context } ||= 'element';
    $self->{ context }->{ $param{ context } }->( $self, \%param );
    return;
}

sub __cdata__ {
    my $self = shift;
    return $_[0]  if $self->{ cdata } == 1;
    return $self->__cdatax__( $_[0] );
}

sub __cdatax__ {
    my $self = shift;
    return q{<![CDATA[} . $_[0] . q{]]>};
}

sub __say__ {
    my ( $self, @say ) = @_;
    for my $said ( @say ) { $self->__push__( sub { $said } ) }
    $self;
}

sub __push__ {
    my ( $self, $code ) = @_;
    
    # straight to output stream if provided
    if ( $self->{ _output } ) {
        print { $self->{ _output } } $code->();
        return;
    }
    
    # else add to stack
    push @{ $self->{ stack } }, [ $self->{ block_id }, $code ];
}

sub __inc__ { $_[0]->{ _inc }->() }

sub __dec__ { $_[0]->{ _dec }->() }

sub __level__ { $_[0]->{ _level }->() }

sub __tab__ {
    my $self = shift;
    my $tab = q{};
    $tab = q{ } x $self->{ pre_indent }                     if $self->{ pre_indent };
    $tab.= q{ } x ( $self->{ indent } * $self->__level__ )  if $self->{ indent };
    return $tab;
}

sub __start_tab__ { $_[0]->__tab__ }

sub __end_tab__ {
    my $self = shift;
    return q{}  if $self->{ newline } && ! $self->{ open_newline };
    $self->__tab__;
}

sub __open_newline__ {
    my $self = shift;
    return $self->{cr} if $self->{ open_newline };
    return q{};
}

sub __close_newline__ {
    my $self = shift;
    return $self->{cr} if $self->{ close_newline };
    return q{};
}

sub DESTROY {
    my $self = shift;
    $self = undef;
}


1;


__END__

=head1 NAME

Builder::XML - Building block for XML

=head1 VERSION

Version 0.06


=head1 SYNOPSIS

Please look at L<Builder> docs.   This currently contains the necessary synopsis & description for Builder::XML.
At some point in future it will be moved here and Builder docs will be replaced with something more generic.


=head1 DESCRIPTION

See above.

=head2 So how does it work? (in more detail!)

Here are Builder::XML parameter contexts....

no parameters => produces a closed tag

    $xm->br;
    
    # => <br />
    
    
first parameter is a hashref  =>  attributes

    $xm->span( { id => 'mydiv', class => 'thisClass' }, 'some content' );
    
    # => <span class="thisClass" id="mydiv">some content</span>
    
    
parameter(s) are a anon sub or code ref  -->  callback

    $xm->ul( { class => 'list' }, sub {
       for my $numb qw/one two three/ {
           $xm->li( $numb );
       }
    });

    # => <ul class="list"><li>one</li><li>two</li><li>three</li></ul>
    
    
parameter(s) are content  =>  element text

    $xm->p( 'one', 'two', 'and three' );
    
    # => <p>one two and three</p>
    
    
parameter(s) are Builder blocks or content  =>  nesting  

    $xm->p( 'one', $xm->span( 'two' ), 'and three' );
    
    # => <p>one <span>two</span> and three</p>
    
    # NB. THIS DOESN'T WORK YET... unless first param is an object
    # Workaround - use __say__ method around text like so...
    #
    #      $xm->p( $xm->__say__('one'), $xm->span( 'two' ), 'and three' );
    #
    # This needs "fixing" for HTML usage


parameter(s) are Builder blocks within builder blocks  =>  nesting ad-infinitum

    $xm->div(
        $xm->div(
            xm->span( 'hi there'),
        ),
    );
    
    # => <div><div><span>hi there</span></div></div>


=head2 Gotchas?

TODO: XML entities not implemented

TODO: invalid method calls...  $xm->flip-flop, $xm->DESTROY, $xm->AUTOLOAD

TODO: Fix / workaround for attribute ordering


=head1 EXPORT

None.


=head1 METHODS

All methods are prefix/postfixed with __ so that ambigious method calls wont clash 
and can be turned successfully into XML elements.

Below is a complete list of defined methods in Builder::XML.
NB. Most of these are private methods and only listing here for reference.


=head2 __new__

Private. 

This is the contructor called by the Builder object when creating a block...

    $xm = $builder->block( 'Builder::XML' );
    
All arguments are passed from Builder->block method straight to Builder::XML->__new__
 

=head2 __render__

Will immediately render the building block.  
Can be useful in some cases...

    # provide example here of it working
    
    # and then provide example of what can go wrong!

...but recommend $builder->render for best practise.


=head2 __element__

Private


=head2 __cdata__

Wraps content in <![CDATA[ ]]> element.  
Useful for quick ditties like....

    $xm->span( $xm->__cdata__( 'yada yada' ) );
    
    # => <span><!CDATA[yada yada]]></span>
    
But for best practise you probably still find building a block more useful in the long run...

    my $xm = $builder->block( 'Builder::XML', { cdata => 1 } );
    
    $xm->span( 'yada yada' );


=head2 __cdatax__

PRIVATE - used with __cdata__


=head2 __say__

Really a Private method but as mentioned in I<Gotchas> it can be useful for working around some implementation issues.

=head2 __push__

Private


=head2 __inc__

Private


=head2 __dec__

Private


=head2 __level__

Private


=head2 __tab__

Private


=head2 __start_tab__

Private


=head2 __end_tab__

Private


=head2 __open_newline__

Private


=head2 __close_newline__

Private


=head2 AUTOLOAD

Used in method to XML element resolution.   

Therefore at present AUTOLOAD cannot be used as a XML element.


=head2 DESTROY

Standard POOP!

Therefore at present DESTROY cannot be used as a XML element.



=head1 AUTHOR

Barry Walsh C<< <draegtun at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-builder at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Builder>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Builder::XML


You can also look for information at: L<Builder>

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Builder>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Builder>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Builder>

=item * Search CPAN

L<http://search.cpan.org/dist/Builder/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008-2013 Barry Walsh (Draegtun Systems Ltd | L<http://www.draegtun.com>), all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

