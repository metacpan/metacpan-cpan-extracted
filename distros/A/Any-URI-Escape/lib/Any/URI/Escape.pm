package Any::URI::Escape;

use strict;
use warnings;

our $VERSION = 0.01;

=head1 NAME

Any::URI::Escape - Load URI::Escape::XS preferentially over URI::Escape

=cut

use base 'Exporter';
our @EXPORT = qw( uri_escape uri_unescape );

BEGIN {

    eval 'require URI::Escape::XS';

    my $pkg;
    if ($@) {

        # xs version not installed, use URI::Escape
        require URI::Escape;
        $pkg = 'URI::Escape';

    }
    else {

        $pkg = 'URI::Escape::XS';
    }
    no strict 'refs';
    my $class = __PACKAGE__;
    *{"$class\::uri_escape"} = *{"$pkg\::uri_escape"};
    *{"$class\::uri_unescape"} = *{"$pkg\::uri_unescape"};
}


1;

=head1 SYNOPSIS

  use Any::URI::Escape;
  $escaped_url = uri_escape($url);

  # URI::Escape::XS will be used instead of URI::Escape if it is installed.

=head1 DESCRIPTION

URI::Escape is great, but URI::Escape::XS is faster.  This module loads
URI::Escape::XS and imports the two most common methods if XS is installed.

The insides of this module aren't completely shaken out yet, so patches
welcome.

=head1 SEE ALSO

L<URI::Escape>

L<URI::Escape::XS>

=head1 AUTHOR

Fred Moyer, E<lt>fred@redhotpenguin.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Fred Moyer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
