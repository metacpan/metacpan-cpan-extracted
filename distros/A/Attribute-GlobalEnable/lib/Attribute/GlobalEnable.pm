package Attribute::GlobalEnable;

our $VERSION = '0.1';

use strict;
use warnings;
use Attribute::Handlers;
use Carp qw( croak );
use base qw( Exporter );
use Time::HiRes qw( time );


## hold the switch settings for each module, method etc. (see above)
my $ENABLE_CHK      = {};

## set the hash for the Debug attribute and the key for the hash ##
my $ENABLE_ATTR     = {};

## hold flag definitions.
my $ENABLE_FLAG     = {};

## hold our current package (our sub-package name really)
my $PACKAGE         = '';

## mark this as true once we've automatically loaded all the stuff.  It's
## once true, other packages that load this module will ONLY get the 
## symbols exported.
my $DONE_INIT       = 0;



##
## import is an auto sub... happens when you... well... import.  In our case
## it automatically exports our attribute functionality to the properr places.
## The first time it runs should be when it is initialized.  After this
## initialization process, it will only export the proper symbols (checks
## $DONE_INIT).
##
## this should return true if it is successfull... it should bail otherwise.
sub import {
  return _export_my_attribute_symbols() if $DONE_INIT;
  my $class = shift();
  croak "Must specify some arguments." if not @_;
  my $args  = {@_};

  ## set the package to the caller
  $PACKAGE = caller();
  croak "Must sub-package ".$PACKAGE if not $PACKAGE or $PACKAGE eq __PACKAGE__;

  ## make sure our sub-packaged module is using the exporter
  _export_the_exporter_to( $PACKAGE ) or die "Bad exporting exporter";

  ## check to make sure ENABLE_CHK exists, and is a hashref ##
  if ( not $args->{ENABLE_CHK} or ref $args->{ENABLE_CHK} ne 'HASH' ) {
    croak "ENABLE_CHK needs to be set with a hash ref for this module "
      ."to be used.";
  }

  ## build the enabled attributes and store internally
  _check_and_build_enable_attr($args) or die "bad ENABLE_ATTR";

  ## handle the flags array and store internally.
  _check_and_build_enable_flags($args) or die "Bad ENABLE_FLAGS";

  ## convert the checks from the passed in hash to our internal hash ##
  _build_enable_chks($args) or die "Bad ENABLE_CHK";

  ## build and export the attribute functions
  _build_attr_exports() or die "Bad build ATTR exports";

  ## export the proper subs to the package that init'd this ##
  _export_my_attribute_symbols();

  return $DONE_INIT++;
}





sub _export_the_exporter_to {
  my $package = shift();

  my $eval_str = "{ package $package; use Exporter; use base qw( Exporter ); }";
  eval $eval_str;
  _eval_die($eval_str, $@) if $@;

  return 1;
}




sub _build_attr_exports {
  ## set the proper attribute functions to point to our internal handler ##
  foreach my $attribute ( keys %$ENABLE_ATTR ) {

    ## set the attribute function to our internal one ##
    my $eval_str = "sub UNIVERSAL::$attribute : ATTR(CODE) { return "
      . __PACKAGE__ ."::My_attr_handler(\@_) }";

    eval $eval_str;
    _eval_die( $eval_str, $@) if $@;

    ## set exporting for each attribute as well so that we can get imported
    ## $attributes as function calls.
    $eval_str = "push \@${PACKAGE}::EXPORT_OK, \$attribute; "
      ."push \@${PACKAGE}::EXPORT, \$attribute;";

    eval $eval_str;
    _eval_die( $eval_str, $@) if $@;

    ## set our internal ref to our wrapper for function calls only if
    ## there are some switches turned on in ENABLE_CHK.
    $eval_str = "sub ". $PACKAGE ."::$attribute ";
    if ( %{$ENABLE_CHK->{$attribute}} || %{$ENABLE_FLAG->{$attribute}}) {
      $eval_str .= "{ return " . __PACKAGE__
        ."::my_static_handler('$attribute', \@_) }";
    } else {
      ## do nothing.
      $eval_str .= "{ }";
    }

    eval $eval_str;
    _eval_die( $eval_str, $@) if $@;
  }

  return 1;
}




