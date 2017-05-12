package App::FTNDB::Command::drop;
use App::FTNDB -command;

=head1 NAME

App::FTNDB::Command::drop - The drop command for Fidonet/FTN Database processing.

=head1 DESCRIPTION

Administration of a database for Fidonet/FTN related processing. The SQL
database engine is one for which a DBD module exists, defaulting to SQLite.

=head2 COMMANDS

=over

=item drop database name

C<ftndbadm -c config_file [options] drop database name>

This will drop a database if it exists in an SQL database server
being used for Fidonet/FTN processing, where I<name> is the name
of the database to be dropped.

=item drop table name

C<ftndbadm -c config_file [options] drop table name>

This will drop a database table if it exists in an SQL database
server being used for Fidonet/FTN processing, where I<name> is
the name of the table to be dropped.

=back

=head2 FUNCTIONS

=over

=item I<usage_desc>

Provides the command usage.

=cut

sub usage_desc { "ftndbadm %o database|table name" }

=item I<execute>

Execute the command

=cut

sub execute {
    my ($self, $opt, $args) = @_;

    print "The drop command is not yet implemented.\n";

}

=back

=head1 AUTHOR

Robert James Clay, C<< <jame at rocasa.us> >>

=head1 BUGS

Please report any bugs or feature requests via the web interface at
L<https://sourceforge.net/p/ftnpl/ftndb/tickets/>. I will be notified,
and then you'll automatically be notified of progress on your bug
as I make changes.

Note that you can also report any bugs or feature requests to
C<bug-ftndb at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-FTNDB>;
however, the FTN Database application  Issue tracker at the
SoureForge project is preferred.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::FTNDB::Command::drop

You can also look for information at:

=over 4

=item * FTN Database application issue tracker

L<https://sourceforge.net/p/ftnpl/ftndb/tickets/>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-FTNDB>

=item * Search CPAN

L<http://search.cpan.org/dist/App-FTNDB>

=back


=head1 SEE ALSO

 L<ftndbadm>, L<ftndb-admim>, L<ftndb-nodelist>, L<App::FTNDB>, L<App::FTNDB::Command::create>,
  L<FTN::Database>, L<FTN::Database::Nodelist>


=head1 COPYRIGHT & LICENSE

Copyright 2012-2013 Robert James Clay, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
