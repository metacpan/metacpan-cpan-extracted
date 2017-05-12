package Catalyst::Plugin::ForwardChained;

=head1 NAME

Catalyst::Plugin::ForwardChained - Forwarding to "Chain"-Actions in Catalyst

=head1 DESCRIPTION

Forwarding to the end point of a couple of chain methods .. 

In most cases: dont use - better user redirect instead

This is a hackaround, not a clean solution.

Experimental.

=head1 SYNOPSIS

    # In your application class 
    use Catalyst qw/ ForwardChained /;
    
    # ... somwhere else:
    $c->forward_to_chained( [ qw/ chained endpoint /, [ qw/ args / ] );
    $c->forward_to_chained( 'chained/endpoint', [ qw/ args / ] );


=head2 Example 1

Having some controller:

    package MyApp::Controller::Test;
    
    # ..
    # to be clear :
    __PACKAGE__->config->{ namespace } = 'test';
    
    # url would be "/one/*"
    sub my_index : PathPart( 'one' ) : Chained( '/' ) : CaptureArgs( 1 ) {
        # do some..
    }
    
    # url would be "/one/*/two/*"
    sub my_other : PathPart( 'two') : Chained( 'my_index' ) : Args( 1 ) {
        # do some..
    }

You would use:

    # somewhere
    #   this would call: "/namespace/one/111/two/222"
    $c->forward_to_chained( [ qw/ namespace two / ], [ "111", "222 ] );
    
    # same as above
    $c->forward_to_chained( "namespace/two", [ "111", "222 ] );


=head2 Example 2

it's not always obvious which path to choose when calling "forward_to_chained" .. 

An example testing controller

    package MyApp::Controller::Testing;
    
    use strict;
    use warnings;
    
    use base qw/ Catalyst::Controller /;
    use Data::Dumper;
    
    __PACKAGE__->config->{ namespace } = 'testing';
    
    sub one : PathPart( 'testing/one' ) : Chained( '/' ) : CaptureArgs( 1 ) {
        my ( $self, $c, @args ) = @_;
        push @{ $c->stash->{ called } ||= [] }, {
            name => 'one',
            args => \@args
        };
    }
    
    sub two : Chained( 'one' ) : CaptureArgs( 1 ) {
        my ( $self, $c, @args ) = @_;
        push @{ $c->stash->{ called } ||= [] }, {
            name => 'two',
            args => \@args
        };
    }
    
    sub three : Chained( 'two' ) {
        my ( $self, $c, @args ) = @_;
        push @{ $c->stash->{ called } ||= [] }, {
            name => 'three',
            args => \@args
        };
    }
    
    
    sub right : PathPart( 'testing/right' ) : Chained( '/' ) : CaptureArgs( 0 ) {
        my ( $self, $c, @args ) = @_;
        push @{ $c->stash->{ called } ||= [] }, {
            name => 'right',
            args => \@args
        };
    }
    
    sub again : Chained( 'right' ) : Args( 1 ) {
        my ( $self, $c, @args ) = @_;
        push @{ $c->stash->{ called } ||= [] }, {
            name => 'again',
            args => \@args
        };
    }
    
    
    sub chainor : Local {
        my ( $self, $c ) = @_;
        
        # calling chained:
        
        # 1) WRONG:
        #$c->forward_to_chained( 'testing/one/arg1/two/arg2/three/arg3' );
        
        # 2) WRONG:
        #$c->forward_to_chained( 'testing/one/two/three', [ qw/ arg1 arg2 arg3 arg4 / ] );
        
        # 3) CORRECT:
        $c->forward_to_chained( 'testing/three', [qw/ arg1 arg2 arg3 arg4 /] );
        
        $c->forward_to_chained( 'testing/again', [qw/ arg /] );
        
        $c->res->content_type( 'text/plain' );
        $c->res->body( "Called: \n". Dumper( $c->stash->{ called } ) );
    }
    
    1;


would produce something like this:

    Called: 
    $VAR1 = [
          {
            'args' => [
                        'arg1'
                      ],
            'name' => 'one'
          },
          {
            'args' => [
                        'arg2'
                      ],
            'name' => 'two'
          },
          {
            'args' => [
                        'arg3',
                        'arg4'
                      ],
            'name' => 'three'
          },
          {
            'args' => [],
            'name' => 'right'
          },
          {
            'args' => [
                        'arg'
                      ],
            'name' => 'again'
          }
        ];


and catalyst debug out:

    .----------------------------------------------------------------+-----------.
    | Action                                                         | Time      |
    +----------------------------------------------------------------+-----------+
    | /begin                                                         | 0.064814s |
    | /testing/chainor                                               | 0.002931s |
    | /testing/one                                                   | 0.000588s |
    | /testing/two                                                   | 0.000208s |
    | /testing/three                                                 | 0.000197s |
    | /testing/right                                                 | 0.000061s |
    | /testing/again                                                 | 0.000055s |
    | /end                                                           | 0.000495s |
    '----------------------------------------------------------------+-----------'


=head1 METHODS

=cut

use strict;
use warnings;

use vars qw/ $VERSION /;
use Catalyst::Exception;

$VERSION = '0.03';


=head2 forward_to_chained

forwards to a certain chained action endpoint ..

    $c->forward_to_chained( "some/path", [ qw/ arg1 arg2 arg3 / ] );
    $c->forward_to_chained( [qw/ some path /], [ qw/ arg1 arg2 arg3 / ] );

=cut

sub forward_to_chained {
    my ( $c, $chained_ref, $args_ref ) = @_;
    
    
    # transform from string to array-ref .. and back to clear things
    $chained_ref = [ grep { length } split( /\//, $chained_ref ) ]
        unless ref( $chained_ref );
    my $search_chain = join( "/", @{ $chained_ref } );
    
    # search chain parts in action hash ..
    my $actions_ref      = $c->dispatcher->action_hash;
    my ( @chain, %seen ) = ();
    
    # while defined the action path in the action ref... cycle through url
    SEARCH_CHAIN:
    while ( defined( my $action_ref = $actions_ref->{ $search_chain } ) && !$seen{ $search_chain }++ ) {
        
        # building our chain..
        unshift @chain, $action_ref;
        
        # found next part ...
        if ( defined $action_ref->{ attributes }->{ Chained } ) {
            $search_chain = $action_ref->{ attributes }->{ Chained }->[ -1 ]; # current part of "url"
            $search_chain =~ s~^\/+~~; # remove any leading "/"
        }
        
        # not further parts
        else {
            last SEARCH_CHAIN;
        }
    }
    
    # no chain found: bye bye
    Catalyst::Exception->throw( 
        message => "Cant forward to chained action because cant find chain for '$search_chain'" )
        if ( scalar @chain == 0 );
    
    
    # going to build up / setup new action.. and dispatch to this action
    
    # save orig captures ..
    my $captures_ref = $c->req->captures;
    
    # .. setup new captures ..
    $args_ref ||= [];
    $args_ref = [ $args_ref ] unless ref( $args_ref );
    $c->req->captures( $args_ref );
    
    # .. build up action chain and settle to catalyst ..
    my $action_chain = __Catalyst_ActionChain->from_chain( \@chain );
    #$c->action( Catalyst::ActionChain->from_chain( \@chain ) );
    
    # .. dispatch to it ..
    $action_chain->dispatch( $c );
    #$c->dispatcher->dispatch( $c );
    
    # .. and set orig captures back
    $c->req->captures( $captures_ref );
    
    return ;
}



=head2 get_chained_action_endpoints

returns array or arrayref of endpoints.. to help you find the one you need

    my @endpoints = $c->get_chained_action_endpoints;
    my $endpoints_ref = $c->get_chained_action_endpoints;

=cut

sub get_chained_action_endpoints {
    my ( $c ) = @_;
    
    my $actions_ref = $c->dispatcher->action_hash;
    my @endpoints   = 
        sort
        grep { 
            defined $actions_ref->{ $_ }->{ attributes } && 
            ref $actions_ref->{ $_ }->{ attributes }->{ Chained } 
        } 
        grep { ! /(?:^|\/)_[A-Z]+$/ } keys %{ $actions_ref }
    ;
    
    return wantarray ? @endpoints : \@endpoints;
}







=head1 AUTHOR

Ulrich Kautz, uk@fortrabbit.de

=cut


1;

#
# we require some small changes on the Catalyst::ActionChain::dispatch-method
# to provide the request-arguments to the last chain-action ..
#


package __Catalyst_ActionChain;

use strict;
use base qw/ Catalyst::ActionChain /;

sub dispatch {
    my ( $self, $c ) = @_;
    my @captures = @{$c->req->captures||[]};
    my @chain = @{ $self->chain };
    my $last = pop(@chain);
    foreach my $action ( @chain ) {
        my @args;
        if (my $cap = $action->attributes->{CaptureArgs}) {
            @args = splice(@captures, 0, $cap->[0]);
        }
        local $c->request->{arguments} = \@args;
        $action->dispatch( $c );
    }
    
    # --- START CHANGES ----
    my @args;
    if ( my $cap = $last->attributes->{Args} ) {
        @args = $#$cap > -1 
            ? splice(@captures, 0, $cap->[0])
            : @captures
        ;
    }
    local $c->request->{arguments} = \@args;
    # --- END CHANGES ----
    
    $last->dispatch( $c );
}

1;
