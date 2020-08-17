package CGI::Application::Plugin::OpenTracing::DataDog;

use parent 'CGI::Application::Plugin::OpenTracing';

our $VERSION = 'v0.1.0';

use Carp qw( croak carp );
use Import::Into;

use Readonly;

Readonly $IMPLEMENTATION_NAME_PACKAGE => 'DataDog';
Readonly $IMPLEMENTATION_NAME_NOOP    => 'NoOp';



sub import {
    my $package = shift;
    my @implementation_import_opts = @_;
    
    my $caller  = caller;
    my $implementation_name = _get_implementation_name();
    
    CGI::Application::Plugin::OpenTracing->import::into(
        $caller, 
        $implementation_name,
        default_service_name    => $caller,
        default_service_type    => 'web',
        default_resource_name   => '',
        @implementation_import_opts
    );
    
    return;
}



sub _get_implementation_name {
    defined ($ENV{OPENTRACING_IMPLEMENTATION} )
        or
        return $IMPLEMENTATION_NAME_PACKAGE;
    
    $ENV{OPENTRACING_IMPLEMENTATION} eq $IMPLEMENTATION_NAME_PACKAGE
        and
        return $IMPLEMENTATION_NAME_PACKAGE;
        
    $ENV{OPENTRACING_IMPLEMENTATION} eq $IMPLEMENTATION_NAME_NOOP
        and
        return $IMPLEMENTATION_NAME_NOOP;
    
    croak join q{ },
            "Environment variable 'OPENTRACING_IMPLEMENTION' must be",
            "'$IMPLEMENTATION_NAME_PACKAGE' or '$IMPLEMENTATION_NAME_NOOP'",
            "not '$ENV{OPENTRACING_IMPLEMENTATION}'",
    ;
    
}

1;
