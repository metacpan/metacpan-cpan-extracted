#$Id: DBI.pm,v 1.19 2009/09/30 07:37:09 dinosau2 Exp $
# /* vim:et: set ts=4 sw=4 sts=4 tw=78: */

package ACME::QuoteDB::DB::DBI;
use base 'Class::DBI';

use 5.008005;        # require perl 5.8.5
                     # DBD::SQLite Unicode is not supported before 5.8.5
use warnings;
use strict;

#use criticism 'brutal'; # use critic with a ~/.perlcriticrc

use version; our $VERSION = qv('0.1.2');

use Readonly;
use File::Basename qw/dirname/;
use Carp qw/croak/;
use Cwd 'abs_path';
use File::Spec;

Readonly my $QUOTES_DATABASE => $ENV{ACME_QUOTEDB_PATH}
                                  || File::Spec->catfile(_untaint_db_path(),
                                                   q(quotedb), q(quotes.db)
                                     );

# set this to use a remote database
# i.e. mysql
Readonly my $REMOTE => $ENV{ACME_QUOTEDB_REMOTE};

# be more specific (or more general) this is mysql
# and 'remote' can be localhost
if ($REMOTE && $REMOTE ne 'mysql') {
      croak "mysql is the only remote database supported"
               ." set ENV{ACME_QUOTEDB_REMOTE} = 'mysql'";
}
elsif ($REMOTE && $REMOTE eq 'mysql') {

    my $database = $ENV{ACME_QUOTEDB_DB};
    my $host     = $ENV{ACME_QUOTEDB_HOST};
    my $user     = $ENV{ACME_QUOTEDB_USER};
    my $pass     = $ENV{ACME_QUOTEDB_PASS};

    ACME::QuoteDB::DB::DBI->connection(
           "DBI:mysql:database=$database;host=$host",$user,$pass,
               {
                   RaiseError        => 1,
                   mysql_enable_utf8 => 1,
               }
               
           )
      || croak "can not connect to: $database $!";
}
else {

  ACME::QuoteDB::DB::DBI->connection(
           'dbi:SQLite:dbname='.$QUOTES_DATABASE, '', '',
               {
                   RaiseError => 1,
                   unicode    => 1,
                   # func/pragma's may not work here,..(probably isnt' smart anyway)
                   #count_changes  => 0,
                   #temp_store     => 2,
                   #synchronous    => 'OFF',
                   #busy_timeout => 3600000
               }
           )
      || croak "$QUOTES_DATABASE does not exist, or cant be created $!";

      # how to enable this function?
      #ACME::QuoteDB::DB::DBI->set_sql(func( 3600000, 'busy_timeout' ); 
}


sub get_current_db_path {
    return $QUOTES_DATABASE;
}

sub _untaint_db_path {
    my $sane_path = abs_path(dirname(__FILE__));
    # appease taint mode, what a dir path looks like,... (probably not)
    $sane_path =~ m{([a-zA-Z0-9-_\.:\/\\\s]+)}; #add '.', ':' for win32
    return $1 || croak 'cannot untaint db path';
}


1;

__END__

=head1 NAME

ACME::QuoteDB::DB::DBI - DBI For ACME::QuoteDB

=head1 VERSION

Version 0.1.2


=head1 SYNOPSIS

This module is not meant to be used standalone it is used by C<ACME::QuoteDB>;

see L<ACME::QuoteDB>

=head1 DESCRIPTION

This module is not meant to be used standalone it is used by C<ACME::QuoteDB>;

see L<ACME::QuoteDB>

see L<Class::DBI>

=head1 OVERVIEW

see L<ACME::QuoteDB>

See L<Description|/Description> above

=head1 USAGE

See Synopsis

Also see t/01* included with the distribution.
(available from the CPAN if not included on your system)

=head1 SUBROUTINES/METHODS

see L<ACME::QuoteDB>


=head2 get_current_db_path

returns the path to our current database.
determined first by $ENV{ACME_QUOTEDB_PATH}
and next by the default system path to 'quotes.db'


=head1 DIAGNOSTICS

None currently known


=head1 CONFIGURATION AND ENVIRONMENT

By default, the quotes database used by this module installs in a system path,
which means you'll need to be root (sudo :) to load and modify it.

Alternativly, one can specify a location to a quotes database (file) to use.

Set the environmental variable:

$ENV{ACME_QUOTEDB_PATH} (untested on windows)

(this has to be set before trying a database load and also (everytime) before 
using this module, obviouly)

see L<ACME::QuoteDB>

and

see L<ACME::QuoteDB::LoadDB>


=head1 DEPENDENCIES

L<Readonly>

L<version>(pragma - version numbers)

L<File::Basename>

L<Class::DBI>

=head1 INCOMPATIBILITIES


none known of

=head1 SEE ALSO

L<ACME::QuoteDB>;

L<Class::DBI>;

=head1 AUTHOR

David Wright, C<< <david_v_wright at yahoo.com> >>

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to C<bug-acme-thesimpsonsquotes at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=ACME-QuoteDB>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc ACME::QuoteDB


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=ACME-QuoteDB>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/ACME-QuoteDB>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/ACME-QuoteDB>

=item * Search CPAN

L<http://search.cpan.org/dist/ACME-QuoteDB/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT


Copyright 2009 David Wright, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


