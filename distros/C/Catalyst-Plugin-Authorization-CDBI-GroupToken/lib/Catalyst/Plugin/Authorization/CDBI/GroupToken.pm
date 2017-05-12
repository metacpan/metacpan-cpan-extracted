package Catalyst::Plugin::Authorization::CDBI::GroupToken;

use strict;
use NEXT;

our $VERSION = '0.01';

=head1 NAME

Catalyst::Plugin::Authorization::CDBI::GroupToken - CDBI Authorization for Catalyst

=head1 SYNOPSIS

    use Catalyst qw/Authorization::CDBI::GroupToken/;

    __PACKAGE__->config->{authorization} = {
         user_class               => 'MyApp::Model::CDBI::User'        
        ,token_class              => 'MyApp::Model::CDBI::Token'
        ,token_field              => 'name'
        ,user_token_class         => 'MyApp::Model::CDBI::UserToken'
        ,user_token_user_field    => 'user'
        ,user_token_token_field   => 'token'
        ,group_class              => 'MyApp::Model::CDBI::Group'
        ,group_field              => 'name'
        ,group_description_field  => 'description'
        ,user_group_class         => 'MyApp::Model::CDBI::UserGroup'
        ,user_group_user_field    => 'user'
        ,user_group_group_field   => 'group'
        ,token_group_class        => 'MyApp::Model::CDBI::TokenGroup'
        ,token_group_token_field  => 'token'
        ,token_group_group_field  => 'group'
        ,group_group_class        => 'MyApp::Model::CDBI::GroupGroup'
        ,group_group_parent_field => 'parent'
        ,group_group_child_field  => 'child'
    };

    $c->token(qw/myapp.access/);


    # the basic setup
    CREATE TABLE user (
        id INTEGER PRIMARY KEY,
        email TEXT,
        password TEXT
    );

    CREATE TABLE token (
        id INTEGER PRIMARY KEY,
        name TEXT
    );

    CREATE TABLE user_token (
        id INTEGER PRIMARY KEY,
        user INTEGER REFERENCES customer,
        token INTEGER REFERENCES token
    );

    # user-groups and token-groups
    CREATE TABLE group (
        id INTEGER PRIMARY KEY,
        group TEXT
    );

    CREATE TABLE token_group (
        id INTEGER PRIMARY KEY,
        token INTEGER REFERENCES token,
        group INTEGER REFERENCES group
    );

    CREATE TABLE user_group (
        id INTEGER PRIMARY KEY,
        customer INTEGER REFERENCES user,
        group INTEGER REFERENCES group
    );

    # group-groups
    CREATE TABLE group_group (
        id INTEGER PRIMARY KEY,
        parent INTEGER REFERENCES group
        child INTEGER REFERENCES group
    );

=head1 DESCRIPTION

This is a simplified version of the group-role-permission-token paradigm.
Working from the theory that at the end of the day all the developer really
cares about is whether someone has permission to access something or not.
Traditional roles and groups are just storage and assignment mechanisms.
This model changes the notion of a permission to a "token". Roles and groups are
simplified to "group". And a user is still a user. Tokens (permissions) are
assigned to a user and or a group. A user is assigned to groups. Groups can
also be assigned to groups (think of roles assigned to groups without all
the headaches of realizing that a role has suddenly morphed into a group or
into a permission). The flexibility is that exceptions are easily handled.
If Rob is in Group A, but also needs also needs a permission for something
from group B we just give him the permission directly. These alleviates the
need to build another role or group just to handle the special case for Rob.
Why all this you ask? Again it gets back to the concept of "all I really
care about is can this user do this". So outside of an administrative
interface the only thing to query is the tokens (permissions). This is
similar to testing for a particular capability in javascript versus doing a
browser detect and branching off from there.

