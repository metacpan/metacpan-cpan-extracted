################################################################################
# This is CodeManager
# Copyright 2009-2013 by Waldemar Biernacki
# http://codemanager.sao.pl\n" .
#
# License statement:
#
# This program/library is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#
# Last modified (DMYhms): 13-01-2013 20:15:38.
################################################################################

package Prima::CodeManager::Misc;

use strict;
use warnings;

use POSIX;

################################################################################

sub read_file_at_once {
    my( $self, $file ) = @_ ;

	return unless -f $file;
    my $content;

    local *FH;
    sysopen( FH, $file, O_RDONLY ) or $self->{ERROR} = "Can't open $file: $!";

	-f FH and sysread FH, $content, -s FH;

	return $content;
}

################################################################################

sub read_ini_file {
	my ( $self, $ini_file, $global ) = @_;

	my $group = '';

	if ( open ( my $FH, "<$ini_file" )) {

		while ( my $wiersz = <$FH> ) {
			next if $wiersz =~ /^(;|#|--)/;

			$wiersz =~ s/\n*//g;
			$wiersz =~ s/\r*//g;
			$wiersz =~ s/\t*//g;
			next unless $wiersz;

			$wiersz =~ s/^([^#]*)#.*$/$1/;

			if ( $wiersz =~ /^\s*\[(.+)\]/ ) {
				$group = $1;
			} else {

				if ( $wiersz =~ /^([^=]+?)\s*=\s*(.*)$/ ) {
					my $name   = $1;
					my $object = $2;
					$object =~ s/%\[([^%]*)\]([^%]*)%/$global->{$1}->{$2}/g;
					$global->{$group}->{$name} = $object if $group && $name;
				}
			}
		}
		close ($FH);
	}

	return 0;
}

################################################################################

sub write_ini_file {
	my ( $self, $ini_file ) = @_;

	foreach my $group (sort keys %::_GLOBAL ) {
		my %hasz = %{$::_GLOBAL{$group}};

		foreach my $name (sort keys %hasz ) {
			print "$group\[$name\]=",$hasz{$name},"\n";
		}

	}

	return 1;
}

################################################################################

sub read_one_row {
	my ( $self, $FH ) = ( shift, shift );

	my $wiersz = <$FH>;
	$wiersz = '' unless $wiersz;
	if ( $wiersz =~ /\\/ ) {
		$wiersz =~  s/^(.*)\\.*/$1/;
		$wiersz =~  s/^(.*)#.*/$1/;
		$wiersz .= ' ' unless $wiersz =~ /(,|;|`)\t*$/;	#`
		$wiersz .= $self-> read_one_row( $FH )
	}
	return $wiersz;
}

################################################################################

sub write_to_file {
	my ( $self, $file, $content ) = ( shift, shift, shift );

	if ( open (my $FH , ">>$file" )) {
		print $FH $content if $content;
		close $FH;
	}
}

#-------------------------------------------------------------------------------

sub read_file {
	my ( $self, $file, $content ) = ( shift, shift, '' );

	if ( open (my $FH , "<$file" )) {
		while ( my $row = <$FH> ) { $content .= $row }
		close $FH;
	}

	return $content;
}

################################################################################

sub czas {
	my ( $self, $format, $time ) = ( shift, shift, shift );
	my ($s,$m,$h,$D,$M,$Y) = localtime;
	($s,$m,$h,$D,$M,$Y) = localtime $time if defined $time;

	$s = substr('00'.$s,-2);
	$m = substr('00'.$m,-2);
	$h = substr('00'.$h,-2);
	$format =~ s/s/$s/g;
	$format =~ s/m/$m/g;
	$format =~ s/h/$h/g;

	$D = substr('00'.$D,-2);
	$M = substr('00'.($M+1),-2);
	$Y+= 1900;
	$format =~ s/DD/$D/g;
#	if ( $format =~ /MR/ ) {
#		$M = roman($M);
#		$M =~  tr/a-z/A-Z/;
#	}
#	$format =~ s/MR/$M/g;
	$format =~ s/MM/$M/g;
	$format =~ s/YYYY/$Y/g;
	$format =~ s/YY/substr($Y,-2)/ge;

	return $format;
}

################################################################################

sub licz_kolor
{
	my ( $self, $col1, $col2, $l1, $inw ) = @_;

	$l1  = 0 unless $l1; $l1 += 0; $l1 = 0 if $l1 < 0; $l1 = 1 if $l1 > 1;

	my $l2 = 1 - $l1;

	$inw =   0 unless $inw;
	$inw = 255 if     $inw;

	my @c1;
	my @c2;
	my @re;

	$c1[2] = $col1 % 256; $col1 = ( $col1 - $c1[2] ) / 256;
	$c1[1] = $col1 % 256; $col1 = ( $col1 - $c1[1] ) / 256;
	$c1[0] = $col1 % 256;

	$c2[2] = $col2 % 256; $col2 = ( $col2 - $c2[2] ) / 256;
	$c2[1] = $col2 % 256; $col2 = ( $col2 - $c2[1] ) / 256;
	$c2[0] = $col2 % 256;

	$re[0] = int( $l1 * $c1[0] + $l2 * $c2[0] );
	$re[0] =   0 if $re[0] <   0;
	$re[0] = 255 if $re[0] > 255;

	$re[1] = int( $l1 * $c1[1] + $l2 * $c2[1] );
	$re[1] =   0 if $re[1] <   0;
	$re[1] = 255 if $re[1] > 255;

	$re[2] = int( $l1 * $c1[2] + $l2 * $c2[2] );
	$re[2] =   0 if $re[2] <   0;
	$re[2] = 255 if $re[2] > 255;

	if ( $inw ) {
		return 256 * 256 * (255-$re[0]) + 256 * (255-$re[1]) + (255-$re[2]);
	} else {
		return 256 * 256 * $re[0] + 256 * $re[1] + $re[2];
	}
}

################################################################################

sub angle_color
{
	my ( $self, $phi, $white, $black ) = @_;

	$phi   %= 360;

	$white  = 255 unless defined $white;
	$white %= 256;

	$black  =   0 unless defined $black;
	$black %= 256;

	if ( $black > $white ) {
		my $tmp = $white;
		$white = $black;
		$black = $tmp;
	}

	my $gamma = int ( ( $white - $black ) * ( $phi % 60 ) / 60 );
	my ( $red, $gre, $blu ) = (0,0,0);

	if    ( $phi <  60 ) { ( $red, $gre, $blu ) = ( $black+$gamma,        $white,        $black ) }
	elsif ( $phi < 120 ) { ( $red, $gre, $blu ) = (        $white, $white-$gamma,        $black ) }
	elsif ( $phi < 160 ) { ( $red, $gre, $blu ) = (        $white,        $black, $black+$gamma ) }
	elsif ( $phi < 240 ) { ( $red, $gre, $blu ) = ( $white-$gamma,        $black,        $white ) }
	elsif ( $phi < 300 ) { ( $red, $gre, $blu ) = (        $black, $black+$gamma,        $white ) }
	elsif ( $phi < 360 ) { ( $red, $gre, $blu ) = (        $black,        $white, $white-$gamma ) }

	return int( 1.0 * ( $red + 256 * $gre + 256 * 256 * $blu ));
}

########################################################################################

sub create_user_home_directory
{
	my ( $self, $home_directory ) = @_;

	return if -e $home_directory;

	mkdir "$home_directory";
	$self-> write_to_file ( "$home_directory/.exists" , '' );

my $CodeManager_CodeManager =<< "_CODE_MANAGER_";
[GLOBAL]
#group of projects
group = System

#name of project
name = CodeManager

############## PROJECT TREE CONFIGURATION #############
#main project encoding
#can be redefined in each sub-project [DIRECTORY]
CodeManager_encoding= UTF8
#this is the height of one tree project branch:
#if none or less than 16 then tree_itemHeight = 16
tree_itemHeight		= 18
#the indent of next level branch relative to the parent one.
#if none or less than 16 then tree_itemIndent = 16
tree_itemIndent		= 16
#font name of the branches description
#if none then DejaVu Sans Mono is taken
tree_fontName		= DejaVu Sans Mono
#size and height of branch description font.
#only one is taken; height - if > 0 - has higher rank than size
#if none then tree_fontSize = 0.625 * tree_itemHeight
tree_fontSize		= 10
tree_fontHeight		= 14

############## EDITOR PANEL #############
#additional space between lines. Can be negative!
#It is possible to dynamically change by pressing AltDown/AltUp keys
editor_lineSpace	=  2

#editor font size or height (similar rules to the tree configuration ones)
#It is possible to dynamically change by pressing CtrlDown/CtrlUp keys
editor_fontSize		= 11
editor_fontHeight	= 14

#Font family should be chosen the mono type, but whatever!
editor_fontName		= DejaVu Sans Mono

############## NOTEBOOK CONFIGURATION #############

notebook_fontSize	=  9
notebook_fontHeight	= 12
notebook_fontName	= Arial

[EXTERNAL_EDITORS]
png	=	gimp
exe	=	no edit!

[DIRECTORY]
name		= My projects
image		= cm.png
linux		= ~/projects
windows		= ~/projects
extensions	= cm

[DIRECTORY]
name		= My templates
image		= pl.png
linux		= ~/templates
windows		= ~/templates
extensions	= pl|pm|ini
directories	= all

[DIRECTORY]
name		= CodeManager
image		= cm.png
linux		= %CodeManager%
windows		= %CodeManager%
extensions	= all
ext_exclude	= \.exists
directories	= all
dir_exclude	= \.svn

_CODE_MANAGER_

	mkdir "$home_directory/projects";
	$self-> write_to_file ( "$home_directory/projects/.exists" , '' );
	$self-> write_to_file ( "$home_directory/projects/CodeManager.cm" , $CodeManager_CodeManager );

	mkdir "$home_directory/templates";
	$self-> write_to_file ( "$home_directory/templates/.exists" , '' );
	$self-> write_to_file ( "$home_directory/templates/templates.ini" , '' );

	mkdir "$home_directory/templates/default";
	$self-> write_to_file ( "$home_directory/templates/default/.exists" , '' );

	mkdir "$home_directory/templates/list";
	$self-> write_to_file ( "$home_directory/templates/list/.exists" , '' );

	return;
}

################################################################################

1;

__END__

=pod

=head1 NAME

Prima::CodeManager::Misc

=head1 DESCRIPTION

This is part of CodeManager project - not for direct use.

=head1 AUTHOR

Waldemar Biernacki, E<lt>wb@sao.plE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2009-2012 by Waldemar Biernacki.

L<http://CodeManager.sao.pl>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
