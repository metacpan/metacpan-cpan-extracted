# ABSTRACT: Board configuration management

package App::karr::Config;
our $VERSION = '0.402';
use Moo;
use YAML::XS qw( LoadFile DumpFile );
use Path::Tiny;


has file => ( is => 'ro', required => 1 );
has data => ( is => 'lazy' );

sub _build_data {
  my ($self) = @_;
  my $file = $self->file;
  return LoadFile($file->stringify) if defined $file && -f $file;
  die "No file or data provided to Config\n";
}

sub from_merged {
  my ($class, $merged) = @_;
  return bless { data => $merged, file => undef }, $class;
}

sub save {
  my ($self) = @_;
  DumpFile($self->file->stringify, $self->data);
}

sub statuses {
  my ($self) = @_;
  return map {
    ref $_ ? $_->{name} : $_
  } @{ $self->data->{statuses} // [] };
}

sub status_config {
  my ($self, $name) = @_;
  for my $s (@{ $self->data->{statuses} // [] }) {
    if (ref $s) {
      return $s if $s->{name} eq $name;
    } elsif ($s eq $name) {
      return { name => $s };
    }
  }
  return undef;
}

sub priorities {
  my ($self) = @_;
  return @{ $self->data->{priorities} // [qw(low medium high critical)] };
}

sub claim_timeout {
  my ($self) = @_;
  return $self->data->{claim_timeout} // '1h';
}

sub foundation_enabled {
  my ($self) = @_;
  my $f = $self->data->{foundation};
  return 1 unless ref $f eq 'HASH' && exists $f->{enabled};
  return $f->{enabled} ? 1 : 0;
}


sub foundation_reason {
  my ($self) = @_;
  my $f = $self->data->{foundation};
  return undef unless ref $f eq 'HASH';
  my $reason = $f->{reason};
  return ( defined $reason && length $reason ) ? $reason : undef;
}


sub parse_bool {
  my ($class, $value) = @_;
  die "Missing boolean value\n" unless defined $value;
  my $v = lc $value;
  $v =~ s/^\s+//;
  $v =~ s/\s+$//;
  return 1 if $v =~ /^(?:1|true|yes|on)$/;
  return 0 if $v =~ /^(?:0|false|no|off)$/;
  die "Invalid boolean: $value (use true/false, yes/no, on/off, 1/0)\n";
}


sub priority_order {
  my ($class) = @_;
  return (critical => 0, high => 1, medium => 2, low => 3);
}


sub class_order {
  my ($class) = @_;
  return (expedite => 0, 'fixed-date' => 1, standard => 2, intangible => 3);
}


sub is_terminal_status {
  my ($class, $status) = @_;
  return 1 if $status eq 'done' || $status eq 'archived';
  return 0;
}


sub terminal_statuses {
  my ($class) = @_;
  return ('done', 'archived');
}


sub status_requires_claim {
  my ($self, $status_name) = @_;
  my ($sc) = grep {
    (ref $_ ? $_->{name} : $_) eq $status_name
  } @{$self->data->{statuses} // []};
  return 0 unless $sc;
  return 0 if !ref $sc;
  return $sc->{require_claim} ? 1 : 0;
}

sub effective_config {
  my ($class, $overrides, %args) = @_;
  my $defaults = $class->default_config(%args);
  return _merge_hashes($defaults, $overrides // {});
}

sub default_config {
  my ($class, %args) = @_;
  return {
    version => 1,
    board => {
      name => $args{name} // 'Kanban Board',
    },
    tasks_dir => 'tasks',
    statuses => [
      'backlog',
      'todo',
      { name => 'in-progress', require_claim => 1 },
      { name => 'review', require_claim => 1 },
      'done',
      'archived',
    ],
    priorities => [qw( low medium high critical )],
    classes => [
      { name => 'expedite', wip_limit => 1, bypass_column_wip => 1 },
      { name => 'fixed-date' },
      { name => 'standard' },
      { name => 'intangible' },
    ],
    claim_timeout => '1h',
    # Board-level switch for automated agent runs (karr-foundation). Boards are
    # enabled by default; `karr disable` writes enabled => 0 (plus an optional
    # reason) into refs/karr/config so the opt-out syncs with the board.
    foundation => {
      enabled => 1,
    },
    defaults => {
      status   => 'backlog',
      priority => 'medium',
      class    => 'standard',
    },
  };
}

sub _merge_hashes {
  my ($left, $right) = @_;
  my %merged = %{$left // {}};
  for my $key (keys %{$right // {}}) {
    if (ref($merged{$key}) eq 'HASH' && ref($right->{$key}) eq 'HASH') {
      $merged{$key} = _merge_hashes($merged{$key}, $right->{$key});
    } else {
      $merged{$key} = $right->{$key};
    }
  }
  return \%merged;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Config - Board configuration management

=head1 VERSION

version 0.402

=head1 SYNOPSIS

    my $config = App::karr::Config->new(
      file => path('/tmp/karr-materialized/config.yml'),
    );

    my @statuses = $config->statuses;

=head1 DESCRIPTION

L<App::karr::Config> wraps the board configuration file and centralises access
to derived values such as status names, priority order, and merged effective
defaults. It is used by command modules that need a structured view of the
materialized board config instead of working with raw YAML hashes. In the
ref-first architecture the canonical config lives in C<refs/karr/config>, while
this class works with the temporary YAML file generated for a command run.

=head1 SEE ALSO

L<karr>, L<App::karr>, L<App::karr::BoardStore>, L<App::karr::Task>,
L<App::karr::Git>

=head2 foundation_enabled

Returns true when automated agent runs (L<App::karr::Foundation>) are allowed on
this board. The flag lives in the board config under C<foundation.enabled> and
therefore travels with C<refs/karr/config>; a board that never set it is
enabled.

    if ($config->foundation_enabled) {
        # karr-foundation may drain this board
    }

=head2 foundation_reason

Returns the free-text reason recorded alongside C<foundation.enabled>, or undef
when none was given. Only meaningful while the board is disabled.

    my $why = $config->foundation_reason;

=head2 parse_bool

Coerces a CLI-supplied boolean string to C<1> or C<0>, dying on anything else.
Needed because a bare C<"false"> from the command line is true in Perl.

    my $bool = App::karr::Config->parse_bool('false');   # 0

=head2 priority_order

Returns a hash for sorting tasks by priority.

    my %order = App::karr::Config->priority_order;
    # (critical => 0, high => 1, medium => 2, low => 3)

=head2 class_order

Returns a hash for sorting tasks by class of service.

    my %order = App::karr::Config->class_order;
    # (expedite => 0, 'fixed-date' => 1, standard => 2, intangible => 3)

=head2 is_terminal_status

Returns true if the given status is terminal (done or archived).

    if (App::karr::Config->is_terminal_status($task->status)) {
        # task is in a terminal state
    }

=head2 terminal_statuses

Returns a list of terminal status names.

    my @terminal = App::karr::Config->terminal_statuses;

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

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
