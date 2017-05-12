
package Config::Constants;

use strict;
use warnings;

our $VERSION = '0.03';

my %CONFIG_LOADER_CLASSES = (
    perl => 'Config::Constants::Perl',
    xml  => 'Config::Constants::XML'
);

# our config object
my $CONFIG;

# these two hashes are used
# for checking to make sure
# no invalid constants are used
my %UNCHECKED_CONSTANTS;
my %CHECKED_CONSTANTS;

sub import {
    shift;
    return unless @_;
    my @args = @_;
    if ($args[0] =~ /xml|perl/) {
        my ($type, $file) = @args;
        my $config_loader_class = $CONFIG_LOADER_CLASSES{$type};
        # try to load the config loader ...
        eval "use $config_loader_class";
        die "Failed to load config loader class ($config_loader_class) : $@" if $@;
        # try to load the config ...
        $CONFIG = eval { $config_loader_class->new($file) };
        die "Failed to load config (type => $type, file => $file) : $@" if $@;
        _load_all_modules();
    }
    else { 
        my $calling_pkg = caller();
        if (exists $UNCHECKED_CONSTANTS{$calling_pkg}) {
            # this means that the conf was loaded first, so we 
            # need to check the constants which were created
            # against the ones which are allowed for this
            # module, and if we find we have created extra
            # ones we throw an exception
            foreach my $arg (@args) {
                delete $UNCHECKED_CONSTANTS{$calling_pkg}->{$arg} 
                    if exists $UNCHECKED_CONSTANTS{$calling_pkg}->{$arg}
            }
            die "Unchecked constants found in config for '$calling_pkg' -> (" . 
                join(", " => keys(%{$UNCHECKED_CONSTANTS{$calling_pkg}})) . 
                ")" if keys %{$UNCHECKED_CONSTANTS{$calling_pkg}};
        }
        else {    
            # this means the conf has not been loaded yet, 
            # so we need to build a list of acceptable 
            # constants to check against.
            $CHECKED_CONSTANTS{$calling_pkg} = {  map { $_ => undef } @args };
        }
        no strict 'refs';
        foreach my $arg (@args) {
            # skip it if it has already been defined
            # NOTE: this means that the config was 
            # loaded before the module itself was
            # loaded, so we don't want to overwrite
            next if defined &{"${calling_pkg}::$arg"};         
            # However, if it hasn't been defined, then
            # we want to do so. This will create a 
            # stub sub which will die if it is not 
            # configured. 
            # NOTE: the sub does not have the () prototype
            # here so that we can prevent constant folding
            # from happening. When the proper sub gets 
            # installed, it will have that prototype (and 
            # thus be folded in)
            *{"${calling_pkg}::$arg"} = sub { die "undefined Config::Constant in ${calling_pkg}::$arg" };
        }
    }
}

## For DEBUGGING
#INIT {
#    use Data::Dumper;
#    print "UNCHECKED: " . Dumper \%UNCHECKED_CONSTANTS;
#    print "CHECKED: "   . Dumper \%CHECKED_CONSTANTS;     
#}

## Private Utility Functions

sub _load_all_modules {
    foreach my $module ($CONFIG->modules()) {
        _load_module($module);
    }
}

sub _load_module {
    my $module = shift;
    no strict 'refs';    
    foreach my $constant ($CONFIG->constants($module)) {
        my ($name, $value) = each %{$constant};
        if (defined &{"${module}::$name"}) {
            # since this already exists, we 
            # assume that it is a valid constant
            # and that our module was already
            # loaded
            no warnings;
            *{"${module}::$name"} = sub () { $value };    
            delete $CHECKED_CONSTANTS{$module}->{$name};
        }
        else {
            # since this does not exist, then our
            # module may not have been loaded yet.
            # but in order to determine this,
            # we have to see if the constants have
            # been registered yet ...
            if (exists $CHECKED_CONSTANTS{$module}) {
                # this means our module was loaded first, and
                # the constants were registered. Now, if 
                # we do not see this particular constant 
                # in here, then we need to throw an exception
                die "Unknown constant for '$module' -> ($name)"
                    unless exists $CHECKED_CONSTANTS{$module}->{$name};
            }
            else {
                # being in this block means that is is unlikely 
                # the conf has been loaded yet, so we will 
                # just create our constants, and make a note
                # of each of them so that they can be 
                # checked later on.
                $UNCHECKED_CONSTANTS{$module} = { $name => undef };                                        
                *{"${module}::$name"} = sub () { $value };                    
            }
        }            
    }    
}


1;

__END__

=pod

=head1 NAME

Config::Constants - Configuration variables as constants

