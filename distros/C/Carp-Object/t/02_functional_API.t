use utf8;
use strict;
use warnings;
use Test::More;

# ===============================================================================
# global vars, can be localized during tests
# ===============================================================================

our $note_msg;  # if true, the error msg is printed out
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
use Carp::Object carp => {-as => 'acarp'}, croak => {-as => 'acroak'};
our %CARP_OBJECT_CONSTRUCTOR;

sub eat {
  acroak "that beautiful apple is forbidden"; $die_line{+__PACKAGE__} = __LINE__;
}  

sub salivate {
  acarp "beware, that beautiful apple is forbidden";
}



# ===============================================================================
# infrastructure : wrappers around Test::More
# ===============================================================================

package main;
use Carp::Object qw/:carp/, {-prefix => 'co_',
                             -suffix => '_wrapped',
                             -constructor_args => {indent => 0},
                           };

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

# imported functions have been renamed
croak_at_line  {co_croak_wrapped 'aargh'}  __LINE__,           "croak in main";
croak_msg_like {co_confess_wrapped 'ouch'} qr/\n.*\n.*\n/,     "confess in main";

# -constructor_args was handled
croak_msg_like {co_confess_wrapped 'oops'} qr/^main.*\neval/m, "no indent";

# check if croaking is at the proper level
croak_at_line {Serpent->induce}  $die_line{Eva},  "croak at Eva (from Serpent)";
croak_at_line {Eva->induce}      $die_line{Eva},  "croak at Eva (from Eva)";
croak_at_line {Adam->eat}        __LINE__,        "croak in main";

# verbose arg transforms a croak into a confess
{
  local %Adam::CARP_OBJECT_CONSTRUCTOR = (verbose => 1);
  # local $note_msg = 1;
  croak_msg_like {Adam->eat} qr/\n.*\n.*\n/,    "verbose: croak => confess";
}



done_testing;

