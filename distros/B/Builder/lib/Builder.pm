package Builder;
use strict;
use warnings;
use Carp;
our $VERSION = '0.06';


sub new {
    my ( $class, %args ) = @_;
    my $level = 0;
    bless { 
        %args, 
        blocks => [], 
        stack  => [], 
        level  => sub { $level },
        inc    => sub { $level++ },
        dec    => sub { $level-- },
    }, $class;
}

sub block {
    my ( $self, $block, $args_ref ) = @_;
    # TODO: check args_ref is hashref and if anything left in @_ then croak
    eval "require $block";
    # TODO: put $@ check here and add relevant test
    
    return $self->_new_block( $block->__new__( 
        %$args_ref, 
        _output   => $self->{output},
        _inc      => $self->{inc},
        _dec      => $self->{dec},
        _level    => $self->{level},
        _block_id => $self->_block_id, 
        _stack    => $self->{ stack } 
    ));
}

sub render {
    my ( $self ) = @_;
    my $render;
    
    # loop thru return chain (DOM!)
    while ( my $block = shift @{ $self->{ stack } } ) {
        my ( $block_id, $code ) = @$block;
        $render.= $code->();
    }
    
    return $render;
}

sub flush {
    my ( $self ) = @_;
    $self->{ stack } = [];
}

sub _block_id {
    my ( $self ) = shift;
    return scalar @{ $self->{blocks} };
}

sub _new_block {
    my ( $self, $block ) = @_;
    push @{ $self->{blocks} }, $block;
    return $block;
}


1;

__END__


=head1 NAME

Builder - Build XML, HTML, CSS and other outputs in blocks

=head1 VERSION

Version 0.06


=head1 SYNOPSIS

Simple example....

    use Builder;

    my $builder = Builder->new;
    
    my $xm = $builder->block( 'Builder::XML' );

    $xm->parent( $xm->child( 'Hi Mum!' ) );
    
    say $builder->render;

    # => <parent><child>Hi Mum!</child></parent>


Another example using same block object....

    $xm->body(
        $xm->div( 
            $xm->span( { id => 1 }, 'one' ), 
            $xm->span( { id => 2 }, 'two' ),
        ),
    );

    say $builder->render;

    # => <body><div><span id="1">one</span><span id="2">two</span>/div></body>

And finally something a bit more whizzy....

    my $rainbow = $builder->block( 'Builder::XML', { indent => 4, newline => 1 } );

    $rainbow->colours( sub {
        for my $colour qw/red green blue/ {
            $rainbow->$colour( uc $colour );
        }
    });

    say $builder->render;

    # <colours>
    #     <red>RED</red>
    #     <green>GREEN</green>
    #     <blue>BLUE</blue>
    # </colours>


=head1 DESCRIPTION

=head2 Marketing Spiel

If you need to build structured output then Builder will be exactly what you you've always been waiting for!

Just select and/or tailor the blocks you need then simply click them all together to construct the output of your dreams!


=head2 Technical Reality

First we need to create the stack / buffer / scaffold / bucket / zimmerframe (pick your favourite term) object....

    use Builder;
    my $builder = Builder->new;

Then you create the blocks associated with this build object....

    my $xm = $builder->block( 'Builder::XML' );
    my $ns = $builder->block( 'Builder::XML', { namespace => 'baz' } );
    
Then build your output using these blocks....

    $xm->fubar(
        $xm->before( 'foo' ),
        $ns->during( 'I3az' ),
        $xm->after( 'bar' ),
    );

Continue to add more blocks to hearts content until happy then render it.....

    my $output = $builder->render;

    # <fubar><before>foo</before><baz:during>I3az</baz:during><after>bar</after><fubar>



=head2 So how does it work?

Remove the smoke and mirrors and all you are left with is parameter context.

Each block component will have its own parameter context.  
For example when Builder::XML receives no parameters then it will return a closed tag....

    $xm->br;
    
    # => <br />
    
For more information see relevant Builder::* block docs.


=head1 EXPORT

Nothing (at this moment!)


=head1 METHODS

=head2 new

By default the constructor will maintain an internal stack (buffer) of the blocks being built.

    my $builder = Builder->new;

This is then later returned (processed) using render method on this object.

Using the I<output> named parameter changes default behaviour to immediately output the blocks to the filehandle provided.

    my $builder = Builder->new( output => \*STDOUT );

There are no other parameters used by constructor.


=head2 block

Creates a block in this stack.  

First arg is the block to use, for eg.  'Builder::XML'.  Second arg must be a hashref of options (named parameters).

    my $builder = Builder->new();

    my $xm = $builder->block( 'Builder::XML', { cdata => 1 } );


For options that can be passed as args please see relevant Builder::* documentation.


=head2 render

Renders all the blocks for the requested builder stack returning the information.

    my $output = $builder->render;

=head2 flush

The render method will automatically flush the builder stack (by calling this method).   
Unlikely this will be of any use in the outside world!

    $builder->flush;     # there goes all the blocks I just built ;-(


=head1 AUTHOR

Barry Walsh C<< <draegtun at cpan.org> >>


=head1 MOTIVATION

Yep there was some... more on that later!


=head1 BUGS

Please report any bugs or feature requests to C<bug-builder at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Builder>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Builder


You can also look for information at:  http://github.com/draegtun/builder

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

=over 4

My main inspiration came primarily from Builder for Ruby L<http://builder.rubyforge.org/>
 and also a little bit from Groovy Builders L<http://groovy.codehaus.org/Builders>

=back


=head1 SEE ALSO

=over 4

=item B<Other Builder::* modules>:

L<Builder::XML>

=item B<Similar CPAN modules>:

L<Class::XML>, L<XML::Generator>

=back

=head2 Builder Source Code

GitHub at  http://github.com/draegtun/builder

=head1 DISCLAIMER

This is (near) beta software.   I'll strive to make it better each and every day!

However I accept no liability I<whatsoever> should this software do what you expected ;-)



=head1 COPYRIGHT & LICENSE

Copyright 2008-2013 Barry Walsh (Draegtun Systems Ltd | L<http://www.draegtun.com>), all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.



