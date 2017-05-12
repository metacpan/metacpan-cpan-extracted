#line 1 "inc/Module/Load.pm - /Users/kane/sources/p4/other/module-load/lib/Module/Load.pm"
package Module::Load;

$VERSION = 0.05;

use strict;
use File::Spec ();

sub import {
    my $who = _who();

    {   no strict 'refs';
        *{"${who}::load"} = *load;
    }
}

sub load (*)  {
    my $mod = shift or return;
    my $who = _who();

    if( _is_file( $mod ) ) {
        require $mod;
    } else {
        LOAD: {
            my $err;
            for my $flag ( qw[1 0] ) {
                my $file = _to_file( $mod, $flag);
                eval { require $file };
                $@ ? $err .= $@ : last LOAD;
            }
            die $err if $err;
        }
    }
}

sub _to_file{
    local $_    = shift;
    my $pm      = shift || '';

    my @parts = split /::/;

    ### because of [perl #19213], see caveats ###
    my $file = $^O eq 'MSWin32'
                    ? join "/", @parts
                    : File::Spec->catfile( @parts );

    $file   .= '.pm' if $pm;

    return $file;
}

sub _who { (caller(1))[0] }

sub _is_file {
    local $_ = shift;
    return  /^\./               ? 1 :
            /[^\w:']/           ? 1 :
            undef
    #' silly bbedit..
}


1;

__END__

#line 166
