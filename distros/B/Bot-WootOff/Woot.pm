###########################################
###########################################
package Bot::Woot;
###########################################
###########################################
use strict;
use warnings;
our @ISA = qw(Bot::WootOff);

1;

__END__

=head1 NAME

Bot::Woot - Poll woot.com propagate changes to an IRC channel

=head1 SYNOPSIS

    # See SYNOPSIS in the Bot::WootOff documentation.

=head1 DESCRIPTION

Please read the main documentation in Bot::WootOff.

Bot::Woot is just a subclass of Bot::WootOff, for the sole purpose of
helping the confused search.cpan.org search engine to find Bot::WootOff
if someone searches for "woot".

=head1 LEGALESE

Copyright 2009 by Mike Schilli, all rights reserved.
This program is free software, you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

2009, Mike Schilli <cpan@perlmeister.com>
