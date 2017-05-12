package Class::DBI::Factory::Handler;
use strict;

use Apache2;
use Apache::Const qw(:common);
use Apache::Request ();
use Apache::Cookie ();
use Apache::Upload ();

use IO::File;
use Carp ();
use Class::DBI::Factory::Exception qw(:try);
use List::Util qw(first max min);
use Data::Dumper;

require 5.6.0;
use vars qw( $VERSION );

$VERSION = '0.93';      # mod_perl 2 only.
$|++;

=head1 NAME

Class::DBI::Factory::Handler - a handler base class for Class::DBI::Factory applications

=head1 SYNOPSIS
    
in Apache configuration somewhere:

  <Location "/handler/path">
    SetHandler perl-script
    PerlHandler Handler::Subclass
  </Location>
  
and:

  Package Handler::Subclass;
  use base qw( Class::DBI::Factory::Handler );
  
  sub build_page {
    my $self = shift;
    my $person = $self->factory->retrieve('person', $self->cookie('person'));
    $self->print('hello ' . $person->name);
    $self->print(', sir') if $person->magnificence > 6;
  }

But see also the Class::DBI::Factory docs about configuration files and environment variables.

=head1 INTRODUCTION

Class::DBI::Factory::Handler (CDFH) is an off-the-peg mod_perl handler designed to function as part of a Class::DBI::Factory application. It can be used as it is, but is much more likely to be subclassed and has been written with that in mind.

It's just a convenience, really, and consists largely of utility methods that deal with cookies, headers, input, output, etc. It is meant to free authors from the dreary bits of input handling and database integration, and let them concentrate on writing application logic.

Note that if you want to subclass the handler module - and you do, you do - then mod_perl must be compiled with support for method handlers.

Authors are expected to subclass build_page(), at least, but you can use the standard version if you like. It creates a very basic bundle of useful objects and passes it to a selected template toolkit template. 

(TT is not loaded until CDFH::process() is called, so you're not paying for it unless you use it.)

=head1 CONFIGURATION

See the Class::DBI::Factory documentation for information about how to configure a CDF appplication. it goes on at some length. The handler just asks the factory for configuration information, and all you really have to do is make sure that each short-lived handler object gets the right long-lived factory object.

NB. This module's original purpose was to facilitate moves between CGI and mod_perl, but I let all that go because the factory system reached a size that wasn't very CGI-friendly. It's a little slimmer now (but not, you know, slim), and if anyone is interested, it would be easy to reinstate the CGI functionality. These days it's just a base class for mod_perl handlers.

=cut

sub new {
    my ($class, $r) = @_;
    my $self = bless {
		output_parameters => {},
		cookies_out => [],
	}, $class;
	$self->{_request} = Apache::Request->new($r) if $r;
	return $self;
}

sub handler : method {
	my ($self, $r) = @_;
	$self = $self->new($r) unless ref $self;
	return $self->build_page;
}

=head1 PAGE CONSTRUCTION

The Handler includes some simple methods for directing output to the request handler with or without template processing, and a fairly well-developed skeleton for processing requests and working with cdbi objects. It is all designed to be easy to subclass and extend or replace.

=head2 PAGE CONSTRUCTION

This is built around the idea of a task sequence: each subclass defines (or inherits) a sequence of events that the request will pass through before the page is returned. Each event in the sequence can throw an exception to halt processing and probably divert to some other view, such as a login screen. The exception types correspond to Apache return codes: OK, REDIRECT and SERVER_ERROR.

This base class includes a simple but sufficient task sequence along with create, update and delete methods that can be invoked in response to input.

=head2 build_page()

This is the main control method: it looks up the task sequence, performs each task in turn and catches any exceptions that result.

There are several ways to make use of this. You can use it exactly as it is, to get basic but comprehensive i/o. You can selectively override some of the steps - see below, you can change the list of tasks by overriding task_sequence(), or you can override build_page() to replace the whole mechanism with something more to your taste.

=cut

sub build_page {
	my $self = shift;
	
	$self->debug(1, "\n\n\n____________REQUEST: " . $self->full_url, 'handler');
    $self->debug(3, "task sequence: " . join(', ', $self->task_sequence, 'handler'));
    my $return_code = OK;
	
    try {
        for($self->task_sequence) {
            $self->debug(2, "\n\n____________${_}", 'handler');
            $self->$_();
        }
    }
    
    catch Exception::OK with {
        my $x = shift;
        $self->debug(1, 'caught OK exception: ' . $x->text, 'handler');
        $self->view( $x->view );
        $self->error( @{ $x->errors }) if $x->errors;
        $self->message( $x->text );
        $self->return_output;
    }
    catch Exception::NOT_FOUND with {
        my $x = shift;
        $self->debug(1, 'caught NOT_FOUND exception: ' . $x->text, 'handler');
        my $view = $x->view || 'notfound';
        $self->return_error( $view, $x );
    }
    catch Exception::AUTH_REQUIRED with {
        my $x = shift;
        $self->debug(1, 'caught AUTH_REQUIRED exception: ' . $x->text, 'handler');
        my $view = $x->view || ($self->session ? 'denied' : 'login');
        $self->return_error( $view, $x );
    }
    catch Exception::SERVER_ERROR with {
        my $x = shift;
        $self->debug(1, 'caught SERVER_ERROR exception: ' . $x->text, 'handler');
        $x->log_error;
        $x->notify_admin;
        my $view = $x->view || 'error';
        $self->return_error( $view, $x );
    }
    catch Exception::REDIRECT with {
        my $x = shift;
        $self->debug(1, 'caught REDIRECT exception: ' . $x->text, 'handler');
        $self->redirect( $x->redirect_to );
    }
    otherwise {
        my $x = shift;
        $self->debug(1, 'caught unknown exception: ' . $x->text, 'handler');
        $self->return_error( 'error', $x );
    };
    #return $return_code;
}

=head2 task_sequence() 

The default sequence defined here is:

  check_permission 
  read_input
  do_op
  return_output

And each step is described below.

=cut

sub task_sequence {
    return qw( check_permission read_input do_op return_output );
}

=head3 check_permission() 

This is just a placeholder, and always returns true. It is very likely that your data classes will include a session class, and that you will want to check that  suitable session tokens have been presented, but I'm not going to impose a particular way of doing that (because CDF doesn't like to make assumptions about the presence of particular data classes).

