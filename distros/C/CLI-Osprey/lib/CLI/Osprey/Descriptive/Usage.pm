package CLI::Osprey::Descriptive::Usage;

use strict;
use warnings;
use Moo;

use overload (
  q{""} => "text",
);

use Getopt::Long::Descriptive::Usage ();

*option_text = \&Getopt::Long::Descriptive::Usage::option_text;

# ABSTRACT: Produce usage information for CLI::Osprey apps
our $VERSION = '0.08'; # VERSION
our $AUTHORITY = 'cpan:ARODLAND'; # AUTHORITY

my %format_doc = (
  s => { short => "string", long => "string" },
  i => { short => "int"   , long => "integer" },
  o => { short => "int"   , long => "integer (dec/hex/bin/oct)" },
  f => { short => "num"   , long => "number" },
);

has 'options' => (
  is => 'ro',
);

has 'leader_text' => (
  is => 'ro',
);

has 'target' => (
  is => 'ro',
  predicate => 1,
);

has 'prog_name' => (
  is => 'ro',
  predicate => 1,
);

has 'width' => (
  is => 'ro',
  default => sub {
    return $ENV{CLI_OSPREY_OVERRIDE_WIDTH} if exists $ENV{CLI_OSPREY_OVERRIDE_WIDTH};
    return $ENV{COLUMNS} if exists $ENV{COLUMNS};
    return 80;
  },
);

sub wrap {
  my ($self, $in, $prefix) = @_;

  my $width = $self->width;
  return $in if $width <= 0;

  my @out;
  my $line = "";

  while ($in =~ /(\s*)(\S+)/g) {
    my ($space, $nonspace) = ($1, $2);
    if (length($line) + length($space) + length($nonspace) <= $width) {
      $line .= $space . $nonspace;
    } else {
      while (length($nonspace)) {
        push @out, $line;
        $line = $prefix;
        $line .= substr($nonspace, 0, $width - length($line), '');
      }
    }
  }
  push @out, $line if length($line);
  return @out;
}

sub maxlen {
  my $max = 0;
  for (@_) {
    $max = length($_) if length($_) > $max;
  }
  return $max;
}

sub sub_commands_text {
  my ($self, $length) = @_;

  if ($self->has_target && (my %subcommands = $self->target->_osprey_subcommands)) {
    if ($length eq 'long') {
      my $maxlen = maxlen(keys %subcommands);

      my @out;
      push @out, "";
      push @out, "Subcommands available:";

      for my $name (sort keys %subcommands) {
        my $desc = $subcommands{$name}->can('_osprey_subcommand_desc') && $subcommands{$name}->_osprey_subcommand_desc;
        if (defined $desc) {
          push @out, $self->wrap(
            sprintf("%*s  %s", -$maxlen, $name, $subcommands{$name}->_osprey_subcommand_desc),
            " " x ($maxlen + 2)
          );
        } else {
          push @out, $name;
        }
      }
      push @out, "";

      return @out;
    } else {
      return "",
      $self->wrap(
        "Subcommands available: " . join(" | ", sort keys %subcommands),
        " " x length("Subcommands available: ")
      );
    }
  }
  return;
}

sub pod_escape {
  my ($self, $text) = @_;
  my %map = (
    '<' => 'lt',
    '>' => 'gt',
    '|' => 'verbar',
    '/' => 'sol',
  );

  $text =~ s,([<>|/]),"E<$map{$1}>",eg;
  return $text;
}

