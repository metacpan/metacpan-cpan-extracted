# NAME

Amon2::Web::Dispatcher::RouterSimple::Extended - extending Amon2::Web::Dispatcher::RouterSimple

# SYNOPSIS



    package MyApp::Web::Dispatcher;
    use strict;
    use warnings;
    use utf8;
    use Amon2::Web::Dispatcher::RouterSimple::Extended;
    connect '/' => 'Root#index';
    # API
    submapper '/api/' => API => sub {
        get  'foo' => 'foo';
        post 'bar' => 'bar';
    };
    # user
    submapper '/user/' => User => sub {
        get     '',           'index';
        connect '{uid}',      'show';
        post    '{uid}/hoge', 'hoge';
        connect 'new',        'create';
    };
    1;

# DESCRIPTION

This is an extension of Amon2::Web::Dispatcher::RouterSimple. 100% compatible, and it provides useful functions.



# METHODS

- get $path, "${controller}\#${action}"

this is equivalent to 'connect $path, { controller => $controller, action => $action }, { method => 'GET' };'

- post $path, "${controller}\#${action}"

this is equivalent to 'connect $path, { controller => $controller, action => $action }, { method => 'POST' };'

- put $path, "${controller}\#${action}"

this is equivalent to 'connect $path, { controller => $controller, action => $action }, { method => 'PUT' };'

- delete $path, "${controller}\#${action}"

this is equivalent to 'connect $path, { controller => $controller, action => $action }, { method => 'DELETE' };'

- submapper $path, $controller, sub {}

this is main feature of this module. In subroutine of the third argument, connect/get/post/put/delete method fits in submapper. As a results, in submapper you can be described in the same interface. If this third argument not exists, this function behave in the same way as Amon2::Web::Dispatcher::RouterSimple.



Copyright (C) taiyoh

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

taiyoh

# SEE ALSO

[Amon2::Web::Dispatcher::RouterSimple](http://search.cpan.org/perldoc?Amon2::Web::Dispatcher::RouterSimple)