For example given the following setup:
   
   User Rob
      Group WholeDamnCompany
      Group Foo
      widgets_inc.sales.leads
   
   Group Accounting
      widgets_inc.acct.access
      widgets_inc.acct.edit
   
   Group HR
      widgets_inc.hr.admin.access
      widgets_inc.hr.admin.add_user
   
   Group WholeDamnCompany
      Group Accounting
      Group HR
      widgets_inc.widget_view
   
   Group Foo
      widgets_inc.bar
   
   Group IT
      widgets_inc.it.root
   
   Token
      widgets_inc.bldg1.access
   
We test with $c->tokens('[token name]'), each of these will return true for Rob:

        widgets_inc.wizbang.feature
        widgets_inc.acct.access
        widgets_inc.acct.edit
        widgets_inc.hr.admin.access
        widgets_inc.hr.admin.add_user
        widgets_inc.sales.leads
        widgets_inc.bar

Each of these will return false for Rob as he is not in IT nor has the widgets_inc.bldg1.access directly assigned:
        
        widgets_inc.it.root
        widgets_inc.bldg1.access

So why the hierarchy in the token naming? Really this is a matter of
preference. You can name your tokens whatever works best for your needs, but
the idea here is to make the permission self describing. I also have some
interesting future features in mind, such as tying user specific data to a
given token via key/value and predefining settings for these keys(See TODO).
Why "tokens"? No real reason, its what the group I work with has been
calling them for years, so just what I am used to. Also it is to clearly
delineate this school of thought from "roles". Oh and I could not come up
with a catchy acronym for Tokens Aint Roles like YAML.

Note that this plugin is designed to work with
C<Catalyst::Plugin::Authentication::CDBI> and works much the same way as the
roles method in this plugin. It will pick up the user_class and user_field
settings from Authentication::CDBI if omitted. In theory it should work with
any Authentication plugin that sets $c->request->{user_id}.

=head1 CONFIGURATION

Most of configuration is optional. The _class suffixed configuration options
essentially enable a given feature. There are three different setups that
build upon one another:

=head2 Basic Configuration

Start with the user and a simple token assignment. This is identical to
roles in L<Catalyst::Plugin::Authentication::CDBI> v0.09

=over 4

=item user_class

The User Model Class. i.e., 'MyApp::Model::CDBI::User'
Optional. Defaults to $c->config->{authentication}->{user_class}

=item token_class

The Token Model Class. i.e., 'MyApp::Model::CDBI::Token'
Required.

=item token_field

The Token Field from the Token Model Class. i.e., 'name'
Optional. Defaults to 'name'

=item user_token_class

The User-Token Model Class. i.e., 'MyApp::Model::CDBI::UserToken'
Required.

=item user_token_user_field

The User Field from the User-Token Model Class. i.e., 'user'
Optional. Defaults to 'user'

=item user_token_token_field

The Token Field from the User-Token Model Class. i.e., 'token'
Optional. Defaults to 'token'

=back

=head2 Group Configuration

This builds upon all the settings above. It adds User-Group  and
Token-Group to the setup.

=over 4

=item group_class

The Group Model Class. i.e., 'MyApp::Model::CDBI::Group'
Optional. Future plans include an out of the box admin scripts.

=item group_field

The Group Field from the Group Model Class. i.e., 'name'
Optional. Defaults to 'name'

=item group_description_field

The Description Field from the Group Model Class. i.e., 'description'
Optional. Defaults to 'description'

=item user_group_class

The User-Group Model Class. i.e., 'MyApp::Model::CDBI::UserGroup'
Optional. If omitted then just User-Token will be used.
Enables Group Configuration along with token_group_class

=item user_group_user_field

The User Field from the User-Group Model Class. i.e., 'user'
Optional. Defaults to 'user'

=item user_group_group_field

The Group Field from the User-Group Model Class. i.e., 'group'
Optional. Defaults to 'group'

=item token_group_class

The Token-Group Model Class. i.e., 'MyApp::Model::CDBI::TokenGroup'
Optional. If omitted then just User-Token will be used.
Enables Group Configuration along with user_group_class

