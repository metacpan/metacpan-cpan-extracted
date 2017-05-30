package App::CISetup;

use v5.14;
use strict;
use warnings;

our $VERSION = '0.02';

1;

# ABSTRACT: Command line tools to generate and update Travis and AppVeyor configs for Perl libraries

__END__

=pod

=encoding UTF-8

=head1 NAME

App::CISetup - Command line tools to generate and update Travis and AppVeyor configs for Perl libraries

=head1 VERSION

version 0.02

=head1 DESCRIPTION

This distro includes two command-line tools, L<update-travis-yml.pl> and
L<update-appveyor-yml.pl>. They update Travis and AppVeyor YAML config files
with some opinionated defaults. See the docs for the respective scripts for
more details.

=head1 SUPPORT

Bugs may be submitted through L<https://github.com/maxmind/App-CISetup/issues>.

=head1 AUTHORS

=over 4

=item *

Mark Fowler <mark@twoshortplanks.com>

=item *

Dave Rolsky <autarch@urth.org>

=back

=head1 CONTRIBUTOR

=for stopwords Mark Fowler

Mark Fowler <mfowler@maxmind.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by MaxMind, Inc.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
