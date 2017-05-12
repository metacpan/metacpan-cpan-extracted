package Attribute::SigHandler;

use warnings;
use strict;
use Attribute::Handlers;

our $VERSION = sprintf "%d.%02d", q$Revision: 1.2 $ =~ /(\d+)/g;

sub UNIVERSAL::SigHandler : ATTR(CODE) {
	my ($symbol, $data) = @_[1,4];
	$SIG{$_} = *{$symbol}{NAME} for ref $data eq 'ARRAY' ? @$data : $data;
}

"Rosebud"; # for MARCEL's sake, not 1 -- dankogai

__END__

=head1 NAME

Attribute::SigHandler - A Signal Handler Attribute

=head1 SYNOPSIS

  use Attribute::SigHandler;

  sub myalrm : SigHandler(ALRM, VTALRM) { ...  }
  sub mywarn : SigHandler(__WARN__) { ... }

=head1 DESCRIPTION

When used on a subroutine, this attribute declares that subroutine
to be a signal handler for the signal(s) given as options for this
attribute. It thereby frees you from the implementation details of
defining sig handlers and keeps the handler definitions where they
belong, namely with the handler subroutine.

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
