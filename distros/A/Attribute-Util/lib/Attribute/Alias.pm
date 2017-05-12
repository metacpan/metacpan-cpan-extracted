package Attribute::Alias;

use warnings;
use strict;
use Attribute::Handlers;

our $VERSION = sprintf "%d.%02d", q$Revision: 1.2 $ =~ /(\d+)/g;

sub UNIVERSAL::Alias : ATTR {
	my ($pkg, $symbol, $data) = @_[0,1,4];
	no strict 'refs';
	*{"$pkg\::$_"} = $symbol for ref $data eq 'ARRAY' ? @$data : $data;
}

"Rosebud"; # for MARCEL's sake, not 1 -- dankogai

__END__

=head1 NAME

Attribute::Alias - An Alias attribute

=head1 SYNOPSIS

  use Attribute::Alias;

  sub color : Alias(colour) { return 'red' }

=head1 DESCRIPTION

If you need a variable or subroutine to be known by another name,
use this attribute. Internally, the attribute's handler assigns
typeglobs to each other. As such, the C<Alias> attribute provides
a layer of abstraction. If the underlying mechanism changes in a
future version of Perl (say, one that might not have the concept
of typeglobs anymore :), a new version of this module will take
care of that, but your C<Alias> declarations are going to stay the
same.

Note that assigning typeglobs means that you can't specify a synonym
for one element of the glob and use the same synonym for a different
target name in a different slot. I.e.,

  sub color :Alias(colour) { ... }
  my $farbe :Alias(colour);

doesn't make sense, since the sub declaration aliases the whole
C<colour> glob to C<color>, but then the scalar declaration aliases
the whole C<colour> glob to C<farbe>, so the first alias is lost.

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
