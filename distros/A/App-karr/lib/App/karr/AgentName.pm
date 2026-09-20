# ABSTRACT: Derive a claim-safe agent name from a checkout directory

package App::karr::AgentName;
our $VERSION = '0.601';
use strict;
use warnings;
use Path::Tiny ();
use App::karr::Git ();
use Exporter qw( import );

our @EXPORT_OK = qw( agent_name checkout_basename sanitize_claim_token );


sub agent_name {
  my (%args) = @_;
  my $base = sanitize_claim_token( checkout_basename( dir => $args{dir} ) );
  $base = 'agent' unless length $base;
  return $base unless $args{unique};
  return $base . '-' . _suffix();
}


sub checkout_basename {
  my (%args) = @_;
  my $start = Path::Tiny::path( defined $args{dir} ? $args{dir} : '.' )->absolute;
  my $git   = App::karr::Git->new( dir => $start->stringify );
  my $root  = eval { $git->repo_root };
  return $root ? $root->basename : $start->basename;
}


sub sanitize_claim_token {
  my ($raw) = @_;
  my $token = lc( defined $raw ? $raw : '' );
  $token =~ s/[^a-z0-9]+/-/g;
  $token =~ s/\A-+//;
  $token =~ s/-+\z//;
  return $token;
}

# Three lowercase-alphanumeric characters, the "8fa" in ADR 0005's karr-8fa.
# rand seeds itself on first use, which is all this needs: the suffix only has
# to differ between two agents in one directory, not resist prediction.
sub _suffix {
  my @chars = ( 0 .. 9, 'a' .. 'z' );
  return join '', map { $chars[ int rand @chars ] } 1 .. 3;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::AgentName - Derive a claim-safe agent name from a checkout directory

=head1 VERSION

version 0.601

=head1 SYNOPSIS

    use App::karr::AgentName qw( agent_name );

    my $name   = agent_name();                       # this checkout, e.g. "karr"
    my $unique = agent_name( unique => 1 );           # e.g. "karr-8fa"
    my $other  = agent_name( dir => $path, unique => 1 );

=head1 DESCRIPTION

The name derivation behind C<karr agent-name> (L<App::karr::Cmd::AgentName>),
lifted out of the command so that it is callable without a command object.
ADR 0005 makes C<KARR_CLAIM> default to exactly what C<karr agent-name> prints,
and L<App::karr::Foundation::Runner> exports C<KARR_CLAIM> into an agent's
environment -- so both sides have to produce the same string from the same
checkout, which means one function, not two copies.

The name is the checkout's own directory name, sanitised to a claim-safe token:
a value that is stable per worktree, meaningful in C<karr show>, and distinct
per worktree without a generator. C<< unique => 1 >> appends a short random
suffix for the one case a directory name cannot tell apart -- several agents
started in the B<same> directory (ADR 0005, scenario S3).

=head2 agent_name

    my $name = agent_name( dir => $path, unique => 1 );

The claim name for a checkout. Both arguments are optional:

=over 4

=item * C<dir> -- the directory to name. Defaults to the current directory.
The worktree root is discovered from it (L</checkout_basename>), so it does not
matter which subdirectory of the checkout is passed.

=item * C<unique> -- when true, append C<-> and a short random alphanumeric
suffix, so several agents in the same directory get distinct names.

=back

Returns the sanitised base name (L</sanitize_claim_token>), with the suffix
when asked. A directory whose name sanitises to nothing falls back to C<agent>,
so the result is always a usable claim token.

=head2 checkout_basename

    my $base = checkout_basename( dir => $path );

The raw (un-sanitised) directory name of the checkout C<dir> sits in: the
worktree root discovered by walking up from C<dir> the way every other
board-discovering path does (L<App::karr::Git/repo_root>, libgit2's C<workdir>,
which is what C<git rev-parse --show-toplevel> reports). Outside a work tree it
falls back to the basename of C<dir> itself (default: the current directory).

=head2 sanitize_claim_token

    my $token = sanitize_claim_token('My Project!');   # "my-project"

Folds any string to a claim-safe token: lowercase, every run of characters
outside C<[a-z0-9]> collapsed to a single C<->, with leading and trailing C<->
trimmed. Returns the empty string when nothing survives.

=head1 SEE ALSO

L<karr>, L<App::karr>, L<App::karr::Cmd::AgentName>

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/karr/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
