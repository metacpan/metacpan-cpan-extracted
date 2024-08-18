package Apache::AuthCookie::Params::Base;
$Apache::AuthCookie::Params::Base::VERSION = '3.32';
# ABSTRACT: Internal CGI AuthCookie Params Base Class

use strict;
use warnings;
use Class::Load qw(load_class);
use Apache::AuthCookie::Util qw(is_blank);


sub new {
    my ($class, $r) = @_;

    my $debug = $r->dir_config("AuthCookieDebug") || 0;

    # use existing params object if possible
    my $obj = $r->pnotes($class);
    if (defined $obj) {
        return $obj;
    }

    # if an encoding is in effect, then always use the ::CGI interface because
    # libapreq has no support for UTF-8
    my $auth_name = $r->auth_name;

    if (!is_blank($r->dir_config("${auth_name}Encoding"))) {
        $obj = __PACKAGE__->_new_instance($r);
    }
    else {
        $obj = $class->_new_instance($r);
    }

    $r->pnotes($class, $obj);

    return $obj;
}

sub _new_instance {
    my ($self, $r) = @_;

    load_class('Apache::AuthCookie::Params::CGI');

    return Apache::AuthCookie::Params::CGI->new($r);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Apache::AuthCookie::Params::Base - Internal CGI AuthCookie Params Base Class

=head1 VERSION

version 3.32

=head1 SYNOPSIS

 Internal Use Only!

=head1 DESCRIPTION

This is the base class for AuthCookie Params drivers.

=head1 METHODS

=head2 new($r)

Constructor.  This will generate either an internal
L<Apache::AuthCookie::Params::CGI> object, or, if available, use libapreq2.
Note that libapreq2 will not be used if you turned on C<Encoding> support
because libapreq2 does not have any support for unicode.

=head1 SOURCE

The development version is on github at L<https://github.com/mschout/apache-authcookie>
and may be cloned from L<https://github.com/mschout/apache-authcookie.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/mschout/apache-authcookie/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Michael Schout <mschout@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2000 by Ken Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
