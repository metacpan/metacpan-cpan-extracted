package Alien::gettext;
# ABSTRACT: Getting latest gettext installed an available

our $VERSION = '0.002';

use parent 'Alien::Base';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::gettext - Getting latest gettext installed an available

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    use Alien::gettext;
    use Env qw( @PATH );

    unshift @PATH, Alien::gettext->bin_dir;

=head1 DESCRIPTION

This distribution provides the GNU gettext utilities via L<Alien::Base>. It
will either use the system gettext if available and recent enough, or download
and build it from source.

The gettext utilities include C<msgfmt>, C<msgmerge>, C<xgettext>, and other
tools for working with translation files.

=head1 METHODS

This module inherits all methods from L<Alien::Base>.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-alien-gettext/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
