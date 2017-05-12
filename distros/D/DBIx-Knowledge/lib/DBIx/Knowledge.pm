#
# $Id: Knowledge.pm,v 1.1 2005/06/30 02:01:39 rsandberg Exp $
#


package DBIx::Knowledge;

use strict;
use Exporter;

use vars qw( $REPORT_TOTAL_KEY $VERSION );

$VERSION = '1.13';

$REPORT_TOTAL_KEY = 'REPORT_TOTAL';


our @EXPORT_OK = qw( $REPORT_TOTAL_KEY );

our @ISA = qw(Exporter);

=head1 NAME

DBIx::Knowledge - Report creation on linear convergent data sets for Business Intelligence

=head1 INTRODUCTION

DBIx::Knowledge gives analysts and non-engineers the ability to create reports and drill-down into
an aggregated data set (database table or view). Furthermore, the available fields and data points to choose
from can be configured without writing any code.

See SmartCruddy! for a quick-start and example implementation:

L<http://www.thesmbexchange.com/smartcruddy/index.html>

=cut

1;

__END__

=head1 SEE ALSO

L<DBIx::Knowledge::Report>, SmartCruddy! L<http://www.thesmbexchange.com/smartcruddy/index.html>, Cruddy! L<http://www.thesmbexchange.com/cruddy/index.html>

=head1 AUTHOR

Reed Sandberg, E<lt>reed_sandberg Ӓ yahooE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004-2008 Reed Sandberg

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

