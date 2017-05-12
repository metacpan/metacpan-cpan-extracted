package Catalyst::ActionRole::BuildDBICResult;

our $VERSION = '0.04';

use Moose::Role;
use namespace::autoclean;
use Try::Tiny qw(try catch);
use Perl6::Junction qw(any all);
use Catalyst::ActionRole::BuildDBICResult::Types qw(:all);

requires 'name', 'dispatch', 'attributes';

has 'store' => (
    isa => StoreType,
    is => 'ro',
    coerce => 1,
    lazy_build => 1,
);

sub _search_attributes_for {
    my ($self, $attr) = @_;
    my $attribute = $self->attributes->{$attr} || $self->attributes->{lc $attr};
    if ($attribute) {
        my ($value, @more) = @{$attribute};
        return @more ? [$value, @more] : $value;
    } else {
    return;
    }
}

sub _build_store {
    my $self = shift @_;
    if(my $store = $self->_search_attributes_for('Store')) {
        my ($value, @extra) =  eval $store || eval '"$store"';
        if(@extra) {
            return {$value, @extra};
        } else {
            return $value;
        }
    } else {
        return +{accessor=>'model_resultset'}
    }
}

has 'find_condition' => (
    isa => FindConditions,
    is => 'ro',
    coerce => 1,
    lazy_build => 1,
);

sub _build_find_condition {
    my $self = shift @_;
    if(my $fc = $self->_search_attributes_for('Find_condition')) {
        my ($value, @extra) =  eval $fc || eval '"$fc"';
        if(@extra) {
            return [$value, @extra];
        } else {
            return $value;
        }
    } else {
        return  +[{constraint_name=>'primary'}] 
    }
}

has 'auto_stash' => (is=>'ro', isa=>AutoStash, lazy_build=>1);

sub _build_auto_stash {
    my $self = shift @_;
    if(my $as = $self->_search_attributes_for('Auto_stash')) {
        my ($value, @extra) =  eval $as || eval '"$as"';
        if(@extra) {
            return $value;
        } else {
            return $value;
        }
    } else {
        return 0;
    }
}

has 'handlers' => (
    is => 'ro',
    isa => Handlers,
    coerce => 1,
    predicate => 'has_handlers',
);

sub resultset_from_model {
    my ($self, $controller, $ctx, $store_value) = @_;
    return $ctx->model($store_value);
}

sub resultset_from_accessor {
    my ($self, $controller, $ctx, $store_value) = @_;
    if(my $code = $controller->can($store_value)) {
        return $controller->$code();
    } else {
        $ctx->error("$store_value is not a accessor on $controller");
    }
    return;
}

sub resultset_from_stash {
    my ($self, $controller, $ctx, $store_value) = @_;
    return $ctx->stash->{$store_value};
}

sub resultset_from_value {
    my ($self, $controller, $ctx, $store_value) = @_;
    return $store_value;
}

sub resultset_from_code {
    my ($self, $controller, $ctx, $store_value) = @_;
    my $code = ref $store_value eq 'CODE' ? $store_value : $controller->can($store_value);
    my @args = @{$ctx->req->args};
    if($code) {      
        return $code->($controller, $self, $ctx, @args);
    } else {
        $ctx->error("Can't call code when it doesn't exist");
    }
}

sub prepare_resultset {
    my ($self, $controller, $ctx) = @_;
    my ($store_type, $store_value) = %{$self->store};

    my $resultset;
    if(my $code = $self->can('resultset_from_'.$store_type)) {
        $resultset = $self->$code($controller, $ctx, $store_value);
    } else {
        Catalyst::Exception->throw(message=>"'$store_type' is not valid.");
    }

    if($resultset && ref $resultset && $resultset->isa('DBIx::Class::ResultSet')) {
        return $resultset;
    } else {
        Catalyst::Exception->throw(message=>"Your Store ($store_type) failed to return a ResultSet, got a $resultset.");
    }
}

