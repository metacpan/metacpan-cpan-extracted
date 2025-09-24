package Alien::Turso::CLI;
use 5.018;
use strict;
use warnings;

use base qw( Alien::Base );

our $VERSION = "0.01";

1;
__END__

=encoding utf-8

=head1 NAME

Alien::Turso::CLI - Install and find Turso CLI

=head1 SYNOPSIS

    use Alien::Turso::CLI;
    use Alien qw( Alien::Turso::CLI );
    
    my $turso = Alien::Turso::CLI->bin_dir . '/turso';
    system $turso, "--version";

=head1 DESCRIPTION

Alien::Turso::CLI provides the Turso CLI (Command Line Interface) for Perl applications.
This module will download and install the Turso CLI binary if it's not already available on your system.

Turso CLI is the official command-line interface for Turso, the edge-hosted, distributed database built on libSQL.

=head1 REQUIREMENTS

=over 4

=item *

Perl 5.18 or later

=item *

Linux x86_64 platform (currently supported)

=item *

Internet connection for downloading Turso CLI binary

=back

=head1 INSTALLATION

    cpanm Alien::Turso::CLI

Or manually:

    perl Build.PL
    ./Build
    ./Build test
    ./Build install

After installation, you can use the Turso CLI:

    perl -MAlien::Turso::CLI -E 'system Alien::Turso::CLI->bin_dir . "/turso", "--version"'

=head1 KNOWN ISSUES

During installation, you may see warnings about "Download::Negotiate" plugin. 
These warnings are harmless and do not affect functionality. They are a known 
issue with the current version of Alien::Build::Plugin::Download::GitHub, 
which correctly uses the GitHub API despite the warnings.

=head1 METHODS

This module inherits all methods from L<Alien::Base>. The most commonly used methods are:

=over 4

=item bin_dir

Returns the directory containing the turso binary.

=item exe

Returns the full path to the turso executable.

=back

=head1 SEE ALSO

=over 4

=item L<Alien>

=item L<Alien::Base>

=item L<https://turso.tech/>

=back

=head1 LICENSE

Copyright (C) ytnobody.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

ytnobody E<lt>ytnobody@gmail.comE<gt>

=cut

