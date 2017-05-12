package Attribute::Util;

use warnings;
use strict;
use Attribute::Handlers;
use Carp ();

our $VERSION = sprintf "%d.%02d", q$Revision: 1.7 $ =~ /(\d+)/g;
our @DEFAULT_ATTRIBUTES = qw(Abstract Alias Memoize Method SigHandler);

sub import{
    my $pkg = shift;
    my @attrs = @_ ? @_ : @DEFAULT_ATTRIBUTES;
    for my $attr (@attrs){
	eval qq{ require Attribute::$attr; };
	$@ and Carp::croak $@;
	# import is not neccessary for Attribute modules.
    }
}

"Rosebud"; # for MARCEL's sake, not 1 -- dankogai

__END__

=head1 NAME

Attribute::Util - Assorted general utility attributes

=head1 SYNOPSIS

  # makes all attributes available
  use  Attribute::Util;

  # or you can load individual attributes 
  use Attribute::Util qw(Memoize SigHandler);

=head1 DESCRIPTION

When used without argument, this module provides four universally
accessible attributes of general interest as follows:

=over 4

=item Abstract

See L<Attribute::Abstract>.

=item Alias

See L<Attribute::Alias>.

=item Memoize

See L<Attribute::Memoize>.

=item Method

See L<Attribute::Method>.

=item SigHandler

See L<Attribute::SigHandler>.

=back

When used with arguments, this module acts as an attributes loader.

  use Attribute::Util qw/Memoize SigHandler/;

Is exactly the same as

  use Attribute::Memoize; use Attribute::SigHandler;

Theoretically, you can load any other attribute handlers so long as it
is named I<Attribute::AnyThing>.

=head1 BUGS

None known so far. If you find any bugs or oddities, please do inform
the author.

=head1 AUTHOR

Marcel Grunauer, <marcel@codewerk.com>

Dan Kogai, C<< <dankogai+cpan at gmail.com> >>

=head1 COPYRIGHT

Copyright 2001 Marcel Grunauer. All rights reserved.

Copyright 2006 Dan Kogai. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

perl(1), L<Attribute::Handlers>

=cut
