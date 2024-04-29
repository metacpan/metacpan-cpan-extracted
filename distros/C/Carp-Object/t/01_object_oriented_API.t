use utf8;
use strict;
use warnings;
use Test::More;
use Carp::Object ();

# ===============================================================================
# global vars, can be localized during tests
# ===============================================================================

our $note_msg;  # if true, the error msg is printed out
our %ctor_args; # used when building Carp::Object instances
our %die_line;  # remember source lines where some croaking occurs

# ===============================================================================
# infrastructure : a couple of packages to check how croak() skips calling packages
# ===============================================================================
package Serpent;
sub induce {Eva->induce}                               $die_line{+__PACKAGE__} = __LINE__;
# NOTE : '+' in the line above prevents __PACKAGE__ from being parsed as a bareword
                                                                
package Eva;
sub induce {Adam->eat}                                 $die_line{+__PACKAGE__} = __LINE__;

package Adam;
sub eat {
  my $carper = Carp::Object->new(%ctor_args);                                            
  $carper->croak("that beautiful apple is forbidden"); $die_line{+__PACKAGE__} = __LINE__;
}  

sub salivate {
  my $carper = Carp::Object->new(%ctor_args);                                            
  $carper->carp("beware, that beautiful apple is forbidden");
}



# ===============================================================================
# infrastructure : wrappers around Test::More
# ===============================================================================

package main;

sub croak_msg_like (&$;$) {
  my ($code, $regexp, $test_name) = @_;
  local $SIG{__DIE__} = sub {note $_[0] if $note_msg; like $_[0], $regexp, $test_name};
  eval {$code->()};
}

sub croak_at_line (&$;$) {
  my ($code, $line, $test_name) = @_;
  croak_msg_like \&$code, qr/\bline $line\.$/, $test_name;
  # NOTE : \&$ above : thanks https://stackoverflow.com/questions/54785472/type-of-arg-1-must-be-block-or-sub-not-subroutine-entry
}

sub carp_msg_like (&$;$) {
  my ($code, $regexp, $test_name) = @_;
  local $SIG{__WARN__} = sub {note $_[0] if $note_msg; like $_[0], $regexp, $test_name};
  $code->();
}

# ===============================================================================
# beginning of tests
# ===============================================================================

# basic stuff
croak_at_line  {Carp::Object->new->croak('aargh')} __LINE__,        "croak in main";
croak_msg_like {Carp::Object->new->confess('ouch')} qr/\n.*\n.*\n/, "confess in main";


# check if croaking is at the proper level
croak_at_line {Serpent->induce}  $die_line{Eva},  "croak at Eva (from Serpent)";
croak_at_line {Eva->induce}      $die_line{Eva},  "croak at Eva (from Eva)";
croak_at_line {Adam->eat}        __LINE__,        "croak in main";

# verbose arg transforms a croak into a confess
{
  local %ctor_args = (verbose => 1);
  # local $note_msg = 1;
  croak_msg_like {Adam->eat} qr/\n.*\n.*\n/,    "verbose: croak => confess";
  croak_msg_like {Adam->eat} qr/Adam->eat\(\)/, "frame rewrite for method calls";
}

# global $Carp::Verbose is like the verbose arg
{
  local $Carp::Verbose = 1;
  croak_msg_like {Adam->eat} qr/\n.*\n.*\n/, "Carp::verbose: croak => confess";
}

# frame_filter
{
  local %ctor_args = (verbose => 1,
                      frame_filter => sub {my $raw_frame_ref = shift;
                                           my $first_arg = $raw_frame_ref->{args}[0] // "";
                                           return $first_arg !~ /^CODE\b/}); # stupid criteria, just for the test
  croak_msg_like {Serpent->induce} qr/eval.*$/, "frame main::croak_msg was filtered out";
}

# clan of packages to ignore
{
  local %ctor_args = (clan => qr/^(Adam|Eva|Serpent)$/);
  croak_at_line {Serpent->induce}  __LINE__, "croak in main (Serpent)";
  croak_at_line {Eva->induce}      __LINE__, "croak in main (Eva)";
  croak_at_line {Adam->eat}        __LINE__, "croak in main (Adam)";
}

# custom display_frame()
{
  local %ctor_args = (verbose => 1,
                      display_frame => sub {my $frame = shift;
                                            return sprintf "line %d in %s\n", $frame->line, $frame->package});
  croak_msg_like {Serpent->induce} qr/^line \d+ in Eva$/m, "custom sub for display_frame";
}


# carp
carp_msg_like {Adam->salivate} qr/beware/, "carp method";
  


done_testing;

