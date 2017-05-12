package IncTestApp;
# FIXME: I have to do this because TestApp runs setup at compile time
# Perhaps it would be better to let the tests run setup?

use strict;
use Catalyst;
use FindBin;
use TestLog;

our $VERSION = '0.01';

IncTestApp->config(
    name => 'TestApp',
    debug => 1,
    static => {
        include_path => [
            IncTestApp->config->{root},
        ]
    },
    'Plugin::Static::Simple' => {
        include_path => [
            IncTestApp->config->{root} . '/overlay',
        ]
    },
);

IncTestApp->log( TestLog->new );
my @plugins = qw/Static::Simple/;

# load the SubRequest plugin if available
eval { 
    require Catalyst::Plugin::SubRequest; 
    die unless Catalyst::Plugin::SubRequest->VERSION ge '0.08';
};
push @plugins, 'SubRequest' unless ($@);

IncTestApp->setup( @plugins );

sub incpath_generator {
    my $c = shift;
    
    return [ $c->config->{root} . '/incpath' ];
}


1;
