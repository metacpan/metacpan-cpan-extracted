# Copyright (c) 2026 Philipp Schafft

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: Work with Tag databases, plugin base package

package Data::TagDB::Interface::Plugin;

use v5.10;
use strict;
use warnings;

use parent ();

our $VERSION = v0.14;

our %_known_plugins;



sub plugin_attach {
    my ($pkg, $db, $conf, %opts) = @_;

    return {};
}

# ---- Private helpers ----

sub import {
    my ($caller) = caller(0);
    $_known_plugins{$caller} = undef;
    @_ = (parent::, -norequire, __PACKAGE__);
    goto &parent::import;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::TagDB::Interface::Plugin - Work with Tag databases, plugin base package

=head1 VERSION

version v0.14

=head1 SYNOPSIS

    use Data::TagDB::Interface::Plugin; # See notes below

(experimental since v0.14)

B<Note:>
Modules will L<perlfunc/use> this module and not use L<parent> as one would expect.
This is due to this module performing some early registration that is impossible with L<parent>.
This module's C<import()> will make the package using this one also inherit from it.

=head1 METHODS

=head2 plugin_attach

    my $info = My::Plugin->plugin_attach($db, $conf, %opts);

(experimental since v0.14)

This method is called by the database to attach the plugin to a database.

The method is passed a configuration (C<$conf>) that is specific to the plugin or C<undef>.

The method must return a hashref to an information structure as used by the database to talk to the plugin.
The database module might write to the plugin structure (so it cannot be read-only) but
will do so only in ways that allow it to be reused (so it is safe to store the info structure in a global or state variable).

This method B<MUST NOT> write to the database.
If a plugin requires data to be present in the database it should document that and provide it in a way supported by L<Data::TagDB::Migration>.

This method may C<die> on error. This will not corrupt the state of the database or the database handle.

If the plugin requires to state information it B<MUST NOT> do this via global or state variables.
It can however use L<Data::Identifier::Interface::Userdata/userdata> on the provided database handle.

The default implementation will return an empty information structure.

=head1 FURTHER DIRECTIONS

=head2 FUTURE METHODS

To be future-safe this interface reserves the following methods:
C<new>,
C<plugin_*>,
C<_*_provider>.

Also the methods used and/or reserved by L<Data::Identifier::Interface::Simple>, L<Data::Identifier::Interface::Known>, L<Data::Identifier::Interface::Subobjects>, and L<Data::Identifier::Interface::Userdata> are reserved to be used by those interfaces.

=head1 AUTHOR

Philipp Schafft <lion@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024-2026 by Philipp Schafft <lion@cpan.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
