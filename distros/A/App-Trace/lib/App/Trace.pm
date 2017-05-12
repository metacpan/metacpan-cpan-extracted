
#############################################################################
## $Id: Trace.pm 6702 2006-07-25 01:43:27Z spadkins $
#############################################################################

package App::Trace;

use vars qw($VERSION);
use strict;

$VERSION = "0.50";

=head1 NAME

App::Trace - Embedded debug statements, including call/return tracing

=head1 SYNOPSIS

  In a program (such as the following one named "foo"), you can do the following...

  #!/usr/bin/perl

  use App::Option;  # App::Trace was written to be used with App::Options
  use App::Trace;   # enable tracing support

  use Foo;
  &run();
  sub run {
      &App::sub_entry if ($App::trace);        # trace subroutine entry
      my $foo = Foo->new();
      $foo->run();
      &App::sub_exit() if ($App::trace);       # trace subroutine exit
  }

  in a module (i.e. Foo.pm), you can do the following...

  package Foo;
  # new(): a generic object constructor
  sub new {
      &App::sub_entry if ($App::trace);        # trace method entry
      my ($this, @args) = @_;
      my $class = ref($this) || $this;
      my $self = { @args };
      bless $self, $class;
      &App::sub_exit($self) if ($App::trace);  # trace method exit
      return($self);
  }
  sub run {
      &App::sub_entry if ($App::trace);        # trace method entry
      print "Expression: (1 + 2) * (7 - (2*2))\n";
      my $value = $self->multiply(
          $self->add(1, 2),
          $self->subtract(7, $self->multiply(2, 2))
      );
      print "Value:      $value\n";
      &App::sub_exit() if ($App::trace);       # trace method exit
  }
  sub add {
      &App::sub_entry if ($App::trace);        # trace method entry
      my ($self, $operand1, $operand2) = @_;
      my $value = $operand1 + $operand2;
      &App::sub_exit($value) if ($App::trace); # trace method exit
      return($value);
  }
  sub subtract {
      &App::sub_entry if ($App::trace);        # trace method entry
      my ($self, $operand1, $operand2) = @_;
      my $value = $operand1 - $operand2;
      &App::sub_exit($value) if ($App::trace); # trace method exit
      return($value);
  }
  sub multiply {
      &App::sub_entry if ($App::trace);        # trace method entry
      my ($self, $operand1, $operand2) = @_;
      my $value = $operand1 * $operand2;
      &App::sub_exit($value) if ($App::trace); # trace method exit
      return($value);
  }

  Then when you invoke the program normally, you get no debug output.
  You only get the expected program output.

    foo

  However, when you invoke the program with something like the following...

    foo --trace

  you get trace output like the following.

  ...

  Try the following options...

    foo --trace --trace_width=0    # unlimited width (long lines wrap on screen)
    foo --trace --trace_width=78   # set max width of output
    foo --trace --trace_width=78 --trace_justify    # right-justify package
    foo --trace=main               # only trace subs in "main" package
    foo --trace=Foo                # only trace subs in "Foo" package
    foo --trace=Foo.multiply       # only trace the multiply() method in the Foo package
    foo --trace=main,Foo.run       # trace a combo of full packages and specific methods

=head1 DESCRIPTION

App::Trace provides debug/tracing support for perl programs and modules.

The basic concept is that you put a special call at the beginning and
end of each subroutine/method, and when tracing is enabled, you can see
the flow of your program.

This module reflects my dislike of the perl debugger.
I also dislike putting in print statements to debug, then commenting
them out when I'm done.  I would rather put debug statements in my
code and leave them there.  That way, when programs work their way
into production, they can still be debugged by using appropriate
command line options.

Perl modules which are written to be used with App::Trace can be debugged
easily without entering the perl debugger. 
The output of tracing is a "program trace" which shows the entry and
exit of every subroutine/method (and the arguments).
This trace is printed in a format which allows you to follow the
flow of the program.

Someday I might figure out how to do this at a language level so it will
work on any module, not just ones which have been specially instrumented
with &App::sub_entry() and &App::sub_exit() calls.  In fact, I started
work on this with the Aspect.pm module, but that was specific to perl
version 5.6.x and didn't work with 5.8.x.  That's when I decided I would
write App::Trace which would work on any Perl (even back to 5.5.3, which
I consider to be the first Perl 5 to support for deep backward
compatibility).

