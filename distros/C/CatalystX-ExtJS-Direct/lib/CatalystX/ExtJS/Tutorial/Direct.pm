#
# This file is part of CatalystX-ExtJS-Direct
#
# This software is Copyright (c) 2014 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package CatalystX::ExtJS::Tutorial::Direct;
$CatalystX::ExtJS::Tutorial::Direct::VERSION = '2.1.5';
#ABSTRACT: Introduction to CatalystX::ExtJS::Direct
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CatalystX::ExtJS::Tutorial::Direct - Introduction to CatalystX::ExtJS::Direct

=head1 VERSION

version 2.1.5

=head1 INTRODUCTION

Ext.Direct is an ExtJS component which creates classes and methods
according to an API provided by the server. 
These methods are used to communicate with the server in a Remote
Procedure Call fashion. 
This requires a router on the server side to route the requests to the
matching method.

L<CatalystX::ExtJS::Direct> will take care of creating the
API and provides a convenient way to include it in your web application
as well as providing a router which takes care of calling the correct
Catalyst actions when it comes to a request.

Please find a working example of the tutorial at C</tutorial> in the
L<CatalystX::ExtJS> distribution.

=head1 EXAMPLES

=head2 Simple Calculator

B<Run steps 1 to 5 from L<CatalystX::ExtJS::Tutorial/FIRST STEPS>.>

Every controller which wants to add an action to the Ext.Direct API
needs to consume the L<CatalystX::Controller::ExtJS::Direct> role. 
Furthermore each action which should be accessible requires the C<Direct> 
attribute. This simple example adds two numbers and returns
the result:

 package MyApp::Controller::Calculator;
 use Moose;
 BEGIN { extends 'Catalyst::Controller' };
 with 'CatalystX::Controller::ExtJS::Direct';
 
 use JSON::XS;

 sub add : Chained('/') : Path : CaptureArgs(1) {
    my($self,$c, $arg) = @_;
    $c->stash->{add} = $arg;
 }

 sub add_to : Chained('add') : PathPart('to') : Args(1) : Direct('add') {
    my($self,$c,$arg) = @_;
    $c->res->body( $c->stash->{add} + $arg );
 }
    
 sub echo : Local : Direct : DirectArgs(1) {
    my ($self, $c) = @_;
    $c->res->content_type('application/json');
    $c->res->body(encode_json($c->req->data));
 }

As you can see the C<add_to> action has the C<Direct> attribute attached
to it. Direct actions can only be attached to endpoints of Chained actions.
By default the method's name for the API is the same as the action's
name. In this case however we changed the name of the action to C<add> by
adding this as parameter to the C<Direct> attribute.

If you add the Direct attribute to a normal action (e.g. C<Local>)
it has no arguments by default. To change that you can add the C<DirectArgs>
attribute and enter the number of arguments there. If you add C<DirectArgs>
to a Chained endpoint the number of arguments will be added to the number
of arguments required to call this endpoint.

The C<echo> action accepts one argument from the Direct API. You can access this argument
via C<< $c->req->data >>, which is always an arrayref and includes all arguments.
We set the content type to C<application/json> to make sure that the
body is not serialized twice. That is, if you would not set the content type,
the Direct router assumes that the body should be send "as is" to the client.
Usually you would use L<Catalyst::View::JSON> to do this for you.

Run the server (C<# script/myapp_server.pl -r>) and access
L<http://localhost:3000/api>.
You should see something like this:

 --- 
 actions: 
   Calculator: 
        - 
          len: 2
          name: add
        - 
          len: 1
          name: echo
 type: remoting
 url: /api/router

This is the YAML representation of the API. As you can see, the C<add> method
expects two parameters and is inside the C<Calculator> class.

If you set the content type header to C<application/json> you will receive 
the JSON-encoded API.
Try L<http://localhost:3000/api?content-type=application/json> (see 
L<Catalyst::Controller::REST> to see why this is working).

A different way to access the API is to open L<http://localhost:3000/api/src>.
Open the C<index> template and add this to the head area:

 <script type="text/javascript" src="/api/src"></script>

The API is now available from the variable C<Ext.app.REMOTING_API>.

Fire up your favourite browser and go to L<http://localhost:3000/>.
Open the debugger and type in the console:

 Ext.Direct.addProvider(Ext.app.REMOTING_API);
 // This will set up the classes and methods
 // Ext.app.REMOTING_API is provided by /api/src
 Calculator.add(3, 2, function(res){alert(res)});

