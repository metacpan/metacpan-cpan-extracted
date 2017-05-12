package Acme::Magpie::l33t;
use strict;
require Acme::Magpie;
use base qw(Acme::Magpie);

sub shiny {
    local ($_) = $_[1] =~ /.*::(.*)/;
    return tr/[0-9]// > tr/[a-z][A-Z]//;;
}
1;
__END__

=head1 NAME

Acme::Magpie::l33t - example child class of Acme::Magpie

=head1 SYNOPSIS

 use Acme::Magpie::l33t;

 sub f00 { print "we r00lz" };
 f00(); # program breaks

=head1 DESCRIPTION

This is an example of subclassing Acme::Magpie, and is so better
documented there.

=head1 SEE ALSO

L<Acme::Magpie>

=head1 AUTHOR

Richard Clamp E<lt>richardc@unixbeard.netE<gt>, original idea by Tom
Hukins

=head1 COPYRIGHT

       Copyright (C) 2002 Richard Clamp.
       All Rights Reserved.

       This module is free software; you can redistribute it
       and/or modify it under the same terms as Perl itself.

=cut
