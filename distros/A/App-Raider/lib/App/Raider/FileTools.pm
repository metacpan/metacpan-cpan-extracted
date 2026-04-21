package App::Raider::FileTools;
our $VERSION = '0.003';
# ABSTRACT: MCP::Server factory with local filesystem tools (list/read/write/edit)

use strict;
use warnings;
use Path::Tiny;
use MCP::Server;

use Exporter 'import';
our @EXPORT_OK = qw( build_file_tools_server );


sub build_file_tools_server {
  my %args = @_;
  my $root = defined $args{root} ? path($args{root})->absolute : undef;

  my $resolve = sub {
    my ($path) = @_;
    my $p = path($path);
    if ($root) {
      $p = $p->is_absolute ? $p : $root->child($path);
      $p = $p->absolute;
      die "Path escapes root: $p\n" unless $root->subsumes($p);
    }
    return $p;
  };

  my $server = MCP::Server->new(name => 'app-raider-files', version => '1.0');

  $server->tool(
    name         => 'list_files',
    description  => 'List entries in a directory. Directories are suffixed with "/".',
    input_schema => {
      type       => 'object',
      properties => { path => { type => 'string', description => 'Directory path' } },
      required   => ['path'],
    },
    code => sub {
      my ($tool, $in) = @_;
      my $p = eval { $resolve->($in->{path}) };
      return $tool->text_result("Error: $@", 1) if $@;
      return $tool->text_result("Error: not a directory: $p", 1) unless -d $p;
      my @entries = sort map { -d $_ ? $_->basename . '/' : $_->basename } $p->children;
      return $tool->text_result(join("\n", @entries));
    },
  );

  $server->tool(
    name         => 'read_file',
    description  => 'Read the full contents of a text file.',
    input_schema => {
      type       => 'object',
      properties => { path => { type => 'string', description => 'File path' } },
      required   => ['path'],
    },
    code => sub {
      my ($tool, $in) = @_;
      my $p = eval { $resolve->($in->{path}) };
      return $tool->text_result("Error: $@", 1) if $@;
      return $tool->text_result("Error: not a file: $p", 1) unless -f $p;
      my $content = eval { $p->slurp_utf8 };
      return $tool->text_result("Error reading $p: $@", 1) if $@;
      return $tool->text_result($content);
    },
  );

  $server->tool(
    name         => 'write_file',
    description  => 'Write contents to a file. Creates parent directories, overwrites existing files.',
    input_schema => {
      type       => 'object',
      properties => {
        path    => { type => 'string', description => 'File path' },
        content => { type => 'string', description => 'Full file contents' },
      },
      required => ['path', 'content'],
    },
    code => sub {
      my ($tool, $in) = @_;
      my $p = eval { $resolve->($in->{path}) };
      return $tool->text_result("Error: $@", 1) if $@;
      eval {
        $p->parent->mkpath unless -d $p->parent;
        $p->spew_utf8($in->{content});
      };
      return $tool->text_result("Error writing $p: $@", 1) if $@;
      return $tool->text_result("Wrote " . length($in->{content}) . " bytes to $p");
    },
  );

  $server->tool(
    name         => 'edit_file',
    description  => 'Replace an exact unique substring in a file (old_string must match exactly once).',
    input_schema => {
      type       => 'object',
      properties => {
        path       => { type => 'string', description => 'File path' },
        old_string => { type => 'string', description => 'Exact text to replace' },
        new_string => { type => 'string', description => 'Replacement text' },
      },
      required => ['path', 'old_string', 'new_string'],
    },
    code => sub {
      my ($tool, $in) = @_;
      my $p = eval { $resolve->($in->{path}) };
      return $tool->text_result("Error: $@", 1) if $@;
      return $tool->text_result("Error: not a file: $p", 1) unless -f $p;
      my $content = eval { $p->slurp_utf8 };
      return $tool->text_result("Error reading $p: $@", 1) if $@;
      my $old = $in->{old_string};
      my $count = () = $content =~ /\Q$old\E/g;
      return $tool->text_result("Error: old_string not found", 1) if $count == 0;
      return $tool->text_result("Error: old_string matches $count times, must be unique", 1) if $count > 1;
      $content =~ s/\Q$old\E/$in->{new_string}/;
      eval { $p->spew_utf8($content) };
      return $tool->text_result("Error writing $p: $@", 1) if $@;
      return $tool->text_result("Edited $p");
    },
  );

  return $server;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Raider::FileTools - MCP::Server factory with local filesystem tools (list/read/write/edit)

=head1 VERSION

version 0.003

=head2 build_file_tools_server

    my $server = App::Raider::FileTools::build_file_tools_server(
        root => '/some/dir',  # optional chroot
    );

Returns an L<MCP::Server> instance with the tools C<list_files>, C<read_file>,
C<write_file>, and C<edit_file> registered. When C<root> is set, all path
arguments are confined to that directory.

=head1 SEE ALSO

=over

=item * L<MCP::Server>

=item * L<App::Raider>

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-app-raider/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
