## no critic (RCS,VERSION)
package Class::User::DBI::UserDomains;

use strict;
use warnings;

use Carp;

use Class::User::DBI::DB qw( db_run_ex  %UD_QUERY );
use Class::User::DBI::Domains;

our $VERSION = '0.10';
# $VERSION = eval $VERSION;    ## no critic (eval)


# Class methods.

sub new {
    my ( $class, $conn, $userid ) = @_;
    croak 'Constructor called without a DBIx::Connector object.'
      if !ref $conn || !$conn->isa('DBIx::Connector');
    my $self = bless {}, $class;
    $self->{_db_conn} = $conn;
    croak 'Constructor called without passing a username.'
      if !defined $userid
          || !length $userid;
    my $u = Class::User::DBI->new( $self->_db_conn, $userid );
    croak 'Constructor called without passing a valid user by name.'
      if !$u->exists_user($userid);
    $self->{userid} = $userid;
    return $self;
}

sub configure_db {
    my ( $class, $conn ) = @_;
    croak 'Must provide a valid constructor object.'
      if !ref $conn || !$conn->isa('DBIx::Connector');
    $conn->run(
        fixup => sub {
            $_->do( $UD_QUERY{SQL_configure_db_cud_userdomains} );
        }
    );
    return 1;
}

# Object methods.

sub _db_conn {
    my $self = shift;
    return $self->{_db_conn};
}

sub get_userid {
    my $self = shift;
    return $self->{userid};
}

sub has_domain {
    my ( $self, $domain ) = @_;
    croak 'Must pass a defined value in domain test.'
      if !defined $domain;
    croak 'Must pass a non-empty value in privilege test.'
      if !length $domain;
    my $d = Class::User::DBI::Domains->new( $self->_db_conn );
    return 0
      if !$d->exists_domain($domain);
    return 1
      if exists $self->{domains}{$domain}
          && $self->{domains}{$domain};
    my $sth = db_run_ex( $self->_db_conn, $UD_QUERY{SQL_exists_domain},
        $self->get_userid, $domain );
    my $result = defined $sth->fetchrow_array;
    $self->{domains}{$domain}++ if $result;    # Cache the result.

    return $result;
}

# Usage:
# $r->add_domains( qw( domains ) );
# Returns the number of domains actually added to the role.

sub add_domains {
    my ( $self, @domains ) = @_;
    my $d                 = Class::User::DBI::Domains->new( $self->_db_conn );
    my @domains_to_insert = grep {
             defined $_
          && length $_
          && $d->exists_domain($_)
          && !$self->has_domain($_)
    } @domains;
    $self->{domains}{$_}++ for @domains_to_insert;    # Cache.
      # Transform the array of domains to an AoA of [ $userid, $domain ] packets.
    @domains_to_insert =
      map { [ $self->get_userid, $_ ] } @domains_to_insert;
    return 0 if !scalar @domains_to_insert;
    my $sth = db_run_ex( $self->_db_conn, $UD_QUERY{SQL_add_domain},
        @domains_to_insert );
    return scalar @domains_to_insert;
}

# Deletes all domains in @domains (if they exist).
# Silent if non-existent. Returns the number of roles actually deleted.
sub delete_domains {
    my ( $self, @domains ) = @_;
    my @domains_to_delete;
    foreach my $domain (@domains) {
        next
          if !defined $domain
              || !length $domain
              || !$self->has_domain($domain);
        push @domains_to_delete, [ $self->get_userid, $domain ];
        delete $self->{domains}{$domain};    # Remove from cache.
    }
    my $sth = db_run_ex( $self->_db_conn, $UD_QUERY{SQL_delete_domains},
        @domains_to_delete );
    return scalar @domains_to_delete;
}

# Returns a list of priviliges for this object's target user.
sub fetch_domains {
    my $self = shift;
    my $sth  = db_run_ex( $self->_db_conn, $UD_QUERY{SQL_list_domains},
        $self->get_userid );
    my @domains = map { $_->[0] } @{ $sth->fetchall_arrayref };
    $self->{domains} = {    # Construct an anonymous hash.
        map { $_ => 1 } @domains
    };    # Refresh the cache.
    return @domains;
}

1;

__END__

=head1 NAME

Class::User::DBI::UserDomains - A user user domains class.

=head1 VERSION

Version 0.10

=head1 SYNOPSIS

Through a DBIx::Connector object, this module models a class of domains
belonging to a user.

    # Set up a connection using DBIx::Connector:
    # MySQL database settings:

    my $conn = DBIx::Connector->new(
        'dbi:mysql:database=cudbi_tests, 'testing_user', 'testers_pass',
        {
            RaiseError => 1,
            AutoCommit => 1,
        }
    );


    # Now we can play with Class::User::DBI::UserDomains

    # Set up a 'user-domains' table in the database.
    Class::User::DBI::UserDomains->configure_db( $conn );
    
    # Instantiate a UserDomains object so we can play with it.
    my $ud = Class::User::DBI::Domains->new( $conn, 'userid' );

    $ud->add_domains( 'Treasure Island', 'Nimh' ); # This user works with TI and Nimh.

    print "This user works with Nimh.\n" if $ud->has_domain( 'Nimh' );

    my @domains = $ud->fetch_domains;
    foreach my $domain ( @domains ) {
        print "This user works with $domain\n";
    }
    
    $ud->delete_domains( 'Treasure Island' ); # Pass a list for multiple deletes.


=head1 DESCRIPTION

This is a maintenance class facilitating the creation, deletion, and testing of
domains belonging to a user.