=head1 SYNOPSIS
  
  # in your perl modules
  
  package Foo::Bar;
  
  use Config::Constants qw/BAZ/;
  
  sub foo_bar { print "Foo::Bar is " . BAZ }
  
  # in the conf.xml
  
  <config>
      <module name='Foo::Bar'>
            <constant name='BAZ' value='the coolest module ever' />
      </module>
  </config>
  
  # or in the conf.pl
  
  {
      'Foo::Bar' => {
          'BAZ' => 'the coolest module ever',
      }
  }  
  
  # in the in your perl code
  
  use Config::Constants xml => 'conf.xml';
  # or ...
  use Config::Constants perl => 'conf.pl';
  
  use Foo::Bar;
  
  Foo::Bar::foo_bar(); # prints "Foo::Bar is the coolest module ever"

=head1 DESCRIPTION

Using configuration files can help to make you code more flexible. However, this flexiblity comes at a cost of reading and parsing the configuration file, and then making the configuration information available to your application. Most times this is a trade off which is well worth the price, and which works well in many situations.

However, sometimes what you want to configure is really very simple, and it can feel like overengineering to have to use a config object instance and fetch the config variable, and that is where this module comes into play.

Config::Constants allows you to avoid all that overhead by loading the configuration file very early (compile time) and using perl's compile time constant folding to inline your configuration variables. 

If you want to see this module in action. Just run this command from within this distribution's folder, and compare what you see to the actual files.

  perl -I lib/ -MO=Deparse,-ft/lib/Foo/Bar.pm,-ft/lib/Bar/Baz.pm t/11a_Config_Constants_w_Perl.t

=head2 Interaction with OO

This module will work for OO modules, however it does have some restructions. 

=over 4

=item *

The first restriction is that constants cannot be folded properly if they are treated as methods. So given this relationship:

  package Foo;
  use Config::Constants 'BAZ';
  
  package Foo::Bar;
  use base 'Foo';
  
If you wanted to refer to Foo's constant BAZ in Foo::Bar, and still retain the constant folding behavior, you should use it's fully qualified form 'Foo::BAZ'. However, this means that you are hard-coding the name of the super class into it's subclass, something not usually considered good OO practice. 

If you want to avoid hardcoding the super class, then it is possible to call the constant in a number of other ways:

  $instance->BAZ;
  $instance->SUPER::BAZ;
  SUPER::BAZ;
  __PACKAGE__->SUPER::BAZ;
  
The problem with these approaches is that it will prevent any compile time constant folding from happening. This does happens for a very good (and well understood) reason. In most OO langauges the class of the invocant may not be known until runtime, this makes it almost impossible for a constant to know which class to get the constant from at compile time.

=item *

The next restriction is that classes will B<not> inherit the constants from their super class.So given the relationship in the example above, if you wanted to configure BAZ for 'Foo::Bar', you would need to do this.

  package Foo;
  use Config::Constants 'BAZ';

  package Foo::Bar;
  use base 'Foo';
  use Config::Constants 'BAZ';
  
You will still be able to access Foo's version of C<BAZ> via either a SUPER:: call or the fully qualified Foo::BAZ.

=back

=head2 Interaction with Apache & mod_perl

When developing with mod_perl is it useful to use a module like L<Apache::Reload> to help reload modules which have been changed. Because of the way B<Config::Constants> handles loading of constants, this should not require the config to be reloaded. However, if the config file itself is changed, it will require you to restart Apache in order for those changes to take effect. 

Future plans include making a mod_perl handler which can be used to automatically reload the config file if it is modified.

=head1 METHODS

=over 4

=item B<import>

=back

=head1 TO DO

=over 4

=item A means to automatically reload the config while using Apache/mod_perl

=item More tests

=item re-write the docs, they are horrid

=back

=head1 BUGS

None that I am aware of. Of course, if you find a bug, let me know, and I will be sure to fix it. 

=head1 CODE COVERAGE

I use B<Devel::Cover> to test the code coverage of my tests, below is the B<Devel::Cover> report on this module test suite.

 ----------------------------------- ------ ------ ------ ------ ------ ------ ------
 File                                  stmt branch   cond    sub    pod   time  total
 ----------------------------------- ------ ------ ------ ------ ------ ------ ------
 Config/Constants.pm                   95.2   90.9    n/a   75.0    n/a   31.6   91.8
 Config/Constants/Perl.pm             100.0   50.0   33.3  100.0  100.0   23.8   82.0
 Config/Constants/XML.pm              100.0   50.0   33.3  100.0    n/a   23.9   90.6
 Config/Constants/XML/SAX/Handler.pm   96.7   82.4    n/a  100.0  100.0   20.7   92.7
 ----------------------------------- ------ ------ ------ ------ ------ ------ ------
 Total                                 97.0   79.4   33.3   91.2  100.0  100.0   90.3
 ----------------------------------- ------ ------ ------ ------ ------ ------ ------

=head1 SEE ALSO

=over 4

=item L<generics> - this module is largely based on ideas from the L<generics> pragma I wrote. 

=back

=head1 AUTHOR

stevan little, E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
