package Acme::Addslashes;

use utf8;

# ABSTRACT: Perl twist on the most useful PHP function ever - addslashes

=encoding utf-8

=head1 NAME

Acme::Addslashes - Perl twist on the most useful PHP function ever - addslashes

=head1 SYNOPSIS

Do you have some text? Have you ever wanted to add some slashes to it? Well now you can!

PHP has a totally awesome C<addslashes()> function - L<http://php.net/addslashes>.

PERL has long been lacking such a function, and at long last here it is. Of
course the PERL version is better. Here is a run down of what's better in PERL:

=over

=item 1 PHP's addslashes can only adds slashes before characters.

Thanks to unicode, PERL's version doesn't have this limitation. We add slashes
I<directly to the characters>. Isn't that cool?

=item 2 PHP's addslashes only adds slashes to some characters

Why not add slashes to all characters? More slashes directly equals safer code.
That is scientific fact. There is no real evidence for it, but it is scientific fact.

B<UPDATE> Now with extra long slashes for even more protection! Thanks ~SKINGTON!

=back

=head1 USAGE

    use Acme::Addslashes qw(addslashes);

    my $unsafe_string = "Robert'); DROP TABLE Students;--";
    
    my $totally_safe_string = addslashes($unsafe_string);

    # $totally_safe_string now contains:
    # R̸o̸b̸e̸r̸t̸'̸)̸;̸ ̸D̸R̸O̸P̸ ̸T̸A̸B̸L̸E̸ ̸S̸t̸u̸d̸e̸n̸t̸s̸;̸-̸-̸

    # If that's not enough slashes to be safe, I don't know what is

=cut

use v5.12;
use strict; # lolwut? strict??

use Encode qw(encode);
use feature qw(unicode_strings);
use parent "Exporter";

our @EXPORT_OK = qw(addslashes);

our $VERSION = '0.1.3';

=head1 FUNCTIONS

=head2 addslashes

    my $totally_safe_string = addslashes("Robert'); DROP TABLE Students;--");

The only function exported by this module. Will literally add slashes to anything.

Letters, numbers, punctuation, whitespace, unicode symbols.
You name it, this function can add a slash to it.

Will return you a C<utf8> encoded string containing your original string, but with
enough slashes added to make Freddy Krueger jealous.

=cut

# The addslashes function. It is documented above. -- JAITKEN
sub addslashes {
    # Get the arguments passed to the function using the shift command -- JAITKEN
    my $unsafe_string = shift;

    # Split the string into letters - just like explode in PHP. Or maybe str_split
    # I can't remember which one is which -- JAITKEN
    my @unsafe_array = split('', $unsafe_string);
    
    # Add slashes to every character thanks to unicode.
    # This is complex magic -- JAITKEN
    # I think these slashes could be longer -- SKINGTON
    # You forgot the last slash -- JAITKEN
    my $safe_string = join("\N{U+0338}", @unsafe_array) . "\N{U+0338}";

    # Return the safe string using the return function of PERL -- JAITKEN
    return encode("utf8", $safe_string);
}

# The end of the module. -- JAITKEN
1;


=head1 AUTHOR

James Aitken <jaitken@cpan.org>


=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by James Aitken.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
