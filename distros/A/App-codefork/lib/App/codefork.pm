package App::codefork;
# ABSTRACT: Worlds dumbest code forker
our $VERSION = '1.000';
use Moo;
use Path::Tiny;
use Text::Diff;

has config => (
  is => 'ro',
  required => 1,
  coerce => sub { path($_[0]) },
);

has dir => (
  is => 'ro',
  default => sub { path('.')->absolute },
  coerce => sub { path($_[0])->absolute },
);

has debug => (
  is => 'ro',
  default => sub { $ENV{CODEFORK_DEBUG} ? 1 : 0 },
);

has mods => (
  is => 'lazy',
);


sub _build_mods {
  my ($self) = @_;
  my @lines = $self->config->lines({ chomp => 1 });
  return [ map {
    if (/\|/) {
      [ replace => split(/\|/, $_, 2) ]
    } elsif (/%/) {
      [ word => split(/%/, $_, 2) ]
    } else {
      ()
    }
  } @lines ];
}

sub collect_changes {
  my ($self) = @_;
  $self->log('Parsing config...');
  $self->log($_->[0].': '.$_->[1].' => '.$_->[2]) for @{$self->mods};
  my @changes;
  $self->_collect_dir($self->dir, '', \@changes);
  return \@changes;
}


sub _collect_dir {
  my ($self, $dir, $new_dir_prefix, $changes) = @_;
  my @mods = @{$self->mods};

  for my $entry (sort $dir->children) {
    my $basename = $entry->basename;
    next if $basename eq '.git' || $basename eq '.svn';

    my $new_basename = $basename;
    for my $mod (@mods) {
      if ($mod->[0] eq 'replace') {
        $new_basename =~ s/$mod->[1]/$mod->[2]/g;
      }
    }

    my $old_rel = $entry->relative($self->dir)->stringify;
    my $new_rel = length($new_dir_prefix)
      ? "$new_dir_prefix/$new_basename"
      : $new_basename;

    if ($entry->is_dir) {
      $self->_collect_dir($entry, $new_rel, $changes);
    } else {
      my $content = $entry->slurp_raw;
      my $new_content = $content;
      for my $mod (@mods) {
        my ($cmd, $from, $to) = @$mod;
        if ($cmd eq 'replace') {
          $new_content =~ s/$from/$to/g;
        } elsif ($cmd eq 'word') {
          $new_content =~ s/([^A-Za-z0-9]+)$from([^A-Za-z0-9]+)/$1$to$2/g;
        }
      }

      if ($new_rel ne $old_rel || $new_content ne $content) {
        push @$changes, {
          old_path => $old_rel,
          new_path => $new_rel,
          old_content => $content,
          new_content => $new_content,
        };
      }
    }
  }
}

sub generate_diff {
  my ($self, $changes) = @_;
  $changes //= $self->collect_changes;
  my $output = '';
  for my $change (@$changes) {
    my $renamed = $change->{old_path} ne $change->{new_path};
    my $modified = $change->{old_content} ne $change->{new_content};

    if ($modified) {
      my $diff_text = diff(
        \$change->{old_content},
        \$change->{new_content},
        {
          STYLE => 'Unified',
          FILENAME_A => "a/$change->{old_path}",
          FILENAME_B => "b/$change->{new_path}",
        },
      );
      if ($renamed) {
        my $header = "rename from $change->{old_path}\nrename to $change->{new_path}\n";
        $diff_text =~ s/^(---\s)/$header$1/m;
      }
      $output .= $diff_text;
    } elsif ($renamed) {
      $output .= "diff $change->{old_path} $change->{new_path}\n";
      $output .= "rename from $change->{old_path}\n";
      $output .= "rename to $change->{new_path}\n";
    }
  }
  return $output;
}


sub apply_changes {
  my ($self, $changes) = @_;
  $changes //= $self->collect_changes;
  for my $change (@$changes) {
    my $old = $self->dir->child($change->{old_path});
    my $new = $self->dir->child($change->{new_path});
    my $renamed = $change->{old_path} ne $change->{new_path};
    my $modified = $change->{old_content} ne $change->{new_content};

    $new->parent->mkpath if $renamed;

    if ($modified) {
      $self->log("modify: $change->{new_path}");
      $new->spew_raw($change->{new_content});
      if ($renamed) {
        $self->log("rename: $change->{old_path} -> $change->{new_path}");
        $old->remove;
      }
    } elsif ($renamed) {
      $self->log("rename: $change->{old_path} -> $change->{new_path}");
      $old->move($new);
    }
  }
  return scalar @$changes;
}