=item token_group_token_field

The Token Field from the Token-Group Model Class. i.e., 'token'
Optional. Defaults to 'token'

=item token_group_group_field

The Group Field from the Token-Group Model Class. i.e., 'group'
Optional. Defaults to 'group'

=back

=head2 Group Group Configuration

This builds upon all the settings above. It adds Group-Group to the setup.

=over 4

=item group_group_class

The Group_Group Model Class. i.e., 'MyApp::Model::CDBI::GroupGroup'
Enables use of Group Group Configuration

=item group_group_parent_field

The Parent Group Field from the Group-Group Model Class. i.e., 'parent'
Optional. Defaults to 'parent'

=item group_group_child_field

The Child Group Field from the Group-Group Model Class. i.e., 'child'
Optional. Defaults to 'child'

=back

=head2 A Minimal Configuration Example

   __PACKAGE__->config->{authorization} = {
       user_class       => 'MyApp::Model::CDBI::User'
      ,token_class      => 'MyApp::Model::CDBI::Token'
      ,user_token_class => 'MyApp::Model::CDBI::UserToken'
   };      

=head1 METHODS

=over 4

=item token

Check permissions return true or false.

    $c->tokens(qw/widgets_inc.foo widgets_inc.bar/);

Returns an arrayref containing the verified tokens. This is the same as
C<Catalyst::Plugin::Authentic ation::CDBI>->roles

    my @tokens = @{ $c->tokens };

=cut

sub tokens {
    my $c = shift;
    $c->{tokens} ||= [];
    my $tokens = ref $_[0] eq 'ARRAY' ? $_[0] : [@_];
    if ( $_[0] ) {
        my @tokens;
        foreach my $token (@$tokens) {
            push @tokens, $token unless grep $_ eq $token, @{ $c->{tokens} };
        }
        return 1 unless @tokens;
        if ( $c->process_tokens( \@tokens ) ) {
            $c->{tokens} = [ @{ $c->{tokens} }, @tokens ];
            return 1;
        }
        else { return 0 }
    }
    return $c->{tokens};
}


=back

=head2 EXTENDED METHODS

=over 4

=item setup

sets up $c->config->{authorization}.

=cut

sub setup {
    my $c    = shift;
    my $conf = $c->config->{authorization};
    $conf = ref $conf eq 'ARRAY' ? {@$conf} : $conf;
    $c->config->{authorization} = $conf;
    return $c->NEXT::setup(@_);
}

=back

=head2 OVERLOADED METHODS

=over 4

=item process_tokens

Takes an arrayref of tokens and checks if user has the supplied tokens.
Returns 1/0.

=cut