sub _build_enable_chks {
  my $args = shift();
  OUTER: foreach my $attr_str ( keys %$ENABLE_ATTR ) {
    my $key_str = $ENABLE_ATTR->{$attr_str};
    INNER: foreach my $db_var ( keys %{$args->{ENABLE_CHK}} ) {
      if ( $db_var =~ m/^(\w+?)?_?${key_str}_?(\w+)?$/ ) {
	my $our_key = $db_var;
        my $one     = $1;
        $our_key    = "ALL_$key_str", $one = 'ALL' if not $1 and not $2;
	## substitute any __ with the normal :: perly syntax. ##
	$our_key    =~ s/__/::/g;

        ##
        ## there are 2 pre-tags available: NO and ALL.  NO trumps everything.
        ## emptying the hash for that attribute. ALL empties it, but just sets
        ## itself.
	if ($one) {
          if( $args->{ENABLE_CHK}->{$db_var}) {
	    $ENABLE_CHK->{$attr_str} = {};
            if ( $one eq 'NO' ) {
              next OUTER;
            } elsif ( $one eq 'ALL' ) {
              $ENABLE_CHK->{$attr_str}->{$our_key}
                = $args->{ENABLE_CHK}->{$db_var};
              next OUTER;
            }
              my $eval_str = "push \@${PACKAGE}::EXPORT_OK, \$attribute; "
              ."push \@${PACKAGE}::EXPORT, \$attribute;";
	      eval $eval_str;
	      _eval_die( $eval_str, $@) if $@;
	  }
        }


        ## only store those values that are true.  We want ENABLE_CHK to
        ## be empty if there are no debugging flags set so our Debug
	## calls optomize to doing nothing at all.
	$ENABLE_CHK->{$attr_str}->{ $our_key } = $args->{ENABLE_CHK}->{$db_var}
          if $args->{ENABLE_CHK}->{$db_var};
      }
    }
  }
  return 1;
}




sub _check_and_build_enable_attr {
  my $args = shift();

  if ( not $args->{ENABLE_ATTR} or ref $args->{ENABLE_ATTR} ne 'HASH' ) {
    croak "ENABLE_ATTR must be set with a ref to a hash containing "
      ."attribute names => key name.";
  } else {
    foreach my $key ( keys %{ $args->{ENABLE_ATTR} } ) {
      croak "$key or". $args->{ENABLE_ATTR}->{$key} ."must be in valid format."
        if $key !~ m/^\w+$/ or $args->{ENABLE_ATTR}->{$key} !~ m/^\w+$/;

      $ENABLE_ATTR->{$key} = $args->{ENABLE_ATTR}->{$key};
      $ENABLE_CHK->{ $key} = {};
      $ENABLE_FLAG->{$key} = {};
    }
  }
  return 1;
}



sub _check_and_build_enable_flags {
  my $args = shift();

  ## set the FLAGS (if there are any) ##
  foreach my $attr ( keys %{ $args->{ENABLE_FLAG} } ) {
    if ( ref $args->{ENABLE_FLAG}->{$attr} eq 'ARRAY' ) {
      foreach my $flag ( @{$args->{ENABLE_FLAG}->{$attr}} ) {
        $ENABLE_FLAG->{$attr}->{$flag} = 1;
        ## we want to export this as a constant too, so lets do that here ##
        my $eval_str = "{ package $PACKAGE;  use constant $flag => '$flag'; }";
        eval $eval_str;
        _eval_die( $eval_str, $@) if $@;

        $eval_str = "push \@${PACKAGE}::EXPORT_OK, '$flag'; "
        ."push \@${PACKAGE}::EXPORT, '$flag';";
        eval $eval_str;
        _eval_die( $eval_str, $@) if $@;
      }
    } else {
      croak "ENABLE_FLAG needs to be set with an array";
    }
  }

  return 1;
}

