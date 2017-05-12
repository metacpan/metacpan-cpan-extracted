package My::Employee;

use My::Table;

our @ISA = qw(My::Table);

=head1 USAGE

Please note that the table name, unless overridden, is the same as the
package name after the final ::'s.  For example, the table name for this
table is "Employee".  (Actually, table names aren't usually case sensitive,
so this automatically changes to "EMPLOYEE".)

=cut

sub data_order
{
    [
     {
         column => 'EMPNO',
         type   => 'CHAR',
         length => 6,
         opts   => 'NOT NULL',
         primary => 1,
     },
     {
         column => 'FIRSTNAME',
         type   => 'CHAR',
         length => 12,
         opts   => 'NOT NULL',
     },
     {
         column => 'MIDINIT',
         type   => 'CHAR',
     },
     {
         column => 'LASTNAME',
         type   => 'CHAR',
         length => 15,
         opts   => 'NOT NULL',
     },
     {
         column => 'SALARY',
         type   => 'DECIMAL',
         length => '8,2',
     },
    ];
}

1;
