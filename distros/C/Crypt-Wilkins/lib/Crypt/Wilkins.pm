package Crypt::Wilkins;

use 5.008002;
use strict;
use warnings;

our $VERSION = '0.02';

sub new {
    my $class = shift;
	my %attribs = @_;
	my $self = \%attribs;

    my %letters = (
    a => '00001',
    b => '00010',
    c => '00011',
    d => '00100',
    e => '00101',
    f => '00110',
    g => '00111',
    h => '01000',
    i => '01001',
    j => '01010',
    k => '01011',
    l => '01100',
    m => '01101',
    n => '01110',
    o => '01111',
    p => '10000',
    q => '10001',
    r => '10010',
    s => '10011',
    t => '10100',
    u => '10101',
    v => '10110',
    w => '10111',
    x => '11000',
    y => '11001',
    z => '11010',
    '.' => '11011',
    '!' => '11100',
    '?' => '11101',
    ',' => '11110',
    ':' => '11111', );

    $self->{letters} = \%letters;

    return bless $self, $class;
}

sub binencode {
    my $self = shift;
    my $plaintext = shift;
    my %letters = %{ $self->{letters} };

    $plaintext =~ s/9/nine/g;
    $plaintext =~ s/8/eight/g;
    $plaintext =~ s/7/seven/g;
    $plaintext =~ s/6/six/g;
    $plaintext =~ s/5/five/g;
    $plaintext =~ s/4/four/g;
    $plaintext =~ s/3/three/g;
    $plaintext =~ s/2/two/g;
    $plaintext =~ s/1/one/g;
    $plaintext =~ s/0/zero/g;
    $plaintext = lc $plaintext;
    $plaintext =~ s/[^a-z\.!?,:]//g;
    $plaintext =~ s/[a-z\.!?,:]/$letters{$&}/g;
    return $plaintext;
}


sub embed {
    my $self = shift;
    my $plaintext = shift;
    my $substrate = shift;
#    my $key = shift;

    my $begin = $self->{tagbegin};
    my $end = $self->{tagend};

    my $binary = $self->binencode($plaintext);
    return undef unless length($binary) <= length($substrate);

    my @substrate = split //, $substrate;
    my @binary = split //, $binary;

    my $ciphertext = '';
    for my $i (0..$#binary){
        while( $substrate[0] !~ /[A-Za-z0-9]/ ){
            $ciphertext .= shift @substrate;
        }
        if( $binary[$i] == 1 ){
            $ciphertext .= $begin . shift(@substrate) . $end;
        }
        else {
            $ciphertext .= shift @substrate;
        }
    }
    $ciphertext .= join '', @substrate;
    return $ciphertext;
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Crypt::Wilkins - 

=head1 SYNOPSIS

  use Crypt::Wilkins;
  blah blah blah

=head1 DESCRIPTION

Blah blah blah.


=head1 SEE ALSO

Mercury, Quicksilver, The Confusion

=head1 AUTHOR

Ira Joseph Woodhead, E<lt>ira at sweetpota dot toE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Ira Woodhead

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
