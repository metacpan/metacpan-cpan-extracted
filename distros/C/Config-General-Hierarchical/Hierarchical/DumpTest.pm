# Config::General::Hierarchical::DumpTest.pm - Hierarchical Generic Config Dumper Test Module

package Config::General::Hierarchical::DumpTest;

$Config::General::Hierarchical::DumpTest::VERSION = 0.07;

use strict;
use warnings;

use base 'Config::General::Hierarchical::Dump';
use Config::General::Hierarchical::Test;

sub parser { return 'Config::General::Hierarchical::Test'; }

1;

__END__

=head1 NAME

Config::General::Hierarchical::DumpTest - Hierarchical Generic Config Dumper Test Module

=head1 DESCRIPTION

This module is used by L<Config::General::Hierarchical> tests.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2007-2009 Daniele Ricci

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

Daniele Ricci <icc |AT| cpan.org>

=head1 VERSION

0.07

=cut
