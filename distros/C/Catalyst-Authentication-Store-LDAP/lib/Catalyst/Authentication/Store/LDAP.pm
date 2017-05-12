package Catalyst::Authentication::Store::LDAP;

use strict;
use warnings;

our $VERSION = '1.016';

use Catalyst::Authentication::Store::LDAP::Backend;

sub new {
    my ( $class, $config, $app ) = @_;
    return Catalyst::Authentication::Store::LDAP::Backend->new(
        $config);
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Catalyst::Authentication::Store::LDAP
  - Authentication from an LDAP Directory.

=head1 SYNOPSIS

    use Catalyst qw(
      Authentication
      );

    __PACKAGE__->config(
      'authentication' => {
         default_realm => "ldap",
         realms => {
           ldap => {
             credential => {
               class => "Password",
               password_field => "password",
               password_type => "self_check",
             },
             store => {
               binddn              => "anonymous",
               bindpw              => "dontcarehow",
               class               => "LDAP",
               ldap_server         => "ldap.yourcompany.com",
               ldap_server_options => { timeout => 30 },
               role_basedn         => "ou=groups,ou=OxObjects,dc=yourcompany,dc=com",
               role_field          => "uid",
               role_filter         => "(&(objectClass=posixGroup)(memberUid=%s))",
               role_scope          => "one",
               role_search_options => { deref => "always" },
               role_value          => "dn",
               role_search_as_user => 0,
               start_tls           => 1,
               start_tls_options   => { verify => "none" },
               entry_class         => "MyApp::LDAP::Entry",
               use_roles           => 1,
               user_basedn         => "ou=people,dc=yourcompany,dc=com",
               user_field          => "uid",
               user_filter         => "(&(objectClass=posixAccount)(uid=%s))",
               user_scope          => "one", # or "sub" for Active Directory
               user_search_options => {
                 deref => 'always',
                 attrs => [qw( distinguishedname name mail )],
               },
               user_results_filter => sub { return shift->pop_entry },
               persist_in_session  => 'all',
             },
           },
         },
       },
    );

    sub login : Global {
        my ( $self, $c ) = @_;

        $c->authenticate({
                          id          => $c->req->param("login"),
                          password    => $c->req->param("password")
                         });
        $c->res->body("Welcome " . $c->user->username . "!");
    }

=head1 DESCRIPTION

This plugin implements the L<Catalyst::Authentication> v.10 API. Read that documentation first if
you are upgrading from a previous version of this plugin.

This plugin uses C<Net::LDAP> to let your application authenticate against
an LDAP directory.  It has a pretty high degree of flexibility, given the
wide variation of LDAP directories and schemas from one system to another.

It authenticates users in two steps:

1) A search of the directory is performed, looking for a user object that
   matches the username you pass.  This is done with the bind credentials
   supplied in the "binddn" and "bindpw" configuration options.

2) If that object is found, we then re-bind to the directory as that object.
   Assuming this is successful, the user is Authenticated.

=head1 CONFIGURATION OPTIONS

=head2 Configuring with YAML

Set Configuration to be loaded via Config.yml in YourApp.pm

    use YAML qw(LoadFile);
    use Path::Class 'file';

    __PACKAGE__->config(
        LoadFile(
            file(__PACKAGE__->config->{home}, 'Config.yml')
        )
    );

Settings in Config.yml (adapt these to whatever configuration format you use):

    # Config for Store::LDAP
    authentication:
        default_realm: ldap
        realms:
            ldap:
                credential:
                    class: Password
                    password_field: password
                    password_type:  self_check
                store:
                    class: LDAP
                    ldap_server: ldap.yourcompany.com
                    ldap_server_options:
                        timeout: 30
                    binddn: anonymous
                    bindpw: dontcarehow
                    start_tls: 1
                    start_tls_options:
                        verify: none
                    user_basedn: ou=people,dc=yourcompany,dc=com
                    user_filter: (&(objectClass=posixAccount)(uid=%s))
                    user_scope: one
                    user_field: uid
                    user_search_options:
                        deref: always
                    use_roles: 1
                    role_basedn: ou=groups,ou=OxObjects,dc=yourcompany,dc=com
                    role_filter: (&(objectClass=posixGroup)(memberUid=%s))
                    role_scope: one
                    role_field: uid
                    role_value: dn
                    role_search_options:
                        deref: always


B<NOTE:> The settings above reflect the default values for OpenLDAP. If you
are using Active Directory instead, Matija Grabnar suggests that the following
tweeks to the example configuration will work:

    user_basedn: ou=Domain Users,ou=Accounts,dc=mycompany,dc=com
    user_field:  samaccountname
    user_filter: (sAMAccountName=%s)
    user_scope: sub

He also notes: "I found the case in the value of user_field to be significant:
it didn't seem to work when I had the mixed case value there."

=head2 ldap_server

This should be the hostname of your LDAP server.

=head2 ldap_server_options

This should be a hashref containing options to pass to L<Net::LDAP>->new().
See L<Net::LDAP> for the full list.

=head2 binddn

This should be the DN of the object you wish to bind to the directory as
during the first phase of authentication. (The user lookup phase)

If you supply the value "anonymous" to this option, we will bind anonymously
to the directory.  This is the default.

=head2 bindpw

This is the password for the initial bind.

=head2 start_tls

