package CatalystX::Eta;

# ABSTRACT: Mostly, Controller's Moose::Roles for easy CRUD/Validation API's

use strict;
use 5.008_005;
our $VERSION = '0.08';

# no code, you should not use this package directly

1;

__END__

=encoding utf-8

=head1 NAME

CatalystX::Eta are composed of Moose::Roles for consistent CRUD/Validation/Testing between apps.

"Eta" is just a cool Greek letter. I'm using it for not polluting CPAN CatalystX namespace with this module.


=head1 WTH CatalystX::Eta is and why did you do that

I started (although not with this namespace) as set of Catalyst Controller Roles to extend and reduce
repeatable tasks that I had to do to make REST/CRUD stuff.

Later, I had to start more Catalyst projects. After a while, others collaborators were using it
on their projects too, but copying the code in each app.

After a while, they made modifications on those files as well,
and now we have lot of versions of *almost* same thing, and this is hell!
So, I'm using this namespace to group and keep those changes together.

This module may not fit for you, but it's a very simple way to make CRUD schemas on REST,
without prohibit or complicate use of catalyst power, like chains or anything else.


=head1 How it works

CatalystX::Eta do not create any path on you application. This is your job.

Almost all CatalystX::Eta roles need DBIx::Class to work good.

CatalystX::Eta have those packages:

    CatalystX::Eta::Controller::REST
    CatalystX::Eta::Controller::AutoBase
    CatalystX::Eta::Controller::AutoList
    CatalystX::Eta::Controller::AutoObject
    CatalystX::Eta::Controller::AutoResult
    CatalystX::Eta::Controller::CheckRoleForPOST
    CatalystX::Eta::Controller::CheckRoleForPUT
    CatalystX::Eta::Controller::ListAutocomplete
    CatalystX::Eta::Controller::Search
    CatalystX::Eta::Controller::TypesValidation
    CatalystX::Eta::Controller::ParamsAsArray
    CatalystX::Eta::Controller::SimpleCRUD
    CatalystX::Eta::Controller::AssignCollection
    CatalystX::Eta::Test::REST


And now, with a little description:

    CatalystX::Eta::Controller::REST
        - NOT a Moose::ROLE.
        - extends Catalyst::Controller::REST
        - overwrite /end to catch die.

    CatalystX::Eta::Controller::AutoBase
        - requires 'base';
        - load $c->stash->{collection} a $c->model( $self->config->{result} )

    CatalystX::Eta::Controller::AutoList
        - requires 'list_GET';
        - requires 'list_POST';
        - list_GET read lines on $c->stash->{collection} then $self->status_ok
        - list_POST $c->stash->{collection}->execute(...) then $self->status_created

    CatalystX::Eta::Controller::AutoObject
        - May $c->detach('/error_404'), so better you implement this Private Path.
        - requires 'object';
        - $c->stash->{object} = $c->stash->{collection}->search( { "me.id" => $id } )

    CatalystX::Eta::Controller::AutoResult
        - requires 'result_GET';
        - requires 'result_PUT';
        - requires 'result_DELETE';
        - result_GET $self->status_ok a $c->stash->{object}
        - result_PUT $c->stash->{object}->execute(...) and $self->status_accepted
        - result_DELETE $c->stash->{object}->delete and $self->status_no_content

    CatalystX::Eta::Controller::CheckRoleForPOST
        - requires 'list_POST';
        - basically:
            if ( !$c->check_any_user_role( @{ $config->{create_roles} } ) ) {
                $self->status_forbidden( $c, message => "insufficient privileges" );
                $c->detach;
            }

    CatalystX::Eta::Controller::CheckRoleForPUT
        - requires 'result_PUT';
        - that's not so simple as CheckRoleForPOST, because it
          depends on what you have the user_id field on $c->stash->{object}
          and sometimes it is true.

    CatalystX::Eta::Controller::ListAutocomplete
        - requires list_GET
        - return { suggestions => [ value => $row->name, data => $row->id ] } instead of
          the normal response, if $c->req->params->{list_autocompleate} is true.

    CatalystX::Eta::Controller::Search
        - requires 'list_GET';
        - read $self->config->{search_ok} and
          $c->stash->{collection}->search( ... ) if the $c->req->params->{$search_keys} are valid.

    CatalystX::Eta::Controller::TypesValidation
        - add validate_request_params method.
        - validate_request_params uses Moose::Util::TypeConstraints::find_or_parse_type_constraint
          to validate $c->req->params->{...}

    CatalystX::Eta::Controller::ParamsAsArray
        - add params_as_array
        - params_as_array is a litle crazy, see it bellow.

    CatalystX::Eta::Controller::SimpleCRUD
        - just a group of with's.

        with 'CatalystX::Eta::Controller::AutoBase';      # 1
        with 'CatalystX::Eta::Controller::AutoObject';    # 2
        with 'CatalystX::Eta::Controller::AutoResult';    # 3

        with 'CatalystX::Eta::Controller::CheckRoleForPUT';
        with 'CatalystX::Eta::Controller::CheckRoleForPOST';

        with 'CatalystX::Eta::Controller::AutoList';      # 1
        with 'CatalystX::Eta::Controller::Search';        # 2

    CatalystX::Eta::Controller::AssignCollection
        - another group of with's

        with 'CatalystX::Eta::Controller::Search';
        with 'CatalystX::Eta::Controller::AutoBase';
        with 'CatalystX::Eta::Controller::AutoObject';
        with 'CatalystX::Eta::Controller::CheckRoleForPUT';
        with 'CatalystX::Eta::Controller::CheckRoleForPOST';

    CatalystX::Eta::Test::REST
        - extends Stash::REST and use Test::More
        - add a trigger process_response to Stash::REST
        this add a test for each request made with Stash::REST
        is(
            $opt->{res}->code,
            $opt->{conf}->{code},
            $desc . ( exists $opt->{conf}->{name} ? ' - ' . $opt->{conf}->{name} : '' )
        );


