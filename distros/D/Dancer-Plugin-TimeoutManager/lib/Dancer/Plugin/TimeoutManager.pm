package Dancer::Plugin::TimeoutManager;

use strict;
use warnings;
our $VERSION = '0.09'; # VERSION

use Try::Tiny;
use Dancer ':syntax';
use Dancer::Exception ':all';
use Dancer::Plugin;
use Data::Dumper;
use Carp 'croak';
use List::MoreUtils qw( none);

#get the timeout from headers
hook(before => sub { 
    var header_timeout => request->header('X-Dancer-Timeout');
});

register 'timeout' => \&timeout;

register_exception ('InvalidArgumentNumber',
        message_pattern => "the number of arguments must 3 or 4, you've got %s",
        );
register_exception ('InvalidMethod',
        message_pattern => "method must be one in get, put, post, delete and %s is used as a method",
        );


my @authorized_methods = ('get', 'post', 'put', 'delete');

=method exception_message

return the exception message
This method can be used to catch the exception if the code used already contained a try catch

=cut 

sub exception_message{

    return 'Route Timeout Detected';
}

=method timeout

Method that manage the timeout on a dancer request

=cut 

sub timeout {
    my ($timeout,$method, $pattern, @rest);
    if (scalar(@_) == 4){
        ($timeout,$method, $pattern, @rest) = @_;
    }
    elsif(scalar(@_) == 3){
        ($method, $pattern, @rest) = @_;
    }
    else{
         raise InvalidMethod => scalar(@_);
    }
    my $code;
    for my $e (@rest) { $code = $e if (ref($e) eq 'CODE') }
    my $request;

    #if method is not valid an exception is done
    if ( none { $_ eq lc($method) } @authorized_methods ){
        raise InvalidMethod => $method;
    }
    
    my $exception_message = exception_message();
    my $timeout_route = sub {
        my $response;

        #if timeout is not defined but a value is set in the headers for timeout
        my $request_timeout = 0;
        $request_timeout = $timeout if (defined $timeout);
        $request_timeout = vars->{header_timeout} if (!defined $timeout && defined vars->{header_timeout});

        # if timeout is not defined or equal 0 the timeout manager is not used
        my $timeout_exception;
        if (!$request_timeout){
            $response = $code->();
        }
        else{
           try {
                local $SIG{ALRM} = sub { croak ($exception_message); };
                alarm($request_timeout);

                $response = $code->();
                alarm(0);
            }
            catch{
                $timeout_exception = $_;
            };
            alarm(0);
        }
        # Timeout detected
        if ($timeout_exception && $timeout_exception =~ /$exception_message/){
            my $response_with_timeout = Dancer::Response->new(
                    status => 408,
                    content => "Request Timeout : more than $request_timeout seconds elapsed."
                    );
            return $response_with_timeout;
        }
        # Preserve exceptions caught during route call
        croak $@ if $@;

        # else everything is allright
        return $response;
    };


    my @compiled_rest;
    for my $e (@rest) {
        if (ref($e) eq 'CODE') {
            push @compiled_rest, $timeout_route;
        }
        else {
            push @compiled_rest, $e;
        }
    }

    # declare the route in Dancer's registry
    any [$method] => $pattern, @compiled_rest;
}

register_plugin;


1;
__END__
=head1 NAME

Dancer::Plugin::TimeoutManager - Plugin to define route handlers with a timeout

=head1 SYNOPSIS
  package MyDancerApp;

  use Dancer;
  use Dancer::Plugin::TimeoutManager;
  
  # if somecode() takes more than 1 second, execustion flow will be stoped and a 408 returned
  timeout 1, 'get' => '/method' => sub {
      somecode();
  };

  #if header X-Dancer-Timeout is set, the header's value is used as the timeout
  timeout 'get' => '/method' => sub {
    my $code;
  };

 
=head1 DESCRIPTION

This plugins allows to define route handlers with a maximum amount of time for the code execution.

If that time is elapsed and the code of the route still runs, the execution flow is stopped and a 
default 408 response is returned.

If the timeout is set to 0, the behavior is the same than without any timeout defined.

It's also possible to define route handlers that will set a per-request timeout protection, depending 
on the value of the header C<X-Dancer-Timeout>.

If your Dancer code already use try catch, the exeption may be catched. 
So exception_message method can be used to cath the content of the exception in your Dancer code.

=head1 AUTHOR

Frederic Lechauve, E<lt>frederic_lechauve at yahoo.frE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Weborama

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
