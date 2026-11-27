package CLI::Simple::TempDir;

use strict;
use warnings;

use Carp qw(croak);
use File::Temp;
use Role::Tiny;
use Scalar::Util qw(blessed reftype);

my %GENERATED_ACCESSORS;

our $VERSION = '2.6.0';

########################################################################
sub create_temp_dir {
########################################################################
  my ( $self, %args ) = @_;

  croak 'create_temp_dir requires an object instance'
    if !blessed($self);

  croak 'create_temp_dir requires a hash-based object'
    if reftype($self) ne 'HASH';

  my $no_accessors = delete $args{no_accessors} // 0;
  my $cleanup      = delete $args{cleanup}      // 1;
  my $has_accessor = exists $args{accessor};
  my $accessor     = delete $args{accessor};

  croak 'accessor and no_accessors cannot be combined'
    if $no_accessors && $has_accessor;

  $accessor //= 'temp_dir';

  croak 'cleanup must be 0 or 1'
    if !defined $cleanup || $cleanup !~ /\A[01]\z/;

  croak 'no_accessors must be 0 or 1'
    if !defined $no_accessors || $no_accessors !~ /\A[01]\z/;

  my %supported = map { $_ => 1 } qw(dir template);
  foreach my $key ( keys %args ) {
    croak sprintf q{Unknown temporary directory attribute: %s}, $key
      if !exists $supported{$key};
  }

  my $class = ref $self;
  if ( !$no_accessors ) {
    croak sprintf q{Invalid accessor name: %s}, $accessor
      if $accessor !~ /\A[a-zA-Z_]\w*\z/;

    foreach my $prefix (qw(get set)) {
      my $method = $prefix . q{_} . $accessor;
      croak sprintf q{Accessor already exists: %s}, $method
        if $self->can($method) && !$GENERATED_ACCESSORS{$class}{$method};
    }
  }

  my %dir_args = ( CLEANUP => $cleanup );
  $dir_args{DIR}      = $args{dir}      if exists $args{dir};
  $dir_args{TEMPLATE} = $args{template} if exists $args{template};

  my $resource = File::Temp->newdir(%dir_args);
  my $path     = $resource->dirname;

  $self->{_cli_simple_temp_dirs} //= [];
  push @{ $self->{_cli_simple_temp_dirs} }, $resource;

  if ( !$no_accessors ) {
    foreach my $prefix (qw(get set)) {
      my $method = $prefix . q{_} . $accessor;
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
    my $setter = q{set_} . $accessor;
    $self->$setter($path);
  }

  return $path;
}

1;

__END__

=pod

=head1 NAME

CLI::Simple::TempDir - temporary directory creation and ownership for Role::Tiny consumers

=head1 SYNOPSIS

  package My::Processor;

  use Role::Tiny::With;

  with 'CLI::Simple::TempDir';

  sub process {
    my ($self) = @_;

    my $workspace = $self->create_temp_dir(
      accessor => 'workspace',
      cleanup  => 1,
    );

    # $self->get_workspace returns the path.
    return $workspace;
  }

=head1 DESCRIPTION

This role allocates unique temporary directories using L<File::Temp>.
The consumer must be a blessed hash reference. Each consuming object owns
its temporary directory objects; generated accessors expose only pathnames.

With C<cleanup =E<gt> 1> (the default), destroying the owning object
normally removes the directory B<and its contents>, including files the
application placed there. Do not use an automatically cleaned directory
for output that must survive the owning object's destruction.
C<cleanup =E<gt> 0> leaves the directory in place.

Cleanup is not guaranteed after abrupt process termination. Retaining a
reference to the owner delays cleanup, and changing a generated accessor
never transfers ownership of the original directory.

=head1 METHODS

=head2 create_temp_dir

  my $path = $self->create_temp_dir(
    accessor => 'workspace',
    dir      => '/tmp',
    template => 'myapp-XXXXXXXX',
    cleanup  => 1,
  );

Creates a directory and returns its pathname. Supported attributes are
C<accessor>, C<no_accessors>, C<cleanup>, C<dir>, and C<template>.
C<dir> specifies the parent directory; it is not the generated directory.
The latter two creation arguments map to C<DIR> and C<TEMPLATE> in
L<File::Temp>.

By default the role creates C<get_temp_dir()> and C<set_temp_dir()>
in the consuming class. C<accessor> changes the generated names.
C<no_accessors =E<gt> 1> disables accessor generation but still requires
a hash-based object. Specifying both C<accessor> and C<no_accessors>
is an error.

Multiple directories may be created by calling the method repeatedly.
Use distinct accessor names to retain separate paths through accessors.
All created directories remain independently owned by the same instance.

=cut
