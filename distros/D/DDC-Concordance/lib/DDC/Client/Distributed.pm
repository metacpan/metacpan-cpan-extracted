#-*- Mode: CPerl -*-
##
## File: DDC::Client::Distributed.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description:
##  + DDC Query utilities: clients for distributed server
##    (since v0.41 just a dummy wrapper for DDC::Client)
##======================================================================

package DDC::Client::Distributed;
use DDC::Client;
use strict;
our @ISA = qw(DDC::Client);


1; ##-- be happy

__END__

##========================================================================
## NAME
=pod

=head1 NAME

DDC::Client::Distributed - compatibility alias for DDC::Client

=cut

##========================================================================
## DESCRIPTION
=pod

=head1 DESCRIPTION

As of DDC::Concordance v0.41,
the DDC::Client::Distributed class is just a wrapper for
L<DDC::Client|DDC::Client>, which see for details.

=cut

##======================================================================
## Footer
##======================================================================

=pod

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2018 by Bryan Jurish

This package is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.24.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
