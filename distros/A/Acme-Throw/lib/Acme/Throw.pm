use strict;
use warnings;
package Acme::Throw;

# ABSTRACT: For when code makes you want to throw something.

use utf8;

our $MSG;

sub import {
  my ($class, %args) = @_;

  $MSG = $args{-msg} || "WHY WON'T THIS CODE WORK??!?";
  my $orig_handler = $SIG{__DIE__};

  $SIG{__DIE__} = sub {
    binmode(STDERR, ":utf8");
    print STDERR "(╯°□°）╯︵ ┻━┻  $MSG\n";
    $SIG{__DIE__} = $orig_handler;
    die @_;
  };
}

sub _msg { $MSG }

1 && q{ THIS IS MY RAGE FACE }; # truth
__END__

=head1 NAME

Acme::Throw - For when code makes you want to throw something.

=head1 SYNOPSIS

  use Acme::Throw;
  # code that does stuff...
  die "something bad happened"

Alternatively,

  perl -MAcme::Throw /path/to/program.pl

=head1 DESCRIPTION

B<THIS CODE IS CRAP! IT'S SO BAD IT MAKES THE I<COMPUTER> ANGRY!!!>

Do you feel that the error messages in your code don't express your
frustration with enough I<oomph>? Do screens full of stack dumps fill
you with a deep-seated rage?

Have you ever wanted to simply flip a table each time your program
dies with a cryptic, useless exception?

NOW YOU CAN.

=head1 THANKS

I felt I needed to one-up Chris Devers after he posted the bash-equivalent
of this on facebook.

=head1 LICENSE AND COPYRIGHT

GAAAAAAAAARGH!

=cut
