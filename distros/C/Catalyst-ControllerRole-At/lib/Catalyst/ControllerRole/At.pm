package Catalyst::ControllerRole::At;

use Moose::Role;
our $VERSION = '0.008';

sub _parse_Get_attr {
  my ($self, $app, $action_subname, $value) = @_;
  my %attributes = $self->_parse_At_attr($app, $action_subname, $value);
  $attributes{Method} = 'GET';
  return %attributes;
}

sub _parse_Post_attr {
  my ($self, $app, $action_subname, $value) = @_;
  my %attributes = $self->_parse_At_attr($app, $action_subname, $value);
  $attributes{Method} = 'POST';
  return %attributes;
}

sub _parse_Put_attr {
  my ($self, $app, $action_subname, $value) = @_;
  my %attributes = $self->_parse_At_attr($app, $action_subname, $value);
  $attributes{Method} = 'PUT';
  return %attributes;
}

sub _parse_Delete_attr {
  my ($self, $app, $action_subname, $value) = @_;
  my %attributes = $self->_parse_At_attr($app, $action_subname, $value);
  $attributes{Method} = 'DELETE';
  return %attributes;
}

sub _parse_Head_attr {
  my ($self, $app, $action_subname, $value) = @_;
  my %attributes = $self->_parse_At_attr($app, $action_subname, $value);
  $attributes{Method} = 'HEAD';
  return %attributes;
}

sub _parse_Options_attr {
  my ($self, $app, $action_subname, $value) = @_;
  my %attributes = $self->_parse_At_attr($app, $action_subname, $value);
  $attributes{Method} = 'OPTIONS';
  return %attributes;
}

sub _parse_Patch_attr {
  my ($self, $app, $action_subname, $value) = @_;
  my %attributes = $self->_parse_At_attr($app, $action_subname, $value);
  $attributes{Method} = 'PATCH';
  return %attributes;
}

