package Dancer::Plugin::WebDAV;
use strict;
use warnings;
our $VERSION = '0.0.5';

use Dancer ':syntax';
use Dancer::Exception ':all';
use Dancer::Plugin;

our @METHODS = qw(
    propfind
    proppatch
    mkcol
    copy
    move
    lock
    unlock
);

for my $method (@METHODS) {
    register $method => sub {
        Dancer::App->current->registry->universal_add($method, @_);
    };
}

register_plugin;

1;
__END__

=head1 NAME

Dancer::Plugin::WebDAV - Defines routes for methods of HTTP WebDAV

=head1 SYNOPSIS

    package YourDancerApp;
    use Dancer ':syntax';
    use Dancer::Plugin::WebDAV;

    propfind '/somewhere/:param' => sub {
        ...
    };

    mkcol '/anotherwhere/:param' => sub {
        ...
    };

    proppatch '...' => sub {
        ...
    };

    copy '...' => sub {
        ...
    };

    move '...' => sub {
        ...
    };

    lock '...' => sub {
        ...
    };

    unlock '..' => sub {
        ...
    };

=head1 DESCRIPTION

Dancer::Plugin::WebDAV provides the routes controllers to define routes for WebDAV.
Just like the routes controllers L<any|Dancer/any>, L<get|Dancer/get>, L<patch|Dancer/patch>,
L<post|Dancer/post>, L<del|Dancer/del>, L<options|Dancer/options> and L<put|Dancer/put>.

Please making sure your server implementation accepts HTTP methods from WebDAV. The bin/app.pl
coming along with the Dancer app skeleton uses L<HTTP::Server::Simple> which has no support
on WebDAV. L<Plack::Handler::Standalone>, the default handler of plackup, does support WebDAV.

=head1 AUTHOR

shelling E<lt>navyblueshellingford@gmail.comE<gt>

=head1 SEE ALSO

L<Dancer>

L<HTTP::Server::Simple::PSGI>

=head1 LICENSE

Copyright (C) shelling

The MIT License

=cut
