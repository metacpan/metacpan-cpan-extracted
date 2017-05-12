#!/usr/bin/perl

package My;

use strict;

use Acme::Sub::Parms qw(:no_validation :normalize);
my @parms = ( 'handle' => 'hello', 'thing' => 'yes' );
bind1(@parms);
bind2(@parms);
bind3(@parms);
bind4(@parms);
bind5(@parms);



exit;
##########################################

sub bind1 {
    BindParms : (
        my $handle : handle;
        my $thing  : thing;
    )
    warn("Line 27: bind1");
}
##########################################

sub bind2 {
    BindParms : ( # Testing
        my $handle : handle;
 
        my $thing  : thing;
    )
    warn("Line 37: bind2");
}
##########################################

sub bind3 {
    BindParms : ( # Testing
        my $handle : handle;
 
        my $thing  : thing;
        # Test
    )
    warn("Line 48: bind3");
}
##########################################

sub bind4 { warn("Line 52 (bind4)");
    BindParms : ( # Testing
        my $handle : handle[required, default="10"];
 
        my $thing  : thing;
        # Test
    )
    warn("Line 59: bind4");
}
##########################################

sub bind5 { warn("Line 63 (bind5)");
    BindParms : ( # Testing
        my $handle : handle[required, default="10"];
 
        my $thing  : thing;
        # Test
    )
    warn("Line 70: bind5");
}
