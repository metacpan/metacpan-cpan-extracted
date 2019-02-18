package Config::Tree;

our $VERSION = '0';
$VERSION = eval $VERSION;

=head1 NAME

Config::Tree - Simple API for accessing configuration data

=head1 SYNOPSIS

    # Basic:

    use Config::Tree;

    my %new_config = (
        simple => 42,
        more => {
            complex => {
                data => 12,
            },
        },
    );
    CONFIG->append(\%new_config);
    CONFIG("simple");            # 42
    CONFIG("more.complex");      # { data => 12 }
    CONFIG("more.complex.data"); # 12

    # Classy:

    package MyApp::Config;
    use Config::Tree ':reexport';
    our %volatile = (...);
    our @stack    = (...);
    our %default  = (...);

    package main;
    use MyApp::Config;
    CONFIG("foo")                # Scan's MyApp::Config's stashes

=head1 BUGS

=over

=item * I'm not sure about the append/prepend api.

=item * The hash scanner is a bit too magical.

=item * Autovivified entries in %volatile are always hashes regardless
of the contents of @stack or %default.

(... not magical enough)

=item * Uses global variables which restrict its usefulness in library code.

=back

=cut

use strictures 2;
use Exporter ();
use List::Util   qw(pairs);
use Scalar::Util qw(reftype);
use Syntax::Keyword::Try;

our @EXPORT = qw(CONFIG SECRET);

sub import {
  if ($_[1] and $_[1] eq ':reexport') {
    @_ = @EXPORT[1..$#EXPORT]; # ie. not CONFIG
    no strict 'refs';
    my $target = caller;
    *{$target . '::import'} = \&import;
    *{$target . '::CONFIG'} = sub {
      local $Config::Tree::stash = bless [
        \%{ $target . '::volatile' },
        \@{ $target . '::stack' },
        \%{ $target . '::default' },
       ], $target;
      CONFIG(@_);
    };
    push @{ $target . '::ISA' }, __PACKAGE__;
    push @{ $target . '::EXPORT' }, @EXPORT;
  }
  goto \&Exporter::import;
}

=head1 IMPORTANT NOTE

This module does B<not> handle loading configuration data from a file
(or other source) nor does it save data which have been set at
runtime.

Methods to load and save will be included in a future release provided
the API remains unchanged and this distribution's dependencies minimal.

=head1 DESCRIPTION

A common API with for interacting with configuration data. This module
is centred around the L</CONFIG> function, which is exported
unconditionally (along with L</SECRET>, which uses it). The most
common way to use C<CONFIG> is to simply call it with the desired
configuration key as an argument:

    CONFIG("foo.bar.baz");

If the key doesn't exist then an exception will be thrown (C<Value not
found>). To return a default value instead, pass the key as the first
item in an arrayref where the second value is the desired default:

    CONFIG(["foo.bar.baz", "default-baz"]);

The default value can be C<undef>.

Multiple values can be returned from a single call, with or without
defaults. When used in this way C<CONFIG> I<must> be called in L<list
context|func/wantarray>.

When C<CONFIG> is called without arguments it returns the
configuration singleton, whose methods are described below. Ordinarily
this will be the global singleton but see L</Object interface> for a
explanation of how to customise that. C<CONFIG> with arguments is
actually a shortcut to calling C<< CONFIG->get() >>.

=head2 Configuration stack

Configuration values are stored in a stack of hashrefs which are
searched in order. At the top of the stack is C<%volatile> which
contains values which have been set at runtime by L</set>. At the
bottom is C<%default>, the purpose of which I hope is obvious.

In between the volatile and default stashes are zero or more hashrefs,
attached by L</append> and L</prepend>.

=head2 Object interface

If L<Config::Tree> is imported into a module with the C<:reexport>
option. Then that module becomes a subclass of L<Config::Tree> and
also re-exports L</CONFIG> and L</SECRET>, modified as necessary to
use the re-exporter's configuration stash.

By way of example, under normal circumstances C<CONFIG> scans
C<@Config::Tree::stack>. T this can be adjusted by re-exporting
C<Config::Tree>'s symbols:

    package Foo;
    use Config::Tree ':reexport';

Any module which imports C<Foo> will obtain its configuration from
C<@Foo::stack> (and C<%Foo::volatile> and C<%Foo::default>) instead.

=cut

our (%volatile, @stack, %default);
our $stash = bless [ \%volatile, \@stack, \%default ], __PACKAGE__;

