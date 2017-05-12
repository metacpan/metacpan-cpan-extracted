package CGI::Session::Driver::flexmysql;

use strict;
use DBI;
use Carp;
use CGI::Session::Driver;
@CGI::Session::Driver::flexmysql::ISA       = qw( CGI::Session::Driver );
$CGI::Session::Driver::flexmysql::VERSION   = "0.2.04";

########################
# Driver methods follow
########################

sub init {
	my $self = shift;

    $self->{MySQL_dbh} = $self->{Handle} || DBI->connect(
                    $self->{DataSource},
                    $self->{User}       || undef,
                    $self->{Password}   || undef,
                    { RaiseError=>1, PrintError=>1, AutoCommit=>1 } );

    # If we established the connection, we should close it
    $self->{MySQL_disconnect} = 1 unless $self->{Handle};
    $self->{MySQL_disconnect} = $self->{AutoDisconnect} if defined $self->{AutoDisconnect};

    # Table setup options
    $self->{MySQL_table} = $self->{Table} || 'sessions';
    $self->{MySQL_keyfield} = $self->{KeyField} || 'id';
    $self->{MySQL_datafield} = $self->{DataField} || 'a_session';

	return 1;
}


# stores the serialized data. Returns 1 for sucess, undef otherwisefield);
sub store {
    my ($self, $sid, $data) = @_;   

    my $dbh = $self->{MySQL_dbh};
    my $table = $self->{MySQL_table};
    my $keyfield = $self->{MySQL_keyfield};
    my $datafield = $self->{MySQL_datafield};

    my ($ok,$exhausted) = (0,0);
    local $dbh->{RaiseError} = 0;
    local $dbh->{PrintError} = 0;
    do {
		eval {
			if( $self->{NoInsert} ) {
				$dbh->do(qq|UPDATE $table SET $datafield=? WHERE $keyfield=?|,
					undef, $data, $sid) || die $dbh->errstr,"\n"; # croak ref($dbh)," do failed: ",$dbh->errstr;
			}
			elsif( $self->{NoReplace} ) {
				my $rows = $dbh->do(qq|UPDATE $table SET $datafield=? WHERE $keyfield=?|,
					undef, $data, $sid) || die $dbh->errstr,"\n"; # croak ref($dbh)," do failed: ",$dbh->errstr;
				if( $rows == 0 ) {
					$dbh->do(qq|INSERT INTO $table ($keyfield,$datafield) VALUES(?,?)|, 
						undef, $sid, $data) || die $dbh->errstr,"\n"; # croak ref($dbh)," do failed: ",$dbh->errstr;
				}
			}
			else {
				$dbh->do(qq|REPLACE INTO $table ($keyfield,$datafield) VALUES(?,?)|, 
					undef, $sid, $data) || die $dbh->errstr,"\n"; # croak ref($dbh)," do failed: ",$dbh->errstr;
			}
			$ok = 1;
		};
      if( $@ && $@ =~ m/Table '(.+)' doesn't exist/ && $self->{AutoCreate} ) {
           $exhausted = 1;
           $dbh->do("CREATE TABLE $table ($keyfield VARCHAR(32) NOT NULL PRIMARY KEY, $datafield TEXT NULL)") &&
              carp __PACKAGE__," issued CREATE TABLE $table ($keyfield VARCHAR(32) NOT NULL PRIMARY KEY, $datafield TEXT NULL)";
			$dbh->do(qq|INSERT INTO $table ($keyfield,$datafield) VALUES(?,?)|, 
				undef, $sid, $data) || die $dbh->errstr,"\n"; # croak ref($dbh)," do failed: ",$dbh->errstr;
      }
      elsif( $@ ) {
           $exhausted = 1;
           croak __PACKAGE__," store failed: ",$@;
      }
    } until $ok || $exhausted;
    
    return 1;
}



# retrieves the serialized data and deserializes it
sub retrieve {
    my ($self, $sid) = @_;
    
    my $dbh = $self->{MySQL_dbh};
    my $table = $self->{MySQL_table};
    my $keyfield = $self->{MySQL_keyfield};
    my $datafield = $self->{MySQL_datafield};

    my $data = $dbh->selectrow_array(qq|SELECT $datafield FROM $table WHERE $keyfield=?|, undef, $sid);
    $data ||= "";  # in case it was NULL
    return $data;
}


# removes the given data and all the disk space associated with it
sub remove {
    my ($self, $sid) = @_;

    my $dbh = $self->{MySQL_dbh};
    my $table = $self->{MySQL_table};
    my $keyfield = $self->{MySQL_keyfield};
    my $datafield = $self->{MySQL_datafield};

	if( $self->{NoDelete} ) {
		$dbh->do(qq|UPDATE $table SET $datafield=NULL WHERE $keyfield=?|,
		undef, $sid);
	}
	else {
    		$dbh->do(qq|DELETE FROM $table WHERE $keyfield=?|, undef, $sid);
	}
    
    return 1;    
}


