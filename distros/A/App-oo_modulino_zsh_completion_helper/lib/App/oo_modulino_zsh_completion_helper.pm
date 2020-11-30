#!/usr/bin/env perl
package App::oo_modulino_zsh_completion_helper;
use 5.010;
use strict;
use warnings;

our $VERSION = "0.04";

use MOP4Import::Base::CLI_JSON -as_base
  , [fields => [eol => default => "\n"]]
  ;

use MOP4Import::FieldSpec;
use MOP4Import::Util qw/fields_hash fields_array/;
use MOP4Import::Util::FindMethods;

use Module::Runtime ();

use MOP4Import::Util::ResolveSymlinks;

use MOP4Import::Types
  ZshParams => [[fields => qw/pmfile words NUMERIC CURRENT BUFFER CURSOR/]]
  ;

sub cli_inspector {
  require MOP4Import::Util::Inspector;
  'MOP4Import::Util::Inspector';
}

sub onconfigure_zero {
  (my MY $self) = @_;
  $self->{eol} = "\0";
}

sub cmd_joined {
  (my MY $self, my ($method, @args)) = @_;
  my @completion = $self->$method(@args);
  print join($self->{eol}, @completion), $self->{eol};
}

sub IGNORE_OPTIONS_FROM {'MOP4Import::Base::CLI_JSON'}

sub zsh_options {
  (my MY $self, my %opts) = @_;

  my ZshParams $opts = \%opts;

  my ($targetClass, $has_shbang) = $self->load_module_from_pm($opts->{pmfile})
    or Carp::croak "Can't extract class name from $opts->{pmfile}";

  my $optionPrefix = $self->word_prefix($opts);
  $optionPrefix =~ s/^--?// if defined $optionPrefix;

  my $universal_argument = $opts->{NUMERIC};

  my @options = $self->cli_inspector->list_options_of($targetClass);
  if (defined $optionPrefix and $optionPrefix ne '') {
    @options = grep {/^$optionPrefix/} @options;
  }

  my @grouped = map {
    my ($implClass, @specs) = @$_;
    if (not $universal_argument) {
      ($implClass eq '' || $implClass ne $self->IGNORE_OPTIONS_FROM) ? @specs : ();
    } else {
      @specs;
    }
  } $self->cli_inspector->group_options_of($targetClass, @options);

  map {
    if (ref (my FieldSpec $spec = $_)) {
      "--$spec->{name}=-". ($spec->{doc} ? "[$spec->{doc}]" : "");
    } else {
      "--$_=-";
    }
  } @grouped;
}

sub zsh_methods {
  (my MY $self, my %opts) = @_;

  my ZshParams $opts = \%opts;

  my ($targetClass, $has_shbang) = $self->load_module_from_pm($opts->{pmfile})
    or Carp::croak "Can't extract class name from $opts->{pmfile}";

  my $insp = $self->cli_inspector;

  my $methodPrefix = $self->word_prefix($opts);

  my $universal_argument = $opts->{NUMERIC};

  # default => methods implemented in $targetClass only.
  # one universal_argument => find superclasses too.
  # two universal_argument => find all methods including getters, new,...

  my @gather_default = (($methodPrefix || (($universal_argument || 0) >= 4*4))
                        ? (all => 1) : (no_getter => 1));
  my @methods = $self->gather_methods_from($targetClass, undef, @gather_default);
  if ($methodPrefix or $universal_argument) {
    my %seen; $seen{$_} = 1 for @methods;
    (undef, my @super) = @{mro::get_linear_isa($targetClass)};
    foreach my $super (@super) {
      push @methods, $self->gather_methods_from($super, \%seen, @gather_default);
    }
  }

  if ($methodPrefix) {
    @methods = grep {/^$methodPrefix/} @methods;
  }

  map {
    my $method = $targetClass->can("cmd_$_") ? "cmd_$_" : $_;
    if (defined (my $doc = $insp->info_method_doc_of($targetClass, $method, 1))) {
      "$_:$doc"
    } else {
      $_;
    }
  } @methods;
}

