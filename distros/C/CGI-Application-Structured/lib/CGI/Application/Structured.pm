package CGI::Application::Structured;
use strict;
use warnings;
use base 'CGI::Application';

use vars qw($VERSION);
$VERSION = '0.007';


# Load recommended plugins by default. 
use CGI::Application::Plugin::Forward;
use CGI::Application::Plugin::Redirect;
use CGI::Application::Plugin::Session;
use CGI::Application::Plugin::ValidateRM; 
use CGI::Application::Plugin::ConfigAuto 'cfg';
use CGI::Application::Plugin::FillInForm 'fill_form';
use CGI::Application::Plugin::DBH 	  qw(dbh_config dbh); 
use CGI::Application::Plugin::LogDispatch;
use CGI::Application::Plugin::TT;
use CGI::Application::Plugin::AutoRunmode;
use CGI::Application::Plugin::SuperForm;
use CGI::Application::Plugin::DBIC::Schema qw/dbic_config schema resultset/;
use CGI::Application::Plugin::DebugScreen;


#################### main pod documentation begin ###################

=head1 NAME

CGI::Application::Structured - A medium-weight, MVC, DB web micro-framework.

=head2 SYNOPSIS

A simple, medium-weight, MVC, DB web micro-framework built on CGI::Application. The framework combines tested, well known plugins and helper scripts to provide a rapid development environment.