sub _export_my_attribute_symbols {
  ## export this functionality to the package that called it ##
  foreach my $attribute ( keys %$ENABLE_ATTR ) {
    $PACKAGE->export_to_level(2, $PACKAGE, $attribute);

    ## auto export flags for each one too ##
    foreach my $flag ( keys %{ $ENABLE_FLAG->{$attribute}} ) {
      $PACKAGE->export_to_level(2, $PACKAGE, $flag);
    }
  }
}


sub _eval_die {
  my $eval_str = shift();
  my $dol_at   = shift();

  die "Our eval failed: $@ : $eval_str";
}

##
## Attributes _should_ be mixed case or the Attribute handler will bitch
## NOTE: Using UNIVERSAL should install this so everything can use it.
##
## Debug will replace all subroutines that have the Debug attribute
## with a wrapper sub that will handle printing debugging information for
## each particular function call.  The beauty of this method is that this
## is only enabled at compile time, so there _should_ be no (or little) overhead
## at run time.
##
## also, the sub will only be redefined if the PERL_ENABLE environment variable
## was set to true.
#sub UNIVERSAL::Debug :ATTR {
sub My_attr_handler {
  my $attribute = $_[3];

  ## only do this if debugging is on in your environment ##
  return if not %{$ENABLE_CHK->{$attribute}};

  ## see perldoc Attribute::Handlers for full list of what @_ is here.
  my $symbol  = $_[1] or die "No symbol?";

  ## convert the symbol to a scalar and get rid of any crap in the begining ##
  my $chk = scalar( *$symbol );
  $chk =~ s/^\*//;

  ## return if the debug level wasn't set NOTE: $_[0] is the package name
  ## see perldoc Attribute::Handlers for what @_ is.
  my $debug_level = _is_attribute_on( $attribute, $_[0], $chk) or return;

  ## this is how to set some debugging stuff.  You're method call is now
  ## wrapped at compile time.  You've got to shut up warnings, or it will
  ## bitch about this being redefined. (hence the 'no warnings')
  no warnings;
  return *$symbol = _generate_attr_sub(@_, $debug_level);
}


sub _is_attribute_on {
  my $attribute = shift();
  my $package   = shift();
  my $chk       = shift();
  my $debug_str = $ENABLE_ATTR->{$attribute};

  ## if ALL debugging is on or if package specific debugging is on
  ## or if function specific debugging is on.
  my $debug_level = 0;
  if ( $ENABLE_CHK->{$attribute}->{"ALL_$debug_str"} ) {
    $debug_level = $ENABLE_CHK->{$attribute}->{"ALL_$debug_str"};
  } elsif ( $ENABLE_CHK->{$attribute}->{"${debug_str}_$chk"} ) {
    $debug_level = $ENABLE_CHK->{$attribute}->{"${debug_str}_$chk"};
  } elsif ( $ENABLE_CHK->{$attribute}->{"${debug_str}_$package"} ) {
    $debug_level = $ENABLE_CHK->{$attribute}->{"${debug_str}_$package"};
  }

  return $debug_level;
}


##
## this is a basic method for generating the wrapped debug sub.
## it's looking for the debug_$debug_level subroutine.  It'll crap out
## if it can't find it.  It starts looking for whatever level it's set at,
## and walks down one by one till it finds an applicable debug sub. 
sub _generate_attr_sub {
  my $debug_level = pop @_;
  my $attribute   = $_[3];

  while ( $debug_level ) {
    my $debug_sub = join( "_", "attr${attribute}", $debug_level--);
    return $PACKAGE->$debug_sub( @_ ) if $PACKAGE->can( $debug_sub );
  }

  ## crap out if we reach here cause there's no debug level for this ##
  die "I couldn't find a debug level at or below the one set.";
}


