package AnyLoader;

use strict;
use Class::ISA;
use vars qw($VERSION %OkayToLoad %ModsToLoad %LoadAnything);
$VERSION = '0.04';


$SIG{__WARN__} = sub {
    return if $_[0] =~ /^Use of inherited AUTOLOAD for non-method /;
    warn @_;
};

sub import {
    my($pack, @modules) = @_;
    my($caller) = caller;

    $OkayToLoad{$caller} = 1;
    if( @modules ) {
        $LoadAnything{$caller} = 0;
        $ModsToLoad{$caller} = {map { $_ => 1 } @modules};
    }
    else {
        $LoadAnything{$caller} = 1;
    }
}

sub unimport {
    my($pack, @modules) = @_;
    my($caller) = caller;

    if( @modules ) {
        $LoadAnything{$caller} = 1;
        $OkayToLoad{$caller} = 1;
        $ModsToLoad{$caller} = {map { $_ => 0 } @modules};
    }
    else {
        $OkayToLoad{$caller} = 0;
    }
}


{
    package UNIVERSAL;

    use vars qw($AUTOLOAD);
    no strict 'refs';

    sub AUTOLOAD {
    # Find our calling package and extract the module and function
    # being called.
        my($caller) = caller;
        my($module, $func) = $AUTOLOAD =~ /(.*)::([^:]+)$/;

        return if $func eq 'DESTROY';

        # Check to see if we're allow to load this.
        # XXX This is *ALOT* more complicated than it has to be.
        unless( 
               $AnyLoader::OkayToLoad{$caller}            
               
               and
               
               (
                ($AnyLoader::LoadAnything{$caller} and 
                 (!exists $AnyLoader::ModsToLoad{$caller} or 
                  $AnyLoader::ModsToLoad{$caller}{$module}))
                
                or
                
                (exists $AnyLoader::ModsToLoad{$caller}     and
                 $AnyLoader::ModsToLoad{$caller}{$module})
               )
              )
          {
              require Carp;
              Carp::croak(sprintf "Undefined subroutine &%s::%s called", 
                          $module, $func);
          }
        
        # Load up our module.
        eval "require $module;";
        
        # Error checking.
        if ($@) {
            # Gee, AnyLoader would be useful here. :(
            require Carp;
            Carp::croak("Problem while AuyLoader was trying to use '$module' ".
                        "for '$func':  $@");
        }

        # Go do it.
        my $full_func = $module.'::'.$func;
        if( defined &{$full_func} ) {
            goto \&{$full_func};
        }
        else {
            require Carp;
            Carp::croak(sprintf "Undefined subroutine &%s called", $full_func);
        }
    }
}    

=pod

=head1 NAME

AnyLoader - Automagically loads modules for fully qualified functions


=head1 SYNOPSIS

  use AnyLoader;

  Carp::croak("This is going to hurt the Perl community more than it ".
              "is going to hurt you!");


=head1 DESCRIPTION

AnyLoader will automagically load the module and import the function
for any fully qualified function call.  Essentially, this means you
can just call functions without worrying about loading the module
first.

In the example above, AnyLoader does the equivalent of "require Carp"
before the call to Carp::carp().  This should be useful for the many
cases where one does:

    if($error) {
        require Carp;
        Carp::croak($error);
    }

to avoid loading Carp at startup.

AnyLoader is package scoped.


=head2 Restricting what gets loaded.

You might not want to let *every* package be AnyLoaded, so ways of
qualifying what gets loaded are provided.  A list of modules can be
given to C<use AnyLoader> and only those modules will be AnyLoaded.

    use AnyLoader qw(Data::Dumper Carp);

    Data::Dumper::Dumper($foo);         # This works.
    LWP::Simple::get($url);             # This doesn't.

If you wish to shut off AnyLoader, C<no AnyLoader> will do so for the
current package.  C<no AnyLoader> also takes a list of modules.  These
modules are those which are specifically B<not> to be loaded.

    # AnyLoad anything but LWP and URI::URL.
    no AnyLoader qw(LWP URI::URL);

The lists and effects are cumulative and package scoped (B<not lexical>).


=head1 BUGS and CAVEATS

The effects should really be lexically scoped, but I don't think I can
pull that off.

This module requires on the "Use of inherited AUTOLOAD for non-method"
deprecated feature.

$SIG{__WARN__} had to be used to suppress a warning about the
deprecated feature.

Defines UNIVERSAL::AUTOLOAD which may interfere with other modules.

Despite what you'd think, AnyLoader *will* work with modules which
employ an autoloader.


=head1 AUTHORS

Arnar M. Hrafnkelsson <addi@umich.edu> and
Michael G Schwern <schwern@pobox.com>


=head1 LICENSE

Copyright (c) 2000 Arnar M. Hrafnkelsson and Michael G Schwern.  All
Rights Reserved.

You may distribute under the same license as Perl itself.


=head1 SEE ALSO

L<autouse>

=cut

return <<POUND_PERL;
<Addi> purl, speak and spell
<purl> I pronounce Addi as Leeeeooks and spell it Brian D Foy
POUND_PERL
