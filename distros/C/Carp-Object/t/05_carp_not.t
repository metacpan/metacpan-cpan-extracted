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
use Carp::Object;
our @CARP_NOT = qw/Adam Eva Serpent/;

sub eat {
  croak "that beautiful apple is forbidden";           $die_line{+__PACKAGE__} = __LINE__;
}  

sub salivate {
  carp "beware, that beautiful apple is forbidden";
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

# ===============================================================================
# beginning of tests
# ===============================================================================


croak_at_line {Serpent->induce}  __LINE__, "croak in main (Serpent)";
croak_at_line {Eva->induce}      __LINE__, "croak in main (Eva)";
croak_at_line {Adam->eat}        __LINE__, "croak in main (Adam)";


done_testing;