Before a domain may be granted to a user with this class, you need to create a
domain entry using L<Class::User::DBI::Domains>.  That class manages domains 
and their description.  I<This> class grants those domains to a user.  Please
refer to the documentation for L<Class::User::DBI::Domains> to familiarize
yourself with adding domains to the system.

A common usage is to configure a 'cud_userdomains' database table, and then 
add one or more user => domain pairs.  Domains are locality jurisdictions that a
given user may have.  Using C<Class::User::DBI> you have set up
a set of users.  Using C<Class::User::DBI::Domains> you have set up a list of
domains and their descriptions.  Now this class allows you to assign one or more
of those domains to a user.

Finally, the user object may be queried to determine if a user has a given
domain.

Domains are intended to be used independently of Roles and Privileges.  The idea
is that a user has a Role which gives him Privileges that may be exercised within
his domain.  But at the lowest level, a domain is just another set of flags that
a user may hold, which can be used any way you want.  I tend to think of them as
constraints on where a privilege may be applied.

An example is that a user who has a 'sales' role might have a 'sales reports'
privilege.  But the 'West Coast' domain could be used to constrain this user to
only manipulating sales reporting that pertains to the West Coast locality.

On the other hand, another user is a sales manager, and has both the West Coast
and the East Coast under her jurisdiction.  Her 'manager' role may still give
her the 'sales reports' privilege, but she will have two domains: West Coast and
East Coast, thereby having access to sales reports resources for both of those
domains.

=head1 EXPORT

Nothing is exported.  There are many object methods, and three class methods,
described in the next section.


=head1 SUBROUTINES/METHODS


=head2  new
(The constructor -- Class method.)

    my $user_domain_obj = Class::User::DBI::UserDomains->new( $connector, $role );

Creates a user-domains object that can be manipulated to set and get 
domains for the instantiated user.  These user/domain pairs will be stored
in a database table named C<cud_userdomains>.  Throws an exception if it 
doesn't get a valid DBIx::Connector or a valid userid (where valid means the
userid exists in the C<users> table managed by C<Class::User::DBI>.

=head2  configure_db
(Class method)

    Class::User::DBI::UserDomains->configure_db( $connector );

This is a class method.  Pass a valid DBIx::Connector as a parameter.  Builds
a minimal database table in support of the Class::User::DBI::UserDomains class.

The table created will be C<cud_userdomains>.

=head2 add_domains

    $ud->add_domains( 'Mississippi', 'Milwaukee', ... );

Add one or more domains.  Each domain must match a domain that lives in
the C<domains> database, managed by C<Class::User::DBI::Domains>.

It will drop requests to add domains that already exist for a given user.

Returns a count of domains added, which may be less than the number passed if 
one already existed.

=head2 delete_domains

    $ud->delete_domains( 'California', 'Florida' ); # No more sunny beaches.

Deletes from the user all domains specified.  Return value is the number 
of domains actually deleted, which may be less than the number of domains
requested if any of the requested domains don't exist for the object's target
user.


=head2 has_domain

    print "This user gets to enjoy the surf." 
        if $ud->has_domain( 'Hawaii' );

Returns true if a given domain exists for the object's target user, and 
false if not.

=head2 fetch_domains

    foreach my $domain ( $ud->fetch_domains ) {
        print "This user works with $domain\n";
    }
    
Returns a list of domains belonging to the object's target user.

An empty list means there are no domains defined for this user.

=head2 get_userid

    my $userid = $ud->get_userid;

Just an accessor for reading the object's target user ID.


=head1 DEPENDENCIES

The dependencies for this module are the same as for L<Class::User::DBI>, from
this same distribution.  Refer to the documentation in that module for a full
description.


=head1 CONFIGURATION AND ENVIRONMENT

Please refer to the C<configure_db()> class method for this module for a
simple means of creating the table that supports this class.

All SQL for this distribution is contained in the L<Class::User::DBI::DB> 
module.


=head1 DIAGNOSTICS

If you find that your particular database engine is not playing nicely with the
test suite from this module, it may be necessary to provide the database login 
credentials for a test database using the same engine that your application 
will actually be using.  You may do this by setting C<$ENV{CUDBI_TEST_DSN}>,
C<$ENV{CUDBI_TEST_DATABASE}>, C<$ENV{CUDBI_TEST_USER}>, 
and C<$ENV{CUDBI_TEST_PASS}>.

Currently the test suite tests against a SQLite database since it's such a
lightweight dependency for the testing.  The author also uses this module
with several MySQL databases.  As you're configuring your database, providing
its credentials to the tests and running the test scripts will offer really 
good diagnostics if some aspect of your database tables proves to be at odds 
with what this module needs.


=head1 INCOMPATIBILITIES

This module has only been tested on MySQL and SQLite database engines.  If you
are successful in using it with other engines, please send me an email detailing
any additional configuration changes you had to make so that I can document
the compatibility, and improve the documentation for the configuration process.

=head1 BUGS AND LIMITATIONS

Let me know if you find any!  

=head1 AUTHOR


David Oswald, C<< <davido at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-class-user-dbi at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Class-User-DBI>.  I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Class::User::DBI::UserDomains


You can also look for information at:

=over 4

=item * Class-User-DBI on Github

L<https://github.com/daoswald/Class-User-DBI.git>

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Class-User-DBI>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Class-User-DBI>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Class-User-DBI>

=item * Search CPAN

L<http://search.cpan.org/dist/Class-User-DBI/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 David Oswald.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
