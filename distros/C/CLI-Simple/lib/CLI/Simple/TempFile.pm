package CLI::Simple::TempFile;

use strict;
use warnings;

use Carp qw(croak);
use File::Temp;
use Role::Tiny;
use Scalar::Util qw(blessed reftype);

my %GENERATED_ACCESSORS;

our $VERSION = '2.6.0';

########################################################################
sub create_temp_file {
########################################################################
  my ( $self, %args ) = @_;

  croak 'create_temp_file requires an object instance'
    if !blessed($self);

  croak 'create_temp_file requires a hash-based object'
    if reftype($self) ne 'HASH';

  my $no_accessors = delete $args{no_accessors} // 0;
  my $cleanup      = delete $args{cleanup}      // 1;
  my $has_accessor = exists $args{accessor};
  my $accessor     = delete $args{accessor};

  croak 'accessor and no_accessors cannot be combined'
    if $no_accessors && $has_accessor;

  $accessor //= 'temp_file';

  croak 'cleanup must be 0 or 1'
    if $cleanup !~ /\A[01]\z/;

  croak 'no_accessors must be 0 or 1'
    if $no_accessors !~ /\A[01]\z/;

  my %supported = map { $_ => 1 } qw(dir suffix template);
  foreach my $key ( keys %args ) {
    croak sprintf q{Unknown temporary file attribute: %s}, $key
      if !exists $supported{$key};
  }

  my $class = ref $self;
  if ( !$no_accessors ) {
    croak sprintf q{Invalid accessor name: %s}, $accessor
      if $accessor !~ /\A[a-zA-Z_]\w*\z/;

    foreach my $prefix (qw(get set)) {
      my $method = $prefix . '_' . $accessor;
      croak sprintf q{Accessor already exists: %s}, $method
        if $self->can($method) && !$GENERATED_ACCESSORS{$class}{$method};
    }
  }

  my %file_args = ( UNLINK => $cleanup );
  $file_args{DIR}      = $args{dir}      if exists $args{dir};
  $file_args{SUFFIX}   = $args{suffix}   if exists $args{suffix};
  $file_args{TEMPLATE} = $args{template} if exists $args{template};

  my $file = File::Temp->new(%file_args);
  my $path = $file->filename;

  # Retain the File::Temp object, not merely its path. The accessor can
  # later change without affecting which file is cleaned up.
  $self->{_cli_simple_temp_files} //= [];

  push @{ $self->{_cli_simple_temp_files} }, $file;

  if ( !$no_accessors ) {
    foreach my $prefix (qw(get set)) {
      my $method = $prefix . '_' . $accessor;
      if ( !$GENERATED_ACCESSORS{$class}{$method} ) {
        no strict 'refs'; ## no critic (ProhibitNoStrict)
        if ( $prefix eq 'get' ) {
          *{"${class}::${method}"} = sub { return $_[0]->{$accessor}; };
        }
        else {
          *{"${class}::${method}"} = sub { $_[0]->{$accessor} = $_[1]; return $_[0]->{$accessor}; };
        }
        $GENERATED_ACCESSORS{$class}{$method} = 1;
      }
    }
    my $setter = 'set_' . $accessor;
    $self->$setter($path);
  }

  return $path;
}

1;

__END__

=pod

=head1 NAME

CLI::Simple::TempFile - temporary file creation and ownership for Role::Tiny consumers

=head1 SYNOPSIS

  package My::Processor;

  use Role::Tiny::With;

  with 'CLI::Simple::TempFile';

  sub process {
    my ($self) = @_;

    my $path = $self->create_temp_file(
      accessor => 'report',
      suffix   => '.csv',
      cleanup  => 1,
    );

    # $self->get_report returns the same path.
    return $path;
  }

=head1 DESCRIPTION

This role creates temporary files via L<File::Temp>. The consuming object
owns the underlying file objects until it is destroyed. When C<cleanup> is
true (the default), the temporary file is removed when its owner is
destroyed under normal Perl object-lifetime semantics. C<cleanup =E<gt> 0>
leaves it on disk. Cleanup cannot be guaranteed after abrupt termination.

I<Note: Consuming class must be a blessed hash.>

=head1 METHODS

=head2 create_temp_file

  my $path = $self->create_temp_file(
    accessor => 'report',
    dir      => '/tmp',
    suffix   => '.csv',
    cleanup  => 1,
  );

Creates and returns the path of a new temporary file. Supported attributes
are C<accessor>, C<no_accessors>, C<cleanup>, C<dir>, C<suffix>, and
C<template> (the latter three map to the corresponding L<File::Temp>
arguments). By default, generates C<get_temp_file> and C<set_temp_file>
methods in the consuming class; C<accessor> changes the name.

The consuming object must be a blessed hash reference.
C<no_accessors =E<gt> 1> disables accessor generation but does
not change this requirement.

An accessor contains the pathname, not the file object. Changing the
accessor does not transfer file ownership or alter cleanup behavior.
Multiple calls are supported, but callers should use distinct accessor
names when they want to retain multiple generated paths.

=cut