sub columns_from_find_condition {
    my ($self, $resultset, $find_condition) = @_;
    my @columns;
    if(my $constraint_name = $find_condition->{constraint_name}) {
        @columns = $resultset->result_source->unique_constraint_columns($constraint_name);
    } else {
        if(@columns = @{$find_condition->{columns}}) {
            unless($resultset->result_source->name_unique_constraint(\@columns)) {
                my $columns = join ',', @columns;
                my $name = $resultset->result_source->name;
                Catalyst::Exception->throw(message=>"Fields [$columns] don't match any constraints in source $name");           
            }
        } else {
            Catalyst::Exception->throw(message=>'You need either a constraint_name or columns definition');
        }
    }
    if(my $match_order = $find_condition->{match_order}) {
        my @match_order = @$match_order;
        if( 
            (@match_order == @columns) and
            all(@match_order) eq any(@columns)
        ) {
            @columns = @match_order;
        } else {  
            Catalyst::Exception->throw(message=>"Bad match_order definition ". join(',', @match_order));
        }
    }
    return @columns;
}

sub prepare_find_condition {
    my ($self, $args, $columns) = @_;
    my %find_condition = map {$_ => shift(@$args)} @$columns;
    return %find_condition;
}

sub result_from_columns {
    my ($self, $resultset, $args, $columns) = @_;
    my %find_condition = $self->prepare_find_condition($args, $columns);
    my $found_or_not;
    $found_or_not = $resultset->find(\%find_condition);
    return $found_or_not;
}

sub get_type_target {
    my ($self, $controller, $handler) = @_;
    if($self->has_handlers && $self->handlers->{$handler}) {
        return %{$self->handlers->{$handler}};
    } else {
        return ('forward', 
            ($controller->action_for($self->name .'_'. uc($handler)) || 
            $controller->action_for(uc($handler)))
        );
    }        
}

around 'dispatch' => sub  {

    my $orig = shift @_;
    my $self = shift @_;
    my $ctx = shift @_;

    my $controller = $ctx->component($self->class);
    my $resultset = $self->prepare_resultset($controller,$ctx);
 
    my ($row, @err);
    for my $find_condition( @{$self->find_condition}) {
        my @args = @{$ctx->req->args};
        my @columns = $self->columns_from_find_condition($resultset, $find_condition);

        unless(@columns == @args) {
            my $err = 'the number of args ($#args) does not equal the constraint fields ($#columns)';
            Catalyst::Exception->throw(message=>$err);
        }

        try {
            $row = $self->result_from_columns($resultset, \@args, \@columns);
        } catch {
            push @err, $_;
        };

        last if $row;
    }

    if($row && $self->auto_stash) {
        my $key = $self->auto_stash;
        $key = $key=~m/^[\w]{2,}/ ? $key : $self->name;
        Catalyst::Exception->throw(message=>"$key is already defined in the stash!")
          if defined($ctx->stash->{$key});
        $ctx->stash($key => $row);
    }

    my $final_action_result = $self->$orig($ctx, @_);

    if(scalar @err) {
        my ($type, $target) = $self->get_type_target($controller, 'error');
        if($target) {
             $ctx->$type( $target, [$_, @{$ctx->req->args}] ) for @err;
        } else {
            Catalyst::Exception->throw(message=>join(',', @err));
        }
    } 

    if($row) {
        my ($type, $target) = $self->get_type_target($controller, 'found');
        if($target) {
            $final_action_result = $ctx->$type( $target, [$row, @{$ctx->req->args}] );
        } 
    } else {
        my ($type, $target) = $self->get_type_target($controller, 'notfound');
        if($target) {
            $final_action_result =  $ctx->$type( $target, $ctx->req->args );
        }
    }

    return $final_action_result;
};

1;

=head1 NAME

Catalyst::ActionRole::BuildDBICResult - Find a DBIC Results from Arguments

=head1 SYNOPSIS

