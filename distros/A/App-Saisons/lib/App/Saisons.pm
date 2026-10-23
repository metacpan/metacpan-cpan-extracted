package App::Saisons;
use strict;
use warnings;
our $VERSION = '0.2.1';
# Windows has no HOME; every module interpolating $ENV{HOME} loads this one
BEGIN { $ENV{HOME} //= $ENV{USERPROFILE} // '' }
# `make fatpack` stamps $main::SAISONS_BUILD (git describe) into the bundle;
# main:: survives the packer's package renaming where a package var would not
sub version_string {
    no warnings 'once';
    return $VERSION . ' (' . ($main::SAISONS_BUILD // 'dev') . ')';
}
1;

__END__

=head1 NAME

App::Saisons - terminal UI for browsing and resuming AI coding agent sessions

=head1 DESCRIPTION

App::Saisons implements the L<saisons> command: one list of all the AI
coding agent sessions on the machine - Claude Code, OpenAI Codex, Gemini
CLI, Aider and opencode. Sessions can be filtered, searched, grouped and
sorted, and selected ones resume in a new tmux window, terminal tab or the
current terminal.

See L<saisons> for usage, keys and configuration.

=head1 AUTHOR

Nicolas Mendoza E<lt>mendoza@pvv.ntnu.noE<gt>

=head1 LICENSE

This software is licensed under the Artistic License 2.0.

=cut
