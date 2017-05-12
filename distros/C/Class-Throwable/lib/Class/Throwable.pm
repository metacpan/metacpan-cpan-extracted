
package Class::Throwable;

use strict;
use warnings;

our $VERSION = '0.13';

use Scalar::Util qw(blessed);

our $DEFAULT_VERBOSITY = 1;

my %VERBOSITY;

# allow the creation of exceptions 
# without having to actually create 
# a package for them
sub import {
	my $class = shift;
    return unless @_;	
	if ($_[0] eq 'VERBOSE') {
		(defined $_[1]) || die "You must specify a level of verbosity with Class::Throwable\n";
		# make sure its not a refernce
		$class = ref($class) || $class;
		# and then store it
		$VERBOSITY{$class} = $_[1];
	}
    elsif ($_[0] eq 'retrofit') {
		(defined $_[1]) || die "You must specify a module for Class::Throwable to retrofit\n";        
        my $package = $_[1];
        my $retrofitter = sub { Class::Throwable->throw(@_) };
        $retrofitter = $_[2] if defined $_[2] && ref($_[2]) eq 'CODE';
        eval {
            no strict 'refs';
            *{"${package}::die"} = $retrofitter;
        };
        die "Could not retrofit '$package' with Class::Throwable : $@\n" if $@;
    }
	else {
		($class eq 'Class::Throwable') 
			|| die "Inline Exceptions can only be created with Class::Throwable\n";
		my @exceptions = @_;
		foreach my $exception (@exceptions) {
			next unless $exception;
			eval "package ${exception}; \@${exception}::ISA = qw(Class::Throwable);";  
			die "An error occured while constructing Class::Throwable exception ($exception) : $@\n" if $@;      
		}
	}
}

# overload the stringify operation
use overload q|""| => "toString", fallback => 1;

# a class method to set the verbosity 
# of inline exceptions
sub setVerbosity {
	my ($class, $verbosity) = @_;
	(!ref($class)) || die "setVerbosity is a class method only, it cannot be used on an instance\n";
	(defined($verbosity)) || die "You must specify a level of verbosity with Class::Throwable\n";
	$VERBOSITY{$class} = $verbosity;
}

# create an exception without 
# any stack trace information
sub new {
	my ($class, $message, $sub_exception) = @_;
	my $exception = {};
	bless($exception, ref($class) || $class);
	$exception->_init($message, $sub_exception);
	return $exception;		
}

# throw an exception with this
sub throw { 
	my ($class, $message, $sub_exception) = @_;
	# if i am being re-thrown, then just die with the class
	if (blessed($class) && $class->isa("Class::Throwable")) {
		# first make sure we have a stack trace, if we 
		# don't then we were likely created with 'new'
		# and not 'throw', and so we need to gather the
		# stack information from here 
		$class->_initStackTrace() unless my @s = $class->getStackTrace();
		die $class;
	}
	# otherwise i am being thrown for the first time so 
	# create a new 'me' and then die after i am blessed
	my $exception = {};
	bless($exception, $class);
	$exception->_init($message, $sub_exception);
	# init our stack trace
	$exception->_initStackTrace();	
	die $exception;
}

## initializers

sub _init {
	my ($self, $message, $sub_exception) = @_;
    # the sub-exception is another exception
    # which has already been caught, and is
    # the cause of this exception being thrown
    # so we dont want to loose that information
    # so we store it here
    # NOTE: 
    # we do not enforce the type of exception here
    # becuase it is possible this was thrown by
    # perl itself and therefore could be a string
    $self->{sub_exception} = $sub_exception; 
	$self->{message} = $message || "An ". ref($self) . " Exception has been thrown";
	$self->{stack_trace} = [];
}

