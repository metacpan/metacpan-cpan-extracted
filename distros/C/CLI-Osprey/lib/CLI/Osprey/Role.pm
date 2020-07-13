package CLI::Osprey::Role;
use strict;
use warnings;
use Carp 'croak';
use Path::Tiny ();
use Scalar::Util qw(blessed);
use Module::Runtime 'use_module';

use CLI::Osprey::Descriptive;

# ABSTRACT: Role for CLI::Osprey applications
our $VERSION = '0.08'; # VERSION
our $AUTHORITY = 'cpan:ARODLAND'; # AUTHORITY

sub _osprey_option_to_getopt {
  my ($name, %attributes) = @_;
  my $getopt = join('|', grep defined, ($name, $attributes{short}));
  $getopt .= '+' if $attributes{repeatable} && !defined $attributes{format};
  $getopt .= '!' if $attributes{negatable};
  $getopt .= '=' . $attributes{format} if defined $attributes{format};
  $getopt .= '@' if $attributes{repeatable} && defined $attributes{format};
  return $getopt;
}

sub _osprey_prepare_options {
  my ($options, $config) = @_;

  my @getopt;
  my %abbreviations;
  my %fullnames;

  my @order = sort {
    ($options->{$a}{order} || 9999) <=> ($options->{$b}{order} || 9999)
    || ($config->{added_order} ? ($options->{$a}{added_order} <=> $options->{$b}{added_order}) : 0)
    || $a cmp $b
  } keys %$options;

  for my $option (@order) {
    my %attributes = %{ $options->{$option} };

    push @{ $fullnames{ $attributes{option} } }, $option;
  }

  for my $name (keys %fullnames) {
    if (@{ $fullnames{$name} } > 1) {
      croak "Multiple option attributes named $name: [@{ $fullnames{$name} }]";
    }
  }

  for my $option (@order) {
    my %attributes = %{ $options->{$option} };

    my $name = $attributes{option};
    my $doc = $attributes{doc};
    $doc = "no documentation for $name" unless defined $doc;

    push @getopt, [] if $attributes{spacer_before};
    push @getopt, [ _osprey_option_to_getopt($option, %attributes), $doc, ($attributes{hidden} ? { hidden => 1} : ()) ];
    push @getopt, [] if $attributes{spacer_after};

    push @{ $abbreviations{$name} }, $option;

    # If we allow abbreviating long option names, an option can be called by any prefix of its name,
    # unless that prefix is an option name itself. Ambiguous cases (an abbreviation is a prefix of
    # multiple option names) are handled later in _osprey_fix_argv.
    if ($config->{abbreviate}) {
      for my $len (1 .. length($name) - 1) {
        my $abbreviated = substr $name, 0, $len;
        push @{ $abbreviations{$abbreviated} }, $name unless exists $fullnames{$abbreviated};
      }
    }
  }

  return \@getopt, \%abbreviations;
}

sub _osprey_fix_argv {
  my ($options, $abbreviations) = @_;

  my @new_argv;

  while (defined( my $arg = shift @ARGV )) {
    # As soon as we find a -- or a non-option word, stop processing and leave everything
    # from there onwards in ARGV as either positional args or a subcommand.
    if ($arg eq '--' or $arg eq '-' or $arg !~ /^-/) {
      push @new_argv, $arg, @ARGV;
      last;
    }

    my ($arg_name_with_dash, $arg_value) = split /=/, $arg, 2;
    unshift @ARGV, $arg_value if defined $arg_value;

    my ($dash, $negative, $arg_name_without_dash)
      = $arg_name_with_dash =~ /^(-+)(no\-)?(.+)$/;

    my $option_name;
    
    if ($dash eq '--') {
      my $option_names = $abbreviations->{$arg_name_without_dash};
      if (defined $option_names) {
        if (@$option_names == 1) {
          $option_name = $option_names->[0];
        } else {
          # TODO: can't we produce a warning saying that it's ambiguous and which options conflict?
          $option_name = undef;
        }
      }
    }

    my $arg_name = ($dash || '') . ($negative || '');
    if (defined $option_name) {
      $arg_name .= $option_name;
    } else {
      $arg_name .= $arg_name_without_dash;
    }

    push @new_argv, $arg_name;
    if (defined $option_name && $options->{$option_name}{format}) {
      push @new_argv, shift @ARGV;
    }
  }

  return @new_argv;
}

use Moo::Role;

requires qw(_osprey_config _osprey_options _osprey_subcommands);

has 'parent_command' => (
  is => 'ro',
);

has 'invoked_as' => (
  is => 'ro',
);

