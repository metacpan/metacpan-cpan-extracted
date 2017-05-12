package Acme::Tao;

use constant 1.01;
use strict;
no strict 'refs';

use vars qw(@messages $VERSION);

$VERSION = 0.03;

@messages = (
    qq(
The Tao doesn't take sides;
it gives birth to both wins and losses.
),
    qq(
        A novice asked the master: "I have a program that sometimes runs and
sometimes aborts.  I have followed the rules of programming, yet I am totally
baffled. What is the reason for this?"
        The master replied: "You are confused because you do not understand
the Tao.  Only a fool expects rational behavior from his fellow humans.  Why
do you expect it from a machine that humans have constructed?  Computers
simulate determinism; only the Tao is perfect.
        The rules of programming are transitory; only the Tao is eternal.
Therefore you must contemplate the Tao before you receive enlightenment."
        "But how will I know when I have received enlightenment?" asked the
novice.
        "Your program will then run correctly," replied the master.
                -- Geoffrey James, "The Tao of Programming"
),
    qq(
        In the beginning was the Tao.  The Tao gave birth to Space and Time.
Therefore, Space and Time are the Yin and Yang of programming.

        Programmers that do not comprehend the Tao are always running out of
time and space for their programs.  Programmers that comprehend the Tao always
have enough time and space to accomplish their goals.
        How could it be otherwise?
                -- Geoffrey James, "The Tao of Programming"
),
);

sub import {
    my $class = shift;
    if(@_) {
        my($pkg, $file, $line) = caller;
        foreach my $v (@_) {

            # this is based on the perl 5.6.1 perldoc (perldoc constant)
            # not sure why we have to pass $v through a regex -- otherwise, 
            # it gives us an error that we are trying to modify a constant 
            # value (which might be due to the pos($v) being modified)

            $v =~ m{(.*)};
            my $u = $1;
            $u =~ s/^::/main::/;
            my $full_name = $v =~ m{::} ? $u : "${pkg}::$u";
            die "Uh, Oh!  $full_name was declared constant before line $line of $file.\n"
                if $constant::declared{$full_name};
        }
    }
    else {
        if(grep /::Tao$/, keys %constant::declared) {
            my @isas = ($class, @{"${class}::ISA"});
            my $messages;
            while(@isas) {
                my $c = shift @isas;
                if(@{"${c}::ISA"}) {
                    unshift @isas, @{"${c}::ISA"};
                }
                if(@{"${c}::messages"}) {
                    $messages = \@{"${c}::messages"};
                    last;
                }
            }
            # randomly determine if we die or not
            return if rand(rand) < rand(rand);
            die "The Tao is not constant:\n", $messages->[rand @$messages], "\n"
        }
    }
}

1;

__END__

=head1 NAME

Acme::Tao - strongly suggests proper respect for the Tao

=head1 SYNOPSIS

 use Acme::Tao;

or

 use Acme::Tao qw(something_that_must_not_be_constant);

=head1 DESCRIPTION

Everyone knows that the Tao is not constant.  But some people just 
might not get it.  To make sure no one tries to use constant Tao 
in a program with your module, put a C<use Acme::Tao> at the top 
of your code.  If Tao has been made constant by time your module 
is used, Acme::Tao may die with a nice message.  Note that the 
package in which Tao is constant is irrelavent.

On a walk between shrines in Nikko, Japan, I had an epiphany:  if the 
Tao is not constant, than neither should Acme::Tao be constant.

 The Tao doesn't take sides;
 it gives birth to both wins and losses.

Acme::Tao doesn't take sides either, at least not consistently.  It 
will sometimes die and sometimes not (50% chance of it doing so), in 
accordance with its understanding of the nature of the Tao.

As Lao-tzu teaches, "The name that can be named is not the constant 
name," and Acme::Tao can *also* be used to check for any other 
symbols you might not want to have as constants.  When used in this 
fashion, it will always try to work.

For example:

 use Acme::Tao qw(foo);

This will die if C<foo> is defined as a constant in the current package.

 use Acme::Tao qw(::foo);

This will die if C<foo> is defined as a constant in the C<main::> 
package.  This is the same as C<main::foo>.

If Acme::Tao is checking for particular symbols, it will not check 
for a constant Tao.

=head1 MESSAGES

The messages are stored in C<@__PACKAGE__::messages>.  Feel free to 
add to them.  You can even subclass Acme::Tao:

 package My::Tao;

 use Acme::Tao ();
 use vars(@messages @ISA);

 @ISA = qw(Acme::Tao);

 @messages = ( ... );

 1;
 __END__

The messages will come from the appropriate package and are not cumulative.

=head1 AUTHOR

James G. Smith, <jsmith@cpan.org>

I owe Kip Hampton a big thank you for mentioning the idea in 
passing and assisting with parts of the documentation.

The messages are lifted from the C<fortune> data files.

=head1 COPYRIGHT

Copyright (C) 2002, 2004  James G. Smith.  

This module is free software.  It may be used, redistributed, and/or 
modified under the same terms as Perl.
