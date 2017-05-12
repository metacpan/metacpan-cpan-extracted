package Class::DBI::Factory::Exception;

use Apache::Constants qw(:common);

use base qw(Error);
use overload ('""' => 'stringify');

use vars qw( $VERSION $factory_class );
$VERSION = '0.3';   # mod_perl 2 only
$factory_class = 'Class::DBI::Factory';
$Error::Debug = 1;

=head1 NAME

Class::DBI::Factory::Exception - useful exception classes for applications using the CDF framework

=head1 SYNOPSIS
    
  try {
    $self->do_something_to($object);
  }
  catch Exception::SERVER_ERROR with {
    $self->error(shift);
    $self->view('error');
    return $self->redirect_to_view( 'error' );
  }
  
  # and elsewhere
  
  throw Exception::SERVER_ERROR(
    -text => 'Failed to update object',
    -errors => \@errors,
    -object => $object,
  );

  or
  
  throw Exception::OK(
    -text => 'Indexing complete',
    -view => 'index_report',
  );
  
=head1 INTRODUCTION

This is a set of exception classes based around apache return codes. It defines the following hierarchy of errors:

  * Exception::OK
    '- Exception::DONE
    '- Exception::RETRY

  * Exception::SERVER_ERROR
    '- Exception::NOT_FOUND
    '- Exception::GLITCH

  * Exception::REDIRECT
    '- Exception::CONFIRM

  * Exception::AUTH_REQUIRED
    '- Exception::DECLINED

Any of which can be thrown from anywhere in a CDF-based application and should be sensibly dealt with by Class::DBI::Factory::Handler or one of its subclasses.

The hierarchy may seem a little odd, and probably needs some tidying up, but it is practical. The main categories:

=over 4

=item REDIRECT results in a new request to the redirected address (an external redirect with a new, cleared input set).

=item CONFIRM is a REDIRECT and therefore always triggers a new request, usually to display the object that has just been acted upon.

=item AUTH_REQUIRED is redirected internally so that only the view changes and other parameters are preserved: this way the attempted action can be resumed on successful login.

=item DECLINED is a subclass of AUTH_REQUIRED, but points to the 'denied' template rather than the 'login' template.

=item SERVER_ERROR normally just displays an error page with the supplied error messages on it

=item GLITCH on the other hand is recorded but allows processing to continue . Only the task that was being carried out when the exception was thrown is affected. This should only be used for very minor errors that nevertheless abort the task at hand.

=item RETRY tends to bounce people back to an input form to try again.

=item DONE just stops processing and assumes that everything has been done.

=back

Each exception object has access to a few useful methods, in addition to those provided by Error.pm:

=head1 CLASS METHODS

=head2 factory()

As usual, returns the locally active factory object.

=head2 factory_class()

Defines the class that should be used to retrieve the factory. This works differently here. Most CDF modules are designed to be subclassed, but the CDF::Exception is a tricky one. To change the factory class set $Class::DBI::Factory::Exception::factory_class to the full class name you want to use. It will be a subclass of CDF, presumably:

  $Class::DBI::Factory::Exception::factory_class = 'Delivery';

will mean that the factory is retrieved by calling Delivery->instance, not Class::DBI::Factory->instance. 

=head2 do_log()

If a particular exception class returns non-zero here, that kind of error will be logged.

=head2 do_notify()

If a particular exception class returns non-zero here, that kind of error will be emailed to the admin user, if possible.

=head2 persevere()

If this returns a true value then the handler will continue through its task sequence, and only the present task will be aborted by the exception. This is unlikely to be a good idea.

=head2 return_code()

Returns the Apache return code (as one of the constants defined by Apache::Constants) that this error should produce. This may or may not be respected downstream.

=head1 INSTANCE METHODS

Useful bits of error message and context.

=head2 log_error()

By default just logs to STDERR. 

=head2 notify_admin()

Uses the factory's email helper to send the error to the configured admin address. This can be sent plain (just the stringified error) or by way of a template, if the configuration parameter 'error_email_template' is set (in which case it will have access to all the usual Error.pm parameters: file, line, stack trace and so on).

=head2 message()

Returns the main error message (which corresponds to the -text exception parameter).

=head2 errors()

This returns the set of detailed error messages supplied (as the -errors parameter) when the exception was thrown. It will be returned as a list of strings, by reference if called in scalar context.

=head2 view()

