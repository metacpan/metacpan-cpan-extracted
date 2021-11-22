use strict;
use warnings;
package String::Formatter::Cookbook 1.234;
# ABSTRACT: ways to put String::Formatter to use
1;

#pod =encoding utf-8
#pod
#pod =head1 OVERVIEW
#pod
#pod String::Formatter is a pretty simple system for building formatting routines,
#pod but it can be hard to get started without an idea of the sort of things that
#pod are possible.
#pod
#pod =head1 BASIC RECIPES
#pod
#pod =head2 constants only
#pod
#pod The simplest stringf interface you can provide is one that just formats
#pod constant strings, allowing the user to put them inside other fixed strings with
#pod alignment:
#pod
#pod   use String::Formatter stringf => {
#pod     input_processor => 'forbid_input',
#pod     codes => {
#pod       a => 'apples',
#pod       b => 'bananas',
#pod       w => 'watermelon',
#pod     },
#pod   };
#pod
#pod   print stringf('I eat %a and %b but never %w.');
#pod
#pod   # Output:
#pod   # I eat apples and bananas but never watermelon.
#pod
#pod If the user tries to parameterize the string by passing arguments after the
#pod format string, an exception will be raised.
#pod
#pod =head2 sprintf-like conversions
#pod
#pod Another common pattern is to create a routine that behaves like Perl's
#pod C<sprintf>, but with a different set of conversion routines.  (It will also
#pod almost certainly have much simpler semantics than Perl's wildly complex
#pod behavior.)
#pod
#pod   use String::Formatter stringf => {
#pod     codes => {
#pod       s => sub { $_ },     # string itself
#pod       l => sub { length }, # length of input string
#pod       e => sub { /[^\x00-\x7F]/ ? '8bit' : '7bit' }, # ascii-safeness
#pod     },
#pod   };
#pod
#pod   print stringf(
#pod     "My name is %s.  I am about %l feet tall.  I use an %e alphabet.\n",
#pod     'Ricardo',
#pod     'ffffff',
#pod     'abcchdefghijklllmnñopqrrrstuvwxyz',
#pod   );
#pod
#pod   # Output:
#pod   # My name is Ricardo.  I am about 6 feet tall.  I use an 8bit alphabet.
#pod
#pod B<Warning>: The behavior of positional string replacement when the conversion
#pod codes mix constant strings and code references is currently poorly nailed-down.
#pod Do not rely on it yet.
#pod
#pod =head2 named conversions
#pod
#pod This recipe acts a bit like Python's format operator when given a dictionary.
#pod Rather than matching format code position with input ordering, inputs can be
#pod chosen by name.
#pod
#pod   use String::Formatter stringf => {
#pod     input_processor => 'require_named_input',
#pod     string_replacer => 'named_replace',
#pod
#pod     codes => {
#pod       s => sub { $_ },     # string itself
#pod       l => sub { length }, # length of input string
#pod       e => sub { /[^\x00-\x7F]/ ? '8bit' : '7bit' }, # ascii-safeness
#pod     },
#pod   };
#pod
#pod   print stringf(
#pod     "My %{which}s name is %{name}s.  My name is %{name}l letters long.",
#pod     {
#pod       which => 'first',
#pod       name  => 'Marvin',
#pod     },
#pod   );
#pod
#pod   # Output:
#pod   # My first name is Marvin.  My name is 6 letters long.
#pod
#pod Because this is a useful recipe, there is a shorthand for it:
#pod
#pod   use String::Formatter named_stringf => {
#pod     codes => {
#pod       s => sub { $_ },     # string itself
#pod       l => sub { length }, # length of input string
#pod       e => sub { /[^\x00-\x7F]/ ? '8bit' : '7bit' }, # ascii-safeness
#pod     },
#pod   };
#pod
#pod =head2 method calls
#pod
#pod Some objects provide methods to stringify them flexibly.  For example, many
#pod objects that represent timestamps allow you to call C<strftime> or something
#pod similar.  The C<method_replace> string replacer comes in handy here:
#pod
#pod   use String::Formatter stringf => {
#pod     input_processor => 'require_single_input',
#pod     string_replacer => 'method_replace',
#pod
#pod     codes => {
#pod       f => 'strftime',
#pod       c => 'format_cldr',
#pod       s => sub { "$_[0]" },
#pod     },
#pod   };
#pod
#pod   print stringf(
#pod     "%{%Y-%m-%d}f is also %{yyyy-MM-dd}c.  Default string is %s.",
#pod     DateTime->now,
#pod   );
#pod
#pod   # Output:
#pod   # 2009-11-17 is also 2009-11-17.  Default string is 2009-11-17T15:35:11.
#pod
#pod This recipe is available as the export C<method_stringf>:
#pod
#pod   use String::Formatter method_stringf => {
#pod     codes => {
#pod       f => 'strftime',
#pod       c => 'format_cldr',
#pod       s => sub { "$_[0]" },
#pod     },
#pod   };
#pod
#pod You can easily use this to implement an actual stringf-like method:
#pod
#pod   package MyClass;
#pod
#pod   use String::Formatter method_stringf => {
#pod     -as => '_stringf',
#pod     codes => {
#pod       f => 'strftime',
#pod       c => 'format_cldr',
#pod       s => sub { "$_[0]" },
#pod     },
#pod   };
#pod
#pod   sub format {
#pod     my ($self, $format) = @_;
#pod     return _stringf($format, $self);
#pod   }
#pod
#pod =cut

