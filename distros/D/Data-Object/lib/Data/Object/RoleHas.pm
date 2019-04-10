package Data::Object::RoleHas;

use strict;
use warnings;

use Data::Object::Export 'reify';

our $VERSION = '0.96'; # VERSION

# BUILD

sub import {
  my ($class, @args) = @_;

  my $target = caller;

  my $has = $target->can('has') or return;

  no strict 'refs';
  no warnings 'redefine';

  *{"${target}::has"} = _generate_has([$class, $target], $has);

  return;
}

sub _generate_has {
  my ($info, $orig) = @_;

  return sub { @_ = _formulate_opts($info, @_); goto $orig; };
}

sub _formulate_opts {
  my ($info, $name, %opts) = @_;

  # name-only support
  %opts = (is => 'ro', isa => 'Any') unless %opts;

  %opts = (%opts, _formulate_bld($info, $name, %opts)) if $opts{bld};
  %opts = (%opts, _formulate_clr($info, $name, %opts)) if $opts{clr};
  %opts = (%opts, _formulate_crc($info, $name, %opts)) if $opts{crc};
  %opts = (%opts, _formulate_def($info, $name, %opts)) if $opts{def};
  %opts = (%opts, _formulate_hld($info, $name, %opts)) if $opts{hld};
  %opts = (%opts, _formulate_isa($info, $name, %opts)) if $opts{isa};
  %opts = (%opts, _formulate_lzy($info, $name, %opts)) if $opts{lzy};
  %opts = (%opts, _formulate_opt($info, $name, %opts)) if $opts{opt};
  %opts = (%opts, _formulate_pre($info, $name, %opts)) if $opts{pre};
  %opts = (%opts, _formulate_rdr($info, $name, %opts)) if $opts{rdr};
  %opts = (%opts, _formulate_req($info, $name, %opts)) if $opts{req};
  %opts = (%opts, _formulate_tgr($info, $name, %opts)) if $opts{tgr};
  %opts = (%opts, _formulate_wkr($info, $name, %opts)) if $opts{wkr};
  %opts = (%opts, _formulate_wrt($info, $name, %opts)) if $opts{wrt};

  $name = "+$name" if $opts{mod};

  return ($name, %opts);
}

sub _formulate_bld {
  my ($info, $name, %opts) = @_;

  $opts{builder} = delete $opts{bld};

  return (%opts);
}

sub _formulate_clr {
  my ($info, $name, %opts) = @_;

  $opts{clearer} = delete $opts{clr};

  return (%opts);
}

sub _formulate_crc {
  my ($info, $name, %opts) = @_;

  $opts{coerce} = delete $opts{crc};

  return (%opts);
}

sub _formulate_def {
  my ($info, $name, %opts) = @_;

  $opts{default} = delete $opts{def};

  return (%opts);
}

sub _formulate_hld {
  my ($info, $name, %opts) = @_;

  $opts{handles} = delete $opts{hld};

  return (%opts);
}

sub _formulate_isa {
  my ($info, $name, %opts) = @_;

  return (%opts) if ref($opts{isa});

  $opts{isa} = reify($info->[1], $opts{isa});

  return (%opts);
}

sub _formulate_lzy {
  my ($info, $name, %opts) = @_;

  $opts{lazy} = delete $opts{lzy};

  return (%opts);
}

sub _formulate_opt {
  my ($info, $name, %opts) = @_;

  delete $opts{opt};

  $opts{required} = 0;

  return (%opts);
}

sub _formulate_pre {
  my ($info, $name, %opts) = @_;

  $opts{predicate} = delete $opts{pre};

  return (%opts);
}

sub _formulate_rdr {
  my ($info, $name, %opts) = @_;

  $opts{reader} = delete $opts{rdr};

  return (%opts);
}

sub _formulate_req {
  my ($info, $name, %opts) = @_;

  delete $opts{req};

  $opts{required} = 1;

  return (%opts);
}

sub _formulate_tgr {
  my ($info, $name, %opts) = @_;

  $opts{trigger} = delete $opts{tgr};

  return (%opts);
}

sub _formulate_wkr {
  my ($info, $name, %opts) = @_;

  $opts{weak_ref} = delete $opts{wkr};

  return (%opts);
}

sub _formulate_wrt {
  my ($info, $name, %opts) = @_;

  $opts{writer} = delete $opts{wrt};

  return (%opts);
}

# METHODS

1;

=encoding utf8

=head1 NAME

Data::Object::RoleHas

=cut

=head1 ABSTRACT

Data-Object Role Configuration

=cut

=head1 SYNOPSIS

  package Pointable;

  use Data::Object::Role;
  use Data::Object::RoleHas;

  has 'x';
  has 'y';

  1;

=cut

=head1 DESCRIPTION

Data::Object::RoleHas modifies the consuming package with behaviors
useful in defining roles. Specifically, this package wraps the C<has>
attribute keyword functions and adds enhancements which as documented in
L<Data::Object::Role>.

=cut