##
## this handles the static function calls that are exported to each package
## that wishes to use them.  It checks to see if the proper flags are set
## for it do run the user built function.  if not, it does nothing.
sub my_static_handler {
  my $attribute   = shift();
  my $flag        = shift();

  ## checks to see if this debug level is set by a flag being passed in.  If
  ## the flag doesn't exist in our flags hash, then we can assume that
  ## the flag variable isn't actually a flag, and is probably part of the
  ## debug arguments... so put it back onto our args list.
  my $debug_level = _is_flag_on($attribute, $flag);
  if( not defined $debug_level ) {
    unshift( @_, $flag ) if not defined $debug_level;
  }

  my $full_package = (caller(2))[3];

  my $caller_sub_name     = '';
  GET_PROPER_PACKAGE_NAME: {
    my @packages     = split /::/, $full_package;
    pop @packages;
    $caller_sub_name = join '::', @packages;
  }

  $debug_level = _is_attribute_on(
    $attribute,
    $full_package,
    $caller_sub_name
  ) if not $debug_level;

  return if not $debug_level;


  ## we've got our debug level at this point, but we need to make sure that
  ## there is an associated debug sub that matches the level.  If not, then
  ## we'll skip down till we find one.
  my $executable;
  while ( $debug_level ) {
    $executable = $PACKAGE->can( "our${attribute}_". $debug_level--);
    last if defined $executable;
  }

  return if not defined $executable;
      
  return &$executable(@_);
}


sub _is_flag_on {
  my $attribute = shift();
  my $flag      = shift() or return undef;

  return undef if not defined $ENABLE_FLAG->{$attribute}->{$flag};

  return $ENABLE_CHK->{$attribute}->{$ENABLE_ATTR->{$attribute} . "_$flag"} || 0;
}



##
##
## EEE  OOOO FFFF
##
##

=pod

=head1 NAME

Attribute::GlobalEnable - Enable Attrubutes and flags globally across all code.

=head1 SYNOPSIS

  package Attribute::GlobalEnable::MyPackage;
  
  use Attibute::GlobalEnable(
    ENABLE_CHK  => \%ENV,
    ENABLE_ATTR => { Debug => 'DEBUG_PERL' }
  );
  
  ## see Attribute::Handlers for more info on these variables.  Note
  ## that this_package is not included in the list (because we're
  ## calling it as a package method)
  sub attrDebug_1 {
    my $this_package   = shift();
    my $caller_package = shift();
    my $code_symbol    = shift();
    my $code_ref       = shift();
    my $atribute       = shift(); ## will be Debug ##
    my $attribute_data = shift();
    my $phase          = shift();
  
    ## lets see what comes in and out ##
    return sub {
      warn "IN TO ". scalar( *$code_symbol )
        . join "\n", @_;
      my @data = &code_ref(@_);
      warn "OUT FROM ". scalar( *$code_symbol )
        . join "\n", @data;
      return @data;
    }
  }
  
  sub ourTest_1 {
    my $message = shift();
  }
  
  1;
  
  ...
  ...
  
  ## now, in your code: test_me.pl
  
  
  sub my_funky_function : Debug {
    my $self = shift();
    my $var1 = shift();
    my $var2 = shift();
  
    ## do some stuff ##
    Debug( "VAR1: $var1" );
    Debug( "VAR2: $var2" );
  }
  
  ## since you've tied any debugging checks in to your env
  ## you can turn MyPackage functionality on or off by setting
  ## env vars with the special tag: DEBUG_PERL
  
  ## set it to level 1 for everything
  %> ALL_DEBUG_PERL=1 ./test_me.pl
  ## or
  %> DEBUG_PERL=1 ./test_me.pl
  
  ## just for package 'main'
  %> DEBUG_PERL_main=1 ./test_me.pl
  
  ## just for a single function
  %> DEBUG_PERL_main__my_funky_function ./test_me.pl
  
  ## force it off for everyone
  %> NO_DEBUG_PERL=1 ./test_me.pl

=head1 DESCRIPTION

Attribute::GlobalEnable provides switchable attribute hooks for all packages in
your namespace.  It's primarily been developed with the idea of providing
debugging hooks that are very unobtrusive to the code.  Since attributes
trigger their functionality at compile time (or at the least very early on,
before execution time), not enabling (or having your flags all off) does
nothing to the code.  All the special functionality will be skipped, and
your code should operate like it wasn't there at all.  It is, however,
not specific to debugging, so you can do what you wish with your attributes.

