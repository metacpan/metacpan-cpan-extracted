
#

use v5.12;

package Chart::Font;
our $VERSION = 'v2.402.3';

use Carp;

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