sub _initStackTrace {
	my ($self) = @_;
	my @stack_trace;
    # these are the 10 values returned from caller():
    # 	$package, $filename, $line, $subroutine, $hasargs,
    # 	$wantarray, $evaltext, $is_require, $hints, $bitmask    
    # we do not bother to capture the last two as they are
    # subject to change and not meant for internal use
    {
        package DB;
        my $i = 1;            
        my @c;
        while (@c = caller($i++)) {
            # dont bother to get our caller
            next if $c[3] =~ /Class\:\:Throwable\:\:throw/;
            push @stack_trace, [ @c[0 .. 7] ];		
        }
    }
	$self->{stack_trace} = \@stack_trace;
}

# accessors

sub hasSubException {
    my ($self) = @_;
    return defined $self->{sub_exception} ? 1 : 0;
}

sub getSubException {
    my ($self) = @_;
    return $self->{sub_exception};
}

sub getMessage {
	my ($self) = @_;
	return $self->{"message"};
}

sub getStackTrace {
    my ($self) = @_;
    return wantarray ?
                @{$self->{stack_trace}}
                :
                $self->{stack_trace};
}

sub stackTraceToString {
	my ($self, $depth) = @_;
	my @output;
    $depth ||= 1;
    my $indent = "  " x $depth;
	foreach my $frame (@{$self->{stack_trace}}) {
		my ($package, $filename, $line, $subroutine) = @{$frame};	
        $subroutine = "${package}::${subroutine}" if ($subroutine eq '(eval)');
		push @output, "$indent|--[ $subroutine called in $filename line $line ]"                             
	}
	return (join "\n" => @output);
}

sub toString {
	my ($self, $verbosity, $depth) = @_;
	unless (defined $verbosity) {
		if (exists $VERBOSITY{ref($self)}) {
			$verbosity = $VERBOSITY{ref($self)};
		}
		else {
			$verbosity = $DEFAULT_VERBOSITY;
		}
	}	
    # get out of here quick if 
    # exception handling is off
    return "" if $verbosity <= 0;
    # otherwise construct our output
    my $output = ref($self) . " : " . $self->{"message"};
    # if we VERBOSE is set to 1, then 
    # we just return the message
    return $output if $verbosity <= 1;
    $depth ||= 1;
    if ($depth > 1) {
        $output = ("  " x ($depth - 1)) . "+ $output";
        $depth++;
    }
    # however, if VERBOSE is 2 or above
    # then we include the stack trace
	$output .= "\n" . (join "\n" => $self->stackTraceToString($depth)) . "\n";
    # now we gather any sub-exceptions too 
    if ($self->hasSubException()) {
        my $e = $self->getSubException();
        # make sure the sub-exception is one
        # of our objects, and ....
        if (blessed($e) && $e->isa("Class::Throwable")) {
            # deal with it appropriately
            $output .= $e->toString($verbosity, $depth + 1);
        }
        # otherwise ...
        else {
            # just stringify it        
            $output .= ("  " x ($depth)) . "+ $e";        
        }
    }
    return $output;
}

sub stringValue {
    my ($self) = @_;
    return overload::StrVal($self);
}

1;

__END__

=head1 NAME

Class::Throwable - A minimal lightweight exception class

=head1 SYNOPSIS

  use Class::Throwable;     
  
  # simple usage
  eval {
      # code code code,
      if ($something_goes_wrong) {
          throw Class::Throwable "Something has gone wrong";
      }
  };
  if ($@) {
      # we just print out the exception message here
      print "There has been an exception: " $@->getMessage();  
      # but if we are debugging we get the whole
      # stack trace as well
      if (DEBUG) {
          print $@->getStackTraceAsString();
      }
  }
  
  # it can be used to catch perl exceptions
  # and wrap them in a Class::Throwable exception
  eval {
      # generate a perl exception
      eval "2 / 0";
      # then throw our own with the 
      # perl exception as a sub-exception
      throw Class::Throwable "Throwing an exception" => $@ if $@;
  };    
  if ($@) {
      # setting the verbosity to 
      # 2 gives a full stack trace
      # including any sub-exceptions
      # (see below for examples of 
      # this output format)
      $@->toString(2);  
  }
  
  # you can also declare inline exceptions
  use Class::Throwable qw(My::App::Exception::IllegalOperation);
  
  # set their global verbosity as well
  # with the class method
  My::App::Exception::IllegalOperation->setVerbosity(2);
  
  eval {
      throw My::App::Exception::IllegalOperation "Bad, real bad";
  };
  
  # can also declare subclasses of Class::Throwable 
  # in other files, then when you import them, you
  # can set their verbosity
  use My::Sub::Class::In::A::Separate::File (VERBOSE => 1);
  
  throw My::Sub::Class::In::A::Separate::File "This exception will use a verbosity of 1";
  
  # you can even create exceptions, then throw them later
  my $e = Class::Throwable->new("Things have gone bad, but I need to do something first", $@);
  
  # do something else ...
  
  # then throw the exception we created earlier
  throw $e