sub log {
  my ($self, $text) = @_;
  print STDERR $text."\n" if $self->debug;
}


sub run {
  my ($class, @args) = @_;

  my $command = 'diff';
  my $config = 'fork.conf';
  my $output_file;

  if (@args && $args[0] eq 'apply') {
    $command = 'apply';
    shift @args;
    $config = shift @args if @args;
  } elsif (@args && $args[0] eq 'output') {
    $command = 'output';
    shift @args;
    if (@args == 2) {
      $config = shift @args;
    }
    $output_file = shift @args;
    die "output command requires a filename\n" unless defined $output_file;
  } elsif (@args) {
    $config = shift @args;
  }

  die "Config file '$config' not found\n" unless -f $config;

  my $app = $class->new(config => $config);
  my $changes = $app->collect_changes;

  if ($command eq 'diff') {
    my $diff = $app->generate_diff($changes);
    if (length $diff) {
      print $diff;
    } else {
      print "No changes.\n";
    }
  } elsif ($command eq 'apply') {
    my $count = $app->apply_changes($changes);
    print "Applied $count change(s).\n";
  } elsif ($command eq 'output') {
    my $diff = $app->generate_diff($changes);
    path($output_file)->spew_utf8($diff);
    print "Wrote diff to $output_file\n";
  }
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::codefork - Worlds dumbest code forker

=head1 VERSION

version 1.000

=head1 SYNOPSIS

    use App::codefork;

    my $app = App::codefork->new(config => 'fork.conf');

    # Collect changes without applying them
    my $changes = $app->collect_changes;

    # Preview as unified diff
    print $app->generate_diff($changes);

    # Apply when ready
    $app->apply_changes($changes);

=head1 DESCRIPTION

App::codefork is a simple tool for forking code by performing systematic
replacements in filenames and file contents across directory trees.

The workflow is diff-based and safe by design: changes are first collected
and can be previewed as a unified diff before anything is modified on disk.

For the command-line interface, see L<codefork>.

=head2 config

Path to the config file containing forking instructions. Required.

=head2 dir

Work directory to process. Defaults to current directory.

=head2 debug

Show debug information. Enabled via C<CODEFORK_DEBUG=1> environment variable.

=head2 mods

Parsed modification instructions from the config file.

=head2 collect_changes

    my $changes = $app->collect_changes;

Recursively scans the work directory and computes all modifications without
applying them. Returns an arrayref of change hashrefs with keys C<old_path>,
C<new_path>, C<old_content>, C<new_content>.

=head2 generate_diff

    my $diff = $app->generate_diff($changes);

Generates a unified diff string from the collected changes. If C<$changes>
is not passed, calls L</collect_changes> automatically.

=head2 apply_changes

    my $count = $app->apply_changes($changes);

Applies the collected changes to disk. Returns the number of changes applied.

=head2 log

    $self->log($message);

Prints a log message to STDERR if C<debug> is enabled.

=head2 run

    App::codefork->run(@ARGV);

CLI entry point. Parses arguments and executes the appropriate command.

=head1 UPGRADE NOTICE

B<Version 1.000 has a completely new command-line interface.>

The old C<--config>, C<--dir>, and C<--debug> flags from L<MooX::Options>
are no longer supported. The new interface uses positional commands instead:

    # Old (no longer works):
    codefork --config fork.conf --dir /path/to/code

    # New:
    cd /path/to/code
    codefork fork.conf

See L<codefork> for the full new command-line syntax.

Debug output is now enabled via the C<CODEFORK_DEBUG=1> environment variable
instead of C<--debug>.

=head1 CONFIG FILE FORMAT

The config file (default: C<fork.conf>) contains replacement instructions,
one per line:

=over 4

=item * C<from|to> - Replace regex pattern C<from> with C<to> in filenames and file contents

=item * C<from%to> - Replace whole word C<from> with C<to> (non-alphanumeric boundaries enforced, so C<hh> won't match inside C<ohhh>)

=back

Example config:

    HomeHive|AqHive
    homehive|aqhive
    hh%ah

Empty lines and lines without a C<|> or C<%> separator are ignored.

=head1 ENVIRONMENT

=over 4

=item C<CODEFORK_DEBUG>

Set to a true value to enable verbose debug output to STDERR.

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-app-codefork/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
