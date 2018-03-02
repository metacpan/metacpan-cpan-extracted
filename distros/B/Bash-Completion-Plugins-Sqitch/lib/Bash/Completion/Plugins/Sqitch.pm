package Bash::Completion::Plugins::Sqitch;

use strict;
use warnings;
use parent 'Bash::Completion::Plugin';
use Bash::Completion::Utils qw{command_in_path};
use Bash::Completion::RequestX::Sqitch;

our $VERSION = '0.01';

sub complete {
    my ($self, $r) = @_;

    # this is the word bash is trying to complete
    my $word = $r->word;

    # extended request for the sqitch command
    my $rx = Bash::Completion::RequestX::Sqitch->new(request => $r);

    $r->candidates(prefix_match($word, @{$rx->candidates}));
}

# Bash::Completion::Utils version of prefix_match is broken in that it doesn't
# quote the meta characters in variables used in regular expressions.
sub prefix_match {
    my $prefix = shift;

    return grep { /^\Q$prefix\E/ } @_;
}

sub should_activate {
    return [grep { command_in_path($_) } ('sqitch')];
}

1;

__END__

=encoding utf-8

=head1 NAME

Bash::Completion::Plugins::Sqitch - bash completion for Sqitch

=head1 SYNOPSIS

    # Will install App::Sqitch and Bash::Completion if they aren't installed
    $ cpanm Bash::Completion::Plugins::Sqitch;

    # Add newly created Sqitch Bash::Completion plugin to current session. (See
    # "SETTING UP AUTO-COMPLETE" to permanently add completions for `sqitch`.)
    $ eval "$(bash-complete setup)"

    # Magical tab completion for all things Sqitch! (well, kind of - see below)
    $ sqitch <tab><tab>

=head1 DESCRIPTION

L<Bash::Completion::Plugins::Sqitch> is a L<Bash::Completion> plugin for
L<App::Sqitch>.

The functionality of this plugin is heavily dependent and modelled around the
design of L<App::Sqitch> version C<0.9996>. As long as L<App::Sqitch> doesn't
drastically change, things should be fine. I cannot guarantee that it will work
for older versions of L<App::Sqitch>, so update to the latest version if you
have any problems.

Currently this completion module only returns completions for subcommands
(e.g., deploy, verify, revert etc.). It does I<not> return C<< sqitch [options]
>> yet, nor sub-subcommands - I will add them in newer versions.

It works by using the C<App::Sqitch::Command::> namespace to list the C<sqitch>
subcommands, and takes advantage of each subcommand providing the
L<Getopt::Long> options as accessible methods. As such, this means that the
auto-complete candidates should track new subcommands and options that are
added or deprecated. Once downside to this is that some of the options that are
included in the auto-complete candidate list aren't part of the official C<<
$subcommand --help >> for a particular subcommand.

N.B., Sqitch auto-completion works best if you're in the sqitch folder (the one
with the C<sqitch.conf> and C<sqitch.plan> in it - which is generally how I use
it all the time anyway.

=head1 EXTRAS

Extended auto-complete options are available in certain circumstances.

=head2 --target

    $ sqitch target add dev db:pg://username:password@localhost/somedatabase

    # sqitch.conf
    ...
    [target "dev"]
        uri = db:pg://username:password@localhost/somedatabase
    ...

    $ sqitch verify --target <tab><tab>

When the option C<--target> is recognised anywhere in the list of options, the
C<sqitch.conf> file is read, and any C<targets> are returned as candidates.

N.B., this extra requires that your C<cwd> is the sqitch directory with the
C<sqitch.plan> file.

=head2 db:pg

    # .bashrc or .bash_profile
    #
    # auto-complete won't work for the [database] with the default
    # COMP_WORDBREAKS, as such I globally remove `:` and `=`. This isn't for
    # everyone - but this extra will *not* work without doing it.
    export COMP_WORDBREAKS=${COMP_WORDBREAKS/:/}
    export COMP_WORDBREAKS=${COMP_WORDBREAKS/=/}

    $ sqitch status db:pg:<tab><tab>

I'm hoping this is more useful in the future because there is a bug with most
of the useful sqitch subcommands in that they don't honour the C<service>
paramenter in the C<< [database] >> string. It works for status though!

N.B., this currently only works for the C<pg> engine as it uses
L<Pg::ServiceFile> to autocomplete the C<database> based on the service names.

=head1 SETTING UP AUTO-COMPLETE

The instructions for setting up L<Bash::Completion> don't work under all Perl
environments - particularly L<plenv|https://github.com/tokuhirom/plenv>. The
instructions below should work.

=head2 bash

    # Stick this into your .bashrc or .bash_profile
    eval "$(bash-complete setup)"

=head2 zsh

    # Stick this into your .zshrc
    autoload -U bashcompinit
    bashcompinit
    eval "$(bash-complete setup)"

=head1 AUTHOR

Paul Williams E<lt>kwakwa@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2018- Paul Williams

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

L<App::Sqitch>,
L<Bash::Completion>.

=cut
