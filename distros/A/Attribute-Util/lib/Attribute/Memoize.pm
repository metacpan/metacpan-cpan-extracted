package Attribute::Memoize;

use warnings;
use strict;
use Attribute::Handlers;

our $VERSION = sprintf "%d.%02d", q$Revision: 1.2 $ =~ /(\d+)/g;

sub UNIVERSAL::Memoize :ATTR(CODE) {
	my ($pkg, $symbol, $options) = @_[0,1,4];
	$options = [ $options || () ] unless ref $options eq 'ARRAY';
	require Memoize;
	Memoize::memoize($pkg . '::' . *{$symbol}{NAME}, @$options);
}

"Rosebud"; # for MARCEL's sake, not 1 -- dankogai

__END__

=head1 NAME

Attribute::Memoize - A Memoize attribute

=head1 SYNOPSIS

  use Attribute::Memoize;

  sub fib :Memoize {
          my $n = shift;
          return $n if $n < 2;
          fib($n-1) + fib($n-2);
  }
  $|++;
  print fib($_),"\n" for 1..50;

=head1 DESCRIPTION

This attribute makes it slightly easier (and modern) to memoize a
function by providing an attribute, C<:Memoize> that makes it
unnecessary for you to explicitly call C<Memoize::memoize()>.
Options can be passed via the attribute per usual (see the
C<Attribute::Handlers> manpage for details, and the C<Memoize>
manpage for information on memoizing options):

  sub f :Memoize(NORMALIZER => 'main::normalize_f') {
  	...
  }

However, since the call to C<memoize()> is now done in a different
package, it is necessary to include the package name in any function
names passed as options to the attribute, as shown above.

=head1 BUGS

None known so far. If you find any bugs or oddities, please do inform the
author.

=head1 AUTHOR

Marcel Grunauer, <marcel@codewerk.com>

Dan Kogai, C<< <dankogai+cpan at gmail.com> >>

=head1 COPYRIGHT

Copyright 2001 Marcel Grunauer.  All rights reserved.

Copyright 2006 Dan Kogai.  All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

perl(1), L<Attribute::Handlers>, L<Memoize>

=cut