The following is example usage for this role.

    package MyApp::Controller::MyController;

    use Moose;
    use namespace::autoclean;

    BEGIN { extends 'Catalyst::Controller::ActionRole' }
 
    __PACKAGE__->config(
        action_args => {
            user => { store => 'DBICSchema::User' },
        }
    );

    sub user :Path :Args(1) 
        :Does('FindsDBICResult')
    {
        my ($self, $ctx, $id) = @_;

        ## This is always executed, and is done so before we dispatch to one of
        ## the following condition actions (but not before we attempt to find 
        ## the @args in your store resultset. 
    }

    sub  user_FOUND :Action {
        my ($self, $ctx, $user, $id) = @_;
        
        ## Your $id was found in DBICSchema::User and was passed to the action
        ## as $user.  You also get the original $id in case you need it.
    }

    sub user_NOTFOUND :Action {
        my ($self, $ctx, $id) = @_;
         $ctx->go('/error/not_found'); 
    }

    sub user_ERROR :Action {
        my ($self, $ctx, $error, $id = @_;
        $ctx->log->error("Error finding User with $id: $error");
        $ctx->detach; ## stop processing request;
    }

Alternatively, use the subroutine attributes version, if you prefer to keep all
the information related to actions closer together.

    package MyApp::Controller::MyController;

    use Moose;
    use namespace::autoclean;

    BEGIN { extends 'Catalyst::Controller::ActionRole' }
 
    sub user :Path :Args(1) 
        :Does('FindsDBICResult')
        :Store('DBICSchema::User')
    {
        my ($self, $ctx, $id) = @_;
    }

    ## remaining actions as in above example

Please see the test cases for more detailed examples.

=head1 DESCRIPTION

NOTE: For version 0.02 I added some code to make sure that when there are more
than one find condition we don't stop on the first error.  This was done so
that if you are trying to match on a numeric column (like a common auto inc PK)
and on some text column (such as a unique user name) we don't generate a hard
stop error when trying to do a text find against the numeric PK.  However this
approach is not ideal, and as a result I am no longer convinced that feature is
a good one.  I hack around it in case people are using this in production code
but I would encourage people to avoid using the multiply find condition feature
when the matched columns are not of the same type.

This is a L<Moose::Role> intending to enhance any L<Catalyst::Action>, typically
applied in your L<Catalyst::Controller::ActionRole> based controllers, although
it can also be consumed as a role on your custom action classes (such as any 
class which extends L<Catalyst::Action>.)

Mapping incoming arguments to a particular result in a L<DBIx::Class> based model
is a pretty common development case.  Making choices based on the return of that
result is also quite common.  For example, if you can't 'find' a record matching 
the args, you may wish to redirect to a not found error page.  The goal of this 
action role is to reduce the amount of boilerplate code you have to write to get
these common cases completed. It is intended to encapsulate all the boilerplate
code required to perform this task correctly and safely.

Basically we encapsulate the logic: "For a given resultset, does the find
condition return a valid result given the incoming arguments?  Depending on the
result, delegate to assigned handlers until the result is handled."

A find condition maps incoming action arguments to a resultset unique
constraint.  This condition resolves to one of three results: "FOUND", 
"NOTFOUND", "ERROR".  Result condition "FOUND" returns when the find condition
finds a single row against the defined ResultSet, NOTFOUND when the find
condition fails and ERROR when trying to resolve the find condition results
in a catchable error.

Based on the result condition we automatically forward to an action whose name 
matches a default template, as in the SYNOPSIS above.  You may also override
this default template via configuration.  This makes it easy to configure
common results to be handled by a common action.

Be default an ERROR result also calls a NOTFOUND (after calling the ERROR
handler), since both conditions logically match.  However ERROR is delegated to
first, so if you go/detach in that action, the NOTFOUND will not be called.

When dispatching a result condition, such as ERROR, FOUND, etc., to a handler,
we follow a hierachy of defaults or any handlers added in configuration.  The 
first matching handler takes the request and the remaining are ignored.

It is not the intention of this action role to handle 'kitchen sink' tasks
related to accessing the your DBIC model.  If you need more we recommend looking
at L<Catalyst::Controller::DBIC::API> for general API access needs or for a
more complete CRUD setup check out L<CatalystX::CRUD> or L<Catalyst::Plugin::AutoCRUD>.

=head1 EXAMPLES

Assuming "model("DBICSchema::User") is a L<DBIx::Class::ResultSet>, we can
replace the following code:

    package MyApp::Controller::MyController;

    use Moose;
    use namespace::autoclean;

    BEGIN { extends 'Catalyst::Controller' }

    sub user :Path :Args(1) {
        my ($self, $ctx, $user_id) = @_;
        my $user;
        eval {
            $user = $ctx->model('DBICSchema::User')
              ->find({user_id=>$user_id});
            1;
        } or $ctx->go('/error/server_error');

        if($user) {
            ## You Found a User, do something useful...
        } else {
            ## You didn't find a User (or got an error).
            $ctx->go('/error/not_found');
        }
    }

With something like this code:

    package MyApp::Controller::MyController;

    use Moose;
    use namespace::autoclean;

    BEGIN { extends 'Catalyst::Controller::Does' }
 
    __PACKAGE__->config(
        action_args => {
            user => { store => 'Schema::User' },
        }
    );

    sub user :Path :Args(1) 
        :Does('FindsDBICResult')
    {
        my ($self, $ctx, $arg) = @_;
    }

    sub  user_FOUND :Action {
        my ($self, $ctx, $user, $arg) = @_;
        ## You Found a User, do something useful...
    }

    sub user_NOTFOUND :Action {
        my ($self, $ctx, $arg) = @_;
         $ctx->go('/error/not_found')
    }

    sub user_ERROR :Action {
        my ($self, $ctx, $error, $arg) = @_;
         $ctx->go('/error/server_error', [$error]);
    }

Or, if you don't need to handle any code for your exceptional conditions (such
as NOTFOUND or ERROR) you can move more to the configuration:

    package MyApp::Controller::MyController;

    use Moose;
    use namespace::autoclean;

    BEGIN { extends 'Catalyst::Controller::ActionRole' }
 
    __PACKAGE__->config(
        action_args => {
            user => {
                store => 'Schema::User',
                handlers => {
                    notfound => { go => '/error/notfound' },
                    error => { go => '/error/server_error' },
                },
             },
        },
    );

    sub user :Path :Args(1) 
        :Does('FindsDBICResult')
    {
        my ($self, $ctx, $arg) = @_;
    }

    sub  user_FOUND :Action {
        my ($self, $ctx, $user, $arg) = @_;
    }

