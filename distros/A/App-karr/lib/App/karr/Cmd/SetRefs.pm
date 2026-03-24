# ABSTRACT: Store helper payloads in a Git ref

package App::karr::Cmd::SetRefs;
our $VERSION = '0.102';
use Moo;
use MooX::Cmd;
use MooX::Options (
  usage_string => 'USAGE: karr set-refs REF CONTENT...',
);
use App::karr::Git;


sub execute {
  my ($self, $args_ref, $chain_ref) = @_;
  my ($ref_input, @content_parts) = @$args_ref;
  die "Usage: karr set-refs REF CONTENT...\n" unless defined $ref_input && @content_parts;

  my $repo_dir = '.';
  if ($chain_ref && @$chain_ref) {
    my $root = $chain_ref->[0];
    if ($root && $root->can('has_dir') && $root->has_dir) {
      $repo_dir = $root->dir;
    }
  }

  my $git = App::karr::Git->new(dir => $repo_dir);
  die "Not a git repository.\n" unless $git->is_repo;

  my $ref = $git->validate_helper_ref($ref_input);
  my $content = join ' ', @content_parts;

  $git->write_ref($ref, $content) or die "Failed to write $ref\n";
  $git->push_ref($ref) or die "Failed to push $ref\n";

  print STDERR "Stored $ref\n";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Cmd::SetRefs - Store helper payloads in a Git ref

=head1 VERSION

version 0.102

=head1 SYNOPSIS

    karr set-refs superpowers/spec/1234.md draft ready
    karr set-refs refs/superpowers/spec/1234.md "full payload"

=head1 DESCRIPTION

Writes a helper payload into a free-form Git ref outside the protected board
namespace. This is intended for adjunct workflow data such as AI planning
artifacts or coordination hints that should sync through Git without becoming a
task card.

Like the rest of the Perl CLI, this works fine from a local install, and the
same command can be run from the Docker wrapper if you prefer the vendored
runtime style described in the README.

=head1 SEE ALSO

L<karr>, L<App::karr>, L<App::karr::Cmd::GetRefs>,
L<App::karr::Cmd::Backup>, L<App::karr::Git>

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-app-karr/issues>.

=head2 IRC

Join C<#ai> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