sub traverse {
	my ($self,$coderef) = @_;
	# not implemented yet
	return 1;
}


# called right before the object is destroyed to do cleanup
sub DESTROY {
    my ($self) = @_;
    my $dbh = $self->{MySQL_dbh};

    # Call commit if it isn't meant to be autocommited!
    unless ( $dbh->{AutoCommit}  ) {
        $dbh->commit();
    }
    
    if ( $self->{MySQL_disconnect} ) {
        $dbh->disconnect();
    }

    return 1;
}





1;       


=pod

=head1 NAME

CGI::Session::Driver::flexmysql - flexible MySQL driver for  CGI::Session

=head1 SYNOPSIS
    
    use CGI::Session;
    
    # use the default setup, compatible with Apache::Session
    # (table 'sessions', primary key 'id', data field 'a_session')

    $session = new CGI::Session("driver:flexmysql", undef, {Handle=>$dbh});

    # or specify a custom table setup for your sessions:

    $session = new CGI::Session("driver:flexmysql", undef, {
       Handle => $dbh,             # Or use DataSource / User / Password
       Table => 'custom_table',    # You can put your sessions in any table
       KeyField => 'id',           # and any field for your session ids
       DataField => 'a_session',   # and any field for your session data
       AutoCreate => 1,            # even if it doesn't exist yet!
    });
    
For more options and examples, read the rest of this document and
consult L<CGI::Session>.

=head1 DESCRIPTION

FlexMySQL is a CGI::Session driver to store session data in MySQL table.

It differs from the original mysql driver in several ways:

=over

=item 1.

FlexMySQL lets you completely customize your table setup each time you create
a new session object. No more setting a class variable for the table name,
and also no more agonizing about not liking the default field names.

=item 2.

FlexMySQL gives you control over inserting and deleting rows -- so you can 
ensure that only existing table rows are used for storing sessions,
if you're into that sort of thing.

=item 3.

FlexMySQL does not misuse the MySQL locking facility.  Read "LOCKING" below.

=item 4.

FlexMySQL lets you supply an open database handle and then forget about it
using the AutoDisconnect feature.

=back

To write your own drivers for B<CGI::Session>, refer to L<CGI::Session>.

=head1 STORAGE

To store session data in MySQL database, you first need to create or select
a table for it.  If you don't already have a table for sessions, it's easiest
to use the default setup and create a table with the following command:

    CREATE TABLE sessions (
        id CHAR(32) NOT NULL PRIMARY KEY,
        a_session TEXT NOT NULL
    );

You can also add any number of additional columns to the table, but the above "id"
and "a_session" are required (unless you specify other field names with options to C<new>). 

=head1 OPTIONS

You can specify several options to C<new> to change the way FlexMySQL interacts
with your database.

Here is the basic session creation statement:

    $session = new CGI::Session("driver:flexmysql", undef, $options);

Where C<$options> is a hash reference. C<$options> can include:

=head2 Handle => $dbh

An open database handle. Useful if you already have one handy.  FlexMySQL will
not disconnect your handle unless you ask it to do so, so you can safely use it
elsewhere at the same time.

=head2 DataSource => $dbi_data_source

If you don't have an open database handle and don't feel like making one, you can
use this parameter to have FlexMySQL automatically connect for you.  The
C<$dbi_data_source> is what goes in this statement:

DBI->connect( $dbi_data_source );

See L<DBI>  for details. C<$dbi_data_source> could look like "dbi:MySQL:your_db_name".

=head2 User => $dbi_username

Unless you're in configuration paradise, you'll probably need a username to connect
to your database. Specify C<$dbi_username> as if you're making this statement:

DBI->connect( $dbi_data_source, $dbi_username );

=head2 Password => $dbi_password

Again, this is optional.  Use it as if you're making this statement:

DBI->connect( $dbi_data_source, $dbi_username, $dbi_password );

=head2 Table => $session_table

If you don't specify a table, FlexMySQL will try to use a table named 'sessions'
by default. This makes it compatible with L<Apache::Session>.

This option is useful when other apps are using the session table and it's
not named 'sessions'.

=head2 KeyField => $unique_key

If you don't specify a field name to use as the unique key for session ids, 
FlexMySQL will try to use a field named 'id'.  This makes it compatible with
L<Apache::Session>.   

A situation where I use this option is when I use the same table for user info
and sessions.   This makes it easy to find problems that my users are having
because the session is right there on the same row as their other info. I often
use their email address as login names, so my setting looks like:

   Table => 'Member',
   KeyField => 'Email',

=head2 DataField => $field_name

If you don't specify a field name to use for data storage, FlexMySQL will try
to use a field name 'a_session'.  This makes it compatible with L<Apache::Session>.

Few apps use a field named 'a_session', so I usually don't have to mess with this,
but it's here for your configuration pleasure.

=head2 AutoDisconnect => 1

If you don't specify AutoDisconnect at all, or specify undef, then the default
behavior is polite:   if you gave an open database handle with Handle => $dbh,
we leave it open, and if you let FlexMySQL open its own handle by specifying
connection parameters, then we also close it for you.  

