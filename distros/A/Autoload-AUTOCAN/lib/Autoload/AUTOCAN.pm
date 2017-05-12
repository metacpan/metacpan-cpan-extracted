package Autoload::AUTOCAN;

use strict;
use warnings;
use Carp ();
use Scalar::Util ();

our $VERSION = '0.004';

my $autoload_methods = <<'EOF';
sub AUTOLOAD {
  my ($inv) = @_;
  my ($package, $method) = our $AUTOLOAD =~ /^(.+)::(.+)$/;
  Carp::croak qq[Undefined subroutine &${package}::$method called]
    unless defined $inv && (!ref $inv or Scalar::Util::blessed $inv) && $inv->isa(__PACKAGE__);
  return if $method eq 'DESTROY';
  my $autocan = $inv->can('AUTOCAN');
  my $sub = defined $autocan ? $inv->$autocan($method) : undef;
  Carp::croak qq[Can't locate object method "$method" via package "$package"]
    unless defined $sub and do { local $@; eval { $sub = \&$sub } };
  # allow overloads and blessed subrefs; assign ref so overload is only invoked once
  goto &$sub;
}
EOF

my $autoload_functions = <<'EOF';
sub AUTOLOAD {
  my ($package, $function) = our $AUTOLOAD =~ /^(.+)::(.+)$/;
  my $autocan = __PACKAGE__->can('AUTOCAN');
  my $sub = defined $autocan ? __PACKAGE__->$autocan($function) : undef;
  Carp::croak qq[Undefined subroutine &${package}::$function called]
    unless defined $sub and do { local $@; eval { $sub = \&$sub } };
  # allow overloads and blessed subrefs; assign ref so overload is only invoked once
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
  return defined $autocan ? scalar $package->$autocan($function) : undef;
}
EOF

sub import {
  my ($class, $style) = @_;
  $style = 'methods' unless defined $style;
  
  my $target = caller;
  my $autoload_code;
  if ($style eq 'methods') {
    $autoload_code = $autoload_methods;
  } elsif ($style eq 'functions') {
    $autoload_code = $autoload_functions;
  } else {
    Carp::croak "Invalid autoload style '$style' (expected 'functions' or 'methods')";
  }
  
  my ($errored, $error);
  {
    local $@;
    unless (eval "package $target;\n$install_can\n$autoload_code\n1") {
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
