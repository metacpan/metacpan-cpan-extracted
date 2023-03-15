package App::VTide::Hooks;

# Created on: 2016-04-07 16:42:42
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moo;
use warnings;
use version;
use Carp;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;
use Path::Tiny;

our $VERSION = version->new('0.1.21');

has hook_cmds => (
    is      => 'rw',
    lazy    => 1,
    builder => '_hook_cmds',
);
has vtide => (
    is       => 'rw',
    required => 1,
    handles  => [qw/ config hooks /],
);

sub run {
    my ($self, $hook, @args) = @_;

    if ( $self->hook_cmds->{$hook} ) {
        $self->hook_cmds->{$hook}->($self, @args);
    }

    return;
}

sub _hook_cmds {
    my ($self) = @_;
    my $hooks  = {};
    my $global = path( $self->config->global_config )->parent->path('hooks.pl')->absolute;
    my $local  = path( $self->config->local_config )->parent->path('.vtide', 'hooks.pl')->absolute;

    if ( -f $global ) {
        $hooks = do $global;
    }
    if ( -f $local ) {
        my $done = do $local;
        $hooks = { %{ $hooks || {} }, %{ $done || {} } };
    }

    return $hooks;
}

1;

__END__

=head1 NAME

App::VTide::Hooks - Manage code hooks for APP::VTide

=head1 VERSION

This documentation refers to App::VTide::Hooks version 0.1.21

=head1 SYNOPSIS

   use App::VTide::Hooks;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.

=head1 DESCRIPTION

This module provides the basis from running user defined hooks. Those hooks
are located in the C<~/.vtide/hooks.pl> and C<$PROJECT/.vtide/hooks.pl> files.
They are perl files that are expected to return a hash where the keys are the
hook names and the values are subs to be run. Details about individual hooks
can be found in the various sub-command modules.

=head1 SUBROUTINES/METHODS

=head2 C<run ( $hook, @args )>

The the hook C<$hook> with the supplied arguments.

=head1 ATTRIBUTES

=head2 vtide

Reference to the vtide object

=head2 hook_cmds

Hash of configured hook subroutines

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Ivan Wills (ivan.wills@gmail.com).

Patches are welcome.

=head1 AUTHOR

Ivan Wills - (ivan.wills@gmail.com)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2016 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
