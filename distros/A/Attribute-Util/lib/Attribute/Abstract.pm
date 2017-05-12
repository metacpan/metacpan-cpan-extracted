package Attribute::Abstract;

use warnings;
use strict;
use Attribute::Handlers;

our $VERSION = sprintf "%d.%02d", q$Revision: 1.2 $ =~ /(\d+)/g;

sub UNIVERSAL::Abstract :ATTR(CODE) {
	my ($pkg, $symbol) = @_;
	no strict 'refs';
	my $sub = $pkg . '::' . *{$symbol}{NAME};
	*{$sub} = sub {
		my ($file, $line) = (caller)[1,2];
		die "call to abstract method $sub at $file line $line.\n";
	};
}

"Rosebud"; # for MARCEL's sake, not 1 -- dankogai

__END__

=head1 NAME

Attribute::Abstract - An Abstract attribute

=head1 SYNOPSIS

  use Attribute::Abstract;

  package MyObj;
  sub new { ... }
  sub somesub: Abstract;

  package MyObj::Better;
  use base 'MyObj';
  sub somesub { return "I'm implemented!" }

=head1 DESCRIPTION

This attribute declares a subroutine to be abstract using this
attribute causes a call to it to die with a suitable
exception. Subclasses are expected to implement the abstract method.

Using the attribute makes it visually distinctive that a method is
abstract, as opposed to declaring it without any attribute or method
body, or providing a method body that might make it look as though
it was implemented after all.

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

perl(1), L<Attribute::Handlers>

=cut
