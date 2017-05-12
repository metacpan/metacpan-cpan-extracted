#
# $Id: SQL.pm,v 1.1 2005/06/30 02:01:39 rsandberg Exp $
#


package DBIx::Knowledge::SQL;

use strict;

=head1 NAME

DBIx::Knowledge::SQL - SQL generator base class

=head1 DETAILS

Virtual base class to generate RDBMS-specific SQL
must override/implement C<sql_rollup()>.

=cut

sub new
{
    my ($caller) = @_;

    my $class = ref($caller) || $caller;
    my $obj = {};

    return bless($obj,$class);
}

# Must be overridden
sub sql_rollup
{
}

1;

__END__


=head1 SEE ALSO

L<DBIx::Knowledge::Report>, SmartCruddy! L<http://www.thesmbexchange.com/smartcruddy/index.html>

=head1 AUTHOR

Reed Sandberg, E<lt>reed_sandberg Ӓ yahooE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004-2008 Reed Sandberg

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

