package Code::TidyAll::SVN::Util;

use strict;
use warnings;

use Cwd qw(realpath);
use IPC::System::Simple qw(capturex);

use Exporter qw(import);

our $VERSION = '0.78';

our @EXPORT_OK = qw(svn_uncommitted_files);

sub svn_uncommitted_files {
    my ($dir) = @_;

    $dir = realpath($dir);
    my $output = capturex( 'svn', 'status', $dir );
    my @lines  = grep {/^[AM]/} split( "\n", $output );
    my (@files) = grep {-f} ( $output =~ m{^[AM]\s+(.*)$}gm );
    return @files;
}

1;

# ABSTRACT: Utility functions for SVN hooks

__END__

=pod

=encoding UTF-8

=head1 NAME

Code::TidyAll::SVN::Util - Utility functions for SVN hooks

=head1 VERSION

version 0.78

=head1 SUPPORT

Bugs may be submitted at
L<https://github.com/houseabsolute/perl-code-tidyall/issues>.

I am also usually active on IRC as 'autarch' on C<irc://irc.perl.org>.

=head1 SOURCE

The source code repository for Code-TidyAll can be found at
L<https://github.com/houseabsolute/perl-code-tidyall>.

=head1 AUTHORS

=over 4

=item *

Jonathan Swartz <swartz@pobox.com>

=item *

Dave Rolsky <autarch@urth.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 - 2020 by Jonathan Swartz.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

The full text of the license can be found in the F<LICENSE> file included with
this distribution.

=cut