The App-Trace distribution began life as a collection of routines pulled
out of the App-Context distribution.  I created App-Trace because these
routines were very useful independent of the rest of the framework
provided by App-Context.

App::Trace is dependent on App::Options.  It is possible to use App::Trace
without App::Options, but they share a common convention with regard to
certain global variables in the "App" package/namespace.

It is expected that when App::Trace is mature, the routines included will
be removed from App.pm module in the App-Context distribution.  The
App-Context distribution will then be dependent on App::Trace for these
features.

=cut

#############################################################################
# ATTRIBUTES/CONSTANTS/CLASS VARIABLES/GLOBAL VARIABLES
#############################################################################

=head1 Attributes, Constants, Global Variables, Class Variables

=head2 Global Variables

 * Global Variable: %App::scope              scope for debug or tracing output
 * Global Variable: $App::scope_exclusive    flag saying that the scope is exclusive (a list of things *not* to debug/trace)
 * Global Variable: %App::trace              trace level
 * Global Variable: $App::DEBUG              debug level
 * Global Variable: $App::DEBUG_FILE         file for debug output

=cut

if (!defined $App::DEBUG) {
    %App::scope = ();
    $App::scope_exclusive = 0;
    $App::trace = 0;
    $App::DEBUG = 0;
    $App::DEBUG_FILE = "";
}

#################################################################
# DEBUGGING
#################################################################

# Supports the following command-line usage:
#    --debug=1                                     (global debug)
#    --debug=9                                     (detail debug)
#    --scope=App::Context                      (debug class only)
#    --scope=!App::Context             (debug all but this class)
#    --scope=App::Context,App::Session         (multiple classes)
#    --scope=App::Repository::DBI.select_rows    (indiv. methods)
#    --trace=App::Context                      (trace class only)
#    --trace=!App::Context             (trace all but this class)
#    --trace=App::Context,App::Session         (multiple classes)
#    --trace=App::Repository::DBI.select_rows    (indiv. methods)
{
    my $scope = $App::options{scope} || "";

    my $trace = $App::options{trace};
    if ($trace) {
        if ($trace =~ s/^([0-9]+),?//) {
            $App::trace = $1;
        }
        else {
            $App::trace = 9;
        }
    }
    if ($trace) {
        $scope .= "," if ($scope);
        $scope .= $trace;
    }
    $App::trace_width = (defined $App::options{trace_width}) ? $App::options{trace_width} : 1024;
    $App::trace_justify = (defined $App::options{trace_justify}) ? $App::options{trace_justify} : 0;

    my $debug = $App::options{debug};
    if ($debug) {
        if ($debug =~ s/^([0-9]+),?//) {
            $App::DEBUG = $1;
        }
        else {
            $App::DEBUG = 9;
        }
    }
    if ($debug) {
        $scope .= "," if ($scope);
        $scope .= $debug;
    }

    if ($scope =~ s/^!//) {
        $App::scope_exclusive = 1;
    }

    if (defined $scope && $scope ne "") {
        foreach my $pkg (split(/,/,$scope)) {
            $App::scope{$pkg} = 1;
        }
    }

    my $debug_file = $App::options{debug_file};
    if ($debug_file) {
        if ($debug_file !~ /^[>|]/) {
            $debug_file = ">> $debug_file";
        }
        open(App::DEBUG_FILE, $debug_file);
    }
}

# NOTE: All the functions we define are in the App package!!! (not App::Trace)

package App;

#############################################################################
# Aspect-oriented programming support
#############################################################################
# NOTE: This can be done much more elegantly at the Perl language level,
# but it requires version-specific code.  I created these subroutines so that
# any method that is instrumented with them will enable aspect-oriented
# programming in Perl versions from 5.5.3 to the present.
#############################################################################

my $calldepth = 0;

#############################################################################
# sub_entry()
#############################################################################

=head2 sub_entry()

    * Signature: &App::sub_entry;
    * Signature: &App::sub_entry(@args);
    * Param:     @args        any
    * Return:    void
    * Throws:    none
    * Since:     0.01

This is called at the beginning of a subroutine or method (even before $self
may be shifted off).

=cut