sub new_with_options {
  my ($class, %params) = @_;
  my %config = $class->_osprey_config;

  local @ARGV = @ARGV if $config{protect_argv};

  if (!defined $params{invoked_as}) {
    $params{invoked_as} = Getopt::Long::Descriptive::prog_name();
  }

  my ($parsed_params, $usage) = $class->parse_options(%params);

  if ($parsed_params->{h}) {
    return $class->osprey_usage(1, $usage);
  } elsif ($parsed_params->{help}) {
    return $class->osprey_help(1, $usage);
  } elsif ($parsed_params->{man}) {
    return $class->osprey_man($usage);
  }

  my %merged_params;
  if ($config{prefer_commandline}) {
    %merged_params = (%params, %$parsed_params);
  } else {
    %merged_params = (%$parsed_params, %params);
  }

  my %subcommands = $class->_osprey_subcommands;
  my ($subcommand_name, $subcommand_class);
  if (@ARGV && $ARGV[0] ne '--') { # Check what to do with remaining options
    if ($ARGV[0] =~ /^--/) { # Getopt stopped at an unrecognized option, error.
      print STDERR "Unknown option '$ARGV[0]'.\n";
      return $class->osprey_usage(1, $usage);
    } elsif (%subcommands) {
      $subcommand_name = shift @ARGV; # Remove it so the subcommand sees only options
      $subcommand_class = $subcommands{$subcommand_name};
      if (!defined $subcommand_class) {
        print STDERR "Unknown subcommand '$subcommand_name'.\n";
        return $class->osprey_usage(1, $usage);
      }
    }
    # If we're not expecting a subcommand, and getopt didn't stop at an option, consider the remainder
    # as positional args and leave them in ARGV.
  }

  my $self;
  unless (eval { $self = $class->new(%merged_params); 1 }) {
    if ($@ =~ /^Attribute \((.*?)\) is required/) {
      print STDERR "$1 is missing\n";
    } elsif ($@ =~ /^Missing required arguments: (.*) at /) {
      my @missing_required = split /,\s/, $1;
      print STDERR "$_ is missing\n" for @missing_required;
    } elsif ($@ =~ /^(.*?) required/) {
      print STDERR "$1 is missing\n";
    } elsif ($@ =~ /^isa check .*?failed: /) {
      print STDERR substr($@, index($@, ':') + 2);
    } else {
      print STDERR $@;
    }
    return $class->osprey_usage(1, $usage);
  }

  return $self unless $subcommand_class;

  use_module($subcommand_class) unless ref $subcommand_class;

  return $subcommand_class->new_with_options(
      %params,
      parent_command => $self,
      invoked_as => "$params{invoked_as} $subcommand_name"
  );
}

sub parse_options {
  my ($class, %params) = @_;

  my %options = $class->_osprey_options;
  my %config = $class->_osprey_config;
  my %subcommands = $class->_osprey_subcommands;

  my ($options, $abbreviations) = _osprey_prepare_options(\%options, \%config);
  @ARGV = _osprey_fix_argv(\%options, $abbreviations);

  my @getopt_options = %subcommands ? qw(require_order) : ();

  push @getopt_options, @{$config{getopt_options}} if defined $config{getopt_options};

  my $prog_name = $params{invoked_as};
  $prog_name = Getopt::Long::Descriptive::prog_name() if !defined $prog_name;

  my $usage_str = $config{usage_string};
  unless (defined $usage_str) {
    if (%subcommands) {
      $usage_str = "Usage: $prog_name %o [subcommand]";
    } else {
      $usage_str = "Usage: $prog_name %o";
    }
  }

  my ($opt, $usage) = describe_options(
    $usage_str,
    @$options,
    [],
    [ 'h', "show a short help message" ],
    [ 'help', "show a long help message" ],
    [ 'man', "show the manual" ],
    { getopt_conf => \@getopt_options },
  );

  $usage->{prog_name} = $prog_name;
  $usage->{target} = $class;

  if ($usage->{should_die}) {
    return $class->osprey_usage(1, $usage);
  }

  my %parsed_params;

  for my $name (keys %options, qw(h help man)) {
    my $val = $opt->$name();
    $parsed_params{$name} = $val if defined $val;
  }

  return \%parsed_params, $usage;

}

sub osprey_usage {
  my ($class, $code, @messages) = @_;

  my $usage;

  if (@messages && blessed($messages[0]) && $messages[0]->isa('CLI::Osprey::Descriptive::Usage')) {
    $usage = shift @messages;
  } else {
    local @ARGV = ();
    (undef, $usage) = $class->parse_options(help => 1);
  }

  my $message;
  $message = join("\n", @messages, '') if @messages;
  $message .= $usage . "\n";

  if ($code) {
    CORE::warn $message;
  } else {
    print $message;
  }
  exit $code if defined $code;
  return;
}

sub osprey_help {
  my ($class, $code, $usage) = @_;

  unless (defined $usage && blessed($usage) && $usage->isa('CLI::Osprey::Descriptive::Usage')) {
    local @ARGV = ();
    (undef, $usage) = $class->parse_options(help => 1);
  }

  my $message = $usage->option_help . "\n";

  if ($code) {
    CORE::warn $message;
  } else {
    print $message;
  }
  exit $code if defined $code;
  return;
}

sub osprey_man {
  my ($class, $usage, $output) = @_;

  unless (defined $usage && blessed($usage) && $usage->isa('CLI::Osprey::Descriptive::Usage')) {
    local @ARGV = ();
    (undef, $usage) = $class->parse_options(man => 1);
  }

  my $tmpdir = Path::Tiny->tempdir;
  my $podfile = $tmpdir->child("help.pod");
  $podfile->spew_utf8($usage->option_pod);

  require Pod::Usage;
  Pod::Usage::pod2usage(
    -verbose => 2,
    -input => "$podfile",
    -exitval => 'NOEXIT',
    -output => $output,
  );

  exit(0);
}

sub _osprey_subcommand_desc {
  my ($class) = @_;
  my %config = $class->_osprey_config;
  return $config{desc};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CLI::Osprey::Role - Role for CLI::Osprey applications

=head1 VERSION

version 0.08

=head1 AUTHOR

Andrew Rodland <arodland@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Andrew Rodland.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
