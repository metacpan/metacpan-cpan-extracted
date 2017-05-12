package TestApp;
use strict;
use Catalyst qw/
    Test::Headers
/;
use Catalyst::Utils;

use Moose;
use namespace::autoclean;

our $VERSION = '0.01';

TestApp->config( 
    name => 'TestApp', 
    root => '/some/dir', 
    use_request_uri_for_path => 1, 
    # 'Controller::Action::Action' => {
    #     action_args => {
    #         action_action_nine => { another_extra_arg => 13 }
    #     }
    # }
);

TestApp->setup;

sub execute {
    my $c      = shift;
    my $class  = ref( $c->component( $_[0] ) ) || $_[0];
    my $action = $_[1]->reverse;

    my $method;

    if ( $action =~ /->(\w+)$/ ) {
        $method = $1;
    }
    elsif ( $action =~ /\/(\w+)$/ ) {
        $method = $1;
    }
    elsif ( $action =~ /^(\w+)$/ ) {
        $method = $action;
    }

    if ( $class && $method && $method !~ /^_/ ) {
        my $executed = sprintf( "%s->%s", $class, $method );
        my @executed = $c->response->headers->header('X-Catalyst-Executed');
        push @executed, $executed;
        $c->response->headers->header(
            'X-Catalyst-Executed' => join ', ',
            @executed
        );
    }
    no warnings 'recursion';
    return $c->SUPER::execute(@_);
}

# Replace the very large HTML error page with
# useful info if something crashes during a test
sub finalize_error {
    my $c = shift;
    
    $c->next::method(@_);
    
    $c->res->status(500);
    $c->res->body( 'FATAL ERROR: ' . join( ', ', @{ $c->error } ) );
}

{
    no warnings 'redefine';
    sub Catalyst::Log::error { }
}

# Pretend to be Plugin::Session and hook finalize_headers to send a header

sub finalize_headers {
    my $c = shift;

    $c->res->header('X-Test-Header', 'valid');

    my $call_count = $c->stash->{finalize_headers_call_count} || 0;
    $call_count++;
    $c->stash(finalize_headers_call_count => $call_count);
    $c->res->header('X-Test-Header-Call-Count' => $call_count);

    return $c->maybe::next::method(@_);
}

1;
