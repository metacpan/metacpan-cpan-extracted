package Acme::UseStrict;

use 5.010;
use strict;
use overload qw();
use match::smart qw(M);

BEGIN {
	$Acme::UseStrict::AUTHORITY = 'cpan:TOBYINK';
	$Acme::UseStrict::VERSION   = '1.235';
}

sub import
{
	my $class = shift;
	my ($test) = @_;
	$test //= 'use strict';
	
	my %overload = (
		q => sub {
			in_effect(1)
				and $_[1] |M| $test
				and $^H |= strict::bits(qw/refs subs vars/);
			return $_[1];
		},
	);
	overload::constant %overload;
	
	$^H{+__PACKAGE__} = 1;
}

sub unimport
{
	$^H{+__PACKAGE__} = 0;
}

sub in_effect
{
	my $level    = $_[0] // 0;
	my $hinthash = (caller($level))[10];
	return $hinthash->{+__PACKAGE__};
}

'use strict constantly';

__END__

=head1 NAME

Acme::UseStrict - use strict constantly

=head1 SYNOPSIS

  use Acme::UseStrict;
  # not in strict mode
  
  sub foo {
    "use strict";
    # in strict mode here
  }
  
  sub bar {
    no Acme::UseStrict;
    "use strict";
    # not in strict mode
  }

=head1 DESCRIPTION

ECMAScript 5.1 (i.e. Javascript) introduces a "strict mode" similar in
spirit to Perl's strict mode. Usually you enable Perl's strict mode like
this:

 use strict;

But in ECMAScript it must be a quoted string:

 "use strict";

It is received wisdom that Perl has an ugly syntax, so it naturally follows
that any change to make Perl's syntax closer to Javascript will be welcome.

This module allows you use use strict by simply including the string constant
"use strict" anywhere in a scope.

 sub do_stuff {
   warn "use strict";
   *{"do_more_stuff"} = sub { }; # dies because of strict refs.
 }

=head2 import

But what if you'd rather have a different trigger to enable strict mode?
Yes, that can be done:

 use Acme::UseStrict 'complain';
 
 sub do_stuff {
   my $foo = { complain => 'lots' };
   *{"do_more_stuff"} = sub { }; # dies because of strict refs.
 }

You can even provide a regular expression:

 use Acme::UseStrict qr/^(complain|whine|moan|grumble)$/i;

Or an list of values:

 use Acme::UseStrict [qw/complain whine moan grumble/];

Or basically anything that works as a right-hand-side with the smart match
operator.

=head2 unimport

You can disable this module for a lexical scope using:

 no Acme::UseStrict;

=head2 in_effect

You can check if this module is enabled:

 warn Acme::UseStrict::in_effect()
   ? 'mind your language'
   : 'curse freely';

Note that this checks if B<this module> is enabled; not if strict is enabled.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Acme-UseStrict>.

=head1 SEE ALSO

L<https://developer.mozilla.org/en/JavaScript/Strict_mode>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2011, 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

