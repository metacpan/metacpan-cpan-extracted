#
# Copyright (C) 2015 Joel Maslak
# All Rights Reserved - See License
#

package Acme::Unicodify;
# ABSTRACT: Convert ASCII text into look-somewhat-alike unicode
$Acme::Unicodify::VERSION = '0.006';
use utf8;
use v5.22;

use strict;
use warnings;

use File::Slurper 0.008 qw(read_text write_text);


use autodie;

use Carp;
use Unicode::Normalize;

my %_TRANSLATE = (
    a => "\N{U+251}",
    b => "\N{U+432}",
    c => "\N{U+63}\N{U+30A}",
    d => "\N{U+64}\N{U+30A}",
    e => "\N{U+3F5}",
    f => "\N{U+4FB}",
    g => "\N{U+260}",
    h => "\N{U+4A3}",
    i => "\N{U+268}",
    j => "\N{U+135}",
    k => "\N{U+1E31}",
    l => "\N{U+2113}",
    m => "\N{U+271}",
    n => "\N{U+1E47}",
    o => "\N{U+26AC}",
    p => "\N{U+3C1}",
    q => "\N{U+24E0}",
    r => "\N{U+27E}",
    s => "\N{U+15B}",
    t => "\N{U+1C0}\N{U+335}",
    u => "\N{U+1D66A}\N{U+30A}",
    v => "\N{U+22C1}",
    w => "\N{U+2375}",
    x => "\N{U+1E8B}",
    y => "\N{U+1EFE}",
    z => "\N{U+1D66F}",
    A => "\N{U+10300}",
    B => "\N{U+1D6C3}",
    C => "\N{U+C7}",
    D => "\N{U+1D673}",
    E => "\N{U+395}",
    F => "\N{U+4FA}",
    G => "\N{U+1E4}",
    H => "\N{U+10199}",
    I => "\N{U+10309}",
    J => "\N{U+1D4AF}",
    K => "\N{U+212A}",
    L => "\N{U+1D473}",
    M => "\N{U+1D4DC}",
    N => "\N{U+2115}",
    O => "\N{U+2B55}",
    P => "\N{U+5C38}",
    Q => "\N{U+1F160}",
    R => "\N{U+5C3A}",
    S => "\N{U+10296}",
    T => "\N{U+4E05}",
    U => "\N{U+2F10}",
    V => "\N{U+1D54D}",
    W => "\N{U+174}",
    X => "\N{U+274C}",
    Y => "\N{U+1F1FE}",
    Z => "\N{U+2621}"
);


sub new {
    my $class = shift;

    my $self = {};
    bless $self, $class;

    $self->_define_cache();

    return $self;
}


sub to_unicode {
    my $self = shift;
    my $str = shift;

    if (!defined($str)) { return; }

    my @parts = split /\b{gcb}/, $str;
    my $out = '';
    foreach my $l (@parts) {
        if ( exists( $_TRANSLATE{$l} ) ) {
            $out .= $_TRANSLATE{$l};
        } else {
            $out .= $l;
        }
    }

    return NFD($out);
}


sub back_to_ascii {
    my $self = shift;
    my $str = shift;

    if (!defined($str)) { return; }

    my @parts = split /\b{gcb}/, $str;
    my $out = '';
    foreach my $l (@parts) {
        if ( exists( $self->{_ASCII_CACHE}->{$l} ) ) {
            $out .= $self->{_ASCII_CACHE}->{$l};
        } else {
            $out .= $l;
        }
    }

    return $out;
}


sub file_to_unicode {
    if ($#_ != 2) { confess 'invalid call' }
    my ($self, $in_fn, $out_fn) = @_;

    my $txt = read_text($in_fn);
    $txt = $self->to_unicode($txt);
    write_text($out_fn, $txt);

    return;
}


sub file_back_to_ascii {
    if ($#_ != 2) { confess 'invalid call' }
    my ($self, $in_fn, $out_fn) = @_;

    my $txt = read_text($in_fn);
    my $out = $self->back_to_ascii($txt);
    write_text($out_fn, $out);

    return;
}

sub _define_cache {
    my $self = shift;

    $self->{_ASCII_CACHE} = {};

    my $i = 0;
    foreach my $key (keys %_TRANSLATE) {
        $i++;
        $self->{_ASCII_CACHE}->{$self->to_unicode($key)} = $key;
    }
    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::Unicodify - Convert ASCII text into look-somewhat-alike unicode

=head1 VERSION

version 0.006

=head1 SYNOPSIS

  my $translate = Acme::Unicodify->new();

  $foo = $translate->to_unicode('Hello, World');
  $bar = $translate->back_to_ascii($unified_string);

  file_to_unicode('/tmp/infile', '/tmp/outfile');
  file_back_to_ascii('/tmp/infile', '/tmp/outfile');

=head1 DESCRIPTION

This is intended to translate basic 7 bit ASCII into characters
that use several Unicode features, such as accent marks and
non-Latin characters.  While this can be used just for fun, a
better use perhaps is to use it as part of a test suite, to
allow you to easily pass in Unicode and determine if your system
handles Unicode without corrupting the text.

=head1 METHODS

=head2 new

Create a new instance of the Unicodify object.

=head2 to_unicode($str)

Takes an input string and translates it into look-alike Unicode
characters.  Input is any string.

Basic ASCII leters are translated into Unicode "look alikes", while
any character (Unicode or not) is passed through unchanged.

=head2 back_to_ascii($str)

Takes an input string that has perhaps previously been produced
by C<to_unicode> and translates the look-alike characters back
into 7 bit ASCII.  Any other characters (Unicode or ASCII) are
passed through unchanged.

=head2 file_to_unicode($infile, $outfile)

This method reads the file with the named passed as the first
argument, and produces a new output file with the name passed
as the second argument.

The routine will call C<to_unicode> on the contents of the file.

Note this will overwrite existing files and it assumes the input
and output files are in UTF-8 encoding (or plain ASCII in the
case that no codepoints >127 are used).

This also assumes that there is sufficient memory to slurp the
entire contents of the file into memory.

=head2 file_back_to_ascii($infile, $outfile)

This method reads the file with the named passed as the first
argument, and produces a new output file with the name passed
as the second argument.

The routine will call C<back_to_ascii> on the contents of the file.

Note this will overwrite existing files and it assumes the input
and output files are in UTF-8 encoding (or plain ASCII in the
case that no codepoints >127 are used).

=head1 AUTHOR

Joel Maslak <jmaslak@antelope.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015,2016 by Joel Maslak.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