sub describe_opt {
  my ($self, $opt) = @_;

  if ($opt->{desc} eq 'spacer') {
    return { spacer => 1 };
  }

  my $name = my $attr_name = $opt->{name};

  my $option_attrs;

  if ($self->has_target) {
    my %options = $self->target->_osprey_options;
    $option_attrs = $options{$attr_name};
    $name = $option_attrs->{option} if defined $option_attrs->{option};
  }

  my ($short, $format) = $opt->{spec} =~ /(?:\|(\w))?(?:=(.*?))?$/;

  my $array;
  if (defined $format && $format =~ s/[\@\+]$//) {
    $array = 1;
  }

  my $format_doc;
  if (defined $format) {
    if (defined $option_attrs->{format_doc}) {
      $format_doc = {
        short => $option_attrs->{format_doc},
        long => $option_attrs->{format_doc},
      };
    } else {
      $format_doc = $format_doc{$format};
    }
  }

  my $spec;

  if ($short) {
    $spec = "-$short|";
  }

  if (length($name) > 1) {
    $spec .= "--$name";
  } else {
    $spec .= "-$name";
  }

  my ($shortspec, $longspec) = ($spec, $spec);
  my ($podshortspec, $podlongspec) = ("B<< $spec >>", "B<< $spec >>");

  if (defined $format_doc) {
    $shortspec .= " $format_doc->{short}";
    $podshortspec .= " I<< $format_doc->{short} >>";
    $longspec .= " $format_doc->{long}";
    $podlongspec .= " I<< $format_doc->{long} >>";
  }

  if ($array) {
    $shortspec .= "...";
    $podshortspec .= "...";
  }

  if (defined $option_attrs && !$option_attrs->{required}) {
    $shortspec = "[$shortspec]";
    $podshortspec = "[$podshortspec]";
  }

  return {
    short => $shortspec,
    long => $longspec,
    podshort => $podshortspec,
    podlong => $podlongspec,
    doc => $opt->{desc},
    long_doc => defined($option_attrs->{long_doc}) ? $option_attrs->{long_doc} : $self->pod_escape($opt->{desc}),
  };
}

sub describe_options {
  my ($self) = @_;

  return map $self->describe_opt($_), @{ $self->options };
}

sub header {
  my ($self) = @_;

  my @descs = $self->describe_options;

  my $option_text = join "\n", $self->wrap(
    join(" ", map $_->{short}, grep !$_->{spacer}, @descs),
    "  ",
  );

  my $text = $self->leader_text;
  $text =~ s/\Q[long options...]/$option_text/;

  return $text;
}

sub text {
  my ($self) = @_;

  return join "\n", $self->header, $self->sub_commands_text('short');
}

sub option_help {
  my ($self) = @_;

  my @descs = $self->describe_options;

  my $maxlen = maxlen(map $_->{long}, grep !$_->{spacer}, @descs);

  my @out;
  for my $desc (@descs) {
    if ($desc->{spacer}) {
      push @out, "";
    } else {
      push @out, $self->wrap(
        sprintf("%*s  %s", -$maxlen, $desc->{long}, $desc->{doc}),
        " " x ($maxlen + 2),
      );
    }
  }

  return join("\n", $self->header, $self->sub_commands_text('long'), @out);
}

sub option_pod {
  my ($self) = @_;

  my %osprey_config = $self->target->_osprey_config;

  my @descs = $self->describe_options;
  my @pod;

  push @pod, "=encoding UTF-8";

  push @pod, "=head1 NAME";
  push @pod, $self->{prog_name} . ($osprey_config{desc} ? " - " . $osprey_config{desc} : "" );

  push @pod, "=head1 SYNOPSIS";
  push @pod, "B<< $self->{prog_name} >> "
    . join(" ", map "S<<< $_->{podshort} >>>", grep !$_->{spacer}, @descs);

  if ($osprey_config{description_pod}) {
    push @pod, "=head1 DESCRIPTION";
    push @pod, $osprey_config{description_pod};
  }

  if ($osprey_config{extra_pod}) {
    push @pod, $osprey_config{extra_pod};
  }

  push @pod, "=head1 OPTIONS";
  push @pod, "=over";

  for my $desc (@descs) {
    if ($desc->{spacer}) {
      push @pod, "=back";
      push @pod, "E<32>" x 40;
      push @pod, "=over";
    } else {
      push @pod, "=item $desc->{podlong}";
      push @pod, $desc->{long_doc};
    }
  }

  push @pod, "=back";

  if ($self->has_target && (my %subcommands = $self->target->_osprey_subcommands)) {
    push @pod, "=head1 COMMANDS";
    push @pod, "=over";

    for my $name (sort keys %subcommands) {
      my $desc = $subcommands{$name}->can('_osprey_subcommand_desc') && $subcommands{$name}->_osprey_subcommand_desc;
      push @pod, "=item B<< $name >>";
      if ($desc) {
        push @pod, $desc;
      }
    }

    push @pod, "=back";
  }

  return join("\n\n", @pod);
}

sub die  {
  my $self = shift;
  my $arg  = shift || {};

  die(
    join q{}, grep { defined } $arg->{pre_text}, $self->text, $arg->{post_text}
  );
}

sub warn { warn shift->text }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CLI::Osprey::Descriptive::Usage - Produce usage information for CLI::Osprey apps

=head1 VERSION

version 0.08

=head1 AUTHOR

Andrew Rodland <arodland@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Andrew Rodland.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
