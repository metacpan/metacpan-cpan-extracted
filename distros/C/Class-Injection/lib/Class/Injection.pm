package Class::Injection; ## Injects methods to other classes

use 5.006; 
use Class::Inspector;
use strict;
use Data::Dumper;

our $VERSION = '1.10';

our $DEBUG;
our $info_store={};
our $break_flag;

no warnings;





## The import function is called by Perl when the class is included by 'use'.
## It takes the parameters after the 'use Class::Injection' call.
## This function stores your intention of injection in the static collector
## variable. Later you can call install() function to overwrite or append the methods.
sub import{
    my $pkg=shift;
    my $target=shift; # the first parameter, which is the target

    if (!$target){return};

    my $secondvalue = shift;

    my $copymethod;
    my $priority;
    my $returntype;
    my $returnmethod;
    my $replacetarget;
    

    ## if the second value is a hashref, asign the elements
    if ( ref($secondvalue) ){

      $copymethod = $secondvalue->{'how'} || $secondvalue->{'copymethod'};
      $priority   = $secondvalue->{'priority'};
      $returntype = $secondvalue->{'returns'} || $secondvalue->{'returntype'} || '';
      $returnmethod = $secondvalue->{'returnmethod'} || 'last';
      $DEBUG = $DEBUG || $secondvalue->{'debug'} =~ m/^(true|yes|1)$/i ? 1 : 0;

      $replacetarget = $secondvalue->{'replace'} =~ m/^(true|yes|1)$/i ? 1 : 0;

    }else{ ## if the second value is NOT a ref, take copymethod and prio
      $copymethod = $secondvalue || 'replace';
      $priority   = shift; ## default prio is 1 
    }

    if ( $copymethod eq 'replace' ){
      $replacetarget = 1;
    }

    
    my @caller=caller;
    my $class = shift @caller; # calling class (which has 'use Class::Injection')

    ## used for insert and append
    $Class::Injection::counter_neg--;
    $Class::Injection::counter_pos++;
    
    if ($priority < $Class::Injection::counter_neg){
      $Class::Injection::counter_neg = $priority - 1;
    }

    if ($priority < $Class::Injection::counter_pos){
      $Class::Injection::counter_pos = $priority + 1;
    }

    

    ## setting default priorities
    if ( $priority eq "" ){
        if ( $copymethod eq 'insert'){
            $priority = $Class::Injection::counter_neg;
        }else{ ## add or append
            $priority = $Class::Injection::counter_pos;
        }
    }
    

    
    if (!$target) {
      die __PACKAGE__." expects a parameter as target class in the use line."
    }

    
    ## collection the classnames using the injector
    $__PACKAGE__::collector ||= {};
    $__PACKAGE__::collector->{$class} = { target          =>  $target,
                                          priority        =>  $priority,
                                          copymethod      =>  $copymethod,
                                          returntype      =>  $returntype,
                                          returnmethod    =>  $returnmethod,
                                          replacetarget   =>  $replacetarget,
                                        };
}





