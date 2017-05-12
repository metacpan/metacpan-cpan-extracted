package Acme::LeetSpeak;

use warnings;
use strict;
use base 'Exporter';

our @EXPORT = qw/leet/;

=head1 NAME

Acme::LeetSpeak - Speak like a kI[)dI3 

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

This module makes translates english sentences into "leet".  For more 
information on leet, please consult wikipedia (L< http://en.wikipedia.org/ >).

    use warnings;
    use strict;
    use Acme::LeetSpeak;
    ...
    my $leet = leet( $string );

=head1 FUNCTIONS

=head2 leet

=cut

use constant {
    INPUT  => 0,
    CHANCE => 1,
    OUTPUTS => 2,
};

our @LEET_WORD_MAP = (
# pre number-ization

    # words
    [ '\bfear\b', 10, [ 'phear', ], ],
    [ '\bp(?:ro|or)n\w*\b', 10, [ 'pron', ] ],
    [ '\belite\b', 10, [ 'eleet', 'leet', ], ],
    [ '\bdo\b', 9, [ 'do', 'doo', ], ],
    [ '\bthe\b', 9, [ 'teh', 'da', ], ],
    [ '\byou\b', 9, [ 'yuo', 'joo', ], ],
    [ '\byour\b', 9, [ 'yuor', 'joor', ], ],
    [ '\bdude\b', 9, [ '${1}od', '${1}ood', ], ],
    [ '\bhack\b', 9, [ 'hax', ], ],
    [ '\b(?:too?|two)\b', 9, [ '2', ], ],
    [ '\b(?:good)?bye\b', 9, [ 'latez', 'laterz', 'cya', 'bai', ], ],
    [ '\b(?:hi|hello)\b', 9, [ 'hai', 'y helo thar', 'hai2u', ], ],
    [ '\bat\b', 9, [ '\\@', ], ],
    [ '\bdude(\w*)\b', 9, [ 'dood${1}', ], ], 


    # suffixes
    [ '\b(\w+)er\b', 7, [ '${1}xor', '${1}xxor', '${1}zor', '${1}or', ], ],
    [ '\b(\w+)ed\b', 7, [ '${1}\'d', '${1}d', '${1}t', ], ],
    [ '\b(\w+)cks\b', 7, [ '${1}x', '${1}xx', ], ],
    [ '\b(\w+)an(?:d|n?ned|nt)\b', 7, [ '${1}&', ] ],
);

our %LEET_CHAR_MAP = (
    # letters
    'a', [ '4', '/-\\', '@', ],
    'b', [ '8', '|3', '(3', ], 
    'c', [ '[', '<', '(', '{', ], 
    'd', [ ')', '[)', '|)', ], 
    'e', [ '3', ], 
    'f', [ '|=', '|#', ], 
    'g', [ '9', ], 
    'h', [ '#', '/-/', '[-]', ']-[', ')-(', '}{', '|-|' ], 
    'i', [ '1', '!', '|', '][', ], 
    'j', [ '_|', '_/', ],
    'k', [ '|<', ], 
    'l', [ '1', '7', '1_', '|', '|_', ], 
    'm', [ '|\\/|', '/\\/\\', '/|/|', ], 
    'n', [ '|\\|', '/\\/', '[\\]', ], 
    'o', [ '()', 'oh', '0', ], 
    'p', [ '|o', '|*', '|>', ], 
    'q', [ '0_', '(,)', ], 
    'r', [ 'r' ], 
    's', [ '5', '$', ],
    't', [ '7', '+', ],
    'u', [ '(_)', '|_|', ], 
    'v', [ '\\/', '\\|', '|/', ], 
    'w', [ '\\/\\/', '\\^/', '\v/', ], 
    'x', [ '><', '}{', ], 
    'y', [ 'j', '¥', '`/', ], 
    'z', [ 'z' ], 
);

our $CHANCE_OF_LEET_CHAR = 5; # out of 10
our $CHANCE_OF_UPPER_CHAR = 5; 

sub leet {
	my $text = shift;
    return unless defined $text and $text ne '' and $text !~ /^\s+$/;
    foreach my $rule ( @LEET_WORD_MAP ) { 
            if ( $text =~ $rule->[INPUT] && int( rand 9 ) < $rule->[CHANCE] ) {
                my $find = $rule->[INPUT];
                my $switch = $rule->[OUTPUTS]->[ rand @{ $rule->[OUTPUTS] } ];
                $text =~ s/$find/$switch/i;
            }
    }
    $text =~ s/([a-z])/_leetchar($1)/ige;
    return $text;
}

sub _leetchar {
    my $char = shift;
    if ( int( rand 9 ) < $CHANCE_OF_LEET_CHAR ) {
        my $leet = $LEET_CHAR_MAP{lc $char};
        $char = $leet->[ rand @{ $leet } ];
    }
    if ( int( rand 9 ) < $CHANCE_OF_UPPER_CHAR ) {
        $char = uc $char;
    }
	return $char;
}

=head1 AUTHOR

Jordan M. Adler, C<< <jmadler at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-acme-leetspeak at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Acme-LeetSpeak>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Acme::LeetSpeak

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Acme-LeetSpeak>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Acme-LeetSpeak>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Acme-LeetSpeak>

=item * Search CPAN

L<http://search.cpan.org/dist/Acme-LeetSpeak>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 Jordan M. Adler, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Acme::LeetSpeak