=cut

sub check_permission { 1 };

=head3 adjust_input() 

Placed here as a convenience in case subclasses want to test or adjust the input set. One common tweak is to read path_info. Any changes you make here should be by way of C<set_param>: if you call moniker or id directly, for example, later steps may override your changes.

NB. Most important variables are retrieved from the input set by the corresponding method (eg calling ->moniker) will look at the 'moniker' parameter if it finds no other value to return.

=cut

sub read_input { 
	my $self = shift;
    $self->debug(3, "CDFH->read_input", 'handler', 'input');

	if ($self->param && ! ($self->param('id') || $self->param('moniker'))) {
    	$self->debug(3, "input but no id or moniker parameters. looking for class monikers.", 'handler', 'input');
    	my @monikers = @{ $self->factory->classes };
        my $moniker = first { $self->param($_) eq 'new' } @monikers;
        $moniker ||= first { defined $self->param($_) } @monikers;
                   
        if ($moniker) {
            $self->debug(3, "found a moniker parameter: $moniker.", 'handler', 'input');
            $self->set_param(moniker => $moniker);
            $self->set_param(id => $self->param($moniker));
            #$self->delete_param($moniker);
        }
	}

	if ($self->path_info && ! ( $self->param('id') || $self->param('moniker') )) {
    	$self->debug(3, "path info, but no id or moniker parameter. splitting pi.", 'handler', 'input');
        my ($general, $specific) = $self->read_path_info;
        if ($general eq 'op' && $specific) {
            $self->set_param('op', $specific);
        } elsif ($self->factory->has_class($general)) {
            $self->set_param('moniker', $general);
            $self->set_param('id', $specific) unless $general eq 'all';
        } elsif ($general) {
            $self->set_param('view', $general);
        }
    }   

    $self->adjust_input;
}

=head3 adjust_input( )

Placeholder for a sub that will change input values immediately after read_input has populated them. This version just turns type parameters into moniker parameters to paper over an old syntax change (when monikers were first introduced to cdbi).

=cut

sub adjust_input {
    my $self = shift;
    $self->debug(3, "CDFH->adjust_input", 'handler', 'input');
    $self->set_param( moniker => $self->param('type')) if $self->param('type') && ! $self->param('moniker');
}

=head3 view( view_name )

Most applications based on CDF will have some sort of view mechanism that will determine what template is used to display the objects or lists requested. This method just retrieves the view parameter and calls check_view.

None of this (simple) machinery is invoked unless a template asks for a view, so you can ignore it if it's not relevant to your application.

=cut

sub view {
	my $self = shift;
	$self->debug(4, 'CDFH->view(' . join(',',@_) . ')', 'handler');
    $self->set_param(view => $_[0]) if @_;
    my $view = $self->param('view');
    return $self->prefer_view unless $view;
   	throw Exception::NOT_FOUND(-text => "There is no $view view here") unless $self->check_view($view);
    return $view;
}

