package CloudFlare::Client::Types;
# ABSTRACT: Types for Cloudflare::Client

use strict; use warnings; no indirect 'fatal'; use namespace::autoclean;

use Type::Library -base, -declare => qw( CFCode ErrorCode);
# Theres a bug about using undef as a hashref before this version
use Type::Utils 0.039_12 -all;
use Types::Standard qw( Enum Maybe);
use Readonly;

our $VERSION = 'v0.55.4'; # VERSION

class_type 'LWP::UserAgent';
declare CFCode, as Enum[qw( E_UNAUTH E_INVLDINPUT E_MAXAPI)];
declare ErrorCode, as Maybe[CFCode];

1; # End of CloudFlare::Client::Types

__END__

=pod

=encoding UTF-8

=head1 NAME

CloudFlare::Client::Types - Types for Cloudflare::Client

=head1 VERSION

version v0.55.4

=head1 SYNOPSIS

    use CloudFlare::Client::Types 'ErrorCode';

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