sub sub_entry {
    if ($App::trace) {
        my ($stacklevel, $calling_package, $file, $line, $subroutine, $hasargs, $wantarray, $text);
        $stacklevel = 1;
        ($calling_package, $file, $line, $subroutine, $hasargs, $wantarray) = caller($stacklevel);
        while (defined $subroutine && $subroutine eq "(eval)") {
            $stacklevel++;
            ($calling_package, $file, $line, $subroutine, $hasargs, $wantarray) = caller($stacklevel);
        }
        my ($name, $obj, $class, $package, $sub, $method, $firstarg, $trailer);

        # split subroutine into its "package" and the "sub" within the package
        if ($subroutine =~ /^(.*)::([^:]+)$/) {
            $package = $1;
            $sub = $2;
        }

        # check if it might be a method call rather than a normal subroutine call
        if ($#_ >= 0) {
            $class = ref($_[0]);
            if ($class) {
                $obj = $_[0];
                $method = $sub if ($class ne "ARRAY" && $class ne "HASH");
            }
            else {
                $class = $_[0];
                if ($class =~ /^[A-Z][A-Za-z0-9_:]*$/ && $class->isa($package)) {
                    $method = $sub;  # the sub is a method call on the class
                }
                else {
                    $class = "";     # it wasn't really a class/method
                }
            }
        }

        if (%App::scope) {
            if ($App::scope_exclusive) {
                return if ($App::scope{$package} || $App::scope{"$package.$sub"});
            }
            else {
                return if (!$App::scope{$package} && !$App::scope{"$package.$sub"});
            }
        }

        if ($method) {
            if (ref($obj)) {  # dynamic method, called on an object
                if ($obj->isa("App::Service")) {
                    $text = ("| " x $calldepth) . "+-" . $obj->{name} . "->${method}(";
                }
                else {
                    $text = ("| " x $calldepth) . "+-" . $obj . "->${method}(";
                }
                $trailer = " [$package]";
            }
            else {   # static method, called on a class
                $text = ("| " x $calldepth) . "+-" . "${class}->${method}(";
                $trailer = ($class eq $package) ? "" : " [$package]";
            }
            $firstarg = 1;
        }
        else {
            $text = ("| " x $calldepth) . "+-" . $subroutine . "(";
            $firstarg = 0;
            $trailer = "";
        }
        my ($narg);
        for ($narg = $firstarg; $narg <= $#_; $narg++) {
            $text .= "," if ($narg > $firstarg);
            if (!defined $_[$narg]) {
                $text .= "undef";
            }
            elsif (ref($_[$narg]) eq "") {
                $text .= $_[$narg];
            }
            elsif (ref($_[$narg]) eq "ARRAY") {
                $text .= ("[" . join(",", map { defined $_ ? $_ : "undef" } @{$_[$narg]}) . "]");
            }
            elsif (ref($_[$narg]) eq "HASH") {
                $text .= ("{" . join(",", map { defined $_ ? $_ : "undef" } %{$_[$narg]}) . "}");
            }
            else {
                $text .= $_[$narg];
            }
        }
        #$trailer .= " [package=$package sub=$sub subroutine=$subroutine class=$class method=$method]";
        $text .= ")";
        my $trailer_len = length($trailer);
        $text =~ s/\n/\\n/g;
        my $text_len = length($text);
        if ($App::trace_width) {
            if ($text_len + $trailer_len > $App::trace_width) {
                my $len = $App::trace_width - $trailer_len;
                $len = 1 if ($len < 1);
                print substr($text, 0, $len), $trailer, "\n";
            }
            elsif ($App::trace_justify) {
                my $len = $App::trace_width - $trailer_len - $text_len;
                $len = 0 if ($len < 0);  # should never happen
                print $text, ("." x $len), $trailer, "\n";
            }
            else {
                print $text, $trailer, "\n";
            }
        }
        else {
            print $text, $trailer, "\n";
        }
        $calldepth++;
    }
}

#############################################################################
# sub_exit()
#############################################################################

=head2 sub_exit()

    * Signature: &App::sub_exit(@return);
    * Param:     @return      any
    * Return:    void
    * Throws:    none
    * Since:     0.01

This subroutine is called just before you return from a subroutine or method.
=cut

