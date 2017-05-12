package TestApp;

use strict;
use Catalyst;
use FindBin;

our $VERSION = '0.01';

TestApp->config(
    name => 'TestApp',
    debug => 1,
);

my @plugins = qw/Static::Simple/;

# load the SubRequest plugin if available
eval { 
    require Catalyst::Plugin::SubRequest; 
    die unless Catalyst::Plugin::SubRequest->VERSION ge '0.08';
};
push @plugins, 'SubRequest' unless ($@);

TestApp->setup( @plugins );

sub incpath_generator {
    my $c = shift;
    
    return [ $c->config->{root} . '/incpath' ];
}

1;