=head2 A Controller using CatalystX::Eta::Controller::SimpleCRUD

    package MyApp::Controller::API::User;

    use Moose;

    BEGIN { extends 'CatalystX::Eta::Controller::REST' }

    __PACKAGE__->config(

        # what resultset will be on $c->stash->{collection}
        # used by AutoBase
        result      => 'DB::User',

        # WARNING: you should never change it during "requests",
        # or behavior may be wrong, because Controllers are Singleton objects
        result_cond => { active => 1 },
        result_attr => { order_by => ['me.id'] },

        # where on stash the $c->stash->{collection}->next should be put
        # used by AutoObject and others.
        object_key => 'user',
        # what list_GET key should put collection results.
        list_key   => 'users',

        # check_only_roles => 0 # default.

        # used by CheckRoleForPUT
        update_roles => [qw/superadmin/],

        # used by CheckRoleForPOST
        create_roles => [qw/superadmin/],

        # used by AutoResult
        delete_roles => [qw/superadmin/],

        # if the user requesting delete or update have any of listed roles,
        # the action will be executed.
        # if the role was denied and config->{check_only_roles} is not true,
        # the code test if the object have the column (user_id | created_by ) and
        # if is equals $c->user->id, the action is executed even without the role.

        # used by AutoList and AutoResult
        # to generate the row.
        build_row => sub {
            my ( $r, $self, $c ) = @_;

            return {
                (
                    map { $_ => $r->$_ }
                    qw(
                    id name email type
                    )
                ),

            };
        },

        # change delete behavior to a update.
        before_delete => sub {
            my ( $self, $c, $item ) = @_;

            $item->update({ active => 0 });

            return 0;
        },

        # let the user search for a name using query-parameters
        search_ok => {
            'name' => 'Str',
        }
    );
    with 'CatalystX::Eta::Controller::SimpleCRUD';

    sub base : Chained('/api/base') : PathPart('users') : CaptureArgs(0) { }

    # here we implement read permissons
    after 'base' => sub {
        my ( $self, $c ) = @_;

        # if you are not a superadmin, (or, if you are a user)
        # you can only see youself on GET /users for example.
        $c->stash->{collection} = $c->stash->{collection}->search(
            {
                'me.id' => $c->user->id
            }
        ) if $c->check_any_user_role('user');

    };

    sub object : Chained('base') : PathPart('') : CaptureArgs(1) { }

    sub result : Chained('object') : PathPart('') : Args(0) : ActionClass('REST') { }

    sub result_GET { }

    sub result_PUT { }

    sub result_DELETE { }

    sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

    sub list_GET { }

    sub list_POST { }

    1;

=head2 CatalystX::Eta::Controller::AutoObject

In order to use CatalystX::Eta::Controller::AutoObject you need need '/error_404' Catalyst Private action defined.

=head2 CatalystX::Eta::Controller::AutoResult