Another example this time with Chained actions and a more complex DBIC result
find condition, as well as custom exception handlers:

    __PACKAGE__->config(
        action_args => {
            user => {
                store => { stash => 'user_rs' },
                find_condition => { columns => ['email'] },
                auto_stash => 'user',
                handlers => {
                    notfound => { detach => '/error/notfound' },
                    error => { go => '/error/server_error' },
                },
            },
        },
    );

    sub root :Chained :CaptureArgs(0) {
        my ($self, $ctx) = @_;
        $ctx->stash(user_rs=>$ctx->model('DBICSchema::User'));
    }

    sub find_user :Chained('root') :CaptureArgs(1) 
        :Does('FindsDBICResult') {}

    sub show_details :Chained('user') :Args(0) 
    {
        my ($self, $ctx, $arg) = @_;
        my $user_details = $ctx->stash->{user};
        ## Do something with the #user_details, probably delegate to a View.
    }

This would replace something like the following custom code:

    sub root :Chained :CaptureArgs(0) {
        my ($self, $ctx) = @_;
        $ctx->stash(user_rs=>$ctx->model('DBICSchema::User'));
    }

    sub user :Chained('root') :CaptureArgs(1) {
        my ($self, $ctx, $email) = @_;
        my $user_rs = $ctx->stash->{user_rs};
        my $user;
        eval {
            $user = $user_rs->find({email=>$email});
            1;
        } or $ctx->go('/error/server_error');

        if($user) {
            $ctx->stash(user => $user);
        } else {
            ## You didn't find a User (or got an error).
            $ctx->detach('/error/not_found');
        }
     } 

    sub details :Chained('user') :Args(0) 
    {
        my ($self, $ctx, $arg) = @_;
        my $user_details = $ctx->stash->{user};
        ## Do something with the details, probably delagate to a View, etc.
    }

Another example where the controller is very thin, basically we are just 
getting a result (or not) from a store and letting a View pick it up:

    package MyApp::Controller::User;
    use Moose;

    BEGIN {
        extends 'Catalyst::Controller::ActionRole';
    }

    __PACKAGE__->config(
        action => {
            'user' => {
                Path => 'user',
                Args => 1,
                Does => 'BuildDBICResult',
            },
         },
        action_args => {
            'user' => {
                store => 'Schema::User',
                auto_stash => 1,
                handlers => {
                    notfound => { go => '/error/notfound' },
                    error => { go => '/error/server_error' },
                },
            },
        }
    );

    sub user {};

    1;

And assuming you have a root end action that is using L<Catalyst::Action::RenderView>
or similar, you will automatically delagate to a View object and send it a stash
with a 'user' result.

Overall the idea here is to factor out a lot of boilerplate conditionals and
replace them with a reasonable set of declarative conventions.  Additionally
more behavior is moved to configuration, which will allow more flexible and
rapid development and more easily centralized behaviors.