=head3 viewdir( view_name )

Returns the name of the directory in which we should look for view templates. Sometimes a subclass likes to change this, usually just for filing reasons.

=cut

sub viewdir { 'views' }

=head3 check_view( view_name )

This is a simple method that checks the supplied view parameter against a list of permitted views (via the permitted_view configuration parameter). It returns true if the view is permitted, false if not. It is very likely that you will override this method in subclass to add session-based permissions.

=cut

sub check_view { 
    my ($self, $view) = @_;
    return unless $view;
    my %permitted_view = map { $_ => 1 } $self->config->get('permitted_view');
    return $permitted_view{$view};
}

=head3 default_view( view_name )

Returns the name of the view we should default to if no other instruction is found. This is a relatively low-key instructions that will not be followed until aother avenues have been exhausted: it's normally used by templates looking for something to do. Defaults to the 'default_view' configuration parameter then 'welcome'.

Note that this often means that the usual view-permission check is not applied to the default view.

=cut

sub default_view {
	my $self = shift;
    return $self->config->default_view || 'welcome';    
}

=head3 prefer_view( view_name )

Returns the name of a view that should be imposed if no view parameter is found in input. This is useful for handler subclasses that perform a narrower range of functions and want to preempt a view-choice mechanism that would otherwise be invoked. Does nothing here.

The preferred view will be subject to the usual permission checks.

=cut

sub prefer_view { undef }

=head3 moniker( $moniker )

Looks for a moniker parameter in input and checks it against the factory's list of monikers. Can also be supplied with a moniker.

Throws a NOT_FOUND exception if the type parameter is supplied but does not correspond to a known data class.

NB. the moniker, id, op and view parameters are held as request parameters: they are not copied over into the handler's internal hashref. That way we can be sure that all references to the input data return the same results.

=cut

sub moniker {
	my $self = shift;
	$self->debug(4, 'CDFH->moniker(' . join(',',@_) . ')', 'handler', 'input');
    $self->set_param(moniker => $_[0]) if @_;
    my $moniker = scalar($self->param('moniker')) || return;
  	return unless $self->check_moniker($moniker);
	$self->debug(4, "moniker is $moniker", 'handler', 'input');
    return $moniker;
}

=head3 check_moniker( $moniker )

Checks that the supplied moniker is among those managed by the local factory. Subclasses will hopefully have stricter criteria for who can see what.

=cut

sub check_moniker {
    my ($self, $moniker) = @_;
	$self->debug(4, 'CDFH->check_moniker($moniker)', 'handler', 'input');
    return $self->factory->has_class($moniker);
}

=head3 id( int )

Looks for an 'id' parameter in input. Can be supplied with a value instead.

=cut

sub id {
	my $self = shift;
	$self->debug(4, 'CDFH->id(' . join(',',@_) . ')', 'handler', 'input');
    $self->set_param(id => $_[0]) if @_;
    return scalar( $self->param('id') );
}

=head3 thing( data_object )

If both moniker and id parameters are supplied, this method will retrieve and return the corresponding object (provided, of course, that the moniker matches a valid data class and the id an existing object of that class). 

You can also supply an existing object.

Returns immediately if the necessary parameters are not supplied. Throws a NOT_FOUND exception if the parameters are supplied but the object cannot be retrieved.

=cut

sub thing {
	my $self = shift;
	$self->debug(3, 'CDFH->thing(' . join(',',@_) . ')', 'handler', 'input');
	return $self->{thing} = $_[0] if @_;
	return $self->{thing} if defined $self->{thing};
	
	# we bypass the checking carried out by calling moniker() so that individual objects have a chance to override category access rules.
	
	my $moniker = $self->param('moniker');
	my $id = $self->param('id');

	return unless $moniker && $id;
    return $self->{thing} = $self->ghost if $id eq 'new';
    
    my $thing = $self->factory->retrieve( $moniker, $id );
   	throw Exception::NOT_FOUND(-text => "There is no object of type $moniker with id $id") unless $thing;
   	throw Exception::AUTH_REQUIRED(-text => "You are not authorised to see that object") unless $self->check_thing($thing);

    return $self->{thing} = $thing;
}

=head3 check_thing( data_object )

Just a placeholder: checks object-type visibility. 

Without a session mechanism we can't control access to individual objects, but subclasses will want to, so this method is invoked as part of retrieving the foreground object (ie in $self->thing) and an AUTH_REQUIRED exception is thrown unless it returns true.

