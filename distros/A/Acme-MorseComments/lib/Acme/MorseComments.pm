#!/usr/bin/perl

# .- -.-. -- . ---... ---... -- --- .-. ... . -.-. --- -- -- . -. - ... .-.-.-   ..-. ..- -.  .-.. .. - - .-.. .  -- --- -.. ..- .-.. .  - .... .- -  .-- .. .-.. .-..  ..-. .. -. -..  .- .-.. .-..  - .... .  -.-. --- -- -- . -. - ...  .. -. 
# -.-- --- ..- .-.  ... --- ..-. - .-- .- .-. .  .- -. -..  .-. . .--. .-.. .- -.-. .  - .... . --  .-- .. - ....  -- --- .-. ... .  -.-. --- -.. . .-.-.- 

package Acme::MorseComments;

$VERSION = "1.00";

use PPI::Tokenizer;

my %morse_code = (
        a => '.-',        b => '-...',     c => '-.-.',     d => '-..',
        e => '.',         f => '..-.',     g => '--.',      h => '....',
        i => '..',        j => '.---',     k => '-.-',      l => '.-..',
        m => '--',        n => '-.',       o => '---',      p => '.--.',
        q => '--.-',      r => '.-.',      s => '...',      t => '-',
        u => '..-',       v => '...-',     w => '.--',      x => '-..-',
        y => '-.--',      z => '--..',     0 => '-----',    1 => '.----',
        2 => '..---',     3 => '...--',    4 => '....-',    5 => '.....',
        6 => '-....',     7 => '--...',    8 => '---..',    9 => '----.',
      '.' => '.-.-.-',  ',' => '--..--', '?' => '..--..', '@' => '.--.-.',
     q{'} => '.----.',  '!' => '-.-.--', '/' => '-..-.',  '(' => '-.--.-',
      ')' => '-.--.-',  '&' => '. ...',  ':' => '---...', ';' => '-.-.-.',
      '=' => '-...-',   '/' => '-..-.',  '-' => '-....-', '_' => '..-- .-',
      '$' => '...-..-',
);

die "Not parseable!\n" unless -r $0;

my $content   = do { open my $fh, '<', $0; local $/; <$fh>; };
my $tokenizer = PPI::Tokenizer->new( \$content );

my $new_file  = q{};

TOKEN:
while (my $token = $tokenizer->get_token) {
    if ($token->isa('PPI::Token::Comment') && $token->content !~ /^#!/
            && $token->content =~ /[A-Za-z0-9]/) {
        foreach my $char (split q{}, $token->content) {
            $new_file .= exists $morse_code{lc $char}
                       ? $morse_code{lc $char} . ' '
                       : $char;
        }
    }
    else {
        $new_file .= $token->content;
    }
}

$new_file =~ s/^ \s* (?:use|require) \s+ Acme::MorseComments \s* ;//xms;

if ( write_file("$0.orig", $content) ) {
    open  0, ">$0";
    print {0} $new_file;
}
else {
    print $new_file;
}

sub write_file {
    my ($filename, $content) = @_;

    return 0 if -e $filename;

    open my $fh, '>', $filename or return 0;
    print   $fh $content;
    close   $fh                 or return 0;

    return 1;
}

1;

__END__

=head1 NAME

Acme::MorseComments - Completely useless module that replaces all of your software's comments with morse code.

=head1 SYNOPSIS

    use Acme::MorseComments;

=head1 DESCRIPTION

    Simply use this module, and it will change all of your comments to
    morse code, and rewrite itself without the use line in it.

    A copy of the original file will be saved in $0.orig.  If $0.orig
    cannot be successfully saved, then the morse-coded file will be output
    to STDOUT, and the original file will remain unchanged.

=head1 AUTHOR

    Justin Wheeler <morsecomments@datademons.com>

=head1 BUGS

    None that I'm aware of, but it's always possible.  E-mail me should
    you find any.

=head1 COPYRIGHT

    Copyright (c) 2006 Justin Wheeler <morsecomments@datademons.com.  All
    rights reserved.  This program is free software; you can redistribute
    or modify it under the same terms as Perl itself.

    This software also comes without any warranty to the extent allowed by
    law.  Don't blame me should this software somehow lose all of your
    data and code.

=cut
