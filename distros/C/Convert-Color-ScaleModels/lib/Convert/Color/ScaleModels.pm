package Convert::Color::ScaleModels;

use 5.006;
use strict;
use warnings;
use Carp;        

my $names_colors;

=head1 NAME

Convert::Color::ScaleModels - converts between color numbers from scale model paint manufacturers (Humbrol, Revell, Tamiya)

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';


=head1 SYNOPSIS

This module converts between color numbers from scale model paint manufacturers (Humbrol, Revell, Tamiya).

    use Convert::Color::ScaleModels;

    my $color = Convert::Color::ScaleModels->new();

    my $revell_flesh_num = $color->convert('61', 'humbrol', 'revell');
    print "manufacturer = $color->{man}\n";     # 'revell'
    print "color name = $color->{name}\n";      # 'flesh matt'          
    print "color number = $color->{num}\n";     # 35
    print "color number (return value from method) = $revell_flesh_num\n";  # also 35

The color number values are taken from Humbrol's own conversion tables (L<http://humbrol.com/convert-to-humbrol/conversion-tables/>).

=head1 SUBROUTINES/METHODS

=head2 new

Creates new color object. Each object carries a color name (C<name>), color number (C<num>) and manufacturer name (C<man>), undefined at object creation.
    
    my $color = Convert::Color::ScaleModels->new();    

=cut

sub new {
    my $class = shift;
    my $self = {};

    $self->{name} = undef;
    $self->{num} = undef;
    $self->{man} = undef;

    bless( $self, $class );
    return $self;
}

=head2 convert

Converts between color numbers from scale model paint manufacturers (Humbrol, Revell, Tamiya). The object properties (C<name>, C<num> and C<man>) are set after conversion.
For instance, to convert color number 61 ('flesh matt') from Humbrol to the corresponding value from Revell (if available), use

      my $revell_flesh_num = $color->convert(61, 'humbrol', 'revell');  # $revell_flesh_num = 35      

=cut

sub convert {
    my $self = shift;
    my ($colornum, $man1, $man2) = @_;
    
    return undef unless (_valid_man($man1) 
        && _valid_man($man2));

    if ($man1 eq $man2) {
        # no conversion needed
        $self->{man} = $man1;
        $self->{num} = $colornum;
    } else {
        # lookup color table
        my ($newcolor, $cname);
        foreach my $name ( keys %$names_colors ) {
            if ($man1 =~ /humbrol/i) {
                next unless defined($names_colors->{$name}->[0]) 
                    and $colornum eq $names_colors->{$name}->[0];
                if ($man2 =~ /revell/i) {
                    $newcolor = $names_colors->{$name}->[1];
                } else {    # $man2 matches 'tamiya'
                    $newcolor = $names_colors->{$name}->[2];
                }
                $cname = $name;
            } elsif ($man1 =~ /revell/i) {
                next unless defined($names_colors->{$name}->[1]) 
                    and $colornum eq $names_colors->{$name}->[1];
                if ($man2 =~ /humbrol/i) {
                    $newcolor = $names_colors->{$name}->[0];
                } else {    # $man2 matches 'tamiya'
                    $newcolor = $names_colors->{$name}->[2];
                }
                $cname = $name;
            } else {    # $man1 matches 'tamiya'
                next unless defined($names_colors->{$name}->[2]) 
                    and $colornum eq $names_colors->{$name}->[2];
                if ($man2 =~ /humbrol/i) {
                    $newcolor = $names_colors->{$name}->[0];
                } else {    # $man2 matches 'revell'
                    $newcolor = $names_colors->{$name}->[1];
                }
                $cname = $name;
            }            
        }

        $self->{man} = $man2;
        $self->{num} = $newcolor;
        $self->{name} = $cname;
    }
    return $self->{num};
}

=head2 name

Returns color name, given color number and manufacturer. Otherwise, returns C<undef>.

    print $color->name('65', 'humbrol');    # 'aircraft blue matt'

=cut

sub name {
    my $self = shift;
    my ($cnum, $man) = @_;

    return undef unless _valid_man($man);
    
    foreach my $name ( keys %$names_colors ) {
        if ($man =~ /humbrol/i) {
            return $name if defined($names_colors->{$name}->[0])
                 and $cnum eq $names_colors->{$name}->[0];
        } elsif ($man =~ /revell/i) {
            return $name if defined($names_colors->{$name}->[1])
                 and $cnum eq $names_colors->{$name}->[1];
        } else {    # $man matches 'tamiya'
            return $name if defined($names_colors->{$name}->[2])
                 and $cnum eq $names_colors->{$name}->[2];
        }
    }
    return undef;
}

sub _valid_man {
    my $man = shift;
    if ($man =~ /(humbrol|revell|tamiya)/i) {
        return 1;
    } else {
        # manufacturer unknown
        croak "Manufacturer unknown: $man";
        return undef;
    }
}

=head1 AUTHOR

Ari Constancio, C<< <affc at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-convert-color-scalemodels at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Convert-Color-ScaleModels>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Convert::Color::ScaleModels


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Convert-Color-ScaleModels>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Convert-Color-ScaleModels>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Convert-Color-ScaleModels>

