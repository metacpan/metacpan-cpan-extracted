package App::Raider::Plugin::Trace;
our $VERSION = '0.003';
# ABSTRACT: Live ANSI-colored progress output for a running Langertha::Raider raid

use Moose;
use Future::AsyncAwait;
use Term::ANSIColor qw( colored );
use JSON::MaybeXS ();

extends 'Langertha::Plugin';


has color => (
  is      => 'ro',
  isa     => 'Bool',
  default => sub { -t STDOUT ? 1 : 0 },
);


has max_value_length => (
  is      => 'ro',
  isa     => 'Int',
  default => 80,
);


has token_stats => (
  is      => 'rw',
  isa     => 'HashRef',
  default => sub { { prompt => 0, completion => 0, total => 0, calls => 0 } },
);

sub _extract_usage {
  my ($data) = @_;
  return unless ref $data eq 'HASH';
  my $u = $data->{usage} // $data->{response}{usage};
  return unless ref $u eq 'HASH';
  my $p = $u->{prompt_tokens}     // $u->{input_tokens};
  my $c = $u->{completion_tokens} // $u->{output_tokens};
  my $t = $u->{total_tokens}      // (($p // 0) + ($c // 0));
  return { prompt => $p // 0, completion => $c // 0, total => $t // 0 };
}

my %C = (
  iter   => 'bright_black',
  tool   => 'blue',
  args   => 'bright_black',
  ok     => 'bright_black',
  err    => 'red',
  text   => 'bright_black',
  accent => 'yellow',
);

sub _c {
  my ($self, $key, @text) = @_;
  my $text = join '', @text;
  return $text unless $self->color && !$ENV{ANSI_COLORS_DISABLED};
  return colored([$C{$key}], $text);
}

sub _truncate {
  my ($self, $s) = @_;
  return '' unless defined $s;
  $s =~ s/\s+/ /g;
  my $lim = $self->max_value_length;
  return length($s) > $lim ? substr($s, 0, $lim - 1) . '…' : $s;
}

sub _summarize_args {
  my ($self, $input) = @_;
  return '' unless ref $input eq 'HASH';
  my @parts;
  for my $k (sort keys %$input) {
    my $v = $input->{$k};
    if (ref $v) {
      $v = eval { JSON::MaybeXS->new(utf8 => 0, canonical => 1)->encode($v) } // '?';
    }
    push @parts, "$k=" . $self->_truncate($v);
  }
  return join(' ', @parts);
}

async sub plugin_after_llm_response {
  my ($self, $data, $iteration) = @_;

  my $usage = _extract_usage($data);
  if ($usage) {
    my $s = $self->token_stats;
    $s->{prompt}     += $usage->{prompt};
    $s->{completion} += $usage->{completion};
    $s->{total}      += $usage->{total};
    $s->{calls}++;
  }

  return $data;
}

async sub plugin_before_tool_call {
  my ($self, $name, $input) = @_;
  my $args = $self->_summarize_args($input);
  print
    $self->_c(tool => "> $name"),
    (length $args ? ' ' . $self->_c(args => $args) : ''),
    "\n";
  return ($name, $input);
}

async sub plugin_after_tool_call {
  my ($self, $name, $input, $result) = @_;

  my $is_err = 0;
  my $text   = '';
  if (ref $result eq 'HASH') {
    $is_err = $result->{isError} ? 1 : 0;
    if (ref $result->{content} eq 'ARRAY' && ref $result->{content}[0] eq 'HASH') {
      $text = $result->{content}[0]{text} // '';
    }
  }
  elsif (!ref $result) {
    $text = $result // '';
  }

  my $bytes = length $text;
  my $first = (split /\n/, $text, 2)[0] // '';
  $first =~ s/\s+$//;

  my $key  = $is_err ? 'err' : 'ok';
  my $lead = $is_err ? '! '  : '. ';
  print
    $self->_c($key => $lead . "${bytes}b"),
    (length $first ? ' ' . $self->_c(text => $self->_truncate($first)) : ''),
    "\n";

  return $result;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Raider::Plugin::Trace - Live ANSI-colored progress output for a running Langertha::Raider raid

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    my $raider = Langertha::Raider->new(
        engine  => $engine,
        plugins => ['+App::Raider::Plugin::Trace'],
    );

=head1 DESCRIPTION

Streaming trace plugin used by L<App::Raider> to show live progress during a
raid: per-iteration markers, each tool call with a short argument summary, and
the tool result (ok / error / length). Palette is blue-dominant with yellow
accents to match the rest of the CLI.

Set C<ANSI_COLORS_DISABLED=1> or construct with C<color =E<gt> 0> to render
without ANSI sequences.

=head2 color

Whether to emit ANSI colors. Defaults to true when STDOUT is a terminal.

=head2 max_value_length

Maximum characters shown per argument value in tool-call summaries. Longer
strings are truncated with an ellipsis. Defaults to 80.

=head2 token_stats

Running cumulative hashref: C<{ prompt, completion, total, calls }>.
Updated after every LLM response; read via the C<token_stats> accessor or
through L<App::Raider/token_stats>.

=head1 SEE ALSO

=over

=item * L<App::Raider>

=item * L<Langertha::Plugin>

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