## Installs the methods to existing classes. Do not try to call this method in a BEGIN block,
## the needed environment does not exist so far.
sub install{

  my $col = $__PACKAGE__::collector;

  if ($DEBUG){
      print "collected methods:\n";
      print Dumper($col);
  }

  

  my $sources_by_target={};

  foreach my $source (keys %{ $col }) { ## loop per source class
 
    my $target      = $col->{$source}->{'target'};
    my $copymethod  = $col->{$source}->{'copymethod'};
    my $priority    = $col->{$source}->{'priority'};

    ## check if source exists on the memory (is loaded via 'use')
    if (!Class::Inspector->loaded( $source )) {
      if (!Class::Inspector->installed($source)) {
        die "Class \'$source\' not installed on this machine or path not in \@INC.";
      }
      die "Class \'$source\' not loaded.";
    }

    ## read the methods of the source class
    my $functions = Class::Inspector->functions( $source );


    ## build an array of sources by target
    ## its the reverse way to see what sources wants
    ## to inject a target
    foreach my $method (@$functions) {
        $sources_by_target->{$target}->{$method} ||= [];
        push @{ $sources_by_target->{$target}->{$method} }, $source;
    }


    
    
  
    
  } # end each $source
  

  ## sorting the source by its priority
  foreach my $target (keys %{ $sources_by_target }){
    foreach my $method (keys %{ $sources_by_target->{$target} }){

      my @tosortarray = @{ $sources_by_target->{$target}->{$method} };
#          @tosortarray = sort { $col->{$b}->{'priority'} <=> $col->{$a}->{'priority'} } @tosortarray;
          @tosortarray = sort { $col->{$a}->{'priority'} <=> $col->{$b}->{'priority'} } @tosortarray;

      $sources_by_target->{$target}->{$method} = \@tosortarray;

    }
  }
  
  
#    print Dumper($sources_by_target);exit;



  ## collects replace tags for target.
  ## if there is at least one class which wants
  ## to replace the target, it will not keep the
  ## original target method.
  my $replace_target={};
  foreach my $target (keys %{ $sources_by_target }){
    foreach my $method (keys %{ $sources_by_target->{$target} }){

        foreach my $source ( @{$sources_by_target->{$target}->{$method}} ){
            
            if ( $col->{$source}->{'replacetarget'} ){
                $replace_target->{$target} = 1;    
            }

        }
    }
  }


  
  
  ## building the injection code
  my @cmd;
  foreach my $target (keys %{ $sources_by_target }){

    foreach my $method (keys %{ $sources_by_target->{$target} }){

        my $returntype = 'array';
        my $returnmethod = 'last';

        my @cmd_pos;
        my @cmd_neg;
        my @cmd_zer;


        push @cmd, ' my $orgm=\&'.$target.'::'.$method.';';

#         push @cmd, '*'.$target.'::_INJBAK_'.$method.'=\&'.$target.'::'.$method.';';


        push @cmd, '*'.$target.'::'.$method.' = sub {';

        push @cmd, ' my @ret_org;';
        push @cmd, ' my @ret;';
        push @cmd, ' my @ret_refs;';
        push @cmd, ' my @ret_last;';

        push @cmd, ' $__PACKAGE__::last_returned_value = [];';


        push @cmd, 'do {'; # break block

        
        if (!$replace_target->{$target}){ ## if no replace, reimplement original method
             push @cmd_zer, ' @ret_org = &$orgm(@_);';

#             push @cmd_zer, ' @ret_org = '.$target.'::_INJBAK_'.$method.'(@_);';
            push @cmd_zer, ' push @ret, @ret_org;';

            push @cmd_zer, ' push @ret_refs, \@ret_org;';

            push @cmd_zer,'last if $Class::Injection::break_flag;';

        }
        
        foreach my $source ( @{$sources_by_target->{$target}->{$method}} ){

            my $priority = $col->{$source}->{'priority'};
            my $met_returntype = $col->{$source}->{'returntype'};
            my $met_returnmethod = $col->{$source}->{'returnmethod'};
            
            if ($met_returntype) { ## a different returntype set?
                $returntype = $met_returntype;
            }

            if ($met_returnmethod) { ## a different returntype set?
                $returnmethod = $met_returnmethod;
            }

            #my $copymethod = $col->{$source}->{'copymethod'};

            my $waitcmd;
            $waitcmd .= 'my @ret_tmp = '.$source.'::'.$method.'(@_);'."\n"; # method call


            $waitcmd .= ' $__PACKAGE__::last_returned_value = \@ret_tmp;'."\n";

            $waitcmd .= ' push @ret_last, @ret_tmp;'."\n";
            $waitcmd .= ' push @ret, @ret_tmp;'."\n";
            $waitcmd .= ' push @ret_refs, \@ret_tmp;'."\n"; ## collecting references
            $waitcmd .= ' last if $Class::Injection::break_flag;'."\n";
            
            ## depending on the priority place it before or after
            if ($priority < 0){
                push @cmd_neg, $waitcmd;
            }

            if (0 < $priority){
                push @cmd_pos, $waitcmd;
            }
            
        }

        push @cmd, @cmd_neg;
        push @cmd, @cmd_zer;
        push @cmd, @cmd_pos;

        ## type of return - all the same at the moment
        my $ret_sign='@';
        if ( $returntype eq 'array' ){
            $ret_sign = '@';            
        }
        elsif ( $returntype eq 'scalar' ){
            $ret_sign = '@';            
        }
        elsif ( $returntype eq 'hash' ){
            $ret_sign = '@';            
        }
        
        

        # what to return
        my $ret_meth='ret';
        if ( $returnmethod eq 'last' ){
            $ret_meth = 'ret_last';
        }
        if ( $returnmethod eq 'all' ){
            $ret_meth = 'ret';
        }
        if ( $returnmethod eq 'original' ){
            $ret_meth = 'ret_org';
        }
        if ( $returnmethod eq 'collect' ){
            $ret_meth = 'ret_refs';
        }

        my $retv = $ret_sign.$ret_meth;

        push @cmd, '} until (1 == 1);'; # break block
        push @cmd,'$Class::Injection::break_flag = 0;'; ## reset the break flag

        if ($returnmethod eq 'collect'){
          push @cmd, ' return wantarray ? '.$retv.' : \\'.$retv.';'; ## assembles to a returnvalue
        } else {
          push @cmd, ' return wantarray ? '.$retv.' : shift '.$retv.';'; ## assembles to a returnvalue
        }

        #push @cmd, ' return wantarray ? @ret : \@ret;'     if $returntype eq 'array';
        
        push @cmd, '};';
        

    } # end method
  } ## end building injection code
  
  
  
  my $cmd = join("\n",@cmd);


  if ($DEBUG){
    print "sources by target:\n";
    print Dumper($sources_by_target);
  }

  ## save infos
  $Class::Injection::info_store->{'sources_by_target'} = $sources_by_target;
  _add_detailed_source_infos($sources_by_target);



  print "\n\n\n".$cmd if $DEBUG;
  
  eval($cmd); ## no critic
  if ($@){
    die __PACKAGE__." ERROR when injecting: ".$cmd.$@;
  }

}