=cut

sub check_thing { 
    my ($self, $thing) = @_;
    return unless $thing;
    return $self->check_moniker($thing->moniker);
}

=head3 ghost( )

Builds a ghost object (see L<Class::DBI::Factory::Ghost>) out of the input set, which can be used to populate forms, check input values and perform other tests and confirmations before actually committing the data to the database.

Ghost objects have all the same relationships as objects of the class they shadow. So you can call $ghost->person->title as usual.

Returns if no moniker parameter is found: the ghost has to have a class to shadow.

=cut

sub ghost {
	my $self = shift;
	return unless $self->moniker;
    $self->debug(3, 'CDFH is making a ghost', 'handler', 'ghost');

    my $initial_values = { 
        map { $_ => $self->param($_) }
        grep { $self->param($_) }
        $self->factory->columns($self->moniker, 'All')
    };
 	return $self->factory->ghost_object($self->moniker, $initial_values);
}

=head3 op() 

Get or set that, by default, returns the 'op' input parameter.
 
=cut

sub op {
	my $self = shift;
	$self->debug(3, 'CDFH->op(' . join(',',@_) . ')', 'handler');
    $self->set_param(op => $_[0]) if @_;
    return $self->param('op');
}

=head3 do_op() 

This is a dispatcher: if an 'op' parameter has been supplied, it will check that against the list of permitted operations and then call the class method of the same name.

A query string of the form:
 
 ?moniker=cd&id=4&op=delete
 
will result in a call to something like Class::DBI::Factory::Handler->delete(), if delete is a permitted operation, which will presumably result in the deletion of the My::CD object with id 4.

=cut

sub do_op {
	my $self = shift;
	my $op = $self->op;
    $self->debug(2, 'do_op: no op', 'handler') unless $op;
	return unless $op;
	my $permitted = $self->permitted_ops;
    $self->debug(2, 'Checking permission to ' . $op, 'handler');
    my $op_call = $permitted->{$op};
   	throw Exception::DECLINED(-text => "operation '$op' is not known") unless $op_call;
    $self->$op_call();
}

=head3 permitted_ops() 

This should return a dispatch table in the form of a hashref in which the keys are operation names and the values the associated method names (I<not> subrefs). Note that they are handler methods, not object methods.

=cut

sub permitted_ops {
    return {
        store => 'store_object',
        delete => 'delete_object',
    };
}

=head3 return_output() 

This one deals with the final handover to the template processor, calling C<assemble_output> to supply the values provided to templates and C<template> to get the template file address.

This base class uses the Template Toolkit: override C<return_output> to use some other templating mechanism.

=cut

sub return_output {
	my $self = shift;
	$self->process( $self->master_template, $self->assemble_output );
}

sub return_error {
	my ($self, $error, $x) = @_;
    warn("*** return_error: $error\n");
    $self->debug(3, "*** return_error: $error", 'handler');
    my $output = $self->minimal_output;
    my $template = $self->config->get('error_page');
    $output->{error} = $error;
    $output->{report} = $x;
	$self->process( $template, $output );
}

=head3 assemble_output() 

The variables which will be available to templates are assembled here.

=cut

sub assemble_output {
	my $self = shift;
	$self->debug(4, '* CDFH: assemble_output', 'handler', 'output');
	my $extra = $self->extra_output;
	my $output = { 

		handler => $self,
		factory => $self->factory,

		input => { $self->all_param } || undef,
        errors => $self->error || undef,
		deleted_object => $self->deleted_object || undef,
		report => $self->report || undef,
        referer => $self->referer || undef,

		view => $self->view || undef,
		viewdir => $self->viewdir || undef,
		default_view => $self->default_view || undef,
		moniker => $self->moniker || undef,
		id => $self->id || undef,
		thing => $self->thing || undef,

        %$extra,
    };
    
    if ($self->factory->debug_level >= 5) {
        my $dumper = Data::Dumper->new([$output],['assembled_output']);
        $dumper->Maxdepth(2);
        $self->debug(5, $dumper->Dump, 'handler', 'output');
    }
    
    return $output;
}

sub minimal_output {
	my $self = shift;
	$self->debug(4, 'minimal_output)', 'handler', 'output');
    my $output = {
		handler => $self,
		factory => $self->factory,
		config => $self->config,
		input => { $self->all_param } || undef,
	    url => $self->url,
    };
    return $output;

}

=head3 extra_output()

This is called by assemble_output, and the hashref it returns is appended to the set of values passed to templates. By default it returns {}: its purpose here is to allow subclasses to add to the set of template variables rather than having to redo it from scratch.

