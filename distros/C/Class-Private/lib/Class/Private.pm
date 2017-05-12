package Class::Private;

use 5.010;
use strict;
use warnings;
use XSLoader;

our $VERSION = '0.05';

XSLoader::load('Class::Private', $VERSION);

1;    # End of Class::Private

__END__

=head1 NAME

Class::Private - Private hashes for your objects

=head1 VERSION

Version 0.05

=head1 SYNOPSIS

	package Your::Class;
	use Class::Private;
	sub new {
		my $class = shift;
		my $self = Class::Private->new();
		$self->{foo} = 'bar';
		return bless $self, $class;
	}

	package main;

	my $object = Your::Class->new;

	# This will not affect the internal value
	$object->{foo} = 'quz';

	# This will
	$object->{'Your::Class::foo'} = 'quz';

=head1 DESCRIPTION

This module provides some level of encapsulation around hashrefs for objects. It does this by transforming every C<key> into C<package::key>. This way you won't have collisions. If the key contains C<::>, it will not be transformed, and normal access takes place. Thus keys from other packages can be accessed explicitly if necessary.

=head1 METHODS

=head2 new

This method creates a new private hash object.

=head1 AUTHOR

Leon Timmermans, C<< <leont at cpan.org> >>

=head1 DEPENDENCIES

This module requires perl 5.10.

=head1 BUGS

Please report any bugs or feature requests to C<bug-class-private at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Class-Private>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Class::Private


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Class-Private>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Class-Private>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Class-Private>

=item * Search CPAN

L<http://search.cpan.org/dist/Class-Private>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2009, 2010 Leon Timmermans, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