Since all of the functionality of what your attributes do is defined by the
user (you), you MUST subpackage Attribute::GlobalEnable.  It handles all of
the exporting for you, but you must format your hooks as explained below.

Along with the special attribute functionality, the package also builds
special functions named the same as your attributes, and exports them to
which ever package 'use's your sub-package.  Along with this, you can define
special flags that will turn this function on or off, and the flags play
with the rest of the system as one would expect.

This package does not inherit from the Attribute class.

=head1 FUNCTIONS

There are no functions to use directly with this package.  There are, however,
some special function names that YOU will define when subpackaging this, and
a package constructor where you do just that.

=head2 Package Constructor

This package is NOT an object.  It is functional only.  However, you must
initialize the package for use.  The package is (more or less) a singleton,
so you can only initialize it once.  DO NOT try to have multiple packages
set values, as it will just skip subsequent attempts to import past the
first one.

There are 2 required keys, and 1 optional:

=head3 (required) ENABLE_ATTR => $hash_ref

This key is really the meat of it all, and the data you supply initializes
the attributes, and what functions it expects to see in your sub-package.
The structure of the hash is laid out as:

  {'Attribute_name' => 'SPECIAL_KEY', 'Attribute_name_2'... }

The attribute name must be capitalized (see Attribute::Handlers), the
SPECIAL_KEY can be any string.  You can have as many key => value pairs as
you deem necessary.

Setting this value has multiple effects.  First, it assigns the attribute
'Attribute_name' to a subroutine in the callers namespace, named:

  attr'Attribute_name'_#
  ## ex: attrDebug_1

The # should be an integer, and represents the number the SPECIAL_KEY has
been set to.  More on that in a second tho.  The attribute name is set in
the UNIVERSAL namespace, so now it can be utilized by everything under
your particular perl sun.

What ever packages 'use' your sub-package, have another special subroutine
named 'Attribute_name' exported to their namespace.  This subroutine points
to your sub-package subroutine named (similarly to above):

  our'Attribute_name'_#
  ## ex: ourDebug_1

The # should be an integer (see below for proper values) This function
can be turned on by the regular SPECIAL KEY, but also by any ENABLE_FLAGS
that you've defined as well... but more on that later.

The 'SPECIAL_KEY' is the distinct identifier to trigger this attributes
functionality.  It is not really meant to be used on it's own, (but it can).
It is mostly an identifier string that allows you to add stuff to it to
easily customize what you want to see (or do or whatever).  There are 2
special pre-strings that you can slap on to the begining of the key:

=over

=item ALL_'SPECIAL_KEY' (or just 'SPECIAL_KEY')

This turns the attributes functionality on for ALL of those subroutines that
have the attribute.  This trumps all other settings, except for the NO_
pre-string.

=item NO_'SPECIAL_KEY'

This is essentially the default behaviour, turning the attribute stuff off.
This trumps everything... Other 'SPECIAL_KEY's, and any ENABLE_FLAGS.

=back

You can append package names, or even subroutines to the end of the
'SPECIAL_KEY', in order to turn the attribute functionality on for a specific
package or subroutine.  Just separate the 'SPECIAL_KEY' and your specific
string with an underscore.  Neato eh?  There is one caveat to this.  The regular
perl package (namespace) separator is replaced with two underscores, so if
you wanted to turn on attribute behaviour for MyPackage::ThisPackage, your
key would look like so:

'SPECIAL_KEY'_MyPackage__ThisPacakge

I did this so that you can just pass in the %ENV hash, and set your 
attribute 'SPECIAL_KEY's on the command line or whathave you.

