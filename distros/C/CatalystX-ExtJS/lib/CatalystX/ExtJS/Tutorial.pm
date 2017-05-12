#
# This file is part of CatalystX-ExtJS
#
# This software is Copyright (c) 2011 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package CatalystX::ExtJS::Tutorial;
BEGIN {
  $CatalystX::ExtJS::Tutorial::VERSION = '2.1.3';
}
#ABSTRACT: Introduction to CatalystX::ExtJS
1;


=pod

=head1 NAME

CatalystX::ExtJS::Tutorial - Introduction to CatalystX::ExtJS

=head1 VERSION

version 2.1.3

=head1 INTRODUCTION

=head1 TUTORIALS

L<CatalystX::ExtJS::Tutorial::Direct>

=head1 FIRST STEPS

These tasks are referenced from the tutorials above.

=head2 Step 1: Bootstrap Catalyst

In order to run the examples we need to bootstrap a Catalyst
application. 

First go to your working directory and run:

 # catalyst.pl MyApp

This will create a basic Catalyst application. Open up C<lib/MyApp.pm>
and add C<Unicode> to the list of plugins (after C<Static::Simple>). 

=head2 Step 2: Add the Template View

Next we need a view. We will go with a L<Template::Alloy> view which will
take care of rendering the HTML and JavaScript sources. 
Create C<lib/MyApp/View/TT.pm> with:

 package MyApp::View::TT;
 use Moose;
 extends 'Catalyst::View::TT::Alloy';

 __PACKAGE__->config( {
         CATALYST_VAR => 'c',
         INCLUDE_PATH => [ MyApp->path_to( 'root', 'src' ) ]
     } );
 1;

=head2 Step 3: Adjust the Root Controller

The JavaScript sources should be generated through the view we just
created. For this to work, we need a controller, which handles that. 
We can use the C<Root> controller which was created when
we created C<MyApp>. Open up C<lib/MyApp/Controller/Root.pm> and change
the C<index> subroutine to:

 sub index :Path :Args(0) { }

This removes the Catalyst welcome message and a request to C</> will run
the C<index> template (which we will create later) via the TT view. 

=head2 Step 4: Add the C<index> Template

Now it's time to build some HTML and JavaScript. Add this to C<root/src/index>:

 <html>
 <head>
 <title>Ext.Direct and Catalyst</title>
 <link rel="stylesheet" type="text/css" href="http://extjs.cachefly.net/ext-3.3.1/resources/css/ext-all.css" />
 <script type="text/javascript" src="http://extjs.cachefly.net/ext-3.3.1/adapter/ext/ext-base.js"></script>
 <script type="text/javascript" src="http://extjs.cachefly.net/ext-3.3.1/ext-all-debug.js"></script>
 <script type="text/javascript" src="/api/src"></script>
 </head>
 <body>Hello World!</body>
 </html>

=head2 Step 5: Add the Direct API Controller

To have access to the API we need to add a new controller. Create
C<lib/MyApp/Controller/API.pm> and paste:

 package MyApp::Controller::API;
 use Moose;
 extends q(CatalystX::Controller::ExtJS::Direct::API);
 1;

Now we create an action which will route any request to C</js/*> to 
the according template in C<root/src/js>.

 sub js : Path : Args {
    my ($self, $c, $template) = @_;
    $c->stash->{template} = $template;
 }

=head2 Step 6: Add a DBIC Model

To play around with actual data, we need to set up a model.
We will be using L<DBIx::Class> as ORM which means we have to 
set up a DBIC schema first.

Create the file C<lib/MyApp/Schema.pm> and paste the following:

 package MyApp::Schema;
 use Moose;
 extends 'DBIx::Class::Schema';
 __PACKAGE__->load_namespaces;
 1;

Now we need a result class which describes the user object. Create
C<lib/MyApp/Schema/Result/User.pm>:

 package MyApp::Schema::Result::User;
 use Moose;
 extends 'DBIx::Class::Core';
 __PACKAGE__->table('user');
 __PACKAGE__->add_columns(
    id => { is_auto_increment => 1, data_type => 'integer' },
    qw(email first last)
 );
 __PACKAGE__->set_primary_key('id');
 1;

To glue the DBIC schema and Catalyst together we create a model called
C<MyApp::Model::DBIC>. Paste the following in C<lib/MyApp/Model/DBIC.pm>:

 package MyApp::Model::DBIC;
 use Moose;
 extends 'Catalyst::Model::DBIC::Schema';
 
 # we connect to an in-memory database
 # which means that the database is reset
 # with every start of the application
 __PACKAGE__->config({
    schema_class => 'MyApp::Schema',
    connect_info => ['dbi:SQLite:dbname=:memory:']
 });
 
 # this initializes the empty sqlite database 
 # and inserts one record
 after BUILD => sub {
    my $self = shift;
    my $schema = $self->schema;
    $schema->deploy;
    $schema->resultset('User')->create({
        email => 'onken@netcubed.de', 
        first => 'Moritz', 
        last => 'Onken'
    });
 };
 
 1;

=head1 AUTHOR

Moritz Onken <onken@netcubed.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Moritz Onken.

This is free software, licensed under:

  The (three-clause) BSD License

=cut


__END__

