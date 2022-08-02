
#

use v5.12;

package Chart::Property::DataType::Font;
our $VERSION = 'v2.403.7';

use Carp;

## constructor #########################################################

sub new {
    my $pkg = shift;
    my $def = shift;
    return unless ref $def eq 'HASH';
    bless {};
}

## getter ##############################################################

sub name {

}

sub bold {

}

sub size {

}

sub unicode {
}

sub truetype {

}


1;

__END__

=pod

=head1 NAME

Chart::Font - read only single font holding objects

=head1 SYNOPSIS 

    my $red = Chart::Color->new('red');
    say $red->add('blue')->name;              # magenta, mixed in RGB space
    Chart::Color->new( 0, 0, 255)->hsl        # 240, 100, 50 = blue
    $blue->blend_with({H=> 0, S=> 0, L=> 80}, 0.1);# mix blue with a little grey
    $red->gradient( '#0000FF', 10);           # 10 colors from red to blue  
    $red->complementary( 3 );                 # get fitting red green and blue

=head1 DESCRIPTION



=head1 COPYRIGHT & LICENSE

Copyright 2022 Herbert Breunung.

This program is free software; you can redistribute it and/or modify it 
under same terms as Perl itself.

=head1 AUTHOR

Herbert Breunung, <lichtkind@cpan.org>

=cut


__END__
$im->string( GD::Font->Tiny ,       20,  20, 'Tiny',       2);
$im->string( GD::Font->Small ,      20,  50, 'Small',      1);
$im->string( GD::Font->MediumBold , 20,  80, 'MediumBold', 2);
$im->string( GD::Font->Large ,      20, 110, 'Large',      1);
$im->string( GD::Font->Giant ,      20, 140, 'Giant',      2);

gdTinyFont
gdSmallFont
gdMediumBoldFont
gdLargeFont
gdGiantFont
