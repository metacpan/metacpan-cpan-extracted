=pod

=head1 NAME

Class::Hook - Add hooks on methods from other classes

=head1 SYNOPSIS

  use Class::Hook;

  Class::Hook->before(\&sub1);
  Class::Hook->after(\&sub2);
  Class::Hook->activate();
  # or
  Class::Hook->new(\&sub1, \&sub2);

  # and then
  Anotherclass->aMethod($someParam); # Hooked class

=head1 DESCRIPTION

Class::Hook enables you to trace methods calls from your code to other classes.

Instead of putting 'use Foo;' in your code,
simply type 'use Class::Hook;'.
The class Foo is unknown in your code.
It will be magically caught by Class::Hook which will call Foo itself.
You can see Class::Hook as a kind of relay.

You can setup a subroutine to be called before any call to
C<<Foo-E<gt>amethod>> and a subroutine to be called after the call. Your subs
will receive all the information that C<<Foo-E<gt>amethod>> will receive,
so you can trace everything between your code and Foo.

=cut

package Class::Hook;
$Class::Hook::VERSION = '0.06';
use 5.006;
use strict;
use warnings;
use Time::HiRes;
use warnings::register;
use Carp;


local *autoload = *UNIVERSAL::AUTOLOAD;
our $before = \&_default_before;
our $after  = \&_default_after;
our $param_before = undef;
our $param_after  = undef;

=pod

=head1 METHODS

=head2 new($subref_before, $subref_after, $param)

Install subroutines to be called whenever a method from an unknown
class is called. It is equivalent to the following code:

  Class::Hook->before($subref_before, $param);
  Class::Hook->after($subref_after, $param);
  Class::Hook->activate();

=cut
sub new {
	my ($class, $before, $after, $param) = @_;
	$param_before = undef;
	$param_after  = undef;
	$class->before($before, $param);
	$class->after($after, $param);
	$class->activate();
}


=pod

=head2 before($subref, $param)

Install subroutine to be called whenever a call to an unknown class is
made.  $param will be sent to your $subref if specified &$subref will
receive the following parameters:

  ( $param, { class   => $class_or_object,
              method  => $method_called,
              param   => [@params_sent],
              counter => $no_calls_for_this_method } )
or the following parameters if $param undefined

  ({ class   => $class_or_object,
     method  => $method_called,
     param   => [@params_sent],
     counter => $no_calls_for_this_method } )

=cut

sub before {
        our ($before, $param_before) = @_[1,2];
        ref($before) eq 'CODE' or croak "Not a sub ref";
}


=pod

=head2 after($subref, $param)

Install subroutine to be called whenever a call to an unknown class
returns.  $param will be sent to your $subref if specified. &$subref
will receive the following parameters

  ( $param, { class    => $class_or_object,
              method   => $method_called,
              param    => [@params_sent],
              counter  => $no_calls_for_this_method,
              'return' => [@return_values],
              duration => $duration in seconds } )
or the following parameters if $param undefined

  ( { class    => $class_or_object,
      method   => $method_called,
      param    => [@params_sent],
      counter  => $no_calls_for_this_method,
      'return' => [@return_values],
      duration => $duration in seconds } )

=cut
sub after {
        our ($after, $param_after) = @_[1,2];
        ref($after) eq 'CODE' or croak "Not a sub ref";
}


=pod

=head2 activate()

Activates the hooks on methods calls to unknown classes. Your subs
C<before> and C<after> will be called at each call to an unknown
package.