=cut

sub extra_output {
	my $self = shift;
	$self->debug(4, '* CDFH: extra_output', 'handler', 'output');
	return {};
}

=head3 pager( ignore_id )

If a moniker parameter has been supplied, and corresponds to a valid data class, this method will return a pager object attached to that class. If there's a page parameter, that will be passed on too.

Normally this method will return undef if an id parameter is also supplied, assuming that an object rather than a pager is required. Supply a true value as the first parameter and this reluctance will be overridden.

=cut

sub pager {
	my ($self, $insist) = @_;
	return if $self->id && ! $insist;
	return unless $self->moniker;
    $self->{pager} = $self->factory->pager($self->moniker, $self->param('page'));
    @{ $self->{contents} } = $self->{pager}->retrieve_all();
    return $self->{pager};
}

=head3 list( list_object )

If a moniker parameter has been supplied, this will return an object of Class::DBI::Factory::List attached to the corresponding data class. 

Any other parameters that match columns of the data class will also be passed through, along with any of the list-control flags (sortby, sortorder, startat and step).

As with pager, if there is an id parameter then the list will only be built if you pass a true value to the method.

=cut

sub list {
	my ($self, $insist) = @_;
	return if $self->id && ! $insist;
	return unless $self->moniker;
    my %list_criteria = map { $_ => scalar( $self->param($_) ) } grep { $self->param($_) } $self->factory->columns($self->moniker, 'All');
    $list_criteria{$_} = $self->param($_) for grep { $self->param($_) } qw( sortby sortorder startat step );
    return $self->{list} = $self->factory->list( $self->moniker, %list_criteria );
}

=head3 session( )

This is just a placeholder, and doesn't do or return anything. It is included in the default set, on the assumption that the first thing you do will be to supply a session-handling mechanism: all you have to do is override this session() method.

I'm not going to include anything specific here, becase CDF doesn't like to make any assumptions about the existence of particular data classes.

=cut

sub session { undef }

=head3 container_template( )

Returns the full path of the main template that will be used to build the page that is to be displayed. This may actually be the template that displays the object or list you want to return, but it is more commonly a generic container template that controls layout and configuration.

This value is passed to the Template Toolkit along with the bundle of value returned by C<assemble_output>.

=cut

sub master_template {
	my $self = shift;
    return $self->{_template} = $_[0] if @_;
    return $self->{_template} ||= $self->config->get('master_template');
}

=head1 BASIC OPERATIONS

This small set of methods provides for the most obvious operations performed on cdbi objects: create, update and delete. Most of the actual work is delegated to factory methods.

A real application will also include non-object related operations like logging in and out, registering and making changes to sets or classes all at once.

=head2 store_object()

Uses the input set to create or update an object.

The resulting object is stored in $self->thing.

=head2 delete_object()

calls delete() on the foreground object, but first creates a ghost copy and stores it in deleted_object(). The ghost should have all the values and relationships of the original.

=cut

sub store_object {
	my $self = shift;
	$self->debug(1, "CDFH: store_object", 'handler', 'storage');
	return unless $self->thing;
	$self->debug(1, "thing is " . $self->thing->title, 'handler', 'storage');

    # if this is a new object then thing() will return a ghost that just needs to be solidified with make().

	return $self->thing( $self->thing->make ) if $self->thing->is_ghost;

    # otherwise we apply input values to an existing object then update it.

	my %input = $self->all_param;
	my %parameters = map { $_ => $self->param($_) } grep { $self->thing->find_column( $_ ) } keys %input;
	delete $parameters{$_} for $self->thing->columns( 'Primary' );
    $self->thing->set( %parameters );
    $self->thing->update;
}

sub delete_object {
	my $self = shift;
    if ($self->thing) {
        $self->deleted_object( $self->factory->ghost_from($self->thing) );
        $self->thing->delete;
        $self->thing(undef);
    }
}

sub deleted_object {
	my $self = shift;
    return $self->{deleted_object} = $_[0] if @_;
    return $self->{deleted_object};
}

=head1 USEFUL MACHINERY

=head2 factory()

$handler->factory->retrieve_all('artist');

Returns the local factory object, or creates one if none exists yet. You can also pass in a factory object, though I can't imagine many cirumstances where this would be required. I only use during the installation tests.

=head2 factory_class()

returns the full name of the class that should be used to instantiate the factory. Defaults to Class:DBI::Factory, of course: if you subclass the factory class, you must mention the name of the subclass here.

=cut

sub factory_class { "Class::DBI::Factory" }