NOTE: Variable and class names above choosen for documentation readability
and should not be considered best practice recomendations. For example, I would
not name my L<Catalyst::Model::DBIC::Schema> based model 'DBICSchema'.
 
=head1 ATTRIBUTES

This role defines the following attributes.

=head2 store

This defines the accessor by which we get a L<DBIx::Class::ResultSet> suitable
for applying a L</find_condition>.  The canonical form is a HashRef where the
keys / values conform to the following template.

    { model||accessor||stash||value||code => Str||Code }

Default is C<accessor => 'model_resultset'>, details follow:

=over 4

=item {model => '$dbic_model_name'}

Store comes from a L<Catalyst::Model::DBIC::Schema> based model.  This is the
string you put in "$c->model" as in "$c->model('DBICSchema::User')".

    __PACKAGE__->config(
        action_args => {
            user => {
                store => { model  => 'DBICSchema::User' },
            },
        }
    );

This retrieves a L<DBIx::Class::ResultSet> via $ctx->model($dbic_model_name).

=item {accessor => '$get_resultset'}

Calls a accessor on the containing controller.  This is defined as a method
which returns but doesn't mutate the instance data, such as created by "is=>'ro'"
in a L<Moose> attribute option list.

    __PACKAGE__->config(
        action_args => {
            user => {
                store => { accessor => 'user_resultset' },
            },
        }
    );

    has user_resultset => (
        is => 'ro',
        lazy_build =>1,
    );

    sub _build_user_resultset {
        my ($self) = @_;
        return $self->_app->model('Schema::User');
    }

    sub user :Action :Does('BuildDBICResult') :Args(1) {
        my ($self, $ctx, $arg) = @_;
    }

    sub user_FOUND :Action {
        my ($self, $ctx, $user, $arg) = @_;
    }

The containing controller must define this accessor and it must return a proper
L<DBIx::Class::ResultSet> or an exception is thrown.

Since this is an accessor we are calling, we just invoke it with the calling
controller instance only, as in $controller->$accessor.  If you need a more
flexible code object, or something that can have access to more information
please see the 'code' store below.


=item {stash => '$name_of_stash_key' }

Looks in $ctx->stash->{$name_of_stash_key} for a resultset.

    __PACKAGE__->config(
        action_args => {
            user => {
                store => { stash => 'user_rs' },
            },
        }
    );

This is useful if you are descending a chain of actions and modifying or
restricting a resultset based previous user actions.

=item {value => $resultset_object}

Assigns a literal value, expected to be a value L<DBIx:Class::ResultSet>

    __PACKAGE__->config(
        action_args => {
            user => {
                store => { value => $schema->resultset('User') },
            },
        }
    );

Useful if you need to directly assign an already prepared resultset as the 
value for doing $rs->find against.  You might use this with a more capable
inversion of control container, such as L<Catalyst::Plugin::Bread::Board>.

=item {code => sub { ... }||'controller_method_name'}

Similar to the 'value' option above, might be useful if you are doing tricky
setup.  Should be a subroutine reference that return a L<DBIx::Class::ResultSet>
or the string name of a method inside the containing controller.

    sub get_me_a_resultset {
        my ($controller, $action, $ctx, @args) = @_;
        ## Some custom instantiation needs
        return $resultset;
    }

    __PACKAGE__->config(
        action_args => {
            user => {
                store => {
                    code => 'get_me_a_resultset',
                },
            },
            role => {
                store => { 
                    code => sub {
                        my ($controller, $action, $ctx, @args) = @_;
                        ## inlined code
                        return #resultset;
                    },
                },
            },
        }
    );

The coderef gets the following arguments: $controller, which is the controller
object containing the action, $action, which is the action object for the 
L<Catalyst::Action> based instance, $ctx, which is the current context, and an array
of arguments which are the arguments passed to the action.

=back

NOTE: In order to reduce extra boilerplate and needless typing in your
configuration, we will automatically try to coerce a String value to one of the
listed HashRef values.  We coerce depending on the String value given based on
the following criteria:

=over 4

=item store => Str