__END__

=pod

=encoding utf-8

=head1 NAME

String::Formatter::Cookbook - ways to put String::Formatter to use

=head1 VERSION

version 1.234

=head1 OVERVIEW

String::Formatter is a pretty simple system for building formatting routines,
but it can be hard to get started without an idea of the sort of things that
are possible.

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 BASIC RECIPES

=head2 constants only

The simplest stringf interface you can provide is one that just formats
constant strings, allowing the user to put them inside other fixed strings with
alignment:

  use String::Formatter stringf => {
    input_processor => 'forbid_input',
    codes => {
      a => 'apples',
      b => 'bananas',
      w => 'watermelon',
    },
  };

  print stringf('I eat %a and %b but never %w.');

  # Output:
  # I eat apples and bananas but never watermelon.

If the user tries to parameterize the string by passing arguments after the
format string, an exception will be raised.

=head2 sprintf-like conversions

Another common pattern is to create a routine that behaves like Perl's
C<sprintf>, but with a different set of conversion routines.  (It will also
almost certainly have much simpler semantics than Perl's wildly complex
behavior.)

  use String::Formatter stringf => {
    codes => {
      s => sub { $_ },     # string itself
      l => sub { length }, # length of input string
      e => sub { /[^\x00-\x7F]/ ? '8bit' : '7bit' }, # ascii-safeness
    },
  };

  print stringf(
    "My name is %s.  I am about %l feet tall.  I use an %e alphabet.\n",
    'Ricardo',
    'ffffff',
    'abcchdefghijklllmnñopqrrrstuvwxyz',
  );

  # Output:
  # My name is Ricardo.  I am about 6 feet tall.  I use an 8bit alphabet.

B<Warning>: The behavior of positional string replacement when the conversion
codes mix constant strings and code references is currently poorly nailed-down.
Do not rely on it yet.

=head2 named conversions

This recipe acts a bit like Python's format operator when given a dictionary.
Rather than matching format code position with input ordering, inputs can be
chosen by name.

  use String::Formatter stringf => {
    input_processor => 'require_named_input',
    string_replacer => 'named_replace',

    codes => {
      s => sub { $_ },     # string itself
      l => sub { length }, # length of input string
      e => sub { /[^\x00-\x7F]/ ? '8bit' : '7bit' }, # ascii-safeness
    },
  };

  print stringf(
    "My %{which}s name is %{name}s.  My name is %{name}l letters long.",
    {
      which => 'first',
      name  => 'Marvin',
    },
  );

  # Output:
  # My first name is Marvin.  My name is 6 letters long.

Because this is a useful recipe, there is a shorthand for it:

  use String::Formatter named_stringf => {
    codes => {
      s => sub { $_ },     # string itself
      l => sub { length }, # length of input string
      e => sub { /[^\x00-\x7F]/ ? '8bit' : '7bit' }, # ascii-safeness
    },
  };

=head2 method calls

Some objects provide methods to stringify them flexibly.  For example, many
objects that represent timestamps allow you to call C<strftime> or something
similar.  The C<method_replace> string replacer comes in handy here:

  use String::Formatter stringf => {
    input_processor => 'require_single_input',
    string_replacer => 'method_replace',

    codes => {
      f => 'strftime',
      c => 'format_cldr',
      s => sub { "$_[0]" },
    },
  };

  print stringf(
    "%{%Y-%m-%d}f is also %{yyyy-MM-dd}c.  Default string is %s.",
    DateTime->now,
  );

  # Output:
  # 2009-11-17 is also 2009-11-17.  Default string is 2009-11-17T15:35:11.

This recipe is available as the export C<method_stringf>:

  use String::Formatter method_stringf => {
    codes => {
      f => 'strftime',
      c => 'format_cldr',
      s => sub { "$_[0]" },
    },
  };

You can easily use this to implement an actual stringf-like method:

  package MyClass;

  use String::Formatter method_stringf => {
    -as => '_stringf',
    codes => {
      f => 'strftime',
      c => 'format_cldr',
      s => sub { "$_[0]" },
    },
  };

  sub format {
    my ($self, $format) = @_;
    return _stringf($format, $self);
  }

=head1 AUTHORS

=over 4

=item *

Ricardo Signes <rjbs@semiotic.systems>

=item *

Darren Chamberlain <darren@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2021 by Ricardo Signes <rjbs@cpan.org>.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
