use strict;
use warnings;

package Acme::Llama;

our %llama;

=head1 NAME

Acme::Llama - An object-oriented interface to llamas.

=head1 VERSION

Version 0.42

=head1 SYNOPSIS

use strict;
use warnings;
use Acme::Llama;
my $llama = Acme::Llama->new;
$llama->feed;
$llama->play;
$llama->sacrifice;

=head1 DESCRIPTION

This module provides a simplistic, but powerful, interface to the Lama glama.

=head1 OBJECT INTERFACE

=over

=item B<new>

Create a new llama, all by yourself! :)

=cut

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    $llama{'foodage'}   = 0;
    $llama{'happiness'} = 0;
    $llama{'tired'}     = 0;
    return $self;
}

=item B<feed>

A well-fed llama is a happy llama.
The perl Gods like happy llamas.
Too much food makes a sad llama though. :(
No one likes a sad llama.

[Technical details: returns 1 for a happy hungry llama, and returns
for a big full llama. ]

=cut

sub feed {
    $llama{'foodage'}++;
    if   ( $llama{'foodage'} < 10 ) { $llama{'happiness'}++ and return 1; }
    else                            { $llama{'happiness'}-- and return; }
}

=item B<play>

A good llama trainer should play often with their llama, 
as this makes them happy.
Llamas get tired though, and then they don't like to play,
they need rest instead then.

[Technical details: returns 1 for a llama that wants to play more,
and returns for a llama that needs a nap. ]

=cut

sub play {
    if ( $llama{'tired'} == 1 ) {
        $llama{'happiness'} - 5;
        return;
    }
    my $int = int( rand(20) );
    $llama{'happiness'} + 2;
    if ( $int > 10 ) {
        $llama{'tired'} = 1;
        return;
    }
    else {
        $llama{'tired'} = 0;
        return 1;
    }
}

=item B<nap>

Sometimes, even the big llamas get tired.
When llamas are tired, they need a nap to make them 
feel better! But, if the llama isn't tired, making it
try to take a nap will make it a sad llama. :(

=cut

sub nap {
    if ( $llama{'tired'} == 0 ) { $llama{'happiness'}--; return; }
    else { $llama{'tired'} = 0 and $llama{'happiness'}++; return 1; }
}

=item B<sacrifice>

Ah, we finally have reached the last goal of all good llamas. Sacrificing to the Perl gods. 
You'd best hope your llama was happy enough, or death to your Perl script will come! :(

=back
=cut

sub sacrifice {
    my ( $self, %args ) = @_;
    $args{'TO'} ||= '';
    if ( lc( $args{'TO'} ) ne 'perl gods' ) {
        die('Who are you sacrificing this llama to?');
    }
    if ( $llama{'happiness'} > 10 ) {
        print(
"Congratulations. Your sacrifical llama has appeased the Perl gods!\n"
        );
        exit;
    }
    else {
        die(
"Sorry, your llama was not happy enough. Try to raise it better next time! :("
        );
    }
}

1;

=head1 AUTHOR

Alexandria Marie Wolcott <alyx@cpan.org>

=head1 LICENSE

Copyright (c) Alexandria Marie Wolcott

This module may be used, modified, and distributed under BSD license. See the beginning of this file for said license.

=head1 SEE ALSO

L<http://enwp.org/llama>

=cut