## Can be called inside a new method to get the value of a previosly called method.
## It is allways an arrayref
sub lastvalue{
  my $v = $__PACKAGE__::last_returned_value || [];
  return $v;
}



## add some more infos to the info store, 
## call the method Class::Injection::info for all
## infos.
sub _add_detailed_source_infos{

  my $detailhash = {};

  my $sinfo = $Class::Injection::info_store->{'sources_by_target'};

  ## adding detailed source infos (calling parameters)
  foreach my $target (keys %$sinfo) {
    foreach my $tmethod (keys %{ $sinfo->{$target} } ) {

      my @sdclass;
      foreach my $sclass (@{ $sinfo->{$target}->{$tmethod} } ) {

          my $param = $__PACKAGE__::collector->{$sclass};

          push @sdclass,{ class=>$sclass, param=>$param };

      }
      $detailhash->{$target}->{$tmethod}= \@sdclass;

    }
  }
  

  $Class::Injection::info_store->{'sources_by_target_detail'} = $detailhash;

  my @neg;
  my @pos;

  ## building a replacement matrix as array
  my @allmatrix;
  foreach my $target (keys %$sinfo) {

  my $replacetarget;

    foreach my $tmethod (keys %{ $sinfo->{$target} } ) {

      my @matrix;

      foreach my $sclass (@{ $sinfo->{$target}->{$tmethod} } ) {

          my $param = $__PACKAGE__::collector->{$sclass};

          my $priority = $param->{'priority'} || 1; ## default is add

          if ($param->{'replacetarget'}){ $replacetarget=1 };

          my $node =      { 
                           target  => "$target"."::$tmethod",
                           source  => "$sclass"."::$tmethod",
                           comment => "injected",
                          };

          if ( $priority < 0 ){
            push @neg, $node;
          }else{
            push @pos, $node;
          }


      }

      my $org = {
                            target  => "$target"."::$tmethod",
                            source  => "$target"."::$tmethod",
                            comment => "original",
                };

      push @matrix,@neg;
      push @matrix,$org if !$replacetarget;
      push @matrix,@pos;

      push @allmatrix,\@matrix;

    }


  }


  $Class::Injection::info_store->{'replacement_matrix'} = \@allmatrix;

}


## Shows a easy to read matrix which methods injected which classes.
## It displays also the new order of the methods.
sub show_replacement_matrix{

  my $matrix = $Class::Injection::info_store->{'replacement_matrix'};

  my @rows;

  foreach my $classblock (@$matrix) {

    my @crows;

    foreach my $methodblock (@$classblock) {
      push @crows, sprintf("%-42s <-     %-42s%-10s", $methodblock->{'target'}, $methodblock->{'source'}, $methodblock->{'comment'} );
    }    

    push @rows, join("\n",@crows);
  }

  my $delim;
  $delim.="-" x 100;
  $delim.="\n";

  print $delim.join($delim,@rows)."\n".$delim."\n";

}


