# Copyright (c) 2026 Philipp Schafft

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: Work with Tag databases, plugin base package

package Data::TagDB::Interface::Includeable;

use v5.10;
use strict;
use warnings;

our $VERSION = v0.14;



sub include { ... }

# ---- Private helpers ----


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::TagDB::Interface::Includeable - Work with Tag databases, plugin base package

=head1 VERSION

version v0.14

=head1 SYNOPSIS

    use parent 'Data::TagDB::Interface::Includeable';

(experimental since v0.14)

=head1 METHODS

=head2 include

    Some::Package->include($migration [, %opts ]);

(experimental since v0.14)

=head1 AUTHOR

Philipp Schafft <lion@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024-2026 by Philipp Schafft <lion@cpan.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
