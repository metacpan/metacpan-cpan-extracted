package Acme::Lexical::Thief;

use 5.012;
use strict;
use warnings;
no warnings qw( once void uninitialized numeric );

BEGIN {
	$Acme::Lexical::Thief::AUTHORITY = 'cpan:TOBYINK';
	$Acme::Lexical::Thief::VERSION   = '0.002';
}

use Carp;
use Keyword::Simple ();
use PadWalker ();
use Text::Balanced ();

my $KEYWORD = 'steal';
my $CLASS   = __PACKAGE__;

sub import
{
	Keyword::Simple::define $KEYWORD, sub
	{
		my $ref = shift;
		$$ref =~ s/^\s+//;

		my $depth = 0;
		if ($$ref =~ /^((?: 0x[0-9A-F]+ | 0b[0-1]+ | 0[0-7]* | [1-9][0-9]* )\s*)/ixs)
		{
			$depth = eval $1;
			substr($$ref, 0, length $1) = '';
		}

		my $extracted;
		if ($$ref =~ /^\(/)
		{
			$extracted = Text::Balanced::extract_bracketed($$ref)
				or croak "usage: $KEYWORD (VARIABLES);";
			$extracted =~ s/(^\(|\)$)//gs;
		}
		else
		{
			($extracted, $$ref) = ($$ref =~ /^([^;]+)(;.*)$/s)
				or croak "usage: $KEYWORD VARIABLES;";
		}
		(my $globs = $extracted) =~ s/[\$\%\@]/*/gs;
		$$ref = "our($extracted); local($globs) = $CLASS\::_callback(q($extracted), $depth);$$ref";
	}
}

sub unimport
{
	Keyword::Simple::undefine $KEYWORD;
}

sub _callback
{
	my $vars  = shift;
	my $depth = shift // 0;
	
	$vars =~ s/(^\s*|\s*$)//g;
	my @vars = split /\s*,\s*/, $vars;
	
	my $MY  = PadWalker::peek_my($depth + 2);
	my $OUR = PadWalker::peek_our($depth + 2);
	return map {
		exists $MY->{$_}  ? $MY->{$_} :
		exists $OUR->{$_} ? $OUR->{$_} :
		croak "$KEYWORD($_) failed; caller has no $_ defined";
	} @vars;
}

1;

__END__

=head1 NAME

Acme::Lexical::Thief - steal lexical variables from your caller

=head1 SYNOPSIS

   use 5.012;
   use strict;
   use warnings;
   use Acme::Lexical::Thief;
   
   sub greet {
      my $name = shift;
      greet_verbally();
   }
   
   sub greet_verbally {
      steal $name;  # caller variable
      say "Hello $name";
   }

=head1 DESCRIPTION

This package allows you access to your caller's lexical variables, without
them knowing! Full read/write access. This is generally a pretty bad idea,
hence the Acme namespace.

You can steal scalars, arrays and hashes:

   steal $car, @treasures, %stash;

Parentheses can surround the list of variables to steal:

   steal ($car, @treasures, %stash);

Generally everything should "just work" as you expect it to. Except when it
does not.

Technically speaking, your stolen C<< $car >> is a package-scoped (C<our>)
variable which is lexically aliased (C<< local *car >>) to the caller's
variable of the same name. Because C<steal> is parsed at compile-time,
you don't need to (and indeed should not!) pre-declare your stolen
variables.

   sub greet_verbally {
      my $name;   # don't do this!
      steal $name;
      say "Hello $name";
   }

By default, this module steals from your I<immediate> caller. You can
thieve higher up the call stack using:

   steal 0 ($car);  # caller's $car
   steal 1 @boats;  # caller's caller's @boats
   steal 2 %stash;  # caller's caller's caller's @stash

You cannot indicate the level you wish to steal from using a variable; it
must be a literal integer in your source code. (It can be in decimal, octal,
hexadecimal or binary notation.) The integer must immediately follow the
C<steal> keyword, and not be followed by a comma.

The C<steal> keyword cannot be used in an expression; it must be a
standalone statement.

   steal $foo;
   if (defined $foo) { ... } # ok
   
   if (steal $foo) { ... }   # not this!
   
   # this works...
   if (do { steal $foo; defined $foo })
   {
      # ... but $foo won't exist in this block!
      ...
   }

If you attempt to steal a variable which does not exist, then a run-time
exception will be thrown.

=head1 WHY YOU SHOULD NOT USE THIS MODULE

When people declare lexical (C<my>) variables within a sub, they (quite
reasonably) expect these to stay local to the sub. If they rename those
variables, change them (say replacing a hashref with a hash), drop them
or whatever, then they don't expect code outside the sub to pay much
attention.

Peeking at your caller's lexicals breaks those expectations.

Peeking at your caller's lexicals leaks an abstraction.

Peeking at your caller's lexicals can cause spooky action at a distance.

Every time you peek at your caller's lexicals, a fairy dies.

Just think about that for a minute, won't you?

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Acme-Lexical-Thief>.

=head1 SEE ALSO

L<PadWalker> - a slightly more sane alternative to peeking at your caller's
lexicals.

L<Data::Alias> - a slightly more sane way of creating lexical aliases.

This package was initially published on PerlMonks as C<Acme::Asplode>
L<http://www.perlmonks.org/?node_id=1008814>, but I prefer the current
name.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