And watch the request and response. Next we call the C<echo> method.

 Calculator.echo({foo: 'bar'}, function(res){console.log(res)});
 // Prints {foo: 'bar'} to your browser's console

=head2 RESTful Controllers

=head2 Using CatalystX::Controller::ExtJS::REST

B<Run steps 1 to 6 from L<CatalystX::ExtJS::Tutorial/FIRST STEPS>.>

Check out L<CatalystX::Controller::ExtJS::REST> if you are used to
L<DBIx::Class> and L<HTML::FormFu>. To add such a controller to the
Direct API, simply add the L<CatalystX::Controller::ExtJS::Direct> role:

 package MyApp::Controller::User;
 
 use Moose;
 extends 'CatalystX::Controller::ExtJS::REST';
 with 'CatalystX::Controller::ExtJS::Direct';
 
 1;

L<CatalystX::Controller::ExtJS::REST> expects a L<HTML::FormFu> file to
be located at C<root/forms/user.yml>:

 ---
  elements:
    - name: id
    - name: first
      constraint: Required
    - name: last
      constraint: Required
    - name: email
      constraint: Required

Since the columns C<first>, C<last> and C<email> were defined as 
C<NOT NULL> columns, we have to add the C<Required> constraint to them.
Constraints, however, do not affect C<GET> and C<DELETE> requests.
If you want a different behaviour for C<POST> or C<PUT> requests, you
can create the files C<root/forms/user_put.yml> or
C<root/forms/user_post.yml> accordingly. Same applies to C<GET> requests.

While the CRUD methods (create, read, update, destroy) interact with one
object only, the C<list> method returns a bunch of objects. By default it
uses the same configuration file as the other requests. But you can 
create it's own file (C<root/lists/user.yml>).

Open L<http://localhost:3000/> and try:

  User.list(function(res){console.log('results: ', res.results)});
  
  User.create({first: 'Marge', last: 'Simpson'});
  // this will will cause an error because 'email' is required. The
  // response from the server will contain an error message and the name
  // of the field
  
  User.create({first: 'Marge', last: 'Simpson', email:'marge@simpsons.com'});
  
  User.list(function(res){console.log('results: ', res.results)});
  
  User.destroy(2);

=head2 Using Catalyst::Controller::DBIC::API::RPC

B<Run steps 1 to 6 from L<CatalystX::ExtJS::Tutorial/FIRST STEPS>.>

L<Catalyst::Controller::DBIC::API> is a convenient way to query the
DBIC model via a webservice. With Ext.Direct this becomes even more
convenient.

Add a new controller C<lib/MyApp/Controller/User/DBIC.pm> and paste:

 package MyApp::Controller::User::DBIC;
 
 use Moose;
 extends 'Catalyst::Controller::DBIC::API::RPC';
 with 'CatalystX::Controller::ExtJS::Direct';
 
 # See Catalyst::Controller::DBIC::API for more information
 # on those configuration parameters
 
 __PACKAGE__->config(
    actions => { 
        setup  => { PathPart => 'user', Chained => '/' },
        # enable Direct on these actions
        create => { Direct => undef, DirectArgs => 1 }, 
        item   => { Direct => undef }, 
        update => { Direct => undef, DirectArgs => 1 }, 
        delete => { Direct => undef }, 
        list   => { Direct => undef, DirectArgs => 1 },  
    },
    class => 'DBIC::User',
    use_json_boolean => 1,
    create_requires => [qw(email first last)],
    return_object => 1,
 );
 
 # Catalyst::Controller::DBIC::API cannot handle scalars and arrayrefs so
 # we have to add a little hack
 
 before 'deserialize' => sub {
    my ($self, $c) = @_;
    $c->req->data($c->req->data->[0]) if(ref $c->req->data eq 'ARRAY');
    $c->req->data(undef) unless(ref $c->req->data);
 };
 
 1;

Access L<http://localhost:3000/> in your browser and open the console to
play around with the DBIC API:

 Ext.Direct.addProvider(Ext.app.REMOTING_API);
 
 // get all records from the model
 UserDBIC.list({}, function(res){console.log(res)});
 
 UserDBIC.create({first: 'Marge', last: 'Simpson', email:'marge@simpsons.com'});
 
 UserDBIC.item(2, function(marge){console.log(marge)});
 
 UserDBIC.delete(2); 

Try to run these commands all at once (either put them in one line or use the
multi-line console in Firebug). They are now being batched and processed in just
one request.

=head1 AUTHOR

Moritz Onken <onken@netcubed.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Moritz Onken.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
