use 5.008;
use strict;
use warnings;

package Acme::Marvel::CinematicUniverse::Characters;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.002';

use Module::Pluggable (
	search_path => [ 'Acme::Marvel::CinematicUniverse::Character::Instance' ],
	sub_name    => 'instance_modules',
	require     => 1,
);

my @characters;

sub load_character {
	my ( $class ) = ( shift );
	push @characters, @_;
}

sub characters {
	my ( $class ) = ( shift );
	return @characters;
}

sub find {
	my ( $class, $search ) = ( shift, @_ );
	my $re = ref($search)
		? $search
		: do { my $q = quotemeta( $search ); qr/$q/i };
	my @found = grep /$re/, @characters;
	wantarray ? @found : $found[0];
}

$_->init( __PACKAGE__ )
	for __PACKAGE__->instance_modules;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Acme::Marvel::CinematicUniverse::Characters - example of distributing instance data on CPAN

=head1 SYNOPSIS

  use Acme::Marvel::CinematicUniverse::Characters;
  
  say for Acme::Marvel::CinematicUniverse::Characters->find('tony');

=head1 DESCRIPTION

This module is primarily intended as an example of how to distribute instances
of objects on CPAN.

It uses characters from the Marvel Cinematic Universe (Earth-199999) rather
than the comic book universe, though power grid data is taken from the
Marvel wiki, and mostly based on the comic books. It currently only includes
the six core characters from I<< Marvel's The Avengers >> (2012), also known
as I<< Avengers Assemble >> in the UK and Ireland.

=head2 Methods

=over

=item C<< characters >>

Returns a list of all known characters. In scalar context, returns the
count of characters.

Characters are L<Acme::Marvel::CinematicUniverse::Character> objects.

=item C<< find($needle) >>

Given a string or regexp to search for, searches for a character by name,
returning all the results as a list. In scalar context, returns the first
match, which may or may not be the "best" match.

Strings given as search terms are treated case-insensitively. Regexps
are used as-is, so may or may not be case-sensitive.

Characters are L<Acme::Marvel::CinematicUniverse::Character> objects.

=item C<< instance_modules >>

Returns a list of modules that have been used to find character data.

=item C<< load_character($character) >>

Used by instance modules to load characters.

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Acme-Marvel-CinematicUniverse-Characters>.

=head1 SEE ALSO

L<Acme::Marvel::CinematicUniverse::Character>,
L<WWW::Marvel>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2020 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