=cut
sub activate {
        eval q{
                # hide the package line from PAUSE
                package
                    UNIVERSAL;
                use Carp;
                use Data::Dumper;
                our $AUTOLOAD;
                my %fields_storage = ();
                my %methods        = ();
                my %counter;

                sub UNIVERSAL::AUTOLOAD {
                        return undef if (caller(0) eq 'UNIVERSAL'); # To prevent recursive calls
                        my ($class, $method) = ($AUTOLOAD =~ /(.*)::([^:]+)/);
                        return undef if ($method eq 'DESTROY' or $method eq 'unimport');
                        {
                                no strict;
                                unless ($fields_storage{$class}) { # First time
                                        eval "require $class;" or return Class::Hook->_error("$class: $! $@");
                                        delete $INC{"$class.pm"};
                                        $class->import();
                                        %{$fields_storage{$class}} = %{"${class}::"}; # Stores namespace
                                }
                                %{"${class}::"} = %{$fields_storage{$class}};
                        }
                        my @param = @_;
						my $obj = $_[0] if (ref($_[0]) eq $class);
                        shift @param if ($_[0] eq $class or ref($_[0]) eq $class); # method call
                        $counter{$AUTOLOAD} ||= 0;
                        my @before_params = { class    => $class,
                                              method   => $method,
                                              counter  => $counter{$AUTOLOAD}++,
                                              param    => \@param,
                                            };
                        unshift @before_params, $Class::Hook::param_before if (defined $Class::Hook::param_before);
                        &$Class::Hook::before( @before_params );
                        my $t0 = [Time::HiRes::gettimeofday()];
                        no strict;
                        my @rtn;
                        if ($obj) {
                        	@rtn = $obj->$method(@param) || ();
                        }
                        else {
                        	@rtn = $class->$method(@param) || ();
                        }
                        my @after_params = {  class    => $class,
                                              method   => $method,
                                              counter  => $counter{$AUTOLOAD},
                                              param    => \@param,
                                              'return' => wantarray ? \@rtn : $rtn[0],
                                              duration => Time::HiRes::tv_interval($t0, [Time::HiRes::gettimeofday()]) };
                        unshift @after_params, $Class::Hook::param_after if (defined $Class::Hook::param_after);
                        &$Class::Hook::after( @after_params );
                        %{"${class}::"} = (); # Clean namespace to force calls to %UNIVERSAL::
                        return wantarray ? @rtn : $rtn[0];
                }
                1;
        } or die "Could not activate $@ $!";
}




=pod

=head2 deactivate()

Stops hooks.

=cut
sub deactivate {
        *UNIVERSAL::AUTOLOAD = *autoload;
}

sub _error {
    $warnings::enabled and carp $_[1];
    return undef;
}

sub _default_before {
    $warnings::enabled and carp "before not defined";
}

sub _default_after {
    $warnings::enabled and carp "after not defined";
}

1;

=pod

=head1 EXAMPLES

  You want to study calls to a class 'Foo'
  ========================================
  main.pl
  =======
  # Don't write 'use Foo;'!
  use Data::Dumper;
  use Class::Hook;
  Class::Hook->new(\&mybefore, \&myafter);

  Foo->new('bla', 'blu');
  Foo->bar( { key1 => 'value1',
              key2 => 'value2'} );
  Foo->xxxx(); # Non existing method

  sub mybefore {
      print "Before called: ".Dumper(\@_);
  }

  sub myafter {
      print "After called: ".Dumper(\@_);
  }


  Foo.pm
  ======
  package Foo;
  sub new {
      my ($class, @param) = @_;
      warn "Foo->new called";
      return bless { 'something' => 'whatever',
                     'init'      => \@param }
                     => $class;
  }

  sub bar {
      warn "Foo->bar called";
      return "Hello from bar";
  }

  1;

=head1 CAVEATS

It works only with method calls, not with subroutine calls.
Foo->method will work Foo::method will NOT work.
UNIVERSAL::AUTOLOAD is overriden after Class::Hook->activate() has
been called. Expect some strange behaviors if the module you use plays
with it.

=head1 BUGS

Don't rely on it for production purpose.
Has been tested on perl
5.6.0 only and probably will need some update with later perl versions.

=head1 AUTHOR

"Pierre Denis" <pierre@itrelease.net>

=head1 COPYRIGHT

Copyright (C) 2005, IT Release Ltd. All rights reserved.

This is free software. This software
may be modified and/or distributed under the same terms as Perl
itself.

=cut

