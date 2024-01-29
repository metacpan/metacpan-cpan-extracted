#!/bin/sh

pp -vv \
    -M Plack::Middleware::Proxy::Connect::IO \
    -M Plack::Middleware::Proxy::Requests \
    -M Plack::Middleware::AccessLog \
    -M Plack::Middleware::TrafficLog \
    -M Plack::Loader::Delayed \
    -M Plack::Handler::Starlight \
    -M Plack::Handler::Thrall \
    -M Plack::App::Proxy::Backend::HTTP::Tiny \
    -o pureproxy.bin ../script/pureproxy.pl