## sets a flag to break after current method. No further methods used in the method stack.
## You can use that in your new method like:
##
##  Class::Injection::break;
##
sub break {
    $Class::Injection::break_flag = 1;
}


## returning infos about the installed methods as a hash.
sub info {
    return $Class::Injection::info_store;
}





1;



#################### pod generated by Pod::Autopod - keep this line to make pod updates possible ####################

=head1 NAME

Class::Injection - Injects methods to other classes

=head1 DESCRIPTION

The Injection class is a elegant way to manipulate existing classes without editing them.
It is done during runtime. It is a good way to write plugins without creating special plugins
technologies.



=head1 SYNOPSIS



 # Here an original class
 # Imagine you want to overwrite the test() method.

 package Foo::Target;

 sub test{
   my $this=shift;
 
   print "this is the original method.\n";
   
 }


In a simple Perl file you can use that class:

 use Foo::Target;

 my $foo = Foo::Target->new();

 my $foo = Over->new();

 $foo->test(); # outout is: 'this is the original method'


So far nothing happened

If you want to change the test() method without editing the original code, you can use Class::Injection.
First create a new class, like this:

 package Bar::Over;


 use Class::Injection qw/Foo::Target/; # define the target


 sub test {
   my $this=shift;

   print "this is the new method\n";
  
 }


To define the class which should be overwritten, you set the name after the 'use Class::Injection' call, here Foo::Target.

In the calling Perl script to need to initialize that:


 use Foo::Target;
 use Bar::Over1;

 Class::Injection::install(); # installs the new methods from Bar::Over

 my $foo = Foo::Target->new();
 
 $foo->test(); # Output is: 'this is the new method'

  
The example above uses the default copymethod 'replace', which just replaces the methods.
Class::Injection can do more complicated things, depending on your need you can stack methods
to run several different variations e.g. of a test(). You can also define the way of returning a value.








=head1 ADD A METHOD


The simplest way to add a method to an existing one you can see in the example below. To add a method means to
execute the original method and the new method.

 package Over;

 use Class::Injection qw/Target add/;

 sub test { ... };

This example overwrites a class 'Target'. You can see the second value after the target class is the copymethod.
Here it is 'add'. It is equivalent to 'append'.





=head1 RETURN TYPES


You can configure the return types of a method. Please be aware of the its behaviours:

1. It is a class-wide configuration.

2. If you use more than one overwriting class, The last called, defines the overwriting rules.

At first have a look into the following example how to set complex parameters:

 use Class::Injection 'Target', {
                                    'how'           =>  'add',
                                    'priority'      =>  4,
                                    'returnmethod'  =>  'collect',
                                };

The first parameter is still the target class, but then follows, seperated by a comma, a hashref with some values.

how - defines the way of adding the method. Default is 'replace'. You can also use 'add' (same as 'append') or 'insert'.

copymethod - same as 'how'.

priority - please see the chapter PRIORITY for that.

returns - defines the return-type. (see below)

returntype - same as 'returns'.

returnmethod - defines which method(s) return values are used. (see below)

debug - enables the debug mode and prints some infos as well as the virtual commands. use 'true|yes|1' as value.

replace - will cause the original method not to be used anymore, it will completely replaced by the injection methods. use 'true|yes|1' as value.


The returntype is currently set to 'array' for any type. What means it is not further implemented to returns something else.
I have to see if there changes are neccessary during praxis. So far it looks like a return of array is ok.

The returntype is currently more automatically defined by context! It means if you e.g. call a

 my @x = test();

It gives you an array, and if you do

 my $x = test();

It gives you an scalar. But it depends on the used 'returnmethod' what exaclty you will get! With 'collect' it returns an
arrayref, with anything else it will be the first value, if in scalar context.







=head1 RETURNMETHOD


The returnmethod can have the following values:

last, all, original, collect.

Before you start dealing with returnmethods, please note, that it might get compilcated, because you are changing the way of
returning values of the original method. If you just use 'replace' you dont change the returnmethods. It can be used to build
a plugin system and handling the results of several parallel classes.

If you want to manipulate values with the methods (functions), I recommend using references as a part of the given 
parameters and not the output of a method. For example:

 # not good:
 my $string = 'abcdefg';
 my $new_string = change_text($stgring)