sub sub_exit {
    if ($App::trace) {
        my ($stacklevel, $calling_package, $file, $line, $subroutine, $hasargs, $wantarray, $text);
        $stacklevel = 1;
        ($calling_package, $file, $line, $subroutine, $hasargs, $wantarray) = caller($stacklevel);
        while (defined $subroutine && $subroutine eq "(eval)") {
            $stacklevel++;
            ($calling_package, $file, $line, $subroutine, $hasargs, $wantarray) = caller($stacklevel);
        }

        my ($package, $sub);
        # split subroutine into its "package" and the "sub" within the package
        if ($subroutine =~ /^(.*)::([^:]+)$/) {
            $package = $1;
            $sub = $2;
        }

        return if (%App::scope && !$App::scope{$package} && !$App::scope{"$package.$sub"});

        $calldepth--;
        $text = ("| " x $calldepth) . "+-> $sub()";
        my ($narg, $arg);
        for ($narg = 0; $narg <= $#_; $narg++) {
            $text .= $narg ? "," : " : ";
            $arg = $_[$narg];
            if (! defined $arg) {
                $text .= "undef";
            }
            elsif (ref($arg) eq "") {
                $text .= $arg;
            }
            elsif (ref($arg) eq "ARRAY") {
                $text .= ("[" . join(",", map { defined $_ ? $_ : "undef" } @$arg) . "]");
            }
            elsif (ref($arg) eq "HASH") {
                $text .= ("{" . join(",", map { defined $_ ? $_ : "undef" } %$arg) . "}");
            }
            else {
                $text .= defined $arg ? $arg : "undef";
            }
        }
        $text =~ s/\n/\\n/g;
        if ($App::trace_width && length($text) > $App::trace_width) {
            print substr($text, 0, $App::trace_width), "\n";
        }
        else {
            print $text, "\n";
        }
    }
    return(@_);
}

#############################################################################
# in_debug_scope()
#############################################################################

=head2 in_debug_scope()

    * Signature: &App::in_debug_scope
    * Signature: App->in_debug_scope
    * Param:     <no arg list supplied>
    * Return:    void
    * Throws:    none
    * Since:     0.01

This is called within a subroutine or method in order to see if debug output
should be produced.

  if ($App::debug && &App::in_debug_scope) {
      print "This is debug output\n";
  }

Note: The App::in_debug_scope subroutine also checks $App::debug, but checking
it in your code allows you to skip the subroutine call if you are not debugging.

  if (&App::in_debug_scope) {
      print "This is debug output\n";
  }

=cut

sub in_debug_scope {
    if ($App::debug) {
        my ($stacklevel, $calling_package, $file, $line, $subroutine, $hasargs, $wantarray, $text);
        $stacklevel = 1;
        ($calling_package, $file, $line, $subroutine, $hasargs, $wantarray) = caller($stacklevel);
        while (defined $subroutine && $subroutine eq "(eval)") {
            $stacklevel++;
            ($calling_package, $file, $line, $subroutine, $hasargs, $wantarray) = caller($stacklevel);
        }
        my ($package, $sub);

        # split subroutine into its "package" and the "sub" within the package
        if ($subroutine =~ /^(.*)::([^:]+)$/) {
            $package = $1;
            $sub = $2;
        }

        if (%App::scope) {
            if ($App::scope_exclusive) {
                return(undef) if ($App::scope{$package} || $App::scope{"$package.$sub"});
            }
            else {
                return(undef) if (!$App::scope{$package} && !$App::scope{"$package.$sub"});
            }
        }
        return(1);
    }
    return(undef);
}

#############################################################################
# debug_indent()
#############################################################################

=head2 debug_indent()

    * Signature: &App::debug_indent()
    * Signature: App->debug_indent()
    * Param:     void
    * Return:    $indent_str     string
    * Throws:    none
    * Since:     0.01

This subroutine returns the $indent_str string which should be printed
before all debug lines if you wish to line the debug output up with the
nested/indented trace output.

=cut

sub debug_indent {
    my $text = ("| " x $calldepth) . "  * ";
    return($text);
}


=head1 ACKNOWLEDGEMENTS

 * Author:  Stephen Adkins <spadkins@gmail.com>
 * License: This is free software. It is licensed under the same terms as Perl itself.

=head1 SEE ALSO

=cut

1;

