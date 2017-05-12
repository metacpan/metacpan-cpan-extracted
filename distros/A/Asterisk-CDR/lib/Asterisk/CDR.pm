package Asterisk::CDR;

use 5.008006;
#use strict; # Doesn't like constants below. Anybody know why?
use warnings;

use base Class::DBI;

our $VERSION = '0.01';

use constant DEFAULT_TABLE => 'cdr';
use constant DEFAULT_COLUMNS => ('calldate', 'clid', 'src', 'dst', 'dcontext', 'channel', 'dstchannel',
								 'lastapp', 'lastdata', 'duration', 'billsec', 'disposition', 'amaflags',
								 'accountcode', 'uniqueid', 'userfield');
sub init_db {

  my $class = shift;
  my $args = {@_};

  $class->connection($args->{dsn}, $args->{username}, $args->{password});
  $class->table($args->{table} || DEFAULT_TABLE);
  my @cols = @{$args->{columns}} or DEFAULT_COLUMNS;
  $class->columns(All => @cols);

}

1;

__END__

=head1 NAME

Asterisk::CDR - Perl extension for accessing Asterisk CDRs stored in a database as objects

=head1 SYNOPSIS

 use Asterisk::CDR;
 Asterisk::CDR->init_db(
                        dsn => 'dbi:mysql:database',
                        username => 'username',
                        password => 'password'
                       );
 my @cdrs = Asterisk::CDR->search(userfield => 'some data');

=head1 DESCRIPTION

Asterisk::CDR is a Perl module for accessing Asterisk CDRs stored in a dabatase as objects. It inherits all but one of its useful methods from Class::DBI.

Database information is supplied as a list to the B<init_db()> class method. A DBI data source string, username and password must be supplied. By default, Asterisk::CDR will use B<cdr> as the table and the standard columns expected by Asterisk's B<cdr_odbc> module. Both the table name and the columns can be overriden by specifiying them when calling B<init_db()>:

 use Asterisk::CDR;
 Asterisk::CDR->init_db (
                         dsn => 'dbi:mysql:database',
                         username => 'username',
                         password => 'password',
                         table => 'my_cdrs',
                         columns => \@my_columns
                        );

After B<init_db()> is called, Class::DBI methods may be called to retrieve CDRs as objects:

 my @cdrs = Asterisk::CDR->retrieve(src => '5555551212'); # Retrieve CDRs originating from 555-555-1212

=head1 SEE ALSO

L<Class::DBI>, Asterisk cdr odbc (L<http://www.voip-info.org/wiki/view/Asterisk+cdr+odbc>)

=head1 AUTHOR

Jason Bodnar, E<lt>jbodnar@gnumber.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Jason Bodnar, gNumber, Inc.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.


=cut