We automatically coerce a Str value of $str to {model => $str}, IF $str
begins with an uppercased letter or the string contains "::", indicating the
value is a namespace target, and to {stash => $str} otherwise.  We believe
this is a common case for these types.

    __PACKAGE__->config(
        action_args => {
            user => {
                ## Internally coerced to "store => {model=>'DBICSchema::User'}".
                store => 'DBICSchema::User',
            },
        }
    );


    ## Perl practices indicate you should Title Case object namespaces, but
    ## in case you have some of these we try to detect and do the right thing.

    __PACKAGE__->config(
        action_args => {
            user => {
                ## Internally coerced to "store => {model=>'schema::user'}".
                store => 'schema::user',
            },
        }
    );

    __PACKAGE__->config(
        action_args => {
            user => {
                ## Internally coerced to "store => {stash =>'user_rs'}".
                store => 'user_rs',
            },
        }
    );

=item store => blessed $object isa L<DBIx::Class::ResultSet>

If the value is a blessed object of the correct type (L<DBIx::Class::ResultSet>)
we just assume your want a 'value' type.

    __PACKAGE__->config(
        action_args => {
            user => {
                ## Internally coerced to "store => {value => $user_resultset}".
                store => $user_resultset,
            },
        }
    );

=item store => CodeRef

If the value is a subroutine reference, we coerce to the coderef type.

    __PACKAGE__->config(
        action_args => {
            user => {
                ## Internally coerced to "store => { code => sub {...} }".
                store => sub { ... },
            },
        }
    );

=back

Coercions are of course optional; you may wish to skip them to you want better
self documenting code.

=head2 find_condition