sub process_tokens {
    my ( $c, $tokens ) = @_;

    # Basic Configuration
    my $user_class =
            $c->config->{authorization}->{user_class}
         || $c->config->{authentication}->{user_class};

    my $token_class =
            $c->config->{authorization}->{token_class}; # || die '\$c->config->{authorization}->{token_class} required for Catalyst::Plugin::Authorization::            CDBI::GroupToken'

    my $token_field =
            $c->config->{authorization}->{token_field}
         || 'name';

    my  $user_token_class =
            $c->config->{authorization}->{user_token_class}; # || die '\$c->config->{authorization}->{user_token_class} required for Catalyst::Plugin::Authorization::         CDBI::GroupToken'

    my $user_token_user_field =
            $c->config->{authorization}->{user_token_user_field}
         || 'user';

    my $user_token_token_field =
            $c->config->{authorization}->{user_token_token_field} || 'token';

    # User-Group Token-Group Configuration
    my $group_class =
            $c->config->{authorization}->{group_class};

    my $group_field =
            $c->config->{authorization}->{group_field};

    my $user_group_class =
            $c->config->{authorization}->{user_group_class};

    my $user_group_user_field =
            $c->config->{authorization}->{user_group_user_field}
         || 'user';

    my $user_group_group_field =
            $c->config->{authorization}->{user_group_group_field}
         || 'group';

    my $ token_group_class =
            $c->config->{authorization}->{token_group_class};

    my $token_group_token_field =
            $c->config->{authorization}->{token_group_token_field}
         || 'token';

    my $token_group_group_field =
            $c->config->{authorization}->{token_group_group_field}
         || 'group';

    # Group-Group Configuration
    my $ group_group_class =
            $c->config->{authorization}->{group_group_class};

    my $group_group_parent_field =
            $c->config->{authorization}->{group_group_parent_field}
         || 'parent';

    my $group_group_child_field =
            $c->config->{authorization}->{group_group_child_field}
         || 'child';
    
    if ( my $user = $user_class->retrieve( $c->request->{user_id} ) ) {
        for my $token_name (@$tokens) {
            $c->log->debug("Checking tokens for '$token_name'") if $c->debug;
            if ( my $token =
                $token_class->search( { $token_field => $token_name } )->first )
            {   # check if user has token directly assigned
                 return 1
                  if $user_token_class->search(
                    {
                        $user_token_user_field => $user->id,
                        $user_token_token_field => $token->id
                    }
                  );
                if ( $token_group_class && $user_group_class ) { # feature enabled?
                    # get a list of all groups the token is assigned to
                    my @token_groups = $token_group_class->search(
                        { $token_group_token_field => $token->id }
                     );

                    # merge @token_groups and all of its pa rent (if a user has
                    #   a parent group then they have the children as well)
                    my %groups_to_check; # hash to store unique group ids
                    foreach my $token_group (@token_groups) {
                        $groups_to_check{$token_group->$token_group_group_field} = 1;
                        if ( $group_group_class ) { # feature enabled?
                            # flatten out the ancestors
                            my @parents = _get_all_group_parents(
                                             $group_group_class
                                            ,$group_group_parent_field
                                            ,$group_group_child_field
                                            ,$token_group->$token_group_group_field
                                          );
                            foreach my $parent_group (@parents) {
                                $groups_to_check{$parent_group} = 1;
                            }
                        }
                                                                        }

                    # check to see if user is in                                            one of these groups
                    foreach my $group (keys %groups_to_check) {
                        if( $user_group_class->search(
                                {
                                    $user_group_user_field  => $user->id,
                                    $user_group_group_field => $group
                                }
                            )
                                                    ) {
                            $c->log->debug("'$token_name' passed token-group-user check") if $c->debug;
                            return 1;
                            last;
                         }
                     }
                }
                return 0;
            }
            else { return 0 }
        }
    }
    else { return 0 }
    return 1;
}

# this could be down easily with co nnect by in oracle,
# but other dbs don't readily support heirarchical queries, so we hack away...
sub _get_all_group_parents {
   my ($class, $parent_field, $child_field, $child) = @_;
   my @parents = $class->search( $child_field => $child );
   my @results;
   foreach my $parent( @parents ) {
        push @results, $parent->$parent_field;
        push @results, _get_all_group_parents( $class 
                                              ,$parent_field
                                              ,$child_field
                                              ,$parent->$parent_field
                                             );
   }
   return @results;
}

=back

=head1 TODO

=over 4

=item -structure to restrict parent group assignment to child exceptions
 
=item -OTB admin interface

=item -implement token attributes

    if ( my $token = $c->tokens('widgets_inc.sales') ) {
         my $region = $token->attribute('region'); # specific region for current user
    }

=back

=head1 SEE ALSO

L<Catalyst> L<Catalyst::Plugin::Authentication::CDBI>.

=head1 AUTHOR

Scott Connelly, C<ssc@cpan.org>

=head1 THANKS

Andy Grundman, C<andy@hyrbidized.org>

The authors of L<Catalyst::Plugin::Authentication::CDBI>

   Sebastian Riedel, C<sri@cpan.org>
   Marcus Ramberg, C<mramberg@cpan.org>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;