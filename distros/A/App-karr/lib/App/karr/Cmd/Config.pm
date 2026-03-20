# ABSTRACT: View or modify board configuration

package App::karr::Cmd::Config;
our $VERSION = '0.003';
use Moo;
use MooX::Cmd;
use MooX::Options (
  usage_string => 'USAGE: karr config [show|get KEY|set KEY VALUE] [--json]',
);
use App::karr::Role::BoardAccess;
use App::karr::Role::Output;
use App::karr::Config;

with 'App::karr::Role::BoardAccess', 'App::karr::Role::Output';

my %WRITABLE = map { $_ => 1 } qw(
  board.name board.description
  defaults.status defaults.priority defaults.class
  claim_timeout
);

sub execute {
  my ($self, $args_ref, $chain_ref) = @_;
  my $action = $args_ref->[0] // 'show';

  my $config = App::karr::Config->new(
    file => $self->board_dir->child('config.yml'),
  );

  if ($action eq 'show') {
    $self->_show_all($config);
  } elsif ($action eq 'get') {
    my $key = $args_ref->[1] or die "Usage: karr config get KEY\n";
    $self->_get_key($config, $key);
  } elsif ($action eq 'set') {
    my $key = $args_ref->[1] or die "Usage: karr config set KEY VALUE\n";
    my $val = $args_ref->[2] // die "Usage: karr config set KEY VALUE\n";
    $self->_set_key($config, $key, $val);
  } else {
    die "Unknown action: $action (use show, get, or set)\n";
  }
}

sub _show_all {
  my ($self, $config) = @_;
  my $d = $config->data;

  if ($self->json) {
    $self->print_json($d);
    return;
  }

  my @keys = $self->_display_keys($d);
  for my $entry (@keys) {
    my ($key, $val) = @$entry;
    printf "%-25s %s\n", $key, $self->_format_value($val);
  }
}

sub _display_keys {
  my ($self, $d) = @_;
  my @out;
  push @out, ['version',            $d->{version}];
  push @out, ['board.name',         $d->{board}{name}]        if $d->{board}{name};
  push @out, ['board.description',  $d->{board}{description}] if $d->{board}{description};
  push @out, ['tasks_dir',          $d->{tasks_dir}];
  push @out, ['statuses',           [map { ref $_ ? $_->{name} : $_ } @{$d->{statuses} // []}]];
  push @out, ['priorities',         $d->{priorities}];
  push @out, ['defaults.status',    $d->{defaults}{status}]   if $d->{defaults}{status};
  push @out, ['defaults.priority',  $d->{defaults}{priority}] if $d->{defaults}{priority};
  push @out, ['defaults.class',     $d->{defaults}{class}]    if $d->{defaults}{class};
  push @out, ['wip_limits',         $d->{wip_limits}]         if $d->{wip_limits};
  push @out, ['claim_timeout',      $d->{claim_timeout}];
  push @out, ['classes',            [map { $_->{name} } @{$d->{classes} // []}]];
  push @out, ['next_id',            $d->{next_id}];
  return @out;
}

sub _get_key {
  my ($self, $config, $key) = @_;
  my $val = $self->_resolve_key($config->data, $key);
  die "Unknown key: $key\n" unless defined $val;

  if ($self->json) {
    $self->print_json(ref $val ? $val : { $key => $val });
  } else {
    printf "%s\n", $self->_format_value($val);
  }
}

sub _set_key {
  my ($self, $config, $key, $val) = @_;
  die "Key '$key' is read-only\n" unless $WRITABLE{$key};

  my $d = $config->data;

  # Validate values
  if ($key eq 'defaults.status') {
    my @statuses = $config->statuses;
    die "Invalid status: $val (valid: " . join(', ', @statuses) . ")\n"
      unless grep { $_ eq $val } @statuses;
  } elsif ($key eq 'defaults.priority') {
    my @priorities = $config->priorities;
    die "Invalid priority: $val (valid: " . join(', ', @priorities) . ")\n"
      unless grep { $_ eq $val } @priorities;
  } elsif ($key eq 'defaults.class') {
    if ($val ne '') {
      my @classes = map { $_->{name} } @{$d->{classes} // []};
      die "Invalid class: $val (valid: " . join(', ', @classes) . ")\n"
        unless grep { $_ eq $val } @classes;
    }
  } elsif ($key eq 'claim_timeout') {
    die "Invalid timeout format: $val (use e.g. 1h, 30m)\n"
      unless $val =~ /^\d+[hm]$/;
  }

  # Set the value
  if ($key =~ /^(\w+)\.(\w+)$/) {
    $d->{$1}{$2} = $val;
  } else {
    $d->{$key} = $val;
  }

  $config->save;

  if ($self->json) {
    $self->print_json({ key => $key, value => $val });
  } else {
    printf "Set %s = %s\n", $key, $val;
  }
}

sub _resolve_key {
  my ($self, $d, $key) = @_;
  if ($key =~ /^(\w+)\.(\w+)$/) {
    return $d->{$1}{$2};
  }
  return $d->{$key};
}

sub _format_value {
  my ($self, $val) = @_;
  return '' unless defined $val;
  if (ref $val eq 'ARRAY') {
    return join(', ', @$val);
  } elsif (ref $val eq 'HASH') {
    return join(', ', map { "$_: $val->{$_}" } sort keys %$val);
  }
  return "$val";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Cmd::Config - View or modify board configuration

=head1 VERSION

version 0.003

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-app-karr/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