Finally, the '#'s that you must name each of your special subs with,  represent
a level for a particular functionality.  This level is checked each time,
and the appropriate subroutine will be called, or it will try the next level
down.  So, forexample:  If you just have attr'Attribute_name'_1, but you set
your 'SPECIAL_KEY' to 3, then attr'Attribute_name'_1 will be executed.
if you had an attr'Attribute_name'_2, then that subroutine would be executed
instead of 1.  This will not call each subroutine as it goes, it simply executes
the first one it finds.


=head3 (required) ENABLE_CHK => $hash_ref

This must be set to a hash ref whos structure is laid out as:

  SOME_FLAG => $integer,

$integer should be positive, and represents the attribute level you wish to
do attribute stuff at. (see ENABLEL_ATTR above for more info on that).  The
actual hash can be empty, but the reference must exist.

This represents the actual user set triggers for the attributes.  Telling
GlobalEnable which to... well... enable, and which to skip.

See the previous section for a description on special characters etc...

=head3 ENABLE_FLAG => $hash_ref

The $hash_ref structure must be:

  { Attribute_name => [ list of flags ], Attribute_name_2 ... }

The ENABLE_FLAG is optional, and describes flags that can be set for the
exported 'Attribute_name' subroutines.  These are exported as global
constants, so it looks nice and neat in your code.  This essentially links
that sub call to that flag.  The flag is still set like it would normally be
set in the ENABLE_CHK hash,  however, you still must use the 'SPECIAL_KEY'
(see above) in the assignment, so your assignment will look like:

  'SPECIAL_KEY'_'FLAG'

=head2 attr'Attribute_name'_#

See ENABLE_ATTR above for a description on the layout naming scheme for this
particular subroutine name.

This is your attribute hook for a particular level.  This must return a
subroutine.  The subroutine that it returns replaces the one the attribute is
currently assigned to.  You can do anything you wish at this point, as you'll
have access to everything that's being passed in, everything that's being
passed out, and whatever else you want.

It will always get these variables when it's called:

=over

=item [0] : package name ala $package->attr'Attribute_name'_1

=item [1] : callers package name

=item [2] : the code symbol (GLOB)

=item [3] : the code reference of the sub that has this attribute turned on.

=item [4] : the attribute name that triggered this.

=item [5] : any attribute data assigned to the attribute.

=item [6] : the current phase this was activated in.

=back

See perldoc Attribute::Handlers for more descirption on what these values
are, or how to utilize them.

=head2 our'Attribute_name'_#

This is the sub that's pointed to from our exported 'Attribute_name' subroutine.
If you pass in a valid flag, it'll clear that out before it sends the rest
of the arguments your way.  There is no need to return a sub, as this is the
actual subroutine that's executed when you trigger this special sub.

=head1 EXAMPLES

For right now, see the tests for some examples.  There's a test module in
the test dir as well.  I'll fill in some examples a little later.

=head1 SEE ALSO

perldoc perlsub, Attribute::Handlers

=head1 AUTHOR

Craig Monson (cmonson [at the following]malachiarts com)

=head1 ERRORS

=over

=item Must specify some arguments.

You tried to init the package with nuttin.  Gotta pass in some args.

=item Must sub-package

This isn't meant to be run on it's own.

=item ENABLE_CHK needs to be set with a hash ref for this module to be used

your ENABLE_CHK wasn't a hash ref.  Please read this doc ;)

=item ENABLE_ATTR must be set with a ref to a hash containing attribute names => key name.

your ENABLE_ATTR was in the wrong format.

=item 'blah' or 'blah' must be in valid format.

Your key or value for ENABLE_ATTR wasn't in the right format.

=item ENABLE_FLAG needs to be set with an array.

If you're gonna set ENABLE_FLAG, the values for the keys must be array refs.

=item Our eval failed: blah blah

If you get this, then it's prolly a bug in the package.  Please report it to
me.

=back

=head1 BUGS

<none as of yet>

=head1 COPYRIGHT

I suppose I (Craig Monson) own it.  All Rights Reserved.  This module is 100%
free software, and may be used, reused, redistributed, messed with,
subclassed, deleted, printed, compiled, and pooped on, just so long as you
follow the terms described by Perl itself.

=cut



1;