sub factory { 
    my $self = shift;
    return $self->{_factory} = $_[0] if @_;
    return $self->{_factory} ||= $self->factory_class->instance(); 
}

=head2 request()

Returns the Apache::Request object that started it all.

=head2 tt()

Returns the template object which is being used by the local factory. This method is here to make it easy to override delivery mechanisms in subclass, but this method costs nothing unless used, so if you're using some other templating engine that TT2, you will probably find it more straightforward to replace the process() method.

=head2 config()

Returns the configuration object which is controlling the local factory. The first time this is called in each request, it will call refresh() on the configuration object, which will cause configuration files to be re-read if they have changed.

=cut

sub request { shift->{_request}; }
sub tt { shift->factory->tt(@_); }

sub config { 
    my $self = shift;
    return $self->{_config} if $self->{_config};
    my $config = $self->factory->config;
    $config->refresh;
    return $self->{_config} = $config;
}

=head2 BASIC OUTPUT

=head3 print( )

Prints whatever it is given by way of the request handler's print method. Override if you want to, for example, print directly to STDOUT.

Triggers send_header before printing.

=cut

sub print {
	my $self = shift;
	$self->send_header;
	$self->request->print(@_);
}

=head3 process( )

Accepts a (fully specified) template address and output hashref and passes them to the factory's process() method. The resulting html will be printed out via the request handler due to some magic in the template toolkit. If you are overriding process(), you will probably need to include a call to print().

=cut

sub process {
	my ($self, $template, $output) = @_;
	$self->debug(3, "DMH: processing template: '$template'", 'handler', 'template');
	$self->send_header;
    $self->factory->process($template, $output, $self->request);
}

=head3 report()

  my $messages = $handler->report;
  $handler->report('Mission accomplished.');

Any supplied values are assumed to be messages for the user, and pushed onto an array for later. A reference to the array is then returned.

=cut

sub report {
	my $self = shift;
	$self->debug(2, $_, 'handler') for @_;
    push @{ $self->{_report} }, @_;
    return $self->{_report};
}

=head3 error()

  my $errors = $handler->error;
  $handler->error('No such user.');

Any supplied values are assumed to be error messages. Suggests that debug display the messages (which it will, if debug_level is 1 or more) and returns the accumulated set as an arrayref.

=cut

sub error {
	my $self = shift;
	my @errors = @_;
	$self->{_errors} ||= [];
	$self->debug(1, 'error messages: ' . join('. ', @errors), 'handler');
    push @{ $self->{_errors} }, @_;
    return $self->{_errors};
}

=head1 REPORTING

=head3 debug( $importance, @messages )

Hands over to factory->debug, which will print messages to STDERR if debug_level is set to a sufficiently high value in the configuration of this site.

=cut

sub debug {
    shift->factory->debug(@_);
}

=head2 log( $importance )

Unlike the factory's debugging methods, these are intended to hold and return messages for the user. Whatever you send to C<log> is pushed onto the log...

=head2 report()

...ready to be read back out again when you call C<report>. In scalar it returns the latest item, in list the whole lot in ascending date order.

=cut

sub log {
	my ($self, @messages) = @_;
	push @{ $self->{_log} }, @messages;
	$self->debug(1, "log: $_", 'handler') for @messages;
}

sub report {
	my $self = shift;
	return wantarray ? @{ $self->{_log} } : $self->{_log}->[-1];
}

=head1 CONTEXT

=head2 url()

Returns the url of this request, properly escaped so that it can be included in an html tag or query string.

=head2 qs()

Returns the query string part of the address for this request, properly escaped so that it can be included in an html tag or query string.

=head2 full_url()

Returns the full address of this request (ie url?qs)

=cut

sub url {
	my $self = shift;
	return $self->request->uri;    # changed for mod_perl2 from url to uri
}

sub full_url {
	my $self = shift;
	return $self->url . '?' . $self->qs;    # changed for mod_perl2
}

sub qs {
	my $self = shift;
	my $qs = $self->request->env->args; # updated for mod_perl2, since Apache::RequestRec has no query_string method. docs are oddly silent on this.
	return $qs;
}

=head2 path_info()

Returns the path information that is appended to the address of this handler. if your handler address is /foo and a request is sent to:

/foo/bar/kettle/black

then the path_info will be /bar/kettle/black. Note that the opening / will cause the first variable in a split(/\/) to be undef.

=cut

sub path_info {
	my $self = shift;
	my $pi = $self->request->path_info;
	$self->debug(3, "*** path_info is $pi", 'handler', 'input');
	return $pi;
}

=head2 read_path_info()

Returns a cleaned-up list of values in the path-info string, in the order they appear there. If called in scalar mode, returns only the first value.

