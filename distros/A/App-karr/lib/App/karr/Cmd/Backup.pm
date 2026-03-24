# ABSTRACT: Export the ref-backed karr board as YAML

package App::karr::Cmd::Backup;
our $VERSION = '0.102';
use Moo;
use MooX::Cmd;
use MooX::Options (
  usage_string => 'USAGE: karr backup [--output PATH]',
);
use Path::Tiny;
use YAML::XS qw( Dump );
use App::karr::Git;
use App::karr::BoardStore;


option output => (
  is => 'ro',
  format => 's',
  doc => 'Write YAML snapshot to a file instead of stdout',
);

sub execute {
  my ($self, $args_ref, $chain_ref) = @_;

  my $git = App::karr::Git->new( dir => '.' );
  die "Not a git repository. karr requires Git.\n" unless $git->is_repo;

  my $root = $git->repo_root;
  $git = App::karr::Git->new( dir => $root->stringify );
  $git->pull if $git->has_remote;

  my $store = App::karr::BoardStore->new( git => $git );
  die "No karr board found. Run 'karr init' to create one.\n"
    unless $store->board_exists;

  my $yaml = Dump( $store->snapshot );

  if ( $self->output ) {
    my $file = path( $self->output );
    $file->parent->mkpath;
    $file->spew_utf8($yaml);
    print STDERR "Wrote backup to $file\n";
    return;
  }

  print $yaml;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Cmd::Backup - Export the ref-backed karr board as YAML

=head1 VERSION

version 0.102

=head1 SYNOPSIS

    karr backup > karr-backup.yml
    karr backup --output karr-backup.yml

=head1 DESCRIPTION

Exports the complete C<refs/karr/*> namespace as a YAML snapshot. The default
mode writes the snapshot to standard output so it can be redirected or piped.
Use C<--output> when you want C<karr> to write the file directly.

=head1 OPTIONS

=over 4

=item * C<--output>

Write the YAML snapshot to the given file instead of standard output.

=back

=head1 SEE ALSO

L<karr>, L<App::karr>, L<App::karr::Cmd::Restore>,
L<App::karr::Cmd::Destroy>, L<App::karr::Cmd::Sync>

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
