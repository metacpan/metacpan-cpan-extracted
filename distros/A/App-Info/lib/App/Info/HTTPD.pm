package App::Info::HTTPD;

use strict;
use App::Info;
use vars qw(@ISA $VERSION);
@ISA = qw(App::Info);
$VERSION = '0.57';

my $croak = sub {
    my ($caller, $meth) = @_;
    $caller = ref $caller || $caller;
    if ($caller eq __PACKAGE__) {
        $meth = __PACKAGE__ . '::' . shift;
        Carp::croak(__PACKAGE__ . " is an abstract base class. Attempt to " .
                    " call non-existent method $meth");
    } else {
        Carp::croak("Class $caller inherited from the abstract base class " .
                    __PACKAGE__ . "but failed to redefine the $meth method. " .
                    "Attempt to call non-existent method ${caller}::$meth");
    }
};

sub httpd_root { $croak->(shift, 'httpd_root') }

1;
__END__

=head1 NAME

App::Info::HTTPD - Information about web servers on a system

=head1 DESCRIPTION

This subclass of App::Info is an abstract base class for subclasses that
provide information about web servers. Its subclasses are required to
implement its interface. See L<App::Info|App::Info> for a complete description
and L<App::Info::HTTPD::Apache|App::Info::HTTPD::Apache> for an example
implementation.

=head1 INTERFACE

In addition to the methods outlined by its App::Info parent class,
App::Info::HTTPD offers the following abstract methods

=head1 OBJECT METHODS

=head2 httpd_root

  my $httpd_root = $app->httpd_root;

The root directory of the HTTPD server.

=head1 SUPPORT

This module is stored in an open L<GitHub
repository|http://github.com/theory/app-info/>. Feel free to fork and
contribute!

Please file bug reports via L<GitHub
Issues|http://github.com/theory/app-info/issues/> or by sending mail to
L<bug-App-Info@rt.cpan.org|mailto:bug-App-Info@rt.cpan.org>.

=head1 AUTHOR

David E. Wheeler <david@justatheory.com>

=head1 SEE ALSO

L<App::Info|App::Info>,
L<App::Info::HTTPD::Apache|App::Info::HTTPD::Apache>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2002-2011, David E. Wheeler. Some Rights Reserved.

This module is free software; you can redistribute it and/or modify it under the
same terms as Perl itself.

=cut


