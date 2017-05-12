package Bot::BasicBot::Pluggable::Module::CoreList;

use strict;
use Bot::BasicBot::Pluggable::Module;
use Module::CoreList 2.18;

use vars qw( @ISA $VERSION );
@ISA     = qw(Bot::BasicBot::Pluggable::Module);
$VERSION = '0.05';

my $ident = qr/[A-Za-z_][A-Za-z_0-9]*/;
my $cmds  = qr/find|search|release|date/;

sub told {
    my ( $self, $mess ) = @_;
    my $bot = $self->bot();

    # we must be directly addressed
    return
        if !( ( defined $mess->{address} && $mess->{address} eq $bot->nick() )
        || $mess->{channel} eq 'msg' );

    # ignore people we ignore
    return if $bot->ignore_nick( $mess->{who} );

    # only answer to our command (which can be our name too)
    my $src = $bot->nick() eq 'corelist' ? 'raw_body' : 'body';
    return
        if $mess->{$src}
        !~ /^\s*corelist(?:\W+($cmds))?\W+(.*)/io;

    # grab the parameter list
    my ( $command, $module, @args ) = ( $1 || 'release', split /\s+/, $2 );

    # compute the reply
    my $reply;
    if ( $command =~ /^(?:find|search)$/i ) {
        my @modules = Module::CoreList->find_modules( qr/$module/, @args );

        # shorten large response lists
        @modules = (@modules[0..8], '...') if @modules > 9;

        local $" = ', ';
        my $where = ( @args ? " in perl @args" : '' );
        $reply = ( @modules
            ? "Found @modules"
            : "Found no module matching /$module/" )
            . $where;
    }
    else {
        my $release = Module::CoreList->first_release($module);
        my $removed = $Module::CoreList::VERSION >= 2.32
            && Module::CoreList->removed_from($module);
        my $deprecated = $Module::CoreList::VERSION >= 2.77
            && Module::CoreList->deprecated_in($module);
        no warnings 'uninitialized';
        push my @reply, $release
            ? "$module was first released with perl $release"
            . " (released on $Module::CoreList::released{$release})"
            : "$module is not in the core";
        push @reply, "deprecated in perl $deprecated"
            . " (released on $Module::CoreList::released{$deprecated})"
            if $deprecated;
        push @reply, "removed from perl $removed"
            . " (released on $Module::CoreList::released{$removed})"
            if $removed;
        push @reply, join " and ", splice @reply, -2 if @reply > 1;
        $reply = join ', ', @reply;
    }

    return $reply;
}

sub help {'corelist [release] module, or corelist find regex [perl versions]'}

1;

__END__

=head1 NAME

Bot::BasicBot::Pluggable::Module::CoreList - IRC frontend to Module::CoreList

=head1 SYNOPSIS

    < you> bot: corelist File::Spec
    < bot> File::Spec was first released with perl 5.00503 (released on 1999-03-28)

=head1 DESCRIPTION

This module is a frontend to the excellent C<Module::CoreList> module
which will let you know what modules shipped with which versions of perl,
over IRC.

=head1 IRC USAGE

The robot replies to requests in the following form:

    corelist <subcommand> [args]

=head2 Commands

The robot understand the following subcommands:

=over 4

=item * release

=item * date

    < you> bot: corelist release Test::More
    < bot> you: Test::More was first released with perl 5.7.3 (released on 2002-03-05)

If no command is given, C<release> is the default.

=item * search

=item * find

    < you> bot corelist search Data
    < bot> Found Data::Dumper, Module::Build::ConfigData

Perl version numbers can be passed as optional parameters to restrict
the search:

    < you> corelist search Data 5.006
    < bot> Found Data::Dumper in perl 5.006

The search never returns more than 9 replies, to avoid flooding the channel:

    < you> bot: corelist find e
    < bot> Found AnyDBM_File, AutoLoader, B::Assembler, B::Bytecode, B::Debug, B::Deparse, B::Disassembler, B::Showlex, B::Terse, ...

=back

=head1 AUTHOR

Philippe "BooK" Bruhat, C<< <book@cpan.org> >>, inspired by the existing
C<corelist> bot, last seen on IRC in May 2006.

Since November 2006, the C<corelist> bot in C<irc.perl.org> runs
using this module.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-bot-basicbot-pluggable-module-corelist@rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/>. I will be notified, and
then you'll automatically be notified of progress on your bug as I
make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2006-2013 Philippe "BooK" Bruhat, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