sub _hasx { die "Value not found\n" }
sub _hasa : lvalue { _hasx unless $_[1] < 0 || $#{$_[0]} >= $_[1]; $_[0]->[$_[1]] }
sub _hash : lvalue { _hasx unless defined $_[1] && exists $_[0]->{$_[1]}; $_[0]->{$_[1]} }
sub _find_raw : lvalue {
  my ($stack, $viv, @prop) = @_;
  my $top = $stack;
  my $_sub; $_sub = sub : lvalue { # __SUB__ doesn't work with anonymous lvalue subs?
    my $here = shift;
    try {
      # For unknown reasons, do{} is necessary
      if    (reftype $top eq 'ARRAY') { for ($top = _hasa $top, $here) { return @_ ? do { $_sub->(@_) } : $_ } }
      elsif (reftype $top eq 'HASH')  { for ($top = _hash $top, $here) { return @_ ? do { $_sub->(@_) } : $_ } }
      else { _hasx }
    } catch {
      die $@ if $@ ne "Value not found\n" or not $viv;
      my $next = $top->{$here} = {};
      return $top->{$here} unless @_;
      $top = $next;
      goto $_sub;
    }
  };
  $_sub->(@prop);
}
sub _find (_) {
  my $prop = shift;
  for my $db ($stash->[0], @{ $stash->[1] }, $stash->[2]) {
    try {
      my $top = _find_raw($db, 0, split /\./, $prop);
      return $top if $top;
    } catch {
      die $@ unless $@ eq "Value not found\n";
    }
  }
  die "Value not found: $prop";
}

=head1 API

=over

=item CONFIG

The heart of L<Config::Tree>. When called without arguments returns
the global configuration stash (for whose methods see
L<below|/METHODS>). When called with arguments returns the value or
values requested.

More than one key can be requested, in which case the values are
returned as a list in the same order. Note that CONFIG must be called
in list context when used in this way.

Each key requested is a plain scalar consisting of hash or array
elements seperated by dots (C<.>). Each component of the key
represents a level within the configuration stack. That is the key
C<foo.bar.baz> refers to the value at C<$stash{foo}{bar}{baz}>.

Alternatively the key can be given as the first item of an arrayref,
in which case the second item is the default value which will be
returned if the key cannot be found.

=cut

sub CONFIG {
  return $stash unless @_;
  my @all = map { my $what;
    if ($_ and ref eq 'ARRAY') {
      try { $what = _find $_->[0] }
      catch {
        die unless $@ =~ /^Value not found/;
        $what = $_->[1];
      }
    } elsif (not ref) {
      $what = _find;
    } else {
      die "Unexpected argument to CONFIG";
    }
    $what;
  } @_;
  wantarray ? @all : @all == 1 ? $all[0] : die 'Multi-config request in scalar/void context';
}

=item SECRET

(Not written yet)

A wrapper around L</CONFIG> which post-processes each value
retrieved. The intention is that the value in the configuration will
refer in some way to secret data, which this method will obtain and/or
decode/decrypt.

=cut

sub SECRET {
  goto \&CONFIG unless @_;
  return map {
    ...;
  } CONFIG(@_);
}

=back

=head1 METHODS

=over

=item exists

Returns a boolean indicating whether the requested key exists in the
configuration stash.

Takes exactly 1 key.

    CONFIG->exists("foo.bar");

=cut

sub exists {
  local $stash = shift;
  my $want = shift;
  try { _find $want; return 1 }
  catch { die unless $@ =~ /^Value not found/; return }
}

=item exists

Returns a boolean indicating whether the requested key exists in the
configuration stash and contains a value which perl considers C<true>.

Takes exactly 1 key.

    CONFIG->true("foo.bar");

=cut

sub true {
  local $stash = shift;
  my $want = shift;
  try { return !! _find $want }
  catch { die unless $@ =~ /^Value not found/; return }
}

=item get

Return the value or values for the requested key(s). See L</CONFIG> or
the L</DESCRIPTION> for more detail.

Generally you will want to use L</CONFIG> directly.

    CONFIG->get("foo.bar");
    CONFIG->get("foo.bar", "foo.baz");
    CONFIG->get(["foo.bar", "default-bar"]);

=cut

sub get {
  local $stash = shift;
  CONFIG(@_);
}

=item set

Sets the value or values for the named key(s). The set values are
stored in I<memory only>.

Parent values which don't exist in the volatile stash are autovivified
as hashrefs, despite what the key component is at that level or what
exists in the rest of the stash.

    CONFIG->set("foo.bar" => "new-bar");
    CONFIG->set("foo.bar" => "new-bar",
                "foo.baz" => "new-baz");

=cut

sub set {
  local $stash = shift;
  for (pairs @_) {
    my ($prop, $value) = @$_;
    _find_raw($stash->[0], 1, $prop) = $value;
  }
}

=item append

Append the stash or stashes to the I<end> of the configuration stack
(but before the default values).

    CONFIG->append(\%new_config, ...);

=cut

sub append {
  local $stash = shift;
  push @{ $stash->[1] }, @_;
}

=item prepend

Prepend the stash or stashes to the I<beginning> of the configuration
stack (but after the in-memory values).

    CONFIG->prepend(\%new_config, ...);

=cut

sub prepend {
  local $stash = shift;
  unshift @{ $stash->[1] }, @_;
}

=item replace

Replace the contents of the entire configuration stack with the
stash(es) supplied.

This does not affect the default or in-memory values.

    CONFIG->replace(\%new_config, ...);

=cut

sub replace {
  local $stash = shift;
  @{ $stash->[1] } = @_;
}

=item default

Return the default stash.

=item stack

Return (as a list) the inner stashes.

=item volatile

Return the in-memory stash.

=cut

sub volatile { shift->[0] }
sub stack { @{shift->[1]} }
sub default { shift->[2] }

=item stash

(Not written yet)

Return the entire configuration stash, normalised, as a hashref.

=cut

sub stash { ... } # Need to determine merge strategy (and possibly adapt _find)

1;

=back

=head1 WHY?

It seems like everyone on the CPAN wants their own config-loading
module. Why another one?

Well this one is mine, see?

=head1 SEE ALSO

L<https://metacpan.org/search?q=Config%3A%3A>

=head1 AUTHOR

Matthew King <chohag@jtan.com>

=cut
