package My::Module::Test::Mock_App;

use 5.008;

use strict;
use warnings;

use Carp;

our $VERSION = '0.052';

sub isa {
    my ( undef, $class ) = @_;
    return {
	'Astro::App::Satpass2'	=> 1,
	__PACKAGE__,		1,
    }->{$class} || 0;
}

sub new {
    my ( $class, %self ) = @_;
    return bless \%self, $class;
}

sub get {
    my ( $self, $name ) = @_;
    return $self->{$name};
}

sub set {
    my ( $self, @args ) = @_;
    while ( @args ) {
	my ( $name, $value ) = splice @args, 0, 2;
	$self->{$name} = $value;
    }
    return $self;
}


1;

__END__

=head1 NAME

My::Module::Test::Mock_App - Mock Astro::App::Satpass2

=head1 SYNOPSIS

 use lib 'inc';
 use My::Module::Test::Mock_App;
 my $app = My::Module::Test::Mock_App->new();

=head1 DESCRIPTION

This package mocks a B<very minimal> subset of
L<Astro::App::Satpass2|Astro::App::Satpass2>.

=head1 METHODS

This class supports the following public methods:

=head2 new

 my $app = My::Module::Test::Mock_App->new( ... );

This static method returns a new object. The arguments are name/value
pairs which are stored in the object.

=head2 isa

 $app->isa( 'Astro::App::Satpass2' );  # true

This override returns true for this class and the class being mocked,
and false for everything else.`

=head2 get

 my $val = $app->get( $name );

This method returns the named attribute, either as specified in an
argument to L<new()|/new>, or as set by the L<set()|/set> method.
Unspecified arguments will be return C<undef>.

=head2 set

 $app->set( $name => $value, ... );

This method sets attribute values. No checking is done. It rreturns the
invocant.

=head1 ATTRIBUTES

The attributes are whatever you set. Or get.

=head1 SEE ALSO

L<Astro::App::Satpass2|Astro::App::Satpass2>.

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Astro-App-Satpass2>,
L<https://github.com/trwyant/perl-Astro-App-Satpass2/issues/>, or in
electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2023 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
