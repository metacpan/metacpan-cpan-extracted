package Class::DBI::Plugin::DateFormat::Oracle;

use strict;
use warnings;
use Carp;
use vars '$VERSION';

$VERSION = '0.01';

sub import {
    my $class = shift;
    my $pkg   = caller(0);

    no strict 'refs';
    *{"$pkg\::set_nls_date_format"} = sub {
        my $self   = shift;
        my $format = shift;

        eval {
            $pkg->db_Main->do(qq[ALTER SESSION SET NLS_DATE_FORMAT = '$format']);
        };
        $self->_croak("ALTER SESSION ERROR ".$@ ) if $@;
    };

    *{"$pkg\::get_nls_date_format"} = sub {
        my $self = shift;
        my $date_format;

        $self->set_sql(nls_date_format => q[SELECT VALUE FROM v$nls_parameters WHERE PARAMETER = 'NLS_DATE_FORMAT']);

        eval {
            $date_format = $self->search_nls_date_format->first->{value};
        };

        $self->_croak("SELECT NLS_DATE_FORMAT ERROR ".$@ ) if $@;
        return $date_format;
    }
}

1;
__END__

=head1 NAME

Class::DBI::Plugin::DateFormat::Oracle - Extension to Class::DBI for Oracle date fields.

=head1 VERSION

This documentation refers to Class::DBI::Plugin::DateFormat::Oracle version 0.01

=head1 SYNOPSIS

  package YourBase::CDBI;
  use base 'Class::DBI';
  __PACKAGE__->connection('dbi:Oracle:sid', user, pwd);
  __PACKAGE__->set_nls_date_format('YY/MM/DD HH24:MI:SS');
  $format = __PACKAGE__->get_nls_date_format;

=head1 DESCRIPTION

This module is Extension to Class::DBI for Oracle date fields.

=head1 METHOD

=head2 set_nls_date_format

  __PACKAGE__->set_nls_date_format('YY/MM/DD HH24:MI:SS');

This method sets Oracle date field's format.
This method execute "ALTER SESSION".

=head2 get_nls_date_format

  $format = __PACKAGE__->get_nls_date_format;

This method gets Oracle date field's format.

=head1 DEPENDENCIES

L<Class::DBI>

L<Carp>

=head1 SEE ALSO

L<Class::DBI>

L<Carp>

Class::DBI's Cookbook

http://cdbi.dcmanaged.com/wiki/Working_With_Oracle_Date_Fields

Refer to the Oracle documentation for valid date formats.

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.
Please report problems to Atsushi Kobayashi (E<lt>nekokak@cpan.orgE<gt>)
Patches are welcome.

=head1 AUTHOR

Atsushi Kobayashi, E<lt>nekokak@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Atsushi Kobayashi (E<lt>nekokak@cpan.orgE<gt>). All rights reserved.

This library is free software; you can redistribute it and/or modify it
 under the same terms as Perl itself. See L<perlartistic>.

=cut