You can override this behavior and have the handle disconnected no matter what
by using AutoDisconnect => 1

If you specify a 0 (as opposed to undef or not at all), then FlexMySQL will 
leave the database handle OPEN no matter what (even if it created it).
There aren't many cases where you'll want to use this, but it's here if you want it. 

=head2 NoInsert => 1

This option prevents FlexMySQL from inserting new rows into your session table.
At first glance, this may seem a bit stupid because it would prevent you from
storing any sessions at all --  but I have a use for it, so it's here for you too.

I often store sessions directly on my user table to make sure that when a user
logs in, s/he can always pick up where s/he left off even if logging in from
a different browser, after erasing cookies, etc.  I do this by specifying the 
Table and KeyField options.  Since the user table already has one row for each
user, and since I use the email address of the user as the KeyField, I do NOT
want FlexMySQL to create new rows in my user table and put some random MD5 string
as the email address.  So I specify:

   NoInsert => 1

And this makes FlexMySQL use an UPDATE statement instead of a REPLACE INTO statement,
which guarantees that if the claimed session id doesn't exist in the table, it
won't be created.

=head2 NoDelete => 1

Same scenario as above -- for most applications where you're generating random
session ids and inserting rows into a table, you don't want this option because
it means that you can't delete sessions except with an external script.

However, I have a use for it:  if I call  $session->delete() I want it to delete
the session, but since my sessions are often stored in my user table, I do NOT
want it to delete the entire row!   Using this option effectively makes C<delete>
the same as C<clear> (well, almost)  because when you specify NoDelete => 1, FlexMySQL
updates the database field and sets it to NULL, whereas with C<clear> all the
session fields are cleared but the session object itself is still stored in your
table's data field).

=head2 NoReplace => 1

Use this option when you want to use INSERT and UPDATE statements instead of a
REPLACE statement to store sessions.

Thanks to Simon Rees for suggesting this option. 

=head2 AutoCreate => 1

If you specify this option, FlexMySQL will automatically create a table for 
session storage if one does not already exist. If you specified any customization
such as table name, key field, etc.  it is used to create the table.  

=head1 LOCKING

GET_LOCK and RELEASE_LOCK work on a server-wide basis. If we acquire
a lock on some 32-character id for the purpose of sessions, no other
application can use locking with 32-character id's generated in the
same way (MD5) because there might be a very accidental overlap, which
could really screw things up depending on what that other application
is doing. In general, session data is not important and we can assume
all other applications should have priority with regard to everything.
Also, even though CGI::Session::MySQL obtains the locks, it would still
overwrite the data as soon as the "other thread" releases its lock,
which means that if two clients are using the same session id, the
locking gives absolutely no protection. MySQL already guranatees that
data is not corrupted when we update the same row from different
places at nearly the same time because it uses a queue for the requests.
It would be different if, once it detected that there is a lock, it
read the data again and SYNCHRONIZED it before updating. Then locking
would be helpful because no other client could synchronize at the same
time. But CGI::Session::MySQL doesn't actually do anything that requires
locking. 

A real use for locking would be to actually lock the session data while
the it's being used.  GET_LOCK and RELEASE_LOCK are usually not the
appropriate way to do this, especially for non-cgi applications where
the session may be in use for a considerable amount of time. I propose
that this locking be done using an extra field. GET_LOCK and RELEASE_LOCK
would be appropriate for locking the row while this extra locking field
is being checked and updated, and then this extra locking field would 
tell other processes using FlexMySQL whether they can read or write the
session data. 

Right now I don't have a need for this kind of locking, so it's not
implemented.  If you want it, you can either send me a patch or roll your
own CGI::Session subclass. Asking me very nicely will also work.

=head1 COPYRIGHT

CGI::Session::Driver::flexmysql is Copyright (C) 2004-2005 Jonathan Buhacoff.  All rights reserved.

This library is free software and can be modified and distributed under the same
terms as Perl itself. 


=head1 AUTHOR

Jonathan Buhacoff <jonathan@buhacoff.net> wrote CGI::Session::Driver::flexmysql

=head1 SEE ALSO

=over 4

=item *

L<CGI::Session::Driver::mysql|CGI::Session::Driver::mysql> - The original MySQL driver for CGI::Session
written by Sherzod Ruzmetov <sherzodr@cpan.org>. Kudos
to Sherzod for making such a great session management framework.

=item *

L<CGI::Session|CGI::Session> - CGI::Session manual

=item *

L<CGI::Session::Tutorial|CGI::Session::Tutorial> - extended CGI::Session manual

=item *

L<CGI::Session::CookBook|CGI::Session::CookBook> - practical solutions for real life problems

=item *

B<RFC 2965> - "HTTP State Management Mechanism" found at ftp://ftp.isi.edu/in-notes/rfc2965.txt

=item *

L<CGI|CGI> - standard CGI library

=item *

L<Apache::Session|Apache::Session> - an alternative to CGI::Session

=back

=cut
