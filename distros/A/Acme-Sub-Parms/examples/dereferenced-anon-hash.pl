#!/usr/bin/perl

package My;

use strict;

use Acme::Sub::Parms qw(:no_validation :normalize);
my $parms = { 'handle' => 'hello', 'thing' => 'yes' };
bind1(%$parms);
bind2(%$parms);
bind3(%$parms);



exit;
##########################################

sub bind1 {
    BindParms : (
        my $handle : handle;
        my $thing  : thing;
    )
}
##########################################

sub bind2 {
    BindParms : ( # Testing
        my $handle        : handle;
        my $thing         : thing;
        my $optional_parm : oparm [optional, default="something"];
    )
}
##########################################

sub bind3 {
    BindParms : ( # Testing
        my $handle : handle [required, is_defined];
        my $thing  : thing;
    )
}
##########################################