It is assumed that values will be separated by a forward slash and that any file-type suffix can be ignored. This allows search-engine (and human) friendly urls.

=cut

sub read_path_info {
	my $self = shift;
	my $pi = $self->path_info;
    $pi =~ s/\.\w{2,4}$//i;
    my ($initialslash, @input) = split('/', $pi);
    return wantarray ? @input : $input[0];
}

=head2 path_suffix()

Returns the file-type suffix that was appended to the path info, if any. It's a useful place to put information about the format in which we should be returning data.

=cut

sub path_suffix {
	my $self = shift;
	my $pi = $self->path_info;
    return $1 if $pi =~ s/\.(\w{2,4})$//i;
    return;
}

=head2 referer()

returns the full referring address. Misspelling preserved for the sake of tradition.

=cut 

sub referer {
	return shift->headers_in('Referer');
}

=head2 headers_in()

If a name is supplied, returns the value of that input header. Otherwise returns the set. Nothing clever here: just calls Apache::Request->headers_in().

=cut 

sub headers_in {
	my $self = shift;
	return $self->request->headers_in->get($_[0]) if @_;
	return $self->request->headers_in;
}

=head2 param()

  $session_id = $handler->param('session');

If a name is supplied, returns the value of that input parameter. Acts like CGI.pm in list v scalar.

Note that param() cannot be used to set values: see set_param() for that. Separating them makes it easier to limit the actions available to template authors.

=head2 fat_param()

Like param(), except that wherever it can turn a parameter value into an object, it does.

=head2 has_param()

  $verbose = $handler->has_param('verbose');

Returns true if there is a defined input parameter of the name supplied (ie true for zero, not for undef).

=head2 all_param()

  %parameters = $handler->all_param;

Returns a hash of (name => value) pairs. If there are several input values for a particular parameter, then value with be an arrayref. Otherwise, just a string.

=head2 all_fat_param()

Like all_param(), except that wherever it can turn a parameter value into an object, it does.

=head2 set_param()

  $handler->set_param( 
     time => scalar time,
  ) unless $self->param('time');

Sets the named parameter to the supplied value. If no value is supplied, the parameter will be cleared but not unset (ie it will exist but not be defined).

=head2 delete_param()

  $handler->delete_param('password');

Thoroughly unsets the named parameter.

=head2 delete_all_param()

Erases all input by calling delete_param() for all input parameters.

=cut 

sub param {
	my ($self, $p) = @_;
	$self->debug(5, "CDFH->param($p);", 'handler', 'input');
	return $self->request->param unless $p;
	my @input = map { $self->factory->inflate_if_possible($p => $_) } $self->request->param($p);
	return wantarray ? @input : $input[0];
}

sub has_param {
	my $self = shift;
	return 1 if @_ && defined $self->request->param($_[0]);
	return 1 if !@_ && $self->request->param;
	return 0;
}