sub word_prefix {
  (my MY $self, my ZshParams $opts) = @_;

  unless ($opts->{words} && $opts->{CURRENT}) {
    return undef;
  }

  $opts->{words}[$opts->{CURRENT} - 1];
}

sub gather_methods_from {
  (my MY $self, my $targetClass, my $seenDict, my %opts) = @_;
  my $no_getter = delete $opts{no_getter};
  my $all       = delete $opts{all};
  MOP4Import::Util::function_names(
    from => $targetClass,
    matching => qr{^(?:cmd_)?[a-z]},
    grep => sub {
      my ($realName, $code) = @_;
      s/^cmd_//;
      if ($seenDict->{$_}++) {
        return 0;
      }
      if ($self->cli_inspector->info_code_attribute(MetaOnly => $code)) {
        return 0;
      }
      if ($all) {
        return 1;
      } else {
        return 0 if MOP4Import::Base::Configure->can($_);
      }
      if ($no_getter) {
        return not $self->cli_inspector->is_getter_of($targetClass, $_);
      }
      1;
      # MOP4Import::Util::has_method_attr($code); # Too strict.
    },
    %opts,
  );
}

sub load_module_from_pm {
  (my MY $self, my $pmFile) = @_;

  my ($modname, $libpath, $has_shbang) = $self->find_package_from_pm($pmFile)
    or Carp::croak "Can't find module name and library root from $pmFile'";

  {
    local @INC = ($libpath, @INC);
    Module::Runtime::require_module($modname);
  }

  wantarray ? ($modname, $has_shbang) : $modname;
}

sub find_package_from_pm {
  (my MY $self, my $pmFile) = @_;

  my $realFn = MOP4Import::Util::ResolveSymlinks::normalize($pmFile);
  $realFn =~ s/\.\w+\z//;

  my @dir = $self->splitdir($realFn);

  local $_ = $self->cli_read_file__($pmFile);

  my $has_shbang = m{^\#!};

  while (/(?:^|\n) [\ \t]*     (?# line beginning + space)
	  package  [\n\ \t]+   (?# newline is allowed here)
	  ([\w:]+)             (?# module name)
	  \s* [;\{]            (?# statement or block)
	 /xsg) {
    my ($modname) = $1;

    # Tail of $modname should be equal to it's rootname.
    if (my $libprefix = $self->test_modname_with_path($modname, \@dir)) {
      return wantarray ? ($modname, $libprefix, $has_shbang) : $modname;
    }
  }
  return;
}

sub test_modname_with_path {
  (my MY $self, my ($modname, $pathlist)) = @_;
  my @modpath = split /::/, $modname;
  shift @modpath while @modpath and $modpath[0] eq '';
  my @copy = @$pathlist;
  do {
    if (pop(@copy) ne pop(@modpath)) {
      return;
    }
  } while (@copy and @modpath);
  if (@modpath) {
    return;
  }
  elsif (@copy) {
    File::Spec->catdir(@copy)
  }
}

sub splitdir {
  (my MY $self, my $fn) = @_;
  File::Spec->splitdir($fn);
}

MY->cli_run(\@ARGV, {0 => 'zero'}) unless caller;



1;
__END__

=encoding utf-8

=head1 NAME

App::oo_modulino_zsh_completion_helper - provides zsh completion for OO-Modulinos

=head1 SYNOPSIS

When you install this module and _perl_oo_modulino zsh completer,

    ./Your_OO_Modulino.pm <TAB>

will list methods of Your_OO_Modulino.pm. Also,

    ./Your_OO_Modulino.pm --<TAB>

will list options of Your_OO_Modulino.pm.

If you give zsh numeric-arguments (via M-number or universal argument),
inherited methods/options are included too.

=head1 DESCRIPTION

App::oo_modulino_zsh_completion_helper provides underlying implementation of `_perl_oo_modulino` zsh completer.

=head1 LICENSE

Copyright (C) Kobayasi, Hiroaki.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Kobayasi, Hiroaki E<lt>buribullet@gmail.comE<gt>

=cut

