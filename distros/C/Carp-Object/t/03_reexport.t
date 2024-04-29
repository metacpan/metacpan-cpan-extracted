use utf8;
use strict;
use warnings;
use Test::More;
use FindBin qw/$Bin/;
use lib "$Bin/lib";

# ===============================================================================
# global vars, can be localized during tests
# ===============================================================================

our $note_msg;  # if true, the error msg is printed out
our %die_line;  # remember source lines where some croaking occurs

# ===============================================================================
# infrastructure : a couple of packages to check how croak() skips calling packages
# ===============================================================================

package Serpent;
sub induce {Eva->induce}                     $die_line{+__PACKAGE__} = __LINE__;
# NOTE : '+' in the line above prevents __PACKAGE__ from being parsed as a bareword
                                                                
package Eva;
sub induce {Adam->eat}                       $die_line{+__PACKAGE__} = __LINE__;

package Adam;
use TestReexport;

sub eat {
  croak "that beautiful apple is forbidden"; $die_line{+__PACKAGE__} = __LINE__;
}  


# ===============================================================================
# infrastructure : wrappers around Test::More
# ===============================================================================

package main;
use TestReexport;

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

# basic calls from main
croak_at_line  {croak 'aargh'}  __LINE__,           "croak in main";
croak_msg_like {confess 'ouch'} qr/\n.*\n.*\n/,     "confess in main";


# check if croaking is at the proper level
croak_at_line {Serpent->induce}  $die_line{Eva},  "croak at Eva (from Serpent)";
croak_at_line {Eva->induce}      $die_line{Eva},  "croak at Eva (from Eva)";
croak_at_line {Adam->eat}        __LINE__,        "croak in main";

# verbose arg transforms a croak into a confess
{
  no warnings 'once';
  local %TestReexport::CARP_OBJECT_CONSTRUCTOR = (verbose => 1);
  croak_msg_like {Adam->eat} qr/\n.*\n.*\n/,    "verbose: croak => confess";
}


done_testing;