sub all_param {
	my $self = shift;
    $self->debug(3, 'CDFH: all_param', 'handler', 'input');
	my %p;
	my @param_names = $self->request->param;
    $self->debug(4, "input parameters: " . join(', ', @param_names), 'handler', 'input');
	for ( @param_names ){
	    my @input = $self->param($_);
	    $p{$_} = ($#input) ? \@input : $input[0];
	}
	return %p;
}

sub set_param {
	my ($self, $param, $value) = @_;
	$self->debug(5, "CDFH->set_param($param => $value);", 'handler', 'input');
    return unless $param;
	$self->request->args->{$param} = "$value";   # stringified because it _hates_ getting objects.
}

sub delete_param {
	my $self = shift;
	$self->debug(4, 'delete_param(' . join(',',@_) . ')', 'handler', 'input');
	my $table = $self->request->param; # small change for mod_perl2: parms method now deprecated
	$table->unset($_) for @_;
}

sub delete_all_param {
	my $self = shift;
	$self->delete_param(keys %{ $self->request->param }); # small change for mod_perl2: parms method now deprecated
}

=head2 uploads()

  my @upload_fields = $handler->uploads();

Returns a list of upload field names, each of which can be passed to:

=head2 upload( field_name )

  my $filehandle = $handler->upload('imagefile');

Returns a filehandle connected to the relevant upload.

=cut 

sub uploads {
	my $self = shift;
	my @uploads = $self->request->upload;
	return @uploads;
}

sub upload {
	my $self = shift;
	return $self->request->upload(@_);
}

=head2 cookiejar()

  my $jar = $handler->cookiejar();

Returns an Apache::Cookie::Jar object providing access to all the cookies in the request header.

=head2 cookie( cookie_name )

  my $userid = $handler->cookie('my_site_id');
  my @interests = $handler->cookie('my_keyword');

Returns the value(s) of the specified cookie. In scalar you get the first matching cookie, in list you get them all.

=head2 cookies()

  my $cookies = $handler->cookies();

Returns the full set of input cookies as a hashref. This is the old way, kept for compatibility purposes. Internally we use cookiejar now.

Note that changes to this hashref will not affect the Apache::Table object from which the cookies are drawn, so any code elsewhere that gets cookies directly will only see the original input.

=cut 

sub cookies {
	my $self = shift;
	return $self->{_cookies} if $self->{_cookies};
    my @cookienames = $self->cookiejar->cookies;
    my %cookies = map { $self->cookie($_) } @cookienames;
    return \%cookies;
}

sub cookiejar {
	my $self = shift;
	return $self->{_cookiejar} if $self->{_cookiejar};
    return $self->{_cookiejar} = Apache::Cookie::Jar->new($self->request);
}

sub cookie {
	my ($self, $cookiename) = @_;
	return unless $cookiename;
    my $cookie = $self->cookiejar->cookies($cookiename);
    $self->debug(5, 'found cookie: ' . Dumper($cookie), 'handler', 'cookies');
    return $cookie->value if $cookie;
}

=head1 HEADERS OUT

=head2 send_header()

  $handler->send_header();
  $handler->send_header('image/gif');

Under mod_perl2 all this has to do is set the content type, which it does by calling:

=head2 mime_type( $type )

Simple mutator that will get or set the mime-type for this response, or can be subclassed to make some other decision altogether. Defaults to:

=head2 default_mime_type()

Returns the mime type that will be used if no other is specified. The default default is text/html: set a default_mime_type parameter or subclass the method to do something more complicated.

=cut

sub send_header {
	my $self = shift;
	$self->request->content_type($self->mime_type);
}

sub mime_type {
	my $self = shift;
    return $self->{_mime_type} = $_[0] if @_;
    return $self->{_mime_type} if $self->{_mime_type};
    return $self->{_mime_type} = $self->default_mime_type;
}

sub default_mime_type { 
	my $self = shift;
    return $self->config->default_mime_type || 'text/html';    
}

=head2 set_cookie( hashref )

$handler->set_cookie({
    -name => 'id',
    -value => $id,
    -path => '/',
    -expires => '+100y',
});

Adds one or more cookies to the set that will be returned with this page (or picture or whatever it is). The cookie is baked immediately (unlike mp1 versions of CDF).

=cut

sub set_cookie {
	my $self = shift;
	$self->debug(3, "*** setting " . scalar(@_) . " cookies", 'handler', 'cookies');

    foreach my $c (@_) {
        next unless ref $c eq 'HASH';
        my $dumper = Data::Dumper->new([$c],['cookiedata']);
        $dumper->Maxdepth(2);
        $self->debug(3, $dumper->Dump, 'handler', 'cookies');
        my $cookie = Apache::Cookie->new($self->request, %$c);
        $cookie->bake;
    }
	return 1;
}

=head2 redirect( full_url )

$handler->redirect('http://www.spanner.org/cdf/')

Causes apache to return a '302 moved' response redirecting the browser to the specified address. Ignored if headers have already been sent.

Any cookies that have been defined are sent with the redirection, in accordance with doctrine and to facilitate login mechanisms, but I am not wholly convinced that all browsers will stash a cookie sent with a 302.

=cut

sub redirect {
	my $self = shift;
	my $url = shift || $self->{redirect} || $self->factory->config('url');
    $self->debug(3, "*** redirect: bouncing to $url", 'handler', 'redirect');
	$self->request->err_headers_out->add( Location => $url );
	return REDIRECT;
}

=head2 redirect_to_view( view_name )

$handler->redirect_to_view('login')

This is normally called from an exception handler: the task sequence is stopped and we jump straight to C<return_output> with the view parameter set to whatever value was supplied.

=cut

sub redirect_to_view {
	my ($self, $view) = @_;
    $self->debug(3, "*** redirect_to_view: bouncing to view $view", 'handler');
    $self->view( $view );
    return $self->return_output;
}

=head1 SEE ALSO

L<Class::DBI> L<Class::DBI::Factory> L<Class::DBI::Factory::Config> L<Class::DBI::Factory::List> L<Class::DBI::Factory::Exception>

=head1 AUTHOR

William Ross, wross@cpan.org

=head1 COPYRIGHT

Copyright 2001-4 William Ross, spanner ltd.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