sub _parse_At_attr {
  my ($self, $app, $action_subname, $value) = @_;
  my ($chained, $path_part, $arg_type, $args, %extra_proto) = ('/','','Args',0, ());
  
  my @controller_path_parts = split('/', $self->path_prefix($app));
  my @parent_controller_path_parts = @controller_path_parts;
  my $affix = pop @parent_controller_path_parts;

  my %expansions = (
    '$up' => '/' . join('/', @parent_controller_path_parts),
    '$parent' =>  '/' . join('/', @parent_controller_path_parts, $action_subname),
    '$name' => $action_subname,
    '$controller' => '/' . join('/', @controller_path_parts),
    '$action' => '/' . join('/', @controller_path_parts, $action_subname),
    '$affix' =>  '/' . ($affix||''),
  );

  $expansions{'$path_prefix'} = $expansions{'$controller'}; # Backwards compatibility
  $expansions{'$path_end'} = $expansions{'$affix'}; # Backwards compatibility

  $value = ($value||'') . '';
  my ($path, $query) = ($value=~/^([^?]*)\??(.*)$/);
  my (@path_parts) = map { $expansions{$_} ? $expansions{$_} :$_ } split('/', ($path||''));

  my @arg_proto;
  my @named_fields;

  if($query) {
    my @q = ($query=~m/{(.+?)}/g);
    $extra_proto{QueryParam} = \@q;
    foreach my $q (@q) {
      my ($q_part, $type) = split(':', $q);
      if(defined($q_part)) {
        if($q_part=~m/=/) {
          ($q_part) = split('=', $q_part); # Discard any=default
        }
        $q_part=~s/^[!?]//;
        $extra_proto{Field} = $extra_proto{Field} ?
          "$extra_proto{Field},$q_part=>\$query{$q_part}" : "$q_part=>\$query{$q_part}"
      }
    }
  }

  if(($path_parts[-1]||'') eq '...') {
    $arg_type = 'CaptureArgs';
    pop @path_parts;
  }

  while(my ($spec) = (($path_parts[-1]||'') =~m/^{(.*)}$/)) {
    if($spec) {
      my ($name, $constraint) = split(':', $spec);
      unshift @arg_proto, $constraint if $constraint;
      if($name) {
        if($name eq '*') {
          $args = undef;
        } else {
          unshift @named_fields, $name;
        }
      } else {
        unshift @named_fields, undef;
      }
    }
    $args++ if defined $args;
  } continue {
    pop @path_parts;
  }

  {
    my $cnt = 0;
    foreach my $name (@named_fields) {
      if(defined($name)) {
        $extra_proto{Field} = $extra_proto{Field} ?
          "$extra_proto{Field},$name=>\$args[$cnt]" : "$name=>\$args[$cnt]"
      }
      $cnt++;
    }
  }

  if(
    my ($key, $value) = map { $_ =~ /^(.*?)(?:\(\s*['"]?(.+?)['"]?\s*\))?$/ } grep { $_ =~m/^Via\(.+\)$/ } 
      @{$self->meta->get_method($action_subname)->attributes||[]})
  {
    $chained = join '/', grep { defined $_  } map { $expansions{$_} ? $expansions{$_} : $_ } split('\/',$value);
    $chained =~s[//][/]g;
  }

  $path_part = join('/', @path_parts);
  $path_part =~s/^\///;

  my %attributes = (
    Chained   => $chained,
    PathPart  => $path_part,
    Does => [qw/NamedFields QueryParameter/],
    $arg_type => (@arg_proto ? (join(',',@arg_proto)) : $args),
    %extra_proto,
  );

  return %attributes;
}

1;

=head1 NAME

Catalyst::ControllerRole::At - A new approach to building Catalyst actions

=head1 SYNOPSIS

    package MyApp::Controller::User;

    use Moose;
    use MooseX::MethodAttributes;
    use Types::Standard qw/Int Str/;

    extends 'Catalyst::Controller';
    with 'Catalyst::ControllerRole::At';

    # Define your actions, for example:
    
    sub global :At(/global/{}/{}) { ... }         # http://localhost/global/$arg/$arg

    sub list   :At($action?{q:Str}) { ... }       # http://localhost/user/list?q=$string

    sub find   :At($controller/{id:Int}) { ... }  # http://localhost/user/$integer

    # Define an action with an HTTP Method match at the same time

    sub update :Get($controller/{id:Int}) { ... } # GET http://localhost/user/$integer

    __PACKAGE__->meta->make_immutable;

=head1 DESCRIPTION

The way L<Catalyst> uses method attributes to annote a subroutine with meta
information used to map that action to an incoming request has sometimes been difficult
for newcomers to the framework.  Partly this is due to how the system evolved and was
augmented, with more care towards backwards compatibility (for example with L<Maypole>, its
architectural anscestor) than with designing a forward system that is easy to grasp.
Additionally aspects of the system such as chained dispatch are very useful in the
hands of an expert but the interface leaves a lot to be desired.  For example it is
possible to craft actions that mix chaining syntax with 'classic' syntax in ways that
are confusing.  And having more than one way to do the same thing without clear and
obvious benefits is confusing to newcomers.

Lastly, the core L<Catalyst::Controller> syntax has confusing defaults that are not readily guessed.
For example do you know the difference (if any) between Args and Args()?  Or the difference
between Path, Path(''), and Path()?  In many cases defaults are applied that were not
intended and things that you might think are the same turn out to have different effects.  All
this conspires to worsen the learning curve.

This role defines an alternative syntax that we hope is easier to understand and for the most
part eliminates defaults and guessed intentions.  It only defines two method attributes, "At()"
and "Via()", which have no defaults and one of which is always required.  It also smooths
over differences between 'classic' route matching using :Local and :Path and the newer
syntax based on Chaining by providing a single approach that bridges between the two
styles.  One can mix and match the two without being required to learn a new syntax or to
rearchitect the system.

The "At()" syntax more closely resembles the type of URL you are trying to match, which should
make code creation and maintainance easier by reducing the mental mismatch that happens with
the core syntax.

Ultimately this ControllerRole is an attempt to layer some sugar on top of the existing
interface with the hope to establishing a normalized, easy approach that doesn't have the
learning curve or confusion of the existing system.

I also recommend reading L<Catalyst::RouteMatching> for general notes and details on
how dispatching and matching works.

=head1 URL Templating

The following are examples and specification for how to map a URL to an action or to
a chain of actions in L<Catalyst>. All examples assume the application is running at
the root of your website domain (https://localhost/, not https://localhost/somepath)

=head2 Matching a Literal Path

The action 'global_path' will respond to 'https://localhost/foo/bar/baz'.

    package MyApp::Controller::Example;

    use Moose;
    use MooseX::MethodAttributes;

    extends 'Catalyst::Controller';
    with 'Catalyst::ControllerRole::At';

    sub global_path :At(/foo/bar/baz) { ... }

    __PACKAGE__->meta->make_immutable;

The main two parts are consuming the role c< with 'Catalyst::ControllerRole::At'>
and using the C<At> method attribute.  This attribute can only appear once in your
action and should be string that matches a specification as to be described in the
following examples.

=head2 Arguments in a Path specification

Often you wish to parameterize your URL template such that instead of matching a full
literal path, you may instead place slots for placeholders, which get passed to the
action during a request.  For example:

    package MyApp::Controller::Example;

    use Moose;
    use MooseX::MethodAttributes;

    extends 'Catalyst::Controller';
    with 'Catalyst::ControllerRole::At';

    sub args :At(/example/{}) {
      my ($self, $c, $arg) = @_;     
    }

    __PACKAGE__->meta->make_immutable;

In the above controller we'd match a URL like 'https://localhost/example/100' and
'https://localhost/example/whatever'.  The parameterized argument is passed as '$arg'
into the action when a request is matched.

You may have as many argument placeholders as you wish, or you may specific an open
ended number of placeholders:

    sub arg2 :At(/example/{}/{}) { ... }  # https://localhost/example/foo/bar
    sub args :At(/example/{*} { ... }     # https://localhost/example/1/2/3/4/...

In this case action 'arg2' matches its path with 2 arguments, while 'args' will match
'any number of arguments', subject to operating system limitations.

B<NOTE> Since the open ended argument specification can catch lots of URLs, this type
of argument specification is run as a special 'low priorty' match.  For example (using
the above two actions) should the request be 'https://localhost/example/foo/bar', then
the first action 'arg2' would match since its a better match for that request given it
has a more constrained specification. In general I recommend using '{*}' sparingly.

B<NOTE> Placeholder must come after path part literals or expansion variables as discussed
below.  For example "At(/bar/{}/bar)" is not valid.  This type of match is possible with
chained actions (see more examples below).

=head2 Naming your Arguments

You may name your argument placeholders.  If you do so you can access your argument
placeholder values via the %_ hash.  For example:

    sub args :At(/example/{id}) {
      my ($self, $c, $id) = @_;
      $c->response->body("The requested ID is $_{id}");
    }

Note that regardless of whether you name your arguments or not, they will get passed to
your actions at request via @_, as in core L<Catalyst>.  So in the above example '$id'
is equal to '$_{id}'.  You may use whichever makes the most sense for your task, or
standardize a project on one form or the other.  You might also find naming the arguments
to be a useful form of documentation.

=head2 Type constraints on your Arguments

You may leverage the built in support for applying type constraints on your arguments:

    package MyApp::Controller::Example;

    use Moose;
    use MooseX::MethodAttributes;
    use Types::Standard qw/Int/;

    extends 'Catalyst::Controller';
    with 'Catalyst::ControllerRole::At';

    sub args :At(/example/{id:Int}) {
      my ($self, $c, $id) = @_;     
    }

    __PACKAGE__->meta->make_immutable;

Would match 'http://localhost/example/100' but not 'http://localhost/example/string'

All the same rules that apply to L<Catalyst> regarding use of type constraints apply.  Most
importantly you must remember to inport your type constraints, as in the above example.  You
should consider reviewing L<Catalyst::RouteMatching> for more general help.

You may declare a type constraint on an argument but not name it, as in the following
example:

    sub args :At(/example/{:Int}) {
      my ($self, $c, $id) = @_;     
    }

Note the ':' prepended to the type constraint name is NOT optional.

B<NOTE> Using type constraints in your route matching can have performance implications.

B<NOTE> If you have more than one argument placeholder and you apply a type constraint to
one, you must apply constraints to all.  You may use an open type constraint like C<Any>
as defined in L<Types::Standard> for placeholders where you don't care what the value is.  For
example:

    use Types::Standard qw/Any Int/;

    sub args :At(/example/{:Any}/{:Int}) {
      my ($self, $c, $id) = @_;     
    }

=head2 Expansion Variables in your Path

B<NOTE> Over the years since this role was first written I have found in general that
these expansions seem to add more confusion then they are worth.  I find I really don't
need them.  Your results may vary.  I won't remove them for back compat reasons, but
I recommend using them sparingly.  '$affix' appears to have some value but the name isn't
very good.  I Added an alias '$path_end' which is slightly better I think.   Recommendations
welcomed.

Generally you would prefer not to hardcode the full path of your actions, as in the
examples given so far.  General Catalyst best practice is to have your actions live
under the namespace of the controller in which they are defined.  That makes things
more organized and easier to find as your application grows in complexity.  In order
to make this and other common action template patterns easier, we support the following
variable expansions in your URL template specification:

    $controller: Your controller namespace (as an absolute path)
    $path_prefix: Alias for $controller
    $action: The action namespace (same as $controller/$name)
    $up: The namespace of the controller containing this controller
    $name The name of your action (the subroutine name)
    $affix: The last part of the controller namespace.

For example if your controller is 'MyApp::Controller::User::Details' then:

    $controller => /user/details
    $up => /user
    $affix => /details

And if 'MyApp::Controller::User::Details' contained an action like:

    sub list :At() { ... }

then:

    $name => /list
    $action => /user/details/list

You use these variable expansions the same way as literal paths:

    package MyApp::Controller::Example;

    use Moose;
    use MooseX::MethodAttributes;
    use Types::Standard qw/Int/;

    extends 'Catalyst::Controller';
    with 'Catalyst::ControllerRole::At';

    sub args :At($controller/{id:Int}) {
      my ($self, $c, $id) = @_;     
    }

    sub list :At($action) { ... }

    __PACKAGE__->meta->make_immutable;

In this example the action 'args' would match 'https://localhost/example/100' (with '100' being
considered an argument) while action 'list' would match 'https::/localhost/example/list'.

You can use expansion variables in your base controllers or controller roles to more
easily make shared actions.

B<NOTE> Your controller namespace is typically based on its package name, unless you
have overridden it by setting an alternative in the configuation value 'namespace', or
your have in some way overridden the logic that produces a namespace.  The default
behavior is to produce a namespace like the following:

    package MyApp::Controller::User => /user
    package MyApp::Controller::User::name => /user/name

Changing the way a controller defines its namespace will also change how actions that are
defined in that controller defines thier namespaces.

B<NOTE> WHen using expansions, you should not place a '/' at the start of your
template URI.

=head2 Matching GET parameters

You can match GET (query) parameters in your URL template definitions:

    package MyApp::Controller::Example;

    use Moose;
    use MooseX::MethodAttributes;
    use Types::Standard qw/Int Str/;

    extends 'Catalyst::Controller';
    with 'Catalyst::ControllerRole::At';

    sub query :At($action?{name:Str}{age:Int}) {
      my ($self, $c, $id) = @_;     
    }

    __PACKAGE__->meta->make_immutable;

This would match 'https://example/query?name=john;age=47'.

Your query keys will appear in the %_ in the same way as all your named arguments.

You do not need to use a type constraint on the query parameters.  If you do not do so
all that is required is that the requested query parameters exist.

This uses the ActionRole L<Catalyst::ActionRole::QueryParameter> under the hood, which
you may wish to review for more details.

=head2 Chaining Actions inside a Controller

L<Catalyst> action chaining allows you to spread the logic associated with a given URL
across a set of actions which all are responsible for handling a part of the URL
template.  The idea is to allow you to better decompose your logic to promote clarity
and reuse.  However the built-in syntax for declaring action chains is difficult for
many people to use.  Here's how you do it with L<Catalyst::ControllerRole::At>

Starting a Chain of actions is straightforward.  you just add '/...' to the end of your
path specification.  This is to indicate that the action expects more parts 'to follow'.
For example:

    package MyApp::Controller::Example;

    use Moose;
    use MooseX::MethodAttributes;
    use Types::Standard qw/Int Str/;

    extends 'Catalyst::Controller';
    with 'Catalyst::ControllerRole::At';

    sub init :At($controller/...) { ... }
    
    __PACKAGE__->meta->make_immutable;

The action 'init' starts a new chain of actions and declares the first part of the
definition, 'https://localhost/example/...'.  You continue a chain in the same way,
but you need to specify the parent action that is being continued using the 'Via'
attribute.  You terminate a chain when you define an action that doesn't declare '...'
as the last path.  For example:

    sub init :At($controller/...) {
      my ($self, $c) = @_;
    }

      sub next :Via(init) At({}/...) {
        my ($self, $c, $arg) = @_;
      }

        sub last :Via(next) At({}) {
          my ($self, $c, $arg) = @_;
        }

This defines an action chain with three 'stops' which matches a URL like (for example)
'https://localhost/$controller/arg1/arg2'.  Each action will get executed for the matching
part, and will get arguments as defined in their match specification.

B<NOTE> The 'Via' attribute must contain a value.
 
When chaining you can use (or not) any mix of type constraints on your arguments, named
arguments, and query parameter matching.  Here's a full example:

    package MyApp::Controller::Example;

    use Moose;
    use MooseX::MethodAttributes;
    use Types::Standard qw/Int/;

    extends 'Catalyst::Controller';
    with 'Catalyst::ControllerRole::At';

    sub init :At($controller/...) { ... }

      sub next :Via(init) At({id:Int}/...) {
        my ($self, $c, $int_id) = @_;
      }

        sub last :Via(next) At({id:Int}?{q}) {
          my ($self, $c, $int_id) = @_;
        }

    __PACKAGE__->meta->make_immutable;

=head2 Actions in a Chain with no match template

Sometimes for the purposes of organizing code you will have an action that is a
midpoint in a chain that does not match any part of a URL template.  For that
case you can omit the path and argument match specification.  For example:

    package MyApp::Controller::Example;

    use Moose;
    use MooseX::MethodAttributes;
    use Types::Standard qw/Int/;

    extends 'Catalyst::Controller';
    with 'Catalyst::ControllerRole::At';

    sub init :At($controller/...) { ... }

      sub middle :Via(init) At(...) {
        my ($self, $c) = @_;
      }

        sub last :Via(next) At({id:Int}) {
          my ($self, $c, $id) = @_;
        }

    __PACKAGE__->meta->make_immutable;

This will match a URL like 'https://localhost/example/100'.

B<NOTE> If you declare a Via but not At, this is an error.  You must
always provide an At(), even in the case of a terminal action with no
match parts of it own.  For example:

    package MyApp::Controller::Example;

    use Moose;
    use MooseX::MethodAttributes;

    extends 'Catalyst::Controller';
    with 'Catalyst::ControllerRole::At';

    sub first :At($controller/...) { ... }

      sub second :Via(first) At(...) {
        my ($self, $c) = @_;
      }

        sub third :Via(second) At(...) {
          my ($self, $c) = @_;
        }

          sub last :Via(third) At() {
            my ($self, $c, $id) = @_;
          }

    __PACKAGE__->meta->make_immutable;

This creates a chained action that matches 'http://localhost/example' but calls
each of the three actions in the chain in order.  Although it might seem odd to
create an action that is not connected to a path part of a URL request, you might find
cases where this results in well factored and reusable controllers.

B<NOTE> For the purposes of executing code, we treat 'At' and 'At()' as the same.  However
We highly recommend At() as a best practice since it more clearly represents the idea
of 'no match template'.

=head2 Chaining Actions across Controllers

The method attributes 'Via()' contains a pointer to the action being continued.  In
standard practice this is almost always the name of an action in the same controller
as the one declaring it.  This could be said to be a 'relative' (as in relative to
the current controller) action.  However you don't have to use a relative name.  You
can use any action's absolute private name, as long as it is an action that declares itself
to be a link in a chain.

However in practice it is not alway a good idea to spread your chained acions across
across controllers in a manner that is not easy to follow.  We recommend you try
to limit youself to chains that follow the controller hierarchy, which should be
easier for your code maintainers.

For this common, best practice case when you are continuing your chained actions across
controllers, following a controller hierarchy, we provide some template expansions you can
use in the 'Via' attribute.  These are useful to enforce this best practice as well as
promote reusability by decoupling hard coded private action namespaces from your controller.

    $up: The controller whose namespace contains the current controller
    $name The name of the current actions subroutine
    $parent: Expands to $up/$subname

For example:

    package MyApp::Controller::ThingsTodo;

    use Moose;
    use MooseX::MethodAttributes;

    extends 'Catalyst::Controller';
    with 'Catalyst::ControllerRole::At';

    sub init :At($controller/...) {
      my ($self, $c) = @_;
    }

      sub list :Via(init) At($name) {
        my ($self, $c) = @_;
      }

    __PACKAGE__->meta->make_immutable;

    package MyApp::Controller::ThingsTodo::Item;

    use Moose;
    use MooseX::MethodAttributes;

    extends 'Catalyst::Controller';
    with 'Catalyst::ControllerRole::At';

    sub init :Via($parent) At({id:Int}/...) {
      my ($self, $c) = @_;
    }

      sub show    :Via(init) At($name) { ... }
      sub update  :Via(init) At($name) { ... }
      sub delete  :Via(init) At($name) { ... }

    __PACKAGE__->meta->make_immutable;

This creates four (4) URL templates:

    https://localhost/thingstodo/list
    https://localhost/thingstodo/:id/show
    https://localhost/thingstodo/:id/update
    https://localhost/thingstodo/:id/delete

With an action execution flow as follows:

    https://localhost/thingstodo/list =>
      /thingstodo/init
      /thingstodo/list

    https://localhost/thingstodo/:id/show
      /thingstodo/init
        /thingstodo/item/init
        /thingstodo/item/show

    https://localhost/thingstodo/:id/update
      /thingstodo/init
        /thingstodo/item/init
        /thingstodo/item/update

    https://localhost/thingstodo/:id/delete
      /thingstodo/init
        /thingstodo/item/init
        /thingstodo/item/delete

=head2 Method Shortcuts

Its common today to want to be able to match a URL to a specific HTTP method.  For example
you might want to match a GET request to one action and a POST request to another.  L<Catalyst>
offers the C<Method> attribute as well as shortcuts: C<GET>, C<POST>, C<PUT>, C<DELETE>, C<HEAD>,
C<OPTIONS>.  To tidy your method declarations you can use C<Get>, C<Post>, C<Put>, C<Delete>, C<Head>,
C<Options> in place of C<At>:

    package MyApp::Controller::Example;

    use Moose;
    use MooseX::MethodAttributes;

    extends 'Catalyst::Controller';
    with 'Catalyst::ControllerRole::At';

    sub get :Get($controller/...) { ... }
    sub post :Post($controller/...) { ... }
    sub put :Put($controller/...) { ... }
    sub delete :Delete($controller/...) { ... }
    sub head :Head($controller/...) { ... }
    sub options :Options($controller/...) { ... }

    __PACKAGE__->meta->make_immutable;

Basically:

    sub get :Get($controller/...) { ... }

Is the same as:

    sub get :GET At($controller/...) { ... }

You may find the few characters saved worth it or not.   The choice is yours.

=head1 COOKBOOK

One thing I like to do is create a base controller for my project
so that I can make my controllers more concise:

    package Myapp::Controller;

    use Moose;
    extends 'Catalyst::Controller';
    with 'Catalyst::ControllerRole::At';
     
    __PACKAGE__->meta->make_immutable;

You can of course doa  lot more here if you want but I usually recommend
the lightest touch possible in your base controllers since the more you customize
the harder it might be for people new to the code to debug the system.

=head1 TODO

    - HTTP Methods
    - Incoming Content type matching
    - ??Content Negotiation??

=head1 AUTHOR
 
John Napiorkowski L<email:jjnapiork@cpan.org>
  
=head1 SEE ALSO
 
L<Catalyst>, L<Catalyst::Controller>.
 
=head1 COPYRIGHT & LICENSE
 
Copyright 2016, John Napiorkowski L<email:jjnapiork@cpan.org>
 
This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