=head1 DESCRIPTION

This module implements a minimal lightweight exception object. It is meant to be a compromise between more basic solutions like L<Carp> which can only print information and cannot handle exception objects, and more more complex solutions like L<Exception::Class> which can be used to define complex inline exceptions and has a number of module dependencies. 

=head2 Inline Exceptions

You can easily create new exception classes inline by passing them with the C<use> statment like this:

  use Class::Throwable ('My::InlineException', 'My::Other::InlineException');

This is a quick and easy way to define arbitrary exception classes without the need to manually create separate files or packages for them. However, it should be noted that subclasses of Class::Throwable cannot be used to define inline exceptions. If you attempt to do this, an exception will be thrown.

=head2 Exception Verbosity

Class::Throwable offers a number of different types of diagnostic outputs to suit your needs. Most of this is controlled through the verbosity levels. If the verbosity level is set to 0 or below, an empty string is returned. If the value is set to 1, then the exception's message is returned. If the value is set to 2 or above, a full stack trace along with full stack traces for all sub-exceptions are returned in the format shown in C<stackTraceToString>. The default verbosity setting is 1.

There are a number of ways in which you can set the verbosity of the exceptions produced by Class::Throwable. The simplest way is as the argument to the C<toString> method. Using this method will override any other settings you may have, and insure that the output of this method is as you ask it to be.

  $@->toString(2);

However, to use this style properly, this requires that you test the value of C<$@> to be sure it is a Class::Throwable object. In some cases, this may not be an issue, while in others, it makes more sense to set verbosity on a wider scale. 

For instance, if you define inline exceptions, then the simplest way to set a verbostity level for a particular inline exception is through the class method C<setVerbosity>.

  use Class::Throwable qw(My::InlineException);
  
  My::InlineException->setVerbosity(2);

This means that unless the C<toString> verbosity argument overrides it, all I<My::InlineException> exceptions will use a verbosity setting of 2. This method means that you can easily C<print> the value of C<$@> and then any I<My::InlineException> exceptions will be automatically stringified with a verbosity level of 2. This can simplify exception catching by reducing the need to inspect the value of C<$@>.

If you defined your exceptions as subclasses of Class::Throwable and stored them in separate files, then another means of setting the verbosity level is to assign it in the C<use> statement. 

  use My::SeparateFileSubClass::Exception (VERBOSE => 2);

This has the same effect as the C<setVerbosity> class method, in fact, there is nothing to stop you from using the C<setVerbosity> class method in this case if you like. This method can also be used on Class::Throwable itself, however, this does not set the verbosity level for all subclasses, only for Class::Throwable exceptions.

There is one last method which can be used. This method has the widest scope of all the methods. The variable C<$Class::Throwable::DEFAULT_VERBOSITY> can be set. Setting this value will take effect if, 1) there is no value passed to the C<toString> method and 2) no verbosity level has been set for the particular class, either through C<setVerbosity> or the C<use> statement. 

=head2 Module exception retro-fitting

It is possible to retrofit a module to use Class::Throwable exceptions if you want to. Basically this will allow modules which C<die> with either strings or some other value, to throw Class::Throwable based exceptions. This feature is relatively new and should be considered to be experimental, any feedback on it is greatly appreciated. 