The example above will make trouble if you use 'collect' as returnmethod. 

 # better:
 my $string = 'abcdefg';
 change_text(\$stgring)

Here each new installed method just takes the reference and can change the text. No return values needed.


The default is 'last', what means the last called method's return values are used. This is the most save
way to handle, because this method is usually used somewhere already and a specific returntype is expected.
If you just change it, maybe the code stops working.

Also save is 'orginal' that will just return the original's method value.

With 'all' it merges all return values into an array, what must be handled in context. If you previosly used that call:

 my $x = test();

It will give you now only the first value, what is maybe not what you want. Expect with 'all' an array as return value and handle it:

 my @x = test();




=head1 PRIORITY


You can add more than one method. To finetune the position, you can set as a third value a priority. The original
class has the priority 0. Every positive number comes later and negative numbers before.

 package Over;

 use Class::Injection qw/Target add -5/;

 sub test { ... };

If you dont care about a priority, but just want the same order like it is listed, you can use 'insert' (before) or
'append'.

 use Class::Injection qw/Target append/;
 ...
 use Class::Injection qw/Target insert/;

Inserted class's method will be called before the appended class's method.




=head1 PLUGINS


How to use Class::Injection to build a plugin system?

I see two type of plugins here:

1. Just replacing existing methods and returning ONE value, like the original method.

2. The caller expects plugins, what means he may handle different return values, that can occour when e.g. used 'collect' as
a copymethod.

For both types you will need to scan a folder for perl modules and 'use' them. Of course I assume they have the Class::Injection in use.

If the calller expects plugins, I recommend using an abstract class as a skelleton, which the caller uses to instantiate the class.
The methods of the abstract class should already return an arrayref. And in the plugins use the key " replace => 'true' " in the 
Class::Injection line. That will overwrite the abstract class's methods.

    package Abstract;

    sub test{
    my $this=shift;


    return [];
    }

    1;


Here a plugin:


 package Plugin1;
 
 use base 'Abstract';
 
 use Class::Injection 'Abstract', {
                                   'how'           => 'add',
                                   'returnmethod'  => 'collect',
                                   'replace'       => 'true',
                                  };
 
 sub test{
   my $this=shift;
 
   return "this is plugin 1";
 }
 
 1;

The main script:

    eval('use Plugin1;'); # only to show it might be dynamically loaded

    use Class::Injection;
    use Abstract;

    Class::Injection::install();

    my $foo = Abstract->new();












=head1 FUNCTIONS


 



=head2 import

 Class::Injection::import();

The import function is called by Perl when the class is included by 'use'.
It takes the parameters after the 'use Class::Injection' call.
This function stores your intention of injection in the static collector
variable. Later you can call install() function to overwrite or append the methods.



=head2 break

Breakig in a method

 Class::Injection::break();

sets a flag to break after current method. No further methods used in the method stack.
You can use that in your new method.


If you want to break and makes the current method to the last one used, you can set a break flag by calling a static method:

    sub test{
     my $this=shift;

     Class::Injection::break;

     return "this is plugin 1";
    }

After this method, nur further method is called. Make sure you use the break on the very and of a method, because it could be that further, deeper methods you 
call, also are injected. That would cause a break for them.




=head2 lastvalue

Value of last method

If you want to work with the result of the former injected method in a method, you can get the
result, as a arrayref, with the static method lastvalue:

  Class::Injection::lastvalue



=head2 info

 Class::Injection::info();

returning infos about the installed methods as a hash.



=head2 show_replacement_matrix

 Class::Injection::show_replacement_matrix();

Prints an easy to read matrix like that:

  ----------------------------------------------------------------------------------------------------
  Local::Abstract::test                      <-     Local::Plugin2::test                      injected
  Local::Abstract::test                      <-     Local::Abstract::test                     original
  Local::Abstract::test                      <-     Local::Plugin1::test                      injected
  ----------------------------------------------------------------------------------------------------

to show what happens to the classes and methods.



=head2 install

 Class::Injection::install();

Installs the methods to existing classes. Do not try to call this method in a BEGIN block,
the needed environment does not exist so far.




=head1 REQUIRES

L<Data::Dumper> 

L<Class::Inspector> 





=head1 AUTHOR

Andreas Hernitscheck  ahernit(AT)cpan.org 


=head1 LICENSE

You can redistribute it and/or modify it under the conditions of LGPL and Artistic (What means to keep the original author in the source code).

=cut
