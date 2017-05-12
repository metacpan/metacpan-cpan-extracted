package Attribute::Deprecated;

require v5.6;
use strict;
use warnings;
our $VERSION = '1.04';

use Attribute::Handlers;

my %done = ();

sub UNIVERSAL::Deprecated : ATTR(CODE) {
    my ($package, $symbol, $referent, $attr, $data) = @_;
    my $subname = $package . '::' . *{$symbol}{NAME};
    no warnings 'redefine';
    *{$symbol} = sub {
    	my ($cpack, $file, $line) = caller;
        unless ($done{"$file:$line"}++) {
    	    warn "call to deprecated routine '$subname' at $file line $line.\n";
        }
        goto &$referent;
    };
}

1;

__END__

=head1 NAME

Attribute::Deprecated - mark deprecated methods

=head1 SYNOPSIS

  package SomeObj;
  use Attribute::Deprecated;

  sub do_something_useful : Deprecated {
    ...
  }

=head1 DESCRIPTION

Mark your deprecated subroutines with this attribute and a warning will be
generated when the subroutine is called.  This can be used to weed out old code
that is calling the obsolete method but should be calling its replacement.  It's
a little bit easier, and more visually distinctive, to mark the method like this
that to insert explicit warnings.

=head1 AUTHOR

Marty Pauley E<lt>marty@kasei.comE<gt>,
based on code by Marcel GrE<uuml>nauer E<lt>marcel@codewerk.comE<gt>
and Damian Conway E<lt>damian@conway.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 2001  Kasei

This program is free software; you can redistribute it and/or modify it under
the terms of either:
a) the GNU General Public License as published by the Free Software Foundation;
   either version 2 of the License, or (at your option) any later version.
b) the Perl Artistic License.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.

=cut