Returns the name of the view to which we should redirect the user who has encountered this error. Usually login-related. Corresponds to the -view parameter.

=head2 handler_url()

Returns the address of the handler passed in as part of the exception. This is normally used as the stem of a redirect instruction.

=head2 thing()

Returns the data object that was passed in as part of the exception (using the -object parameter).

=head2 type()

Returns the moniker that was passed in as part of the exception (using the -type parameter). This is normally only used for confirmation.

=head2 id()

Returns the id value that was passed in as part of the exception (using the -id parameter). This is normally only used for confirmation.

=head1 SEE ALSO

L<Error> L<Class::DBI> L<Class::DBI::Factory> L<Class::DBI::Factory::Handler> L<Class::DBI::Factory::Config> L<Class::DBI::Factory::List>

=head1 AUTHOR

William Ross, wross@cpan.org

=head1 COPYRIGHT

Copyright 2004 William Ross, spanner ltd.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

sub factory_class { $factory_class }
sub factory { return shift->factory_class->instance; }

sub log_error {
    my $self = shift;
    return unless $self->do_notify;
    my $warning = $self->stringify . " at " . $self->{-file} . " line " . $self->{-line};
    warn "$warning\n";
}

sub notify_admin {
    my $self = shift;
    return unless $self->do_notify;
    $self->factory->email_admin({
        subject => "[" . $self->factory->id . "] " . $self->text,
        template => $self->factory->config->get('error_email_template'),
        message => $self->stringify,
        line => $self->line,
        file => $self->file,
        object => $self->object,
        trace => $self->stacktrace,
        url => $self->url,
        qs => $self->qs,
    });
}

sub redirect_to {
    my $self = shift;
    return $self->url if $self->url;
    my $stem = $self->handler_url || $self->factory->config->get('url');
    my $view = '&view=' . $self->view if $self->view;
    return "${stem}?" . $self->thing->moniker . '=' . $self->thing->id . $view if $self->thing;
    return "${stem}?" . $self->type . '=' . $self->id . $view if $self->type && $self->id;
    return "${stem}?type=" . $self->type . $view if $self->type;
    return "${stem}?view=" . $self->view if $self->view;
    return $stem;
}

sub errors {
    return shift->{-errors};
}

sub url { shift->{-url} }
sub qs { shift->{-qs} }
sub thing { shift->object }
sub view { shift->{-view} }
sub type { shift->{-type} }
sub id { shift->{-id} }
sub handler_url { shift->{-handler} }
sub return_code { shift->{-return_code} || SERVER_ERROR }
sub persevere { 0 }
sub do_notify { 0 } 
sub do_log { 0 } 
1;

package Exception::OK;
use base qw(Class::DBI::Factory::Exception);
sub return_code { OK }
sub do_notify { 0 } 
sub do_log { 0 } 
1;

package Exception::SERVER_ERROR;
use base qw(Class::DBI::Factory::Exception);
sub return_code { SERVER_ERROR }
sub do_notify { 1 } 
sub do_log { 1 } 
1;

package Exception::NOT_FOUND;
use base qw(Class::DBI::Factory::Exception);
sub view { 'notfound' }
sub do_notify { 0 } 
sub do_log { 0 } 
1;

package Exception::REDIRECT;
use base qw(Class::DBI::Factory::Exception);
sub return_code { REDIRECT }
sub do_notify { 0 } 
sub do_log { 0 } 
1;

package Exception::AUTH_REQUIRED;
use base qw(Class::DBI::Factory::Exception);
sub view { 'login' }
sub do_notify { 0 } 
sub do_log { 1 } 
1;

package Exception::DONE;
use base qw(Exception::OK);
sub do_notify { 0 } 
sub do_log { 0 } 
1;

package Exception::DECLINED;
use base qw(Exception::AUTH_REQUIRED);
sub view { 'denied' }
sub return_code { DECLINED }
sub do_notify { 0 } 
sub do_log { 0 } 
1;

package Exception::GLITCH;
use base qw(Exception::SERVER_ERROR);
sub persevere { 1 }
sub do_notify { 0 } 
sub do_log { 1 } 
1;

package Exception::RETRY;
use base qw(Exception::OK);
sub do_notify { 0 } 
sub do_log { 0 } 
1;

package Exception::CONFIRM;
use base qw(Exception::REDIRECT);
sub do_notify { 0 } 
sub do_log { 0 } 
1;
