package Astro::App::Satpass2::Macro;

use 5.008;

use strict;
use warnings;

use Astro::App::Satpass2::Utils qw{
    instance
    CODE_REF
    @CARP_NOT
};
use Astro::App::Satpass2::Warner;
use Scalar::Util 1.26 qw{ weaken };

our $VERSION = '0.040';

sub new {
    my ( $class, %arg ) = @_;
    my $self = bless \%arg, ref $class || $class;
    $self->init();
    return $self;
}

sub execute {
    __PACKAGE__->weep( 'execute() must be overridden' );
    return;	# weep() dies, but Perl::Critic does not know this.
}

sub generator {
    my ( $self, @args ) = @_;
    $self->{generate}
	or $self->weep( q{'generate' attribute not specified} );
    @args
	or return $self->{generate}->( $self, sort $self->implements() );
    foreach my $macro ( @args ) {
	$self->implements( $macro, required => 1 );
    }
    return $self->{generate}->( $self, @args );
}

sub implements {
    my ( $self, $name, %arg ) = @_;
    defined $name
	or return ( keys %{ $self->{implements} } );
    $self->{implements}{$name}
	or not $arg{required}
	or $self->wail( "This object does not implement macro $name" );
    return $self->{implements}{$name};
}

sub init {
    my ( $self ) = @_;
    $self->{warner} ||= Astro::App::Satpass2::Warner->new();

    defined $self->{generate}
	and CODE_REF ne ref $self->{generate}
        and $self->wail( q{If specified, 'generate' must be a code ref} );

    defined $self->{name}
	or $self->wail( q{Attribute 'name' is required} );

    defined $self->{parent}
	or $self->wail( q{Attribute 'parent' is required} );
    instance( $self->{parent}, 'Astro::App::Satpass2' )
	or $self->wail( q{Attribute 'parent' must be an Astro::App::Satpass2} );
    weaken( $self->{parent} );

    return;
}

sub name {
    my ( $self ) = @_;
    return $self->{name};
}

sub parent {
    my ( $self ) = @_;
    return $self->{parent};
}

sub wail {
    my ( $self, @args ) = @_;
    $self->warner()->wail( @args );
    return;	# wail() dies, but Perl::Critic does not know this.
}

sub warner {
    my ( $self ) = @_;
    ref $self
	or return Astro::App::Satpass2::Warner->new();
    return $self->{warner};
}

sub weep {
    my ( $self, @args ) = @_;
    $self->warner()->weep( @args );
    return;	# weep() dies, but Perl::Critic does not know this.
}

sub whinge {
    my ( $self, @args ) = @_;
    $self->warner()->whinge( @args );
    return;
}

# TODO get rid of this when level1 support goes away.
sub __level1_rewrite {
    return;
}

1;

__END__

=head1 NAME

Astro::App::Satpass2::Macro - Implement a macro

=head1 SYNOPSIS

No user-serviceable parts inside.

=head1 DESCRIPTION

This is an abstract class to implement macros.

=head1 METHODS

This class supports the following public methods:

=head2 new

 my $macro = Astro::App::Satpass2::Macro->new( name => 'Foo' );

This static method returns a new macro object. The arguments are
pairs of attribute names and values. An exception will be thrown if the
object can not be constructed.

=head2 execute

 print $macro->execute( $name, @args );

This method executes the named macro, passing it the given arguments.
The results of the execution are returned.

This method must be overridden by the subclass.

=head2 generator

 print $macro->generator( 'foo' );
 print $macro->generator();

If the C<generate> attribute (q.v.) was not provided when the object was
instantiated , this method fails.

If the C<generate> attribute was provided when the object was
instantiated and arguments were provided, this method validates that the
arguments are all names of macros implemented by this object, failing if
they are not. If the arguments are valid, it calls the code provided
in the C<generate> attribute with the invocant and the arguments.

If the C<generate> attribute was provided when the object was
instantiated and no arguments were provided, the code provided
in the C<generate> attribute is called with the invocant and the list of
all macros implemented by the invocant in ASCIIbetical order.

=head2 implements

 print map { "$_\n" } sort $macro->implements();
 $macro->implements( $name )
     and print "Implements $name\n";
 $macro->implements( $name, required => 1 );

This method has several overloads dealing with what macros this object
implements.

If C<$name> is omitted or C<undef>, it returns the names of all macros
implemented by this object, in no particular order.

If C<$name> is specified, it returns a true value if the object
implements the named macro, and false otherwise. No commitment is made
as to exactly what value is returned, and the caller is to regard this
value as opaque.

After the C<$name> argument, optional name/value pairs can be specified.
The only one defined at the moment is C<required>, which causes an
exception to be thrown if this object does not implement the named
macro.

=head2 init

 $self->init();

This method performs initialization and checking of attributes. It
should not be called by the user. Subclasses that override this method
to add extra attributes should call $self->SUPER::init().

Nothing is returned.

=head2 wail

 $macro->wail( 'Something bad happened' );

This convenience method simply delegates to the corresponding
C<Astro::App::Satpass2::Warner> method.

=head2 weep

 $macro->wail( 'Something bad happened' );

This convenience method simply delegates to the corresponding
C<Astro::App::Satpass2::Warner> method.

=head2 whinge

 $macro->wail( 'Something bad happened' );

This convenience method simply delegates to the corresponding
C<Astro::App::Satpass2::Warner> method.

=head1 ATTRIBUTES

This class has the following attributes:

=head2 generate

This attribute is optional, but if specified as something other than
C<undef> must be a code reference.

This code will be called by the C<generator()> method after it has
validated or defaulted the arguments, and whatever it returns will be
returned by C<generator()>.

The idea is to provide a way to recover a macro definition, given that
only the creator of the class knows what user-provided information it
needs to perform this function. The return need not be the exact
information originally provided, but it must be information that, if
provided again, will generate the same macro. In the case of string
data, this means that it may be quoted or escaped differently, but after
the quotes and escapes are processed you must get the same string that
you got by processing the quotes and escapes in the string originally
provided. If the object implements more than one macro, it should be
capable of returning the information on any one of them by itself.

=head2 name

This required attribute is the name of the object. It is returned by the
C<name()> method.

=head2 parent

This required attribute is the C<Astro::App::Satpass2> object that this
object's C<execute()> method is to operate on. It must be a subclass of
C<Astro::App::Satpass2>. We actually hold a weak reference to this
object, so it can be garbage-collected. It is returned by the
C<parent()> method.

=head2 warner

This optional attribute is an C<Astro::App::Satpass2::Warner> object
used to report errors. If omitted, one will be generated. It is returned
by the C<warner()> method.


=head1 SEE ALSO

<<< replace or remove boilerplate >>>

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<http://rt.cpan.org>, or in electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013-2019 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
