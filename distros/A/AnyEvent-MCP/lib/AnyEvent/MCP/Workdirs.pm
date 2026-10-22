=head1 NAME

AnyEvent::MCP::Workdirs - persistent filesystem workdir IDs

=head1 DESCRIPTION

The registry assigns small positive integers to resolved absolute workdir
paths. It is shared by filesystem server instances using the same file.
Permission-rule identities remain independent of these selectors.

It is used by C<mcp-fs> so assistants can refer to a workdir by a short,
stable-while-retained number instead of repeating its pathname. It is
not a filesystem authorization mechanism: the selected workdir and the
permission engine still determine what an operation may access.
Applications that do not expose workdirs do not need this module.

   use AnyEvent::MCP::Workdirs;

   my $registry = AnyEvent::MCP::Workdirs->new (
      file => $registry_file, paths => [$resolved_project_path],
   );
   my $id = $registry->{ids}[0];
   $registry->refresh; # repeat periodically while the server runs

See L<mcp-fs/SANDBOX GRANTS> for how the server interprets these IDs,
and L<AnyEvent::MCP::File> for the locked state-file operations.

=head1 METHODS

=over

=item $registry = AnyEvent::MCP::Workdirs->new (file => $file, paths => [$path...], expiry => $seconds)

Resolve IDs for the supplied resolved paths, reserving new allocations under
the file lock. C<expiry> defaults to seven days. C<ids> contains the assigned
IDs in path order and stays fixed for this object's lifetime. The caller
refreshes immediately and periodically while its server is running.

=item $registry->refresh

Lock and reread the JSON registry, overwrite this server's assigned IDs with
their paths and the current C<last_use>, expire old entries after C<expiry>
seconds, and atomically replace the file. This never resolves or reallocates
the server's IDs. Startup allocations reuse the smallest available positive
IDs; configured paths retain their previous IDs if nobody reused them.

Entries are C<ID =E<gt> [workdir, last_use]>. The JSON uses UTF-8 with pretty printing.
Manual changes require restarting filesystem servers using the registry.

=back

=cut

package AnyEvent::MCP::Workdirs;

use common::sense;
use AnyEvent::MCP ();
use AnyEvent::MCP::File ();
use JSON::XS ();

our @ISA = qw(AnyEvent::MCP::Base);

my $json = JSON::XS->new->utf8->canonical->pretty;

sub _read {
   my ($self, $lock) = @_;

   local $/;
   my $text = <$lock>;
   my $entries = length $text ? $json->decode ($text) : {};
   ref $entries eq "HASH" or die "$self->{file}: expected workdir ID object\n";

   for my $id (keys %$entries) {
      my $entry = $entries->{$id};
      $id =~ /\A[1-9][0-9]*\z/ && ref $entry eq "ARRAY" && @$entry == 2
         && defined $entry->[0] && !ref $entry->[0] && $entry->[0] =~ m{\A/} && $entry->[0] !~ /\0/
         && defined $entry->[1] && !ref $entry->[1] && $entry->[1] =~ /\A[0-9]+\z/
         or die "$self->{file}: invalid workdir entry '$id'\n";
   }

   $entries
}

sub new {
   my ($class, %kv) = @_;

   my $self = $class->SUPER::new (expiry => 7 * 86400, %kv);
   my $lock = AnyEvent::MCP::File::lock $self->{file};
   my $entries = $self->_read ($lock);
   my $now = time;
   my %active = map { $_ => 1 } @{$self->{paths}};

   for my $id (keys %$entries) {
      delete $entries->{$id}
         unless $active{$entries->{$id}[0]} || $entries->{$id}[1] > $now - $self->{expiry};
   }

   my %id = map { $entries->{$_}[0] => $_ } keys %$entries;
   my @ids;
   my $next = 1;

   for my $path (@{$self->{paths}}) {
      unless (exists $id{$path}) {
         ++$next while exists $entries->{$next};
         $id{$path} = $next++;
         $entries->{$id{$path}} = [$path, $now];
      }

      push @ids, 0 + $id{$path};
   }

   # reserve allocations before another server can choose the same IDs.
   AnyEvent::MCP::File::replace $self->{file}, $json->encode ($entries);
   $self->{ids} = \@ids;

   $self
}

sub refresh {
   my ($self) = @_;

   my $lock = AnyEvent::MCP::File::lock $self->{file};
   my $entries = $self->_read ($lock);
   my $now = time;

   for (0 .. $#{$self->{paths}}) {
      $entries->{$self->{ids}[$_]} = [$self->{paths}[$_], $now];
   }

   for my $id (keys %$entries) {
      delete $entries->{$id} if $entries->{$id}[1] <= $now - $self->{expiry};
   }

   AnyEvent::MCP::File::replace $self->{file}, $json->encode ($entries);
}

1;