The bundled plugins mix the following methods into your controller runmodes:

    $c->forward(runmode)

    $c->redirect(url)

    $c->tt_param(name=>value)

    $c->tt_process()

    $c->schema()->resultset("Things")->find($id)

    $c->resultset("Things)->search({color=>"red"})

    $c->log->info('This also works')

    my $value = $c->session->param('key')

    my $conf_val = $c->cfg('field');

    my $select = $c->superform->select(
                        name    => 'select',
                        default => 2,
                        values  => [ 0, 1, 2, 3 ],
                        labels  => {
                                0 => 'Zero',
                                1 => 'One',
                                2 => 'Two',
                                3 => 'Three'
                        }
                );


    sub method: Runmode {my $c = shift; do_something();}

    $c->fill_form( \$template )

    my  $results = $ ->check_rm(
              'form_display','_form_profile') 
              || return $c->check_rm_error_page;



=head1 DESCRIPTION


I have taken to heart a recent comment by Mark Stosberg on the CGIApp mailing list:

=over 8

"Titanium is just one vision of what can be built on top of 
CGI::Application. Someone else could easily combine their own 
combination of CGI::Application and different favorite plugins, 
and publish that with a different name."     

=back

CGI::Application::Structured, like L<Titanium>, is an opinionated framework, based on CGI::Application.  Both frameworks includes a number of vetted CGI-App plugins each of which are well documented and tested.  C::A::Structured, however takes the view that developer time and consistent projects structures can often be more cost-effective than focusing on the highest performance on low cost hosting solutions.  That being said, C::A::Structured can be deployed on CGI, FastCGI or mod_perl based on your needs.

C::A::Structured focuses on:

=over 4

=item *

adequate performance under CGI, but with more focus speed of development.

=item *

a well-defined project structure with directories for model classes, controllers and view templates.

=item *

a powerful templating DSL via Template Toolkit integration.

=item *

a integrated Object Relational Mapper, L<DBIx::Class>

=item *

no runmode configuration required.

=item *

integrated form building to simplify creation of complex HTML form elements.

=item *

clean url-to-controller mapping by default.


=back

C::A::Structured comes in two packages:

=over 4

=item *

CGI::Application::Strutured - encapsulates the runtime environment.

=item *

CGI::Application::Structured::Tools - includes project creation and developemt scripts for developers.

=back

CGI::Application::Structured::Tools are used to generate a micro-architecture and helper scripts that work within that structure to speed development and maintain project structure across development teams and projects. The helper scripts eliminate the tedium of error-prone manual creation of controllers, templates and database mappings and provide a recognizeable structural conventions that reduced stress on the developer when working across multiple apps, or working with other developers code on the same project.

The first script that is used is 'cas-starter.pl'. This script is used to generate the initial project skeleton. The skeleton app contains a base controller class rather than runnable module as would be found in L<Titanium>.  Also generated is a default 'Home' controller subclass and a URL dispatcher that is customized to default to the Home controllers generated 'index' runmode.  

cas-starter.pl also generates additional helper scripts in your projects 'scripts' subdirectory: 

=over 4

=item *

create_controller.pl

=item *

create_dbic_schema.pl

=back 

'create_controller.pl' is used by the developer to generate additional controller subclasses of your base module with a default 'index' runmode and a default TT template for that runmode. 

'create_dbic_schema.pl' generates a DBIx::Class::Schema subclass and a set of resultset subclasses for your database.  These Object Relational Maps (ORM) will greatly simplify and speed database assess and manipulation in the development process.

Finally CGI::Application::Structured aims to be as compatible as possible with L<Catalyst>.  Many plugins used in CGI::Application::Structured are also available for Catalyst, or are even defaults in L<Catalyst>. If your projects needs grow in scope or scale to require Catalyst, porting much of your code will be very easy.


=head1 CGI::Application::Structured Tutorial



In this tutorial we will build a simplistic database driven web application using CGI::Application::Structured to demonstrate using the starter and helper scripts as well as the minimal required configuration.

CGI::Application::Structured assumes that you have a database that you want to use with the web.  If you have a database you can use for this tutorial.  Otherwise, jump to the "Create The Example Database" section at the bottom of this page before starting the tutorial.


=cut

=head2 Installation

You will need to install L<CGI::Application::Structured> which provides the runtime requirements.  You will also need to install L<CGI::Application::Structured::Tools> which supplies the development environment.

    ~/dev$ sudo cpan
    cpan> install CGI::Application::Structured
          ... ok
    cpan> install CGI::Application::Structured::Tools
          ... ok
    cpan> exit


=cut 

=head2 Creating A Project


    ~/dev$ cas-starter.pl --module=MyApp1 \
                               --author=gordon \
                               --email="vanamburg@cpan.org" \
                               --verbose
    Created MyApp1
    Created MyApp1/lib
    Created MyApp1/lib/MyApp1.pm                      # YOUR *CONTROLLER BASE CLASS* !
    Created MyApp1/t
    Created MyApp1/t/pod-coverage.t
    Created MyApp1/t/pod.t
    Created MyApp1/t/01-load.t
    Created MyApp1/t/test-app.t
    Created MyApp1/t/perl-critic.t
    Created MyApp1/t/boilerplate.t
    Created MyApp1/t/00-signature.t
    Created MyApp1/t/www
    Created MyApp1/t/www/PUT.STATIC.CONTENT.HERE
    Created MyApp1/templates/MyApp1/C/Home
    Created MyApp1/templates/MyApp1/C/Home/index.tmpl # DEFAULT HOME PAGE TEMPLATE
    Created MyApp1/Makefile.PL
    Created MyApp1/Changes
    Created MyApp1/README
    Created MyApp1/MANIFEST.SKIP
    Created MyApp1/t/perlcriticrc
    Created MyApp1/lib/MyApp1/C                       # YOUR CONTROLLERS GO HERE 
    Created MyApp1/lib/MyApp1/C/Home.pm               # YOUR *DEFAULT CONTROLLER SUBCLASS*
    Created MyApp1/lib/MyApp1/Dispatch.pm             # YOUR CUSTOM DISPATCHER
    Created MyApp1/config
    Created MyApp1/config/config-dev.pl               # YOU CONFIG -- MUST BE EDITED BY YOU!
    Created MyApp1/script
    Created MyApp1/script/create_dbic_schema.pl       # IMPORTANT HELPER SCRIPT
    Created MyApp1/script/create_controller.pl        # ANOTHER IMPORTANT HELPER SCRIPT.
    Created MyApp1/server.pl                          # SERVER USES YOUR CUSTOM DISPATCH.PM
    Created MyApp1/MANIFEST
    Created starter directories and files



=cut

=head2 Configure Your Database

CGI::Application::Structured is database centric in some sense and expects that you have a database.  Before running your
app via server.pl you need to configure your database access.

The example config is generated at MyApp1/config/config.pl.  The contents are shown here.

	use strict;
	my %CFG;			

	$CFG{db_dsn} = "dbi:mysql:myapp_dev";
	$CFG{db_user} = "root";
	$CFG{db_pw} = "root";
	$CFG{tt2_dir} = "templates";
	return \%CFG;

Using the root account is shown here as a worst-practice.  You should customize the file supplying the correct database dsn, user and passwords for your database.

If you do not have a database and want to use an example see "Create Example Database" below before continuing.

The configuration file will be found automatically when running with the built in server, but when you deploy your application you may want, or need, to update the config file location in lib/MyApp1/Dispatch.pm to point to your production config file.

For information on advanced configuration see: L<CGI::Application::Plugin::ConfigAuto>
=cut

=head2 Generate A DBIx::Class Schema For Your Database

From your project root directory run the helper script to generate DBIx::Class::Schema and Resultset packages. This will use the configuration you supplied in config_dev.pl to produce a DB.pm in your apps lib/MAINMODULE directory

	~/dev/My-App1$ perl script/create_dbic_schema.pl 
	Dumping manual schema for DB to directory /home/gordon/dev/MyApp1/lib/MyApp1/DB ...
	Schema dump completed.


Given the example database shown below your resulting DBIx::Class related files and folders would look like this:

    ~/dev/MyApp1$ find lib/MyApp1/ | grep DB
    lib/MyApp1/DB
    lib/MyApp1/DB/Result
    lib/MyApp1/DB/Result/Orders.pm
    lib/MyApp1/DB/Result/Customer.pm
    lib/MyApp1/DB.pm


For more information see: L<CGI::Application::Plugin::DBIC::Schema>, L<DBIx::Class>

=cut

=head2 Run Your App

Now that your database is configured and the schema generated you can run your app. 

Run the server:

    ~/dev/MyApp1$ perl server.pl 
    access your default runmode at /cgi-bin/index.cgi
    CGI::Application::Server: You can connect to your server at http://localhost:8060/

Open your browser and test at

    http://localhost:8060/cgi-bin/index.cgi


For more information on the nature of the development server see: L<CGI::Application::Server>

=cut

=head2 Try Plugin::DebugScreen;

CAS comes with L<CGI::Application::Plugin::DebugScreen>.  Plugin::DebugScreen provides a very useful stack trace with multi-line source quotations for each level of the stack.  cas-starter.pl has put debug.sh in your project root directory.  It sets up the environment for Plugin::DebugPage and runs the built in server.  

Edit lib/MyApp1/C/Home.pm to generate an error to demonstrate the DebugScreen:

  
    sub index: StartRunmode {
	my ($c) = @_;

	# add this line for demo of debug screen
	die "testing";

	$c->tt_params({
	    message => 'Hello world!',
	    title   => 'C::Home'
		      });
	return $c->tt_process();
	
    }

Run the server in debug mode:

    ~/dev/MyApp1$ bash debug.sh
    access your default runmode at /cgi-bin/index.cgi
    CGI::Application::Server: You can connect to your server at http://localhost:8060/

Open your browser and test/demo the Plugin::DebugScreen:

    http://localhost:8060/cgi-bin/index.cgi

Remove the line you added to Home.pm

For more information on Plugin::DebugScreen see: L<CGI::Application::Plugin::DebugScreen>

=cut

=head2 Create A New Controller

This is where the create_controller.pl helper script comes in very handy. create_controller.pl will
create a new controller with a default runmode called 'index', and an index template to go with it.

As an example we can generate a new module to interact with the Orders table
of the example database.

    ~/dev/MyApp1$ perl script/create_controller.pl --name=Orders
    will try to create lib/MyApp1/C
    Created lib/MyApp1/C/Orders.pm
    will try to create template directory templates/MyApp1/C/Orders
    Created templates/MyApp1/C/Orders
    Created templates/MyApp1/C/Orders/index.tmpl
 

You can restart server.pl and view default output at:

    http://localhost:8060/cgi-bin/orders

Add a new runmode to lib/MyApp1/C/Orders.pm  to show the orders that we have from the example database.



    sub list: Runmode{
	my $c = shift;


	my @orders = $c->resultset("MyApp1::DB::Result::Orders")->all;

	$c->tt_params(orders =>\@orders);
	return $c->tt_process();

    }



Then add a template for this runmode at templates/MyApp1/C/Orders/list.tmpl with the following content:


    <h1>Order List</h1>
    <table>
      <tr><th>Cust No</th><th>Order No</th></tr>
      [% FOREACH order = orders %]
	 <tr>
	   <td>[% order.customer_id %]</td>
	   <td>[% order.id %]</td>
	 </tr>
      [% END %]
    </table>

Restart server.pl and visit page to see list of orders at:
    
  http://localhost:8060/cgi-bin/orders/list
    

For advanced information on creating controllers, runmodes and templates see: L<CGI::Application::Plugin::AutoRunmode>, L<CGI::Application::Plugin::TT>, L<CGI::Application> and L<Template::Toolkit>.

=cut

=head2 Creating The Example Database (if you don't already have one)

The L<CGI::Application::Structured> distrubution contains an example sql file that you can use for this
example app.  Use the download link at L<CGI::Application::Structured> on CPAN, grab the archive and extract the file from the 'examples' directory of the distribution. 

The script will create the 'myapp1_dev' database, create 2 tables and load a few 
Notice that the create table statements end with 'engine=InnoDB'.  This is important since our DBIC generator script will create perl modules to represent database table relationships, based on the metadata in the database.  While the InnoDB engine will work, the default engine for mysql will not store the relationship metadata and you would then need to hand-craft the relationships at the botton of the generated DB::Result classes.

Example:

	~/dev/MyApp1$ mysql -u root -p < example_tables.mysql.ddl 
	

The contents of the example sql file are as follows:

	CREATE DATABASE myapp1_dev;
	USE myapp1_dev;

	CREATE TABLE customer(
	   id integer not null auto_increment PRIMARY KEY,
	   last_name varchar(25) null,
	   first_name varchar(25) not null
	)engine=InnoDB;

	CREATE TABLE orders(
	  id integer not null auto_increment PRIMARY KEY,
	  customer_id integer not null,
	  order_status varchar(10) default "OPEN" not null,	
	  order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP not null,
	  CONSTRAINT orders_customer_id_fk FOREIGN KEY (customer_id) REFERENCES customer(id)
	)engine=InnoDB;

	INSERT INTO customer (last_name, first_name) VALUES("Doe","John");
	INSERT INTO orders (customer_id) VALUES(  1 );
	INSERT INTO orders (customer_id) VALUES(  1 );
	INSERT INTO orders (customer_id) VALUES(  1 );


If you did not use 'engine=InnoDB' or your database does not support relationships, you can paste the following in the bottom of your "MyApp/DB/Result/Orders.pm" to tell DBIx::Class how the example tables relate:


   # Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-09-15 16:05:33
   # DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:znOKfDkdRzpL0KHWpfpJ+Q

    __PACKAGE__->belongs_to(
      "customer",
      "MyApp1::DB::Result::Customer",
      { id => "customer" },
    );

See documentation for L<DBIx::Class::Manual> for more information on configuring and using relationships in your model.

=cut


=head1 Further Reading

See L<CGI::Application::Structured::Tools> for more information on developer tools package.

See L<CGI::Application::Plugin::DBIC::Schema> for more information on accessing DBIx::Class from your CGI::Application::Structured modules.

See L<CGI::Application::Plugin::SuperForm> for form building support that is build into CGI::Application::Structured.

See L<DBIx::Class::Manual::Intro> for more information on using the powerful ORM included with CGI::Application::Structured.

See L<Template::Toolkit> and L<CGI::Application::Plugin::TT> for more information on advanced templating.

See L<CGI::Application> for lots of good ideas and examples that will work with your CGI::Application::Structured app.



=head1 BUGS

There are no known bugs for this distribution.  

Please report any bugs or feature requests through the web interface at
L<https://rt.cpan.org>.

I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SUPPORT

I recommend joining the cgi-application mailing list.

=head1 AUTHOR

    Gordon Van Amburg
    CPAN ID: VANAMBURG
    vanamburg at cpan.org

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=cut

#################### main pod documentation end ###################

1;

# The preceding line will help the module return a true value

