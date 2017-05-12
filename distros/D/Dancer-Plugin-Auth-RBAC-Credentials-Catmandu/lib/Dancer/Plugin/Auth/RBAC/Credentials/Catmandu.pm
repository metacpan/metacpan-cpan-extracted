package Dancer::Plugin::Auth::RBAC::Credentials::Catmandu;
our $VERSION = "0.01";
use Catmandu::Sane;
use Catmandu::Util qw(require_package :is);
use Catmandu qw(store);
use base qw/Dancer::Plugin::Auth::RBAC::Credentials/;

sub bag {
    my($self,$args)=@_;
    state $bag = store($args->{store})->bag($args->{bag});
}

sub authorize {
    my($self,$options,@arguments) = @_;
    my($login,$password) = @arguments;

    #what are you doing here? You're already in!
    my $user = $self->credentials;
    if(is_hash_ref($user) && ($user->{id} || $user->{login}) && !@{$user->{error}}){

        return $user;

    }

    if(!(is_string($login) && is_string($password))){

        $self->errors('login and password are required');
        return;

    }

    # authorize a new account using supplied credentials
    my $account = $self->bag($options)->get($login);

    if(!is_hash_ref($account)){

        $self->errors('login and/or password is invalid');
        return;

    }

    if(!is_string($account->{password})){

        $self->errors('attempting to access as inaccessible account');
        return;

    }

    if($account->{password} ne $password){

        $self->errors('login and/or password is invalid');
        return;

    }

    my $session_data = {
        id    => $account->{_id},
        name  => $account->{name} || ucfirst($login),
        login => $account->{login},
        roles => [@{$account->{roles}}],
        error => []
    };

    return $self->credentials($session_data);

}

=head1 NAME

Dancer::Plugin::Auth::RBAC::Credentials::Catmandu - Catmandu store backend for Dancer::Plugin::RBAC::Credentials

=head1 INSTALLATION AND CONFIGURATION

=head2 install the following perl modules

=over

=item Catmandu

=item Catmandu::DBI

=back

=head2 add the yaml file 'catmandu.yml' to the root directory of your Dancer project

store:
 default:
  package: Catmandu::Store::DBI
  options:
   data_source: "dbi:mysql:database=myapp"
   username: "admin"
   password: "admin"

=head2 adjust your Dancer config.yml

plugins:
 Auth::RBAC:
  credentials:
   class: Catmandu
   options:
    #name of store in catmandu.yml
    store: 'default'
    #name of table
    bag: 'users'

=head2 The table 'users' will be created if not exists already, and will have the following format

=over

=item id

identifier of the user

=item data

json data, in the following form:

{

    _id: "njfranck",
    login: "njfranck",
    name: "Nicolas Franck",
    password: "password",
    roles: ["admin"]

}

=back

=head2 in order to add users execute the following code

Catmandu->store('default')->bag('users')->add({
    _id => "user2",
    name => "user 2",
    login => "user2",
    password => "secret",
    roles => ["editor","messenger"]

});

=head1 NOTE

The configuration of the store is only a sample. Different other stores exist in Catmandu.
See:

L<Catmandu::Store::Hash>

L<Catmandu::Store::Solr>

L<Catmandu::Store::MongoDB>

=head1 AUTHOR

Nicolas Franck, C<< <nicolas.franck at ugent.be> >>

=head1 SEE ALSO

L<Catmandu>

L<Catmandu::Store::DBI>

L<Dancer::Plugin::Auth::RBAC>

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