B<NOTE:> It is important to do module retrofitting at the earliest possible moment (preferrably before the module you are retrofitting is compiled), as it will override C<die> within a specified package. 

Other than all this, retrofitting is quite simple. Here is a basic example:

  use Class::Throwable retrofit => 'My::Class';
  
Now anytime C<die> is called within I<My::Class> the calls will get converted to a Class::Throwable instance. You can also control how exceptions are converted like so:

  use Class::Throwable retrofit => 'My::Class' => sub { My::Exception->throw(@_) };

Now anytime C<die> is called within I<My::Class> the calls will get converted to a My::Exception instance instead. Or a slightly more complex examples like this:

  use Class::Throwable retrofit => (
                'My::Class' => sub { 
                    My::IllegalOperation->throw(@_) if $_[0] =~ /^Illegal Operation/;
                    My::Exception->throw(@_);
                });
                                
Now anytime C<die> is called within I<My::Class> the calls will get converted to a My::Exception instance unless the exception matches the reg-exp, in which case an My::IllegalOperation exception is thrown.

There are a couple of points to be made regarding this functionality. First, it will add another stack frame to your exceptions (the retrofit routine basically). This is probably avoidable, but as this is still experimental I wanted to keep things somewhat simple. And second, if you supply a custom C<die> handler, you should be sure that it will C<die> somewhere within that routine. If you do not, you may have many un-intended consequences.

=head1 METHODS

=head2 Constructor

=over 4

=item B<throw ($message, $sub_exception)>

The most common way to construct an exception object is to C<throw> it. This method will construct the exception object, collect all the information from the call stack and then C<die>. 

The optional C<$message> argument can be used to pass custom information along with the exception object. Commonly this will be a string, but this module makes no attempt to enforce that it be anything other than a scalar, so more complex references or objects can be used. If no C<$message> is passed in, a default one will be constructed for you.

The second optional argument, C<$sub_exception>, can be used to retain information about an exception which has been caught but might not be appropriate to be re-thrown and is better wrapped within a new exception object. While this argument will commonly be another Class::Throwable object, that fact is not enforced so you can pass in normal string based perl exceptions as well.

If this method is called as an instance method on an exception object pre-built with C<new>, only then is the stack trace information populated and the exception is then passed to C<die>.

=item B<new ($message, $sub_exception)>

This is an alternate means of creating an exception object, it is much like C<throw>, except that it does not collect stack trace information or C<die>. It stores the C<$message> and C<$sub_exception> values, and then returns the exception instance, to be possibly thrown later on.

=back

=head2 Class Methods

=over 4

=item B<setVerbosity ($verbosity)> 

This is a class method, if it is called with an instance, and exception will be thrown. This class method can be used to set the verbosity level for a particular class. See the section L<Exception Verbosity> above for more details.

=back

=head2 Accessors

=over 4

=item B<getMessage>

This allows access to the message in the exception, to allow more granular exception reporting.

=item B<getStackTrace>

This returns the raw stack trace information as an array of arrays. There are 10 values returned by C<caller> (C<$package>, C<$filename>, C<$line>, C<$subroutine>, C<$hasargs>, C<$wantarray>, C<$evaltext>, C<$is_require>, C<$hints>, C<$bitmask>) we do not bother to capture the last two as they are subject to change and meant for internal use, all others are retained in the order returned by C<caller>.

=item B<hasSubException>

The returns true (C<1>) if this exception has a sub-exception, and false (C<0>) otherwise.

=item B<getSubException>

This allows access to the stored sub-exception.

=back

=head2 Output Methods

This object overloads the stringification operator, and will call the C<toString> method to perform that stringification. 

=over 4

=item B<toString ($verbosity)>

This will print out the exception object's information at a variable level of verbosity which is specified be the optional argument C<$verbosity>. See the section L<Exception Verbosity> above for more details.

=item B<stringValue>

This will return the normal perl stringified value of the object without going through the C<toString> method.

=item B<stackTraceToString>