=item * Search CPAN

L<http://search.cpan.org/dist/Convert-Color-ScaleModels/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Ari Constancio.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

$names_colors = {
	"grey primer" 		        => [1, undef, undef ],
	"emerald green gloss" 		=> [2, undef, undef ],
	"brunswick green gloss" 	=> [3, undef, "x5" ],
	"dark admiral grey gloss" 	=> [5, undef, undef ],
	"light buff gloss" 		    => [7, undef, undef ],
	"tan gloss" 		        => [9, undef, undef ],
	"service brown gloss" 		=> [10, 81, "x9" ],
	"silver metallic" 		    => [11, 90, "x11" ],
	"copper metallic" 		    => [12, undef, "xf6" ],
	"french blue gloss" 		=> [14, 52, "x4" ],
	"midnight blue gloss" 		=> [15, undef, "x3" ],
	"gold metallic" 		    => [16, 94, "x12" ],
	"orange gloss" 		        => [18, 30, "x6" ],
	"bright red gloss" 		    => [19, 31, "x7" ],
	"crimson gloss" 		    => [20, undef, undef ],
	"black gloss" 		        => [21, 7, "x1" ],
	"white gloss" 		        => [22, 4, "x2" ],
	"duck egg blue matt" 		=> [23, undef, undef ],
	"trainer yellow matt" 		=> [24, 15, undef ],
	"blue matt" 		        => [25, 56, "xf8" ],
	"khaki matt" 		        => [26, 86, "xf49" ],
	"sea grey matt" 		    => [27, undef, "xf54" ],
	"camouflage grey matt" 		=> [28, undef, "xf55" ],
	"dark earth matt" 		    => [29, 87, "xf52" ],
	"dark green matt" 		    => [30, undef, "xf61" ],
	"slate grey matt"   		=> [31, undef, undef ],
	"dark grey matt" 	    	=> [32, undef, undef ],
	"black matt"    	    	=> [33, 8, "xf1" ],
	"white matt" 	        	=> [34, 5, "xf2" ],
	"varnish gloss" 	    	=> [35, 1, undef ],
	"lime gloss" 	        	=> [38, undef, "x15" ],
	"pale grey gloss" 	    	=> [40, undef, undef ],
	"ivory gloss" 	        	=> [41, 10, undef ],
	"sea blue gloss" 	    	=> [47, undef, undef ],
	"mediterranian blue gloss" 	=> [48, 51, "x14" ],
	"varnish matt" 		        => [49, 2, undef ],
	"green mist metallic" 		=> [50, 97, undef ],
	"sunset red metallic" 		=> [51, 96, undef ],
	"baltic blue metallic" 		=> [52, 96, "x13" ],
	"gunmetal metallic" 		=> [53, undef, "x10" ],
	"brass metallic" 		    => [54, 93, undef ],
	"bronze metallic" 		    => [55, 95, undef ],
	"aluminium metallic" 		=> [56, 99, "xf56" ],
	"scarlet matt"  	    	=> [60, 36, "xf7" ],
	"flesh matt" 	    	    => [61, 35, "xf15" ],
	"leather matt"  	    	=> [62, 85, undef ],
	"sand matt" 	        	=> [63, undef, "xf59" ],
	"light grey matt" 	    	=> [64, 75, "xf12" ],
	"aircraft blue matt" 		=> [65, 55, "xf23" ],
	"olive drab matt" 	    	=> [66, 53, "xf62" ],
	"tank grey matt" 	    	=> [67, 78, undef ],
	"purple gloss" 	       	    => [68, undef, "x16" ],
	"yellow gloss" 	        	=> [69, 12, "x8" ],
	"brick red matt" 	    	=> [70, 37, undef ],
	"oak satin" 	        	=> [71, undef, undef ],
	"khaki drill matt" 		    => [72, undef, undef ],
	"wine matt" 		        => [73, undef, "xf9" ],
	"linen matt" 		        => [74, undef, undef ],
	"bronze green matt" 		=> [75, undef, "xf11" ],
	"uniform green matt" 		=> [76, undef, undef ],
	"navy blue matt" 		    => [77, undef, undef ],
	"cockpit green matt" 		=> [78, undef, undef ],
	"blue grey matt" 	    	=> [79, 77, undef ],
	"grass green matt" 	    	=> [80, undef, undef ],
	"pale yellow matt" 		    => [81, undef, "xf4" ],
	"orange lining matt" 		=> [82, undef, undef ],
	"ochre matt" 		        => [83, undef, "xf57" ],
	"mid stone matt" 	    	=> [84, undef, "xf60" ],
	"coal black satin" 	    	=> [85, 9, "x18" ],
	"light olive matt" 	    	=> [86, 45, undef ],
	"steel grey matt"   		=> [87, undef, "xf25" ],
	"deck green matt" 	    	=> [88, 48, undef ],
	"mid blue matt" 		    => [89, undef, undef ],
	"beige green matt"   		=> [90, undef, "xf21" ],
	"black green matt" 	    	=> [91, 67, "xf27" ],
	"iron grey matt" 		    => [92, 79, "xf22" ],
	"desert yellow matt" 		=> [93, undef, undef ],
	"brown yellow matt" 		=> [94, 16, undef ],
	"raf blue matt"      		=> [96, undef, "xf18" ],
	"chocolate matt" 	    	=> [98, undef, "xf10" ],
	"lemon yellow matt" 		=> [99, undef, "xf3" ],
	"red brown matt"    		=> [100, undef, undef ],
	"mid green matt" 	    	=> [101, 364, "xf5" ],
	"army green matt"    		=> [102, undef, undef ],
	"cream matt" 		        => [103, undef, undef ],
	"oxford blue matt"  		=> [104, undef, "xf17" ],
	"marine green matt" 		=> [105, 361, undef ],
	"ocean grey matt" 	    	=> [106, 47, undef ],
	"ww1 blue matt" 	    	=> [109, undef, undef ],
	"natural wood matt" 		=> [110, undef, undef ],
	"tarmac" 	            	=> [112, 71, "xf24" ],
	"rust matt" 	        	=> [113, undef, undef ],
	"us dark green matt" 		=> [116, undef, "xf13" ],
	"us light green matt" 		=> [117, undef, undef ],
	"us tan matt" 	        	=> [118, 382, undef ],
	"light earth matt" 	    	=> [119, undef, undef ],
	"light green matt" 	    	=> [120, undef, undef ],
	"pale stone matt" 	    	=> [121, undef, undef ],
	"extra dark sea grey satin" => [123, undef, "xf58" ],
	"us dark grey satin" 		=> [125, undef, undef ],
	"us medium grey satin" 		=> [126, undef, "xf20" ],
	"us ghost grey satin" 		=> [127, undef, undef ],
	"us compass grey satin" 	=> [128, 374, undef ],
	"us gull grey satin" 		=> [129, undef, undef ],
	"white satin" 	        	=> [130, 301, undef ],
	"mid green satin" 		    => [131, undef, undef ],
	"red satin" 		        => [132, undef, undef ],
	"brown satin"       		=> [133, undef, undef ],
	"varnish satin" 	    	=> [135, undef, undef ],
	"gull grey matt" 		    => [140, undef, undef ],
	"intermediate blue matt"	=> [144, undef, undef ],
	"medium grey matt" 		    => [145, undef, undef ],
	"light grey matt" 	    	=> [147, undef, "xf14" ],
	"radome tan matt" 		    => [148, undef, undef ],
	"foliage green matt" 		=> [149, undef, "xf26" ],
	"forest green matt" 		=> [150, undef, undef ],
	"insignia red matt" 		=> [153, undef, undef ],
	"insignia yellow matt" 		=> [154, undef, undef ],
	"olive drab matt" 	    	=> [155, undef, undef ],
	"dark camoflage grey satin" => [156, undef, "xf53" ],
	"azure blue matt" 		    => [157, undef, undef ],
	"khaki drab matt" 		    => [159, undef, undef ],
	"german cam red brown matt" => [160, undef, undef ],
	"dark green satin" 		    => [163, undef, undef ],
	"dark sea grey satin" 		=> [164, undef, undef ],
	"medium sea grey satin" 	=> [165, undef, undef ],
	"light aircraft grey satin" => [166, undef, undef ],
	"raf barley grey satin" 	=> [167, undef, undef ],
	"hemp satin" 	        	=> [168, undef, undef ],
	"antique bronze metallic" 	=> [171, undef, undef ],
	"signal red satin" 		    => [174, undef, undef ],
	"brown matt" 		        => [186, undef, undef ],
	"dark stone matt" 		    => [187, undef, undef ],
	"chrome silver metallic" 	=> [191, undef, undef ],
	"chrome green satin" 		=> [195, 363, undef ],
	"light grey satin" 		    => [196, 371, undef ],
	"pink gloss" 		        => [200, undef, "x17" ],
	"black metallic" 		    => [201, undef, undef ],
	"signal green gloss" 		=> [208, undef, undef ],
	"ferrari red gloss" 		=> [220, undef, undef ],
	"moonlight blue metallic" 	=> [222, undef, undef ],
	"dark slate grey matt" 		=> [224, undef, undef ],
	"middle stone matt" 		=> [225, undef, undef ],
	"interior green matt" 		=> [226, undef, undef ],
	"pru blue matt" 		    => [230, undef, undef ],
	"desert sand matt" 		    => [250, undef, undef ],
	"red clear" 		        => [1321, undef, undef ],
	"orange clear" 		        => [1322, undef, undef ],
	"green clear" 		        => [1325, undef, undef ],
	"aluminium metalcote" 		=> [27001, undef, undef ],
	"polish. aluminium metalcote"   => [27002, undef, undef ],
	"polished steel metalcote"	=> [27003, undef, undef ],
	"gunmetal metalcote" 		=> [27004, undef, undef ],
};

1; # End of Convert::Color::ScaleModels
