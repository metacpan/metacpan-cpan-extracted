package Class::Implements;
use strict;
use warnings;
our $VERSION = 0.01;

my %liars;

use Hook::Queue 'UNIVERSAL::isa' => sub {
    my $ref = shift;
    my $what = shift;
    return 1 if grep { $_ eq $what } @{ $liars{ ref $ref || $ref } || [] };
    return Hook::Queue->defer();
};

sub import {
    my $self = shift;
    my $what = shift;
    my $liar = caller;
    push @{ $liars{ $liar } }, $what;
}

1;

__END__

=head1 NAME

Class::Implements - pretend that your class is another class

=head1 SYNOPSIS

  package Some::Class;
  use Class::Implements 'Some::Other::Class';

  print "You are the droids I'm looking for\n"
   if UNIVERSAL::isa( "Some::Class", "Some::Other::Class" );

=head1 DESCRIPTION

Some module authors will insist on writing their object type checks as:

 die "go away"
   unless UNIVERSAL::ISA( $object, "The::Class:I'm::Willing::To::Deal::With" );

It it this authors opinion that this is wrong, and the guilty
developers should be sent to their room without their supper until
they realise that they should be writing:

 die "go away"
   unless $object->isa( "The::Class:I'm::Willing::To::Deal::With" );

So that other module authors can provide an isa method if they decide
to.

Of course, while they're busy contemplating what they've done wrong
their existing code isn't going to be changed, so you'll have to use
this module.  It brings some relief by supplying a fake UNIVERSAL::isa
which understands how to stretch the truth a little.

=head1 AUTHOR

Richard Clamp <richardc@unixbeard.net>

Copyright 2004 Richard Clamp.  All Rights Reserved.

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 BUGS

None known.

Bugs should be reported to me via the CPAN RT system.
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Class::Implements>.

=head1 SEE ALSO

L<Hook::Queue>

=cut

