# ABSTRACT: Board configuration management

package App::karr::Config;
our $VERSION = '0.102';
use Moo;
use YAML::XS qw( LoadFile DumpFile );
use Path::Tiny;


has file => ( is => 'ro', required => 1 );
has data => ( is => 'lazy' );

sub _build_data {
  my ($self) = @_;
  return LoadFile($self->file->stringify);
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

sub next_id {
  my ($self) = @_;
  my $id = $self->data->{next_id} // 1;
  $self->data->{next_id} = $id + 1;
  $self->save;
  return $id;
}

sub claim_timeout {
  my ($self) = @_;
  return $self->data->{claim_timeout} // '1h';
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

version 0.102

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
