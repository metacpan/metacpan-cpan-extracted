package CloudFlare::Client::Exception::Connection;
# ABSTRACT: CloudFlare API Connection Exception

use strict; use warnings; no indirect 'fatal'; use namespace::autoclean;
use mro 'c3';

use Readonly;
use Moose; use MooseX::StrictConstructor;
use Types::Standard 'Str';

our $VERSION = 'v0.55.4'; # VERSION

extends 'Throwable::Error';

has status => (
    is       => 'ro',
    isa      => Str,
    required => 1,);

__PACKAGE__->meta->make_immutable;
1; # End of CloudFlare::Client::Exception::Connection

__END__

=pod

=encoding UTF-8

=head1 NAME

CloudFlare::Client::Exception::Connection - CloudFlare API Connection Exception

=head1 VERSION

version v0.55.4

=head1 SYNOPSIS

    use CloudFlare::Client::Exception::Connection;

    CloudFlare::Client::Exception::Connection::->throw(
        message   => 'HTTPS connection failure',
        status    => '404',
    );

    my $e = CloudFlare::Client::Exception::Connection::->new(
        message   => 'HTTPS connection failure',
        status    => '404',
    );
    $e->throw;

=head1 ATTRIBUTES

=head2 message

The error message thrown upstream, readonly

=head2 status

The status code for the connection failure, readonly

=head1 METHODS

=head2 throw

On the class, throw a new exception

    CloudFlare::Client::Exception::Connection::->throw(
        message   => 'HTTPS connection failure',
        status    => '404',
    );
    ...

On an instance, throw that exception

    $e->throw;

=head2 new

Construct a new exception

    my $e = CloudFlare::Client::Exception::Connection::->throw(
        message   => 'HTTPS connection failure',
        errorcode => '404',
    );

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<CloudFlare::Client|CloudFlare::Client>

=back

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc CloudFlare::Client

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<http://metacpan.org/release/CloudFlare-Client>

=back

=head2 Email

You can email the author of this module at C<me+dev@peter-r.co.uk> asking for help with any problems you have.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/pwr22/cloudflare-client>

  git clone git://github.com/pwr22/cloudflare-client.git

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/pwr22/cloudflare-client/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Peter Roberts <me+dev@peter-r.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Peter Roberts.

This is free software, licensed under:

  The MIT (X11) License

=cut