In order to use CatalystX::Eta::Controller::AutoResult->result_PUT you need that
your DBIx::Class::Result have a sub execute defined.

The routine will be executed as:

    $result->execute(
        $c,
        for => 'update',
        with => $c->req->params,
    );

You should not use $c for things differ than detach to an form_error.

=head2 CatalystX::Eta::Controller::AutoList

In order to use CatalystX::Eta::Controller::AutoList->list_POST you need that
your DBIx::Class::ResultSet have a sub execute defined.

The routine will be executed as:

    $result->execute(
        $c,
        for => 'create',
        with => $c->req->params,
    );

You should not use $c for things differ than detach to an form_error.

=head2 CatalystX::Eta::Controller::REST

CatalystX::Eta::Controller::REST extends `Catalyst::Controller::REST`.

All your controllers should extends `CatalystX::Eta::Controller::REST`.

All exceptions will be more "api friendly" than HTML with '(en) Please come back later\n...'
Response code are set to 500, and rest response to { error => 'Internal Server Error' }


You can also do

    die \['foobar', 'something']

anywhere (where the die goes freely until reach /end) and it will be
transformed in a 400 reponse code with { error => 'form_error', form_error => { 'foobar' => 'something' } }


=head2 MyApp::TraitFor::Controller::TypesValidation

This role add a sub validate_request_params;

validate_request_params uses Moose::Util::TypeConstraints::find_or_parse_type_constraint to valid content,
so you can do things like:

    $self->validate_request_params(
        $c,
        extra_days => {
            type     => 'Int',
            required => 1,
        },
        credit_card_id => {
            type     => 'Int',
            required => 0,
        },
    );

On your controllers, and it do the $c->status_bad_request and $c->detach on invalid/missing params.

=head2 CatalystX::Eta::Controller::ParamsAsArray

This role add a sub params_as_array;

it transform keys of a hash to array of hashes:

    $self->params_as_array( 'foo', {
        'foo:1' => 'a',
        'bar:1' => 'b',
        'zoo:1' => 1,
        'zoo:2' => 2,
    })

    Returns:

    [
        { foo => 'a', zoo => 1},
        { foo => 'b', zoo => 2}
    ]


=head1 Tests Coverage

This is the first version, and need a lot of progress on tests.

    @ version 0.01
    ---------------------------- ------ ------ ------ ------ ------ ------ ------
    File                           stmt   bran   cond    sub    pod   time  total
    ---------------------------- ------ ------ ------ ------ ------ ------ ------
    ...ta/Controller/AutoBase.pm  100.0   50.0   33.3  100.0    n/a   29.5   83.3
    ...ta/Controller/AutoList.pm  100.0   50.0   33.3  100.0    n/a    1.5   87.8
    .../Controller/AutoObject.pm  100.0   75.0    n/a  100.0    n/a    0.7   94.4
    .../Controller/AutoResult.pm   93.3   50.0   33.3  100.0    n/a    0.6   71.4
    ...oller/CheckRoleForPOST.pm   84.6   50.0    n/a  100.0    n/a    0.0   82.3
    ...roller/CheckRoleForPUT.pm  100.0   64.2   44.4  100.0    n/a    0.0   72.7
    ...tX/Eta/Controller/REST.pm   57.7   16.6   30.4  100.0   50.0   62.1   49.4
    .../Eta/Controller/Search.pm   32.7   10.0   11.1  100.0    n/a    0.3   25.7
    .../Controller/SimpleCRUD.pm  100.0    n/a    n/a  100.0    n/a    0.1  100.0
    ...atalystX/Eta/Test/REST.pm   93.3   83.3    n/a  100.0    0.0    4.8   88.4
    Total                          74.4   39.0   32.3  100.0   33.3  100.0   61.5
    ---------------------------- ------ ------ ------ ------ ------ ------ ------


=head1 TODO

- The documentation of all modules need to be created, and this updated.


=head1 AUTHOR

Renato CRON E<lt>rentocron@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2015- Renato CRON

Thanks to http://eokoe.com

=head1 Disclaimer

I'm using the word "REST" application but it really depends on you implement the truly REST. Catalyst::Controller::REST and
CatalystX::Eta::Controller::REST only implement a JSON/YAML response, but lot of people would call those applications REST.

Please do not use XML response with Catalyst::Controller::REST, because it use Simple::XML transform your data
into something potentially unstable! If you want XML responses, use create it with a DTD.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<CatalystX::CRUD>

=cut