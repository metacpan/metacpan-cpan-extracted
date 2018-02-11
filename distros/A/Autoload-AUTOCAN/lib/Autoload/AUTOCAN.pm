package Autoload::AUTOCAN;

use strict;
use warnings;
use Carp ();
use Scalar::Util ();

our $VERSION = '0.005';

my $autoload_methods = <<'EOF';
sub AUTOLOAD {
  my ($inv) = @_;
  my ($package, $function) = our $AUTOLOAD =~ /^(.+)::(.+)$/;
  Carp::croak qq[Undefined subroutine &${package}::$function called]
    unless defined $inv && (!ref $inv or Scalar::Util::blessed $inv) && $inv->isa(__PACKAGE__);
  return if $function eq 'DESTROY';
  my $autocan = $inv->can('AUTOCAN');
  my $sub = defined $autocan ? $inv->$autocan($function) : undef;
  Carp::croak qq[Can't locate object method "$function" via package "$package"]
    unless defined $sub and do { local $@; eval { $sub = \&$sub; 1 } };
  # allow overloads and blessed subrefs; assign ref so overload is only invoked once
__INSTALL_SUB_CODE__
  goto &$sub;
}
EOF

my $autoload_functions = <<'EOF';
sub AUTOLOAD {
  my ($package, $function) = our $AUTOLOAD =~ /^(.+)::(.+)$/;
  my $autocan = __PACKAGE__->can('AUTOCAN');
  my $sub = defined $autocan ? __PACKAGE__->$autocan($function) : undef;
  Carp::croak qq[Undefined subroutine &${package}::$function called]
    unless defined $sub and do { local $@; eval { $sub = \&$sub; 1 } };
  # allow overloads and blessed subrefs; assign ref so overload is only invoked once
__INSTALL_SUB_CODE__
  goto &$sub;
}
EOF

my $install_can = <<'EOF';
sub can {
  my ($package, $function) = @_;
  my $sub = $package->SUPER::can($function);
  return $sub if defined $sub;
  return undef if $function eq 'AUTOCAN'; # don't recurse on AUTOCAN
  my $autocan = $package->can('AUTOCAN');
  $sub = defined $autocan ? $package->$autocan($function) : undef;
  return undef unless defined $sub and do { local $@; eval { $sub = \&$sub; 1 } };
  # allow overloads and blessed subrefs; assign ref so overload is only invoked once
__INSTALL_SUB_CODE__
  return $sub;
}
EOF

my $install_subs = <<'EOF';
  {
    require Sub::Util;
    no strict 'refs';
    *{"${package}::$function"} = Sub::Util::set_subname("${package}::$function", $sub);
  }
EOF

sub import {
  my ($class, @args) = @_;
  
  my $autoload_code = $autoload_methods;
  my $can_code = $install_can;
  my $install_sub_code = '';
  
  foreach my $arg (@args) {
    if ($arg eq 'methods') {
      $autoload_code = $autoload_methods;
    } elsif ($arg eq 'functions') {
      $autoload_code = $autoload_functions;
    } elsif ($arg eq 'install_subs') {
      $install_sub_code = $install_subs;
    } else {
      Carp::croak "Unrecognized import argument '$arg'";
    }
  }
  
  $autoload_code =~ s/__INSTALL_SUB_CODE__/$install_sub_code/;
  $can_code =~ s/__INSTALL_SUB_CODE__/$install_sub_code/;
  
  my $target = caller;
  
  my ($errored, $error);
  {
    local $@;
    unless (eval "package $target;\n$can_code\n$autoload_code\n1") {
      $errored = 1;
      $error = $@;
    }
  }
  
  die $error if $errored;
}

1;

=head1 NAME

Autoload::AUTOCAN - Easily set up autoloading

=head1 SYNOPSIS

  package My::Class;
  use Moo; # or object system of choice
  use Autoload::AUTOCAN;
  
  has count => (is => 'rw', default => 0);
  
  sub increment { $_[0]->count($_[0]->count + 1) }
  
  sub AUTOCAN {
    my ($self, $method) = @_;
    return sub { $_[0]->increment } if $method =~ m/inc/;
    return undef;
  }
  
  1;
  
  # elsewhere
  my $obj = My::Class->new;
  $obj->inc;
  say $obj->count; # 1
  $obj->increment; # existing method, not autoloaded
  say $obj->count; # 2
  $obj->do_increment;
  say $obj->count; # 3
  $obj->explode; # method not found error

=head1 DESCRIPTION

L<Autoloading|perlsub/"Autoloading"> is a very powerful mechanism for
dynamically handling function calls that are not defined. However, its
implementation is very complicated. For the simple case where you wish to
allow method calls to methods that don't yet exist, this module allows you to
define an C<AUTOCAN> method which will return either a code reference or
C<undef>.

L<Autoload::AUTOCAN> installs an C<AUTOLOAD> subroutine in the current package,
which is invoked when an unknown method is called. The installed C<AUTOLOAD>
will call C<AUTOCAN> with the invocant (class or object the method was called
on) and the method name. If C<AUTOCAN> returns a code reference, it will be
called with the same arguments as passed to the unknown method (including the
invocant). If C<AUTOCAN> returns C<undef>, an error will be thrown as expected
when calling an undefined method.

Along with C<AUTOLOAD>, the module installs a C<can> method which returns code
references as normal for defined methods (see L<UNIVERSAL>), and delegates to
C<AUTOCAN> for unknown methods.

=head1 CONFIGURING

L<Autoload::AUTOCAN> accepts import arguments to configure its behavior.

=head2 functions

C<AUTOLOAD> affects standard function calls in addition to method calls. By
default, the C<AUTOLOAD> provided by this module will die (as Perl normally
does without a defined C<AUTOLOAD>) if a nonexistent function is called without
a class or object invocant. If you wish to autoload functions instead of
methods, you can pass C<functions> as an import argument, and the installed
C<AUTOLOAD> will autoload functions using C<AUTOCAN> from the current package,
rather than using the first argument as an invocant.

  package My::Functions;
  use Autoload::AUTOCAN 'functions';
  
  sub AUTOCAN {
    my ($package, $function) = @_;
    return sub { $_[0]x5 } if $function =~ m/dup/;
    return undef;
  }
  
  # elsewhere
  say My::Functions::duplicate('foo'); # foofoofoofoofoo
  say My::Functions::foo('bar'); # undefined subroutine error

=head2 install_subs

By passing C<install_subs> as an import argument, any autoloaded function or
method returned by C<AUTOCAN> will be installed into the package, so that
future invocations do not need to go through C<AUTOLOAD>. This should not be
used if the autoloaded code is expected to change in subsequent calls to
C<AUTOCAN>, as the installed version will be called or returned by C<can>
directly.

  package My::Class;
  use Moo;
  use Autoload::AUTOCAN 'install_subs';
  
  sub AUTOCAN {
    my ($self, $method) = @_;
    my $hash = expensive_calculation($method);
    return sub { $hash };
  }
  
  # elsewhere
  my $obj = My::Class->new;
  $obj->foo; # sub foo installed in My::Class
  $obj->foo; # not autoloaded anymore

=head1 CAVEATS

If you use L<namespace::clean>, it will clean up the installed C<AUTOLOAD>
function. To avoid this, either use this module B<after> L<namespace::clean>,
or add an exception for C<AUTOLOAD> as below.

  use Autoload::AUTOCAN;
  use namespace::clean -except => 'AUTOLOAD';

This issue does not seem to occur with L<namespace::autoclean>.

=head1 BUGS

Report any issues on the public bugtracker.

=head1 AUTHOR

Dan Book <dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Dan Book.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=head1 SEE ALSO

L<AutoLoader>, L<SelfLoader>
