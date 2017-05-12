package Catalyst::Request::REST::ForBrowsers;
$Catalyst::Request::REST::ForBrowsers::VERSION = '1.20';
use Moose;

use namespace::autoclean;

extends 'Catalyst::Request::REST';
with 'Catalyst::TraitFor::Request::REST::ForBrowsers';

sub _related_role { 'Catalyst::TraitFor::Request::REST::ForBrowsers' }

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

Catalyst::Request::REST::ForBrowsers - A Catalyst::Request::REST subclass for dealing with browsers

=head1 SYNOPSIS

    package MyApp;

    use Catalyst::Request::REST::ForBrowsers;

    MyApp->request_class( 'Catalyst::Request::REST::ForBrowsers' );

=head1 DESCRIPTION

This class has been deprecated in favor of
L<Catalyst::TraitFor::Request::REST::ForBrowsers>. Please see that class for
details on methods and attributes.

=head1 AUTHOR

Dave Rolsky, C<< <autarch@urth.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-catalyst-request-rest-forbrowsers@rt.cpan.org>, or through the
web interface at L<http://rt.cpan.org>.  I will be notified, and then
you'll automatically be notified of progress on your bug as I make
changes.

=head1 COPYRIGHT & LICENSE

Copyright 2008-2009 Dave Rolsky, All Rights Reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