This should a way for a given resultset (defined in L</store> to find a single
row.  Not finding anything is also an accepted option.  Everything else is some
sort of error.

Canonically is an ArrayRef of HashRefs where:

    [\%condition1, \%condition2, ...]

an where %condition is one of:

    {constraint_name => '$name', ?match_order? => \@fields}
    {columns => \@fields}

However we define some coercions for simple causes.  If no value is supplied we
default to {constraint_name => 'primary'}.

    ## in your DBIx::Class ResultSource
	__PACKAGE__->set_primary_key('category_id');
	__PACKAGE__->add_unique_constraint(category_name_is_unique => ['name']);

    ## in your L<Catalyst::Controller>
    __PACKAGE__->config(
        action_args => {
            category => {
                store => {model => 'DBICSchema::Category'},
                find_condition => [
                    'primary',
                    'category_name_is_unique',
                ], ## ArrayRef[Str] coerced to {constraint_name => ...}
            }
        }
    );

    sub category :Path :Args(1) :Does('FindsDBICResult') {
        my ($self, $ctx, $category_arg) = @_;
    }

    sub category_FOUND :action {}
    sub category_NOTFOUND :action {}
    sub category_ERROR :action {}

In this example $category_arg would first be checked as a primary key, and then
as a category name field.  This allows you a degree of polymorphism in your url
design or web api.

Each unique constraint refers to one or more columns in your database.  Incoming
args to an action are mapped to columns by the order they are defined in the
primary key or unique constraint condition, or in a configured order.

Example of reordering multi field unique constraints:

    ## in your DBIx::Class ResultSource
	__PACKAGE__->add_unique_constraint(user_role_is_unique => ['user_id', 'role_id']);

    ## in your L<Catalyst::Controller>
    __PACKAGE__->config(
        action_args => {
            user_role => {
                store => {model => 'DBICSchema::UserRole'},
                find_condition => [
                    {
                        constraint_name => 'category_name_is_unique',
                        match_order => ['role_id','user_id'],
                    }
                ],
            }
        }
    );

In the above case 'match_order' is used to define an explict expected order to
map incoming arguments to fields in a result store constraints.  If you don't
set the match_order for a constraint_name, we default to the order you defined 
in your result store. Since this might change we recommend using match_order 
when you have a multi field constraint.

Additionally since most developers don't bother to name their unique constraints
we allow you to specify a constraint by its column(s):

    ## in your DBIx::Class ResultSource
	__PACKAGE__->add_unique_constraint(['user_id', 'role_id']);

    ## in your L<Catalyst::Controller>
    __PACKAGE__->config(
        action_args => {
            user_role => {
                store => {model => 'DBICSchema::UserRole'},
                find_condition => [
                    {
                        columns => ['user_id','role_id'],
                    }
                ],
            }
        }
    );

    sub role_user :Path :Args(2) {
        my ($self, $ctx, $role_id, $user_id) = @_;
    }

Please note that 'columns' is used merely to discover the unique constraint 
which has already been defined via 'add_unique_constraint'.  You cannot name
columns which are not already marked as fields in a unique constraint or in a
primary key.  The order you define fields in your columns option should map 
directly to the order expected by the incoming args.  So if your find_condition
style is columns, you don't need to use match_order.

We automatically handle the common case of mapping a single field primary key
to a single argument in a controller "Args(1)".  If you fail to defined a
find_condition this is the default we use.

Please see L</FIND CONDITIONS DETAILS> for more examples.

<B>NOTE:</B> The feature that allows more than a single find condition per
action binding is now considered ill advised, since having a lookup across
columns of different types can result in database bind type errors.  We could
probably solve this issue by performing some sanity tests on the conditions
using the available column meta-data; test cases and patch very welcomed!

=head2 auto_stash

If this is true (default is false), upon a FOUND result, place the found
result into the stash.  If the value is alpha_numeric, that value is
used as the stash key.  if it is 1 or '1' we instead default to the name of 
the accessor associated with the consuming action.  For example:

    __PACKAGE__->config(
        action_args => {
            user => { store => 'DBICSchema::User', auto_stash => 1 },
        },
    );

    sub user :Path :Args(1) {
        my ($self, $ctx, $user_id) = @_;
        ## $ctx->stash->{user} is defined if $user_id is found.
    }

This could be combined with the L</handlers> attribute to make fast mocks and
prototypes.  See below.

NOTE: Currently if you set auto_stash to the string 'true' or 'TRUE', this will
behave as though you are specifying the stash key (as in $c->stash(true=>$row))
which maybe not be what you want.  This may change in the future in order to
increase compatibility with configuration serialization that store booleans as
"true", "false", etc.  As a result we recommend avoiding using those key words 
as your stash key.

=head2 handlers

Expects a HashRef and is optional.

By default we delegate result conditions (FOUND, NOTFOUND, ERROR) to an action
from a list of predefined options.  These predefined options work very similarly
to L<Catalyst::Action::REST>, so if you are familiar with that system this will
seem very natural.

First we try to match a result to an action specific handler, which follows the
template $action_name .'_'. $result_condition.  So for an action named 'user'
which is consuming this role, there could be actions 'user_FOUND', 'user_NOTFOUND',
'user_ERROR' which would get $ctx->forwarded too AFTER executing the body of
the consuming action.

If this template fails to match (as in you did not define such an action in
the same L<Catalyst::Controller> subclass as your consuming action) we then
look for a 'global' action in the controller, which is in the form of an action
named $result_condition (basically actions named FOUND, NOTFOUND or ERROR).

This could be useful if you wish to centralize control of execeptional 
conditions.  For example you could create a base controller or controller role
that defined the "NOTFOUND" or "ERROR" actions and then extend or consume that 
into the controller containing actions using this action role.  

However there may be cases where you need direct control over the action that
get's called for a given result condition.  In this case you can add handlers
to the end of the lookup list for a given result condition.  This is a HashRef
that accepts one or more of the following keys: found, notfound, error. Example:

    handlers => {
        found => { forward||detach||go||visit => $found_action_name },
        notfound => { forward||detach||go||visit => $notfound_action_name },
        error => { forward||detach||go||visit => $error_action_name },
    }

Globalizing the 'error' and 'notfound' action handlers is probably the most 
useful.  Each option key within 'handlers' canonically takes a hashref, where
the key is either 'forward' or 'detach' and the value is the name of something we
can call "$ctx->forward" or "$ctx->detach" on.  We coerce from a string value
into a hashref where 'detach' is the key.  Example:

    handlers => { notfound => '/notfound' },

would coerce to "handlers => {notfound => {detach => '/notfound'}}"

=head1 SUBROUTINE ATTRIBUTES

So far all the examples given have demonstrated used via configuration and the
C<action_args> key.  Personally, I think this is the most flexible and clean
option.  However, L<Catalyst> actions have traditionally supported subroutine
attributes as a means of configuration.  Although subroutine attributes have
some significant drawbacks, you may prefer them if you think of the configuration
information as fundenmental to your action / controller design.  If so, the
following attributes can be set in this manner.

=over 4

=item Store

Same as C<$action => {store => $storage}>.  Example:

    sub myaction :Action
        Store('{model=>"Schema::User"}')

=item Find_condtion

Same as C<$action => {store => $storage}>.  Example:

    sub myaction :Action
        Find_condition('{model=>"Schema::User"}')

=back

Currently the options C<handlers> is not supported in this manner.  This is
because the data structures that compose this options are highly prone to 
error when I tried to write tests for them.  Rational disagreement and patches
in support would be very welcomed.

=head1 FIND CONDITION DETAILS

This section adds details regarding what a find condition is ond provides some
examples.

=head2 defining a find condition

By default we automatically handle the most common case, where a single argument
maps to a single column primary key field.  In every other case, such as when
you have multi field primary keys or you are finding by an alternative unique
constraint (either single or multi fields) you need to declare the name of the
L<DBIx::Class::ResultSource> unique constraint you are matching against.  Since
L<DBIx::Class> does not require you to name your unique constraints (many people
let the underlying database follow its default convention in this matter),
instead of a unique constraint name you may pass an ArrayRef of one or more
columns which together define a uniqiue constraint.  Please note if you use this
form of defining a find condition, you must use an ArrayRef EVEN if your condition
has only a single column.

Also note that in the case of multi field primary keys or unique constraints,
we attempt to match against the field order as defined in your call to
L<DBIx::Class::ResultSource/primary_columns> or
L<DBIx::Class::ResultSource/add_unique_constraint>.

If you need to to specify the mapping of L<Catalyst> arguments to unique
constraint fields, please see 'match_order' options.
    
=head2 example find conditions

Find where one arg is mapped to a single field primary key (default case).

    __PACKAGE__->config(
        action_args => {
            photo => {
                store => 'Schema::User',
                find_condition => 'primary',
            }
        }
    );

BTW, the above would internally 'canonicalize' the find_condition to:

    find_condition => [{
        constraint_name=>'primary',
        match_order=>['user_id'],
    }],

Same as above but the find condition can be any of several named constraints, 
all of which have the same number of fields.  In this case we'd expect the 
underlying User ResultSource to define a primary key and a unique constraint
named 'unique_email'.

    __PACKAGE__->config(
        action_args => {
            photo => {
                store => 'Schema::User',
                find_condition => ['primary', 'unique_email'],
            }
        }
    );

Same as above, but the unique email constraint was not named so we need to map
some fields to a unique constraint.  Please note we actually look for a unique
constraint using the named columns, failed matches throw an expection.

    __PACKAGE__->config(
        action_args => {
            photo => {
                store => 'Schema::User',
                find_condition =>  [
                    'primary', 
                    { columns => ['email'] },
                ],
            },
        },
    );

An example where the find condition is a mult key unique constraint.  This
example also demonstrates the HashRef to ArrayRef of HashRefs coercion.

    __PACKAGE__->config(
        action_args => {
            photo => {
                store => 'Schema::User',
                find_condition => {
                    columns => ['user_id','role_id'],
                },
            },
        },
    );

As above but lets you specify an argument to field order mapping which is
different from that defined in your L<DBIx::Class::ResultSource>.  This let's
you decouple your L<Catalyst> action arg definition from your L<DBIx::Class::ResultSource>
definition.

    __PACKAGE__->config(
        action_args => {
            photo => {
                store => 'Schema::UserRole',
                find_condition =>  {
                    constraint_name => 'primary',
                    match_order => ['fk_role_id','fk_user_id'],
                },
            }
        }
    );

Again, the above example coerces to ArrayRef of HashRefs.  Please keep this in
mind if you introspect the $action instance, since the coerced values may
differ from those you placed in the configuration!

=head1 NOTES

The following section is additional notes regarding usage or questioned related
to this action role.

=head2 Why an Action Role and not an Action Class?

Role are more flexible, you can combine many roles easily to compose flexible
behavior in an elegant way.  This does of course mean that you will need a
more modern L<Catalyst> based on L<Moose>.

=head2 Why require such a modern L<Catalyst>?

We need a version of L<Catalyst> that is post the L<Moose> migration; additionally
we need equal to or greater than version '5.80025' for the ability to define 
'action_args' in a controller.  See L<Catalyst::Controller> for more.

=head1 AUTHOR

John Napiorkowski <jjnapiork@cpan.org>

=head1 COPYRIGHT & LICENSE

Copyright 2010, John Napiorkowski <jjnapiork@cpan.org>

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

