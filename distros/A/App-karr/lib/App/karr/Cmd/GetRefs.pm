# ABSTRACT: Fetch helper payloads from a Git ref

package App::karr::Cmd::GetRefs;
our $VERSION = '0.101';
use Moo;
use MooX::Cmd;
use MooX::Options (
  usage_string => 'USAGE: karr get-refs REF',
);
use App::karr::Git;


sub execute {
  my ($self, $args_ref, $chain_ref) = @_;
  my $ref_input = $args_ref->[0];
  die "Usage: karr get-refs REF\n" unless defined $ref_input;

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
  $git->pull_ref($ref) or die "Failed to fetch $ref\n";

  my $content = $git->read_ref($ref);
  print STDERR "Fetched $ref\n";
  print $content;
  print "\n" unless $content =~ /\n\z/;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Cmd::GetRefs - Fetch helper payloads from a Git ref

=head1 VERSION

version 0.101

=head1 SYNOPSIS

    karr get-refs superpowers/spec/1234.md
    karr get-refs refs/superpowers/spec/1234.md

=head1 DESCRIPTION

Fetches a single helper ref from the remote and prints only its payload to
standard output. Informational messages go to standard error so the command can
be composed into scripts or agent pipelines.

This is especially useful for AI-oriented workflows that want shared spec or
planning blobs without coupling them to the task board itself.

=head1 SEE ALSO

L<karr>, L<App::karr>, L<App::karr::Cmd::SetRefs>,
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
