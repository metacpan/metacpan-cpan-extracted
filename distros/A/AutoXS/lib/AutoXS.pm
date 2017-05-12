package AutoXS;

use 5.008;
use strict;
use warnings;

our $VERSION = '0.04';

#require XSLoader;
#XSLoader::load('AutoXS', $VERSION);

use vars qw/%ScanClasses $Debug/;

use B;
use B::Utils ();
use B::Generate;

use Carp qw/croak/;
use Module::Pluggable
  except => qr/(?:::b?lib::|^AutoXS::Header$)/,
  search_path => 'AutoXS',
  sub_name => 'plugins',
  ;

use vars qw/@ISA/;
sub import {
  my $class = shift;
  my ($callerpkg) = caller;
  return if $callerpkg =~ /^AutoXS/;

  my @importclasses;

  if (@_ == 1) {
    # load all plugins
    if ($_[0] eq ':all') {
      push @importclasses, $class->plugins();
    }
    else {
      croak("Invalid arguments to 'use $class;'");
    }
  }
  elsif (@_ == 0) {
    if ($class =~ /^AutoXS::(.+)$/) {
      # called on a plugin class (inherited)
      # apply that plugin
      push @importclasses, $class;
    }
  }
  else {
    my %args = @_;
    $AutoXS::Debug = 1 if $args{debug};

    return if not defined $args{plugins};

    push @importclasses, (ref($args{plugins}) ? @{$args{plugins}} : ($args{plugins}));
  }

  foreach my $importclass (@importclasses) {
    $importclass = "AutoXS::$importclass" if not $importclass =~ /^AutoXS::/;
    eval "require $importclass;";
    if ($@) {
      die "Cannot load AutoXS scanner plugin '$importclass': $@";
    }
    warn "Registering AutoXS scanner class '$importclass' for scanning '$callerpkg'.\n" if $AutoXS::Debug;
    $importclass->register_class($callerpkg, $importclass);
  }
}

sub register_class {
  my $class = shift;
  $class = shift if $class =~ /^AutoXS/;
  die "Cannot register undefined class!" if not defined $class;
  my @plugins = @_;

  foreach my $plugin (@plugins) {
    $ScanClasses{$plugin}{$class} = 1;
  }
}

sub get_symbol {
  my $class = shift;
  my $edit_pkg = shift;
  
  no strict 'refs';
  my $sym = \%{$edit_pkg."::"};

  return $sym;
}

1;
__END__

=head1 NAME

AutoXS - Speed up your code after compile time

=head1 SYNOPSIS

  package MyClass;
  sub blah {...}
  use AutoXS ':all';
  # if blah matches one of the patterns, it's running
  # as XS code now!

=head1 DESCRIPTION

I<Warning:> This module contains some scary code. I'm not even sure
it abides by the official Perl API totally. Furthermore, it's my first
I<real> XS module. It abuses some features of the XS/XSUB syntax.
If you break it, you get to keep both halves.

That being said, the purpose of this module and its plugin modules
is to speed up
the execution of your program at the expense of a longer startup time.
L<AutoXS::Accessor> comes with the same distribution as an example plugin.

L<AuotXS> plugins use the L<B> and L<B::Utils> modules to scan
all subroutines  (or methods) in the calling package for certain
patterns. If a subroutine complies with such a pattern, it is
replaced with an XS subroutine that has the same function.

The XS subroutines for replacement are I<not> compiled at runtime
like L<Inline::C> would do.
They have been compiled at module build time just like any other XSUBs.

In a simple minded test, L<AuotXS::Accessor> sped up typical
read-only accessors by a factor of
1.6 to a factor of 2.5. Your mileage may vary, of course.
Keep in mind mind that accessors can sometimes be part of
very tight loops.

To get an impression of the imposed pre-runtime penalty of using AutoXS,
a file containing nine methods (code shown in L<AutoXS::Accessor>)
was compiled with and without AutoXS. The test is contrived because
all nine methods will be replaced. In normal code, there is much more
non-accessor code which will be quickly rejected. Naturally,
rejection is faster than successful matching and replacement.
The compilation with AutoXS took C<74ms> longer than without.

=head1 USAGE AND SYNTAX

You use this module by loading it with C<use>. It is important to load it
at compile time, so if you must absolutely separate the file loading and
importing steps, do so in a C<BEGIN> block.

By loading an C<AutoXS> plugin module in your class, all methods in the
current package will be scanned for potential replacements. You can apply
all installed plugins/optimizations by loading C<AutoXS> with the C<':all'>
tag:

  package MyClass;
  use AutoXS ':all';
  # code that will be optimized

Apart from that, you can also specify the plugins that should be loaded and
applied:

  package OtherClass;
  use AutoXS plugins => ['Accessor']; # that one comes with AutoXS
  # will optimize your accessors.

If you want to know which subroutines/methods were optimized, you can
load C<AutoXS> with the C<debug> option. Note that the following call
only sets the debug option, but does not apply any optimizations:

  use AutoXS debug => 1;

You can also set the debug option on plugin classes, but the option
is still global to all plugins:

  use AutoXS::Accessor debug => 1; # same as the last example

Loading a plugin with no argument applies its optimizations:

  package SomeClass;
  use AutoXS::Accessor;
  # optimizes accessors only.

=head1 CAVEATS

This is alpha code. Beware.

The module abuses XS syntax constructs.

The startup penalty may be big and is proportional to the number of
subroutines in the calling package.

The module works its magic at CHECK time. CHECK blocks are not executed
in string C<eval ""> environments. That means this module potentially
does not work in a L<PAR> packaged executable. (It should do no harm there,
either.)

=head1 SEE ALSO

L<AutoXS::Accessor>

L<AutoXS::Header>

L<B>, L<B::Utils>

Much cleverer: L<Faster>

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