If this is set to 1, we will convert the LDAP connection to use SSL.

=head2 start_tls_options

This is a hashref, which contains the arguments to the L<Net::LDAP> start_tls
method.  See L<Net::LDAP> for the complete list of options.

=head2 user_basedn

This is the basedn for the initial user lookup.  Usually points to the
top of your "users" branch; ie "ou=people,dc=yourcompany,dc=com".

=head2 user_filter

This is the LDAP Search filter used during user lookup.  The special string
'%s' will be replaced with the username you pass to $c->login.  By default
it is set to '(uid=%s)'.  Other possibly useful filters:

    (&(objectClass=posixAccount)(uid=%s))
    (&(objectClass=User)(cn=%s))

=head2 user_scope

This specifies the scope of the search for the initial user lookup.  Valid
values are "base", "one", and "sub".  Defaults to "sub".

=head2 user_field

This is the attribute of the returned LDAP object we will use for their
"username".  This defaults to "uid".  If you had user_filter set to:

    (&(objectClass=User)(cn=%s))

You would probably set this to "cn". You can also set it to an array,
to allow more than one login field. The first field will be returned
as identifier for the user.

=head2 user_search_options

This takes a hashref.  It will append it's values to the call to
L<Net::LDAP>'s "search" method during the initial user lookup.  See
L<Net::LDAP> for valid options.

Be careful not to specify:

    filter
    scope
    base

As they are already taken care of by other configuration options.

=head2 user_results_filter

This is a Perl CODE ref that can be used to filter out multiple results
from your LDAP query. In theory, your LDAP query should only return one result
and find_user() will throw an exception if it encounters more than one result.
However, if you have, for whatever reason, a legitimate reason for returning
multiple search results from your LDAP query, use C<user_results_filter> to filter
out the LDAP entries you do not want considered. Your CODE ref should expect
a single argument, a Net::LDAP::Search object, and it should return exactly one
value, a Net::LDAP::Entry object.

Example:

 user_results_filter => sub {
                          my $search_obj = shift;
                          foreach my $entry ($search_obj->entries) {
                              return $entry if my_match_logic( $entry );
                          }
                          return undef; # i.e., no match
                        }

=head2 use_roles

Whether or not to enable role lookups.  It defaults to true; set it to 0 if
you want to always avoid role lookups.

=head2 role_basedn

This should be the basedn where the LDAP Objects representing your roles are.

=head2 role_filter

This should be the LDAP Search filter to use during the role lookup.  It
defaults to '(memberUid=%s)'.  The %s in this filter is replaced with the value
of the "role_value" configuration option.

So, if you had a role_value of "cn", then this would be populated with the cn
of the User's LDAP object.  The special case is a role_value of "dn", which
will be replaced with the User's DN.

=head2 role_scope

This specifies the scope of the search for the user's role lookup.  Valid
values are "base", "one", and "sub".  Defaults to "sub".

=head2 role_field

Should be set to the Attribute of the Role Object's returned during Role lookup you want to use as the "name" of the role.  Defaults to "CN".

=head2 role_value

This is the attribute of the User object we want to use in our role_filter.
If this is set to "dn", we will use the User Objects DN.

=head2 role_search_options

This takes a hashref.  It will append it's values to the call to
L<Net::LDAP>'s "search" method during the user's role lookup.  See
L<Net::LDAP> for valid options.

Be careful not to specify:

    filter
    scope
    base

As they are already taken care of by other configuration options.

=head2 role_search_as_user

By default this setting is false, and the role search will be performed
by binding to the directory with the details in the I<binddn> and I<bindpw>
fields. If this is set to false, then the role search will instead be
performed when bound as the user you authenticated as.

=head2 persist_in_session

Can take one of the following values, defaults to C<username>:

=over

=item C<username>

Only store the username in the session and lookup the user and its roles
on every request. That was how the module worked until version 1.015 and is
also the default for backwards compatibility.

=item C<all>

Store the user object and its roles in the session and never look it up in
the store after login.

B<NOTE:> It's recommended to limit the user attributes fetched from LDAP
using L<user_search_options> / attrs to not exhaust the session store.

=back

=head2 entry_class

The name of the class of LDAP entries returned. This class should
exist and is expected to be a subclass of Net::LDAP::Entry

=head2 user_class

The name of the class of user object returned. By default, this is
L<Catalyst::Authentication::Store::LDAP::User>.

=head1 METHODS

=head2 new

This method will populate
L<Catalyst::Plugin::Authentication/default_auth_store> with this object.

=head1 AUTHORS

Adam Jacob <holoway@cpan.org>
Peter Karman <karman@cpan.org>
Alexander Hartmaier <abraxxa@cpan.org>

Some parts stolen shamelessly and entirely from
L<Catalyst::Plugin::Authentication::Store::Htpasswd>.

Currently maintained by Dagfinn Ilmari Mannsåker <ilmari@cpan.org>.

=head1 THANKS

To nothingmuch, ghenry, castaway and the rest of #catalyst for the help. :)

=head1 SEE ALSO

L<Catalyst::Authentication::Store::LDAP>,
L<Catalyst::Authentication::Store::LDAP::User>,
L<Catalyst::Authentication::Store::LDAP::Backend>,
L<Catalyst::Plugin::Authentication>,
L<Net::LDAP>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2005 the aforementioned authors. All rights
reserved. This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut


