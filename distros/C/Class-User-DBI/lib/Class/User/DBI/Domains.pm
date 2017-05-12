## no critic (RCS,VERSION)
package Class::User::DBI::Domains;

use strict;
use warnings;

use Carp;

use Class::User::DBI::DB qw( db_run_ex  %DOM_QUERY );

our $VERSION = '0.10';
# $VERSION = eval $VERSION;    ## no critic (eval)

# Class methods.

sub new {
    my ( $class, $conn ) = @_;
    my $self = bless {}, $class;
    croak 'Constructor called without a DBIx::Connector object.'
      if !ref $conn || !$conn->isa('DBIx::Connector');
    $self->{_db_conn} = $conn;
    $self->{domains}  = {};
    return $self;
}

sub configure_db {
    my ( $class, $conn ) = @_;
    croak 'Must provide a valid constructor object.'
      if !ref $conn || !$conn->isa('DBIx::Connector');
    $conn->run(
        fixup => sub {
            $_->do( $DOM_QUERY{SQL_configure_db_cud_domains} );
        }
    );
    return 1;
}

# Object methods.

sub _db_conn {
    my $self = shift;
    return $self->{_db_conn};
}

# Usage:
# $dom->exists_domain( $domain );
# returns 0 or 1.
sub exists_domain {
    my ( $self, $domain ) = @_;
    croak 'Must pass a defined value in domain test.'
      if !defined $domain;
    croak 'Must pass a non-empty value in domain test.'
      if !length $domain;
    return 1 if exists $self->{domains}{$domain};
    my $sth =
      db_run_ex( $self->_db_conn, $DOM_QUERY{SQL_exists_domain}, $domain );
    my $result = defined $sth->fetchrow_array;
    $self->{domains}{$domain}++ if $result;    # Cache the result.
    return $result;
}

# Usage:
# $dom->add_domains( [ qw( domain description ) ], [...] );
# Returns the number of domains actually added.

sub add_domains {
    my ( $self, @domains ) = @_;
    my @domains_to_insert =
      grep { ref $_ eq 'ARRAY' && $_->[0] && !$self->exists_domain( $_->[0] ) }
      @domains;

    # Set undefined descriptions to q{}.
    foreach my $dom_bundle (@domains_to_insert) {

        # This change is intended to propagate back to @domains_to_insert.
        $dom_bundle->[1] = q{} if !$dom_bundle->[1];
    }
    my $sth = db_run_ex( $self->_db_conn, $DOM_QUERY{SQL_add_domains},
        @domains_to_insert );
    return scalar @domains_to_insert;
}

# Deletes all domains in @domains (if they exist).
# Silent if non-existent. Returns the number of domains actually deleted.
sub delete_domains {
    my ( $self, @domains ) = @_;
    my @domains_to_delete;
    foreach my $domain (@domains) {
        next if !$domain || !$self->exists_domain($domain);
        push @domains_to_delete, [$domain];
        delete $self->{domains}{$domain};    # Remove it from the cache too.
    }
    my $sth = db_run_ex( $self->_db_conn, $DOM_QUERY{SQL_delete_domains},
        @domains_to_delete );
    return scalar @domains_to_delete;
}

# Gets the description for a single domain.  Must specify a valid domain.
sub get_domain_description {
    my ( $self, $domain ) = @_;
    croak 'Must specify a domain.'
      if !defined $domain;
    croak 'Specified domain must exist.'
      if !$self->exists_domain($domain);
    my $sth =
      db_run_ex( $self->_db_conn, $DOM_QUERY{SQL_get_domain_description},
        $domain );
    return ( $sth->fetchrow_array )[0];
}

# Pass a domain and a new description.  All parameters required.  Description
# of q{} deletes the description.
sub set_domain_description {
    my ( $self, $domain, $description ) = @_;
    croak 'Must specify a domain.'
      if !defined $domain;
    croak 'Specified domain doesn\'t exist.'
      if !$self->exists_domain($domain);
    croak 'Must specify a description (q{} is ok too).'
      if !defined $description;
    my $sth =
      db_run_ex( $self->_db_conn, $DOM_QUERY{SQL_set_domain_description},
        $description, $domain );
    return 1;
}

# Returns an array of pairs (AoA).  Pairs are [ domain, description ],...
sub fetch_domains {
    my $self    = shift;
    my $sth     = db_run_ex( $self->_db_conn, $DOM_QUERY{SQL_list_domains} );
    my @domains = @{ $sth->fetchall_arrayref };
    return @domains;
}

1;

__END__

=head1 NAME

Class::User::DBI::Domains - A Domains class.

=head1 VERSION

Version 0.10

=head1 SYNOPSIS

Through a DBIx::Connector object, this module models a "Domains" class, used 
for Roles Based Access Control.  

    # Set up a connection using DBIx::Connector:
    # MySQL database settings:

    my $conn = DBIx::Connector->new(
        'dbi:mysql:database=cudbi_tests, 'testing_user', 'testers_pass',
        {
            RaiseError => 1,
            AutoCommit => 1,
        }
    );


    # Now we can play with Class::User::DBI::Domains

    # Set up a 'domains' table in the database.
    Class::User::DBI::Roles->configure_db( $conn );
    
    my $d = Class::User::DBI::Domains->new( $conn );

    $p->add_domains( 
        [ 'portland',    'Portland, Oregon location'       ],
        [ 'los angeles', 'Los Angeles, California location' ],
    );

    print "Domain exists." if $p->exists_domain( 'Los Angeles' );

    my @domains = $p->fetch_domains;
    foreach my $domain ( @domains ) {
        my( $name, $description ) = @{$domain};
        print "$name => $description\n";
    }

    print "Description for 'Portland' domain: ", 
          $d->get_domain_description( 'Portland' );
    
    $d->set_domain_description( 'Portland', 'Portland, Maine location' );
    
    $d->delete_domains( 'Portland' ); # Pass a list for multiple deletes.


=head1 DESCRIPTION

This is a maintenance class facilitating the creation, deletion, and testing of
domains that are compatible with Class::User::DBI::UserDomains.

With Class::User::DBI each user may have multiple domains (handled by
C<Class::User::DBI::UserDomains>, and testable through either that module or
C<Class::User::DBI>).  An example of how a domain might be used: User 'john' has 
the "downtown" domain.  'karen' has the east-side domain.  'nancy' is a manager 
responsible for both downtown and the east-side, so nancy has both domains.

Domains are completely independent of roles and privileges.  They allow for a
separate layer of granularity for access control.  The layer may be used for 
location based access control, jurisdiction/stewardship access control... 
whatever.  It's just another set of constraints that can operate independently 
of roles and privileges.

A common usage is to configure a database table, and then add a few locations
(domains) along with their descriptions.  Next add one or more locations (or
domains) to a user's domain set through Class::User::DBI::UserDomains.  Finally,
test your Class::User::DBI object to see if the user owned by a given object 
belongs to a given domain.

Think of domains as a locality.  In the context of Class::User::DBI, a user may 
have a role which has privileges. And those privileges may be used within any 
of the user's domains or localities. That a "west coast" domain user who has 
the "sales" role might gain access only to "west coast" sales figures, while 
the user with an "east coast" domain who also has a "sales" role (with all the 
same privileges) may only gain access to east coast sales figures.  Of course 
the domain(s) are just flags or attributes, similar to roles and privileges, 
but independent of the roles/privileges structure.  What you do with these 
attributes is up to you.  I like to use them to represent literal locations
where a user my exercise the privileges granted by his role.

=head1 EXPORT

Nothing is exported.  There are many object methods, and three class methods,
described in the next section.


=head1 SUBROUTINES/METHODS


=head2  new
(The constructor -- Class method.)

    my $domain_obj = Class::User::DBI::Domains->new( $connector );

Creates a domain object that can be manipulated to set and get roles from 
the database's 'cud_domains' table.  Pass a DBIx::Connector object as a 
parameter.  Throws an exception if it doesn't get a valid DBIx::Connector.


=head2  configure_db
(Class method)

    Class::User::DBI::Domains->configure_db( $connector );

This is a class method.  Pass a valid DBIx::Connector as a parameter.  Builds
a minimal database table in support of the Class::User::DBI::Domains class.

The table created will be C<cud_domains>.

=head2 add_domains

    $d->add_domains( [ 'Salt Lake City', 'Salt Lake City, Utah' ], ... );

Add one or more domains.  Each domain must be bundled along with its 
description in an array ref.  Pass an AoA for multiple domains, or just an 
aref for a single domain/description pair.

It will drop requests to add domains that already exist.

Returns a count of domains added, which may be less than the number passed if 
one already existed.

=head2 delete_domains

    $d->delete_domains( 'Portland', 'Los Angeles' ); # Closed two locations.

Deletes from the database all domains specified.  Return value is the number 
of domains actually deleted, which may be less than the number of domains
requested if any of the requested domains didn't exist in the database to 
begin with.


=head2 exists_domain

    print "Domain exists." if $d->exists_domain( 'Portland' );

Returns true if a given domain exists, and false if not.

=head2 fetch_domains

    foreach my $domain ( $d->fetch_domains ) {
        print "$domain->[0] = $domain->[1]\n";
    }
    
Returns an array of array refs.  Each array ref contains the domain's name 
and its description as the first and second elements, respectively.

An empty list means there are no domains defined.

=head2 get_domain_description

    my $description = $d->get_domain_description( 'Portland' );
    
Returns the description for a given domain.  Throws an exception if the 
domain doesn't exist, so be sure to test with 
C<< $r->exists_domain( 'Portland' ) >> first.

=head2 set_domain_description

    $d->set_domain_description( 'Portland', 'Portland, Oregon again now.' );

Sets a new description for a given domain.  If the domain doesn't exist 
in the database, if not enough parameters are passed, or if any of the params 
are C<undef>, an exception will be thrown.  To update a domain by giving it 
a blank description, pass an empty string as the description.


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

    perldoc Class::User::DBI::Domains


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