This method is used to print the stack trace information, the stack trace is presented in the following format:
  
    |--[ main::foo called in my_script.pl line 12 ]
    |--[ main::bar called in my_script.pl line 14 ]
    |--[ main::baz called in my_script.pl line 16 ]

=back

=head1 EXAMPLE OUTPUT

Given the following code:

  {
    package Foo;
    sub foo { eval { Bar::bar() }; throw Class::Throwable "Foo!!", $@ }
    
    package Bar;
    sub bar { eval { Baz::baz() }; throw Class::Throwable "Bar!!", $@ }
    
    package Baz;
    sub baz { throw Class::Throwable "Baz!!" }
  }

  eval { Foo::foo() };
  print $@->toString($verbosity) if $@;  
  
If you were to print the exception with verbosity of 0, you would get no output at all. This mode can be used to suppress exception output if needed. If you were to print the exception with verbosity of 1, you would get this output.

  Class::Throwable : Foo!!  
    
If you were to print the exception with verbosity of 2, you would get this output.
    
  Class::Throwable : Foo!!
    |--[ Foo::foo called in test.pl line 26 ]
    |--[ main::(eval) called in test.pl line 26 ]
    + Class::Throwable : Bar!!
        |--[ Bar::bar called in test.pl line 19 ]
        |--[ Foo::(eval) called in test.pl line 19 ]
        |--[ Foo::foo called in test.pl line 26 ]
        |--[ main::(eval) called in test.pl line 26 ]
        + Class::Throwable : Baz!!
            |--[ Baz::baz called in test.pl line 21 ]
            |--[ Bar::(eval) called in test.pl line 21 ]
            |--[ Bar::bar called in test.pl line 19 ]
            |--[ Foo::(eval) called in test.pl line 19 ]
            |--[ Foo::foo called in test.pl line 26 ]
            |--[ main::(eval) called in test.pl line 26 ]

=head1 BUGS

None that I am aware of. Of course, if you find a bug, let me know, and I will be sure to fix it. This is based on code which has been heavily used in production sites for over 2 years now without incident.

=head1 CODE COVERAGE

I use B<Devel::Cover> to test the code coverage of my tests, below is the B<Devel::Cover> report on this module test suite.

 ---------------------------- ------ ------ ------ ------ ------ ------ ------
 File                           stmt branch   cond    sub    pod   time  total
 ---------------------------- ------ ------ ------ ------ ------ ------ ------
 Class/Throwable.pm            100.0   98.0   63.6  100.0  100.0  100.0   95.7
 ---------------------------- ------ ------ ------ ------ ------ ------ ------
 Total                         100.0   98.0   63.6  100.0  100.0  100.0   95.7
 ---------------------------- ------ ------ ------ ------ ------ ------ ------

=head1 SEE ALSO

There are a number of ways to do exceptions with perl, I was not really satisifed with the way anyone else did them, so I created this module. However, if you find this module unsatisfactory, you may want to check these out.

=over 4

=item L<Throwable>

Throwable is a role for classes that are meant to be thrown as exceptions to standard program flow.

=item L<Exception::Class>

This in one of the more common exception classes out there. It does an excellent job with it's default behavior, and allows a number of complex options which can likely serve any needs you might have. My reasoning for not using this module is that I felt these extra options made things more complex than they needed to be, it also introduced a number of dependencies. I am not saying this module is bloated at all, but that for me it was far more than I have found I needed. If you have heavy duty exception needs, this is your module.

=item L<Error>

This is the classic perl exception module, complete with a try/catch mechanism. This module has a lot of bad karma associated with it because of the obscure nested closure memory leak that try/catch has. I never really liked the way its exception object Error::Simple did things either.

=item L<Exception>

This module I have never really experimented with, so take my opinion with a large grain of salt. My problem with this module was always that it seemed to want to do too much. It attempts to make perl into a language with real exceptions, but messing with C<%SIG> handlers and other such things. This can be dangerous territory sometimes, and for me, far more than my needs. 

=back

=head1 AUTHOR

stevan little, E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
