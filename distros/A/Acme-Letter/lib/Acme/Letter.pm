package Acme::Letter;

use 5.010001;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Acme::Letter ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.01';


# TODO:Preloaded methods go here.
sub new {
	my $package = shift;

	my %self = ();
	#inital each letter
	my $array_A = [['*','*','*','*','_','*', '*', '*', '*'],
					['*','*','*','/','*','\\','*','*','*'],
					['*','*','/','*','_','*','\\','*','*'],
					['*','/','*','_','_','_','*','\\','*'],
					['/','_','/','*','*','*','\\','_','\\']];
	$self{"array_A"} = $array_A;	
	my $array_B = [['*','_','_','_','_','_','*'],
				   ['|','*','*','_','*','*','\\'],
				   ['|','*','|','_',')','_','/'],
				   ['|','*','|','_',')','*','\\'],
				   ['|','_','_','_','_','_','/']];
	$self{"array_B"} = $array_B;
	my $array_C = [['*','*','_','_','_','_','_','*'],
				   ['*','/','*','*','_','_','_','|'],
				   ['|','*','*','/','*','*','*','*'],
				   ['|','*','*','\\','_','_','_','*'],
				   ['*','\\','_','_','_','_','_','|']];
	$self{"array_C"} = $array_C;
	my $array_D = [['*','_','_','_','_','_','*','*'],
				   ['|','*','*','_','*','*','\\','*'],
				   ['|','*','|','*','\\','*','*','|'],
				   ['|','*','|','_','/','*','*','|'],
				   ['|','_','_','_','_','_','/','*']];
	$self{"array_D"} = $array_D;

	my $array_E = [['*','_','_','_','_','_','*'],
					['|','*','*','_','_','_','|'],
					['|','*','|','_','_','*','*'],
					['|','*','|','_','_','_','*'],
					['|','_','_','_','_','_','|']];
	$self{"array_E"} = $array_E;

	my $array_F = [['*','_','_','_','_','_','*'],
					['|','*','*','_','_','_','|'],
					['|','*','|','_','*','*','*'],
					['|','*','*','_','|','*','*'],
					['|','_','|','*','*','*','*']];
	$self{"array_F"} = $array_F;

	my $array_G = [['*','*','_','_','_','_','_','*'],
				   ['*','/','*','*','_','_','_','|'],
				   ['|','*','*','/','*','_','_','*'],
				   ['|','*','*','\\','_','_','_','|'],
				   ['*','\\','_','_','_','_','_','|']];
	$self{"array_G"} = $array_G;

	my $array_H = [['*','_','*','*','*','_','*'],
					['|','*','|','*','|','*','|'],
					['|','_','|','_','|','_','|'],
					['|','*','|','*','|','*','|'],
					['|','_','|','*','|','_','|']];
	$self{"array_H"} = $array_H;
	my $array_I = [['*','_','_','_','_','_','*'],
					['|','_','_','*','_','_','|'],
					['*','*','|','*','|','*','*'],
					['*','_','|','_','|','_','*'],
					['|','_','_','_','_','_','|']];
	$self{"array_I"} = $array_I;
	
	my $array_J = [['*','_','_','_','_','_','*'],
					['|','_','_','*','_','_','|'],
					['*','*','|','*','|','*','*'],
					['*','_','|','_','|','*','*'],
					['*','\\','_','/','*','*','*']];
	$self{"array_J"} = $array_J;

	my $array_K = [['*','_','*','*','*','_','*'],
					['|','*','|','*','/','*','/'],
					['|','*','|','/','*','/','*'],
					['|','*','|','\\','*','\\','*'],
					['|','_','|','*','\\','_','\\']];
	$self{"array_K"} = $array_K;

	my $array_L = [['*','_','*','*','*','*','*'],
					['|','*','|','*','*','*','*'],
					['|','*','|','*','*','*','*'],
					['|','*','|','_','_','_','*'],
					['|','_','_','_','_','_',')']];
	$self{"array_L"} = $array_L;

	my $array_M = [['*','_','*','*','*','*','*','*','_','*'],
					['|','*','*','\\','*','*','/','*','*','|'],
					['|','*','|','\\','\\','/','/','|','*','|'],
					['|','*','|','*','\\','/','*','|','*','|'],
					['|','_','|','*','*','*','*','|','_','|']];
	$self{"array_M"} = $array_M;

	my $array_N = [['*','_','*','*','*','*','_','*'],
					['|','*','*','\\','*','|','*','|'],
					['|','*','|','\\','\\','|','*','|'],
					['|','*','|','*','\\','|','*','|'],
					['|','_','|','*','*','\\','_','|']];
	$self{"array_N"} = $array_N;

	my $array_O = [['*','*','_','_','_','_','_','*','*'],
					['*','/','*','*','_','*','*','\\','*'],
					['|','*','*','/','*','\\','*','*','|'],
					['|','*','*','\\','*','/','*','*','|'],
					['*','\\','_','_','_','_','_','/','*']];
	$self{"array_O"} = $array_O;

	my $array_P = [['*','_','_','_','_','*','*'],
					['|','*','*','_','*','\\','*'],
					['|','*','|','_',')','*','|'],
					['|','*','*','_','_','/','*'],
					['|','_','|','*','*','*','*']];
	$self{"array_P"} = $array_P;

	my $array_Q = [['*','*','_','_','_','_','*','*'],
					['*','/','*','*','_','*','\\','*'],
					['|','*','*','(','*','|','*','|'],
					['*','\\','*','_','_','*','*','*'],
					['*','*','*','*','*','|','_','|']];
	$self{"array_Q"} = $array_Q;

	my $array_R = [['*','_','_','_','_','*','*'],
					['|','*','*','_','*','\\','*'],
					['|','*','|','_',')','*','|'],
					['|','*','|','*','*','/','*'],
					['|','_','|','\\','_','\\','*']];
	$self{"array_R"} = $array_R;

	my $array_S = [['*','_','_','_','*'],
					['/','_','_','_','|'],
					['\\','\\','_','*','*','*'],
					['*','_','_','\\','\\'],
					['|','_','_','_','/']];
	$self{"array_S"} = $array_S;

	my $array_T = [['*','_','_','_','_','_','*'],
					['|','_','_','*','_','_','|'],
					['*','*','|','*','|','*','*'],
					['*','*','|','*','|','*','*'],
					['*','*','|','_','|','*','*']];
	$self{"array_T"} = $array_T;

	my $array_U = [['*','_','*','*','*','*','_','*'],
					['|','*','|','*','*','|','*','|'],
					['|','*','|','*','*','|','*','|'],
					['|','*','\\','_','_','/','*','|'],
					['*','\\','_','_','_','_','/','*']];
	$self{"array_U"} = $array_U;

	my $array_V = [['_','_','*','*','*','*','*','*','_','_'],
					['\\','*','\\','*','*','*','*','/','*','/'],
					['*','\\','*','\\','*','*','/','*','/','*'],
					['*','*','\\','*','\\','/','*','/','*','*'],
					['*','*','*','\\','_','_','/','*','*','*']];
	$self{"array_V"} = $array_V;

	my $array_W = [['*','_','*','*','*','*','*','*','_','*'],
					['|','*','|','*','*','*','*','|','*','|'],
					['|','*','|','*','/','\\','*','|','*','|'],
					['|','*','|','/','/','\\','\\','|','*','|'],
					['|','_','*','/','*','*','\\','*','_','|']];
	$self{"array_W"} = $array_W;

	my $array_X = [['*','_','*','*','*','*','_','*'],
					['\\','*','\\','*','*','/','*','/'],
					['*','\\','*','\\','/','*','/','*'],
					['*','/','*','/','\\','*','\\','*'],
					['/','_','/','*','*','\\','_','\\']];
	$self{"array_X"} = $array_X;

	my $array_Y = [['*','_','*','*','*','*','_','*'],
					['\\','*','\\','*','*','/','*','/'],
					['*','\\','_','\\','/','_','/','*'],
					['*','*','*','|','*','|','*','*'],
					['*','*','*','|','_','|','*','*']];
	$self{"array_Y"} = $array_Y;

	my $array_Z = [['*','_','_','_','_','_','*'],
					['|','_','_','*','*','*','|'],
					['|','*','*','/','*','/','*'],
					['*','*','/','*','/','_','_','_','*'],
					['*','|','_','_','_','_','_','_','|']];
	$self{"array_Z"} = $array_Z;

	#draw number
	my $array_1 = [['*','*','*','*','*'],
					['*','*','*','*','*'],
					['*','*','1','*','*'],
					['*','*','*','*','*'],
					['*','*','*','*','*']];
	$self{"array_1"} = $array_1;

	
	my $array_2 = [['*','*','*','_','_','_','_','*','*','*','*'],
					['*','*','|','_','_','_','*','\\','*','*','*'],
					['*','*','*','*','_','_',')','*','|','*','*'],
					['*','*','*','/','*','_','_','*','*','*','*'],
					['*','*','|','_','_','_','_','_','|','*','*']];
	$self{"array_2"} = $array_2;

	my $array_3 = [['*','*','*','*','*'],
					['*','*','*','*','*'],
					['*','*','3','*','*'],
					['*','*','*','*','*'],
					['*','*','*','*','*']];
	$self{"array_3"} = $array_3;

	my $array_4 = [['*','*','*','*','*','_','*','*','*','*','*','*','*'],
					['*','*','*','*','/','*','/','*','*','*','*','*','*'],
					['*','*','*','/','*','_','|','*','|','*','*','*','*'],
					['*','*','/','_','*','_','*','*','*','*','*','*','*'],
					['*','*','*','*','*','*','|','_','|','*','*','*','*']];
	$self{"array_4"} = $array_4;

	
	my $array_5 = [['*','*','*','_','_','_','_','*','*','*'],
					['*','*','|','*','_','_','_','|','*','*'],
					['*','*','|','_','_','*','*','*','*','*'],
					['*','*','*','*','_','\\','*','\\','*','*'],
					['*','*','/','_','_','_','*','/','*','*']];
	$self{"array_5"} = $array_5;

	my $array_6 = [['*','*','*','*','*'],
					['*','*','*','*','*'],
					['*','*','6','*','*'],
					['*','*','*','*','*'],
					['*','*','*','*','*']];
	$self{"array_6"} = $array_6;

	my $array_7 = [['*','*','*','_','_','_','_','_','_','*','*','*'],
					['*','*','|','_','_','_','*','*','*','|','*','*'],
					['*','*','*','*','*','*','/','*','/','*','*','*'],
					['*','*','*','*','*','/','*','/','*','*','*','*'],
					['*','*','*','*','/','_','/','*','*','*','*','*']];
	$self{"array_7"} = $array_7;

	
	my $array_8 = [['*','*','*','_','_','_','_','_','*','*','*'],
					['*','*','/','*','*','_','*','*','\\','*','*'],
					['*','*','\\','_','(','_',')','_','/','*','*'],
					['*','*','/','*','(','_',')','*','\\','*','*'],
					['*','*','\\','_','_','_','_','_','/','*','*']];
	$self{"array_8"} = $array_8;

	my $array_9 = [['*','*','*','*','_','_','_','_','*','*','*','*'],
					['*','*','*','/','*','*','_','*','\\','*','*','*'],
					['*','*','|','*','*','(','_',')','*','|','*','*'],
					['*','*','*','\\','*','_','_','/','*','|','*','*'],
					['*','*','*','*','_','_','/','_','/','*','*','*']];
	$self{"array_9"} = $array_9;

	#draw a space
	my $array_XYZ = [['*','*','*'],['*','*','*'],['*','*','*'],['*','*','*'],['*','*','*']];
	$self{"array_XYZ"} = $array_XYZ;
	
	#draw a colon
	my $array_colon =[['*','*','*','*','*','*','*'],['*','*','*','_','*','*','*'],['*','*','(','_',')','*','*'],['*','*','*','_','*','*','*'],['*','*','(','_',')','*','*']];
	$self{"array_colon"} = $array_colon;
	
	#draw a dot
	my $array_dot =[['*','*','*','*','*','*'],['*','*','*','*','*','*'],['*','*','*','*','*','*'],['*','*','_','*','*','*'],['*','(','_',')','*','*']];
	$self{"array_dot"} = $array_dot;

	my $lines = [];
	$self{"lines"} = $lines;
	return bless(\%self,$package);
}

sub printString()
{
	my $self = shift;
	my $string = shift;

	$self->_createString($string);

	my $lines_ref = $self->{"lines"};
	
	for(my $i = 0; $i <= 4; $i++)
	{
		my $temps=$$lines_ref[$i];
		foreach my $temp (@$temps)
		{
			if(not defined $temp){
				print " ";
			}
			elsif($temp eq "*")
			{
				print " ";
			}
			else{
				print $temp;
			}
		}
		print "\n";
	}
}

sub _createString()
{
	my $self = shift;
	my $words = shift;

	$self->{"lines"} = $self->_createWord($words);
}

#output a word
sub printWord()
{
	my $self = shift;
	my $word = shift;

	$self->_createWord($word);
	my $lines_ref = $self->{"lines"};
	
	for(my $i = 0; $i <= 4; $i++)
	{
		my $temps=$$lines_ref[$i];
		foreach my $temp (@$temps)
		{
			if(not defined $temp){
				print " ";
			}
			elsif($temp eq "*")
			{
				print " ";
			}
			else{
				print $temp;
			}
		}
		print "\n";
	}
}

#create a word with several letters
sub _createWord()
{
	my $self = shift;
	my $word = shift;

	my @chars = split //,$word;
	my @lines = ();
	my ($temp_char,$char);
	my $temp_array;
	my ($i,$j);

	for ($i =0; $i<5;$i++)
	{
		my @line = ();
		foreach $char ( @chars)
		{
			if($char eq " "){
				$temp_array = $self->{"array_XYZ"};
			}
			elsif($char eq ":"){
				$temp_array = $self->{"array_colon"};
			}
			elsif($char eq "."){
				$temp_array = $self->{"array_dot"};
			}
			elsif($char =~/[0-9]/)
			{
				$temp_array = $self->{"array_".$char};
			}
			else{
				$char = uc($char);
				$temp_array = $self->{"array_".$char};
			}	
			$temp_char = $$temp_array[$i];
			for ($j = 0; $j < @$temp_char; $j++ )
			{
				if($j == 0 && $#line != -1){
					my $temp = $line[$#line];
					if($temp ne '*')
					{
						$line[$#line] = $temp;
					}
					else{
						$line[$#line] = $$temp_char[$j];	
					}
				}
				else{
					$line[$#line+1] = $$temp_char[$j];
				}
			}
		}
		push @lines, \@line;
	}
	$self->{"lines"} = \@lines;
}

#output lines to file
sub saveToFile()
{
	my $self = shift;
	my $string = shift;
	my $filename = shift;

	if(-e $filename)
	{
		die "$filename is a directory" if(-d $filename);
		die "You have no permission to write content to $filename" unless(-w $filename);
		die "$filename is not a text file" unless(-f $filename);

	}
	open(OUT, ">$filename") or die "Can not create an file named ".$filename."\n";

	$self->_createWord($string);
	my $lines_ref = $self->{"lines"};
	
	for(my $i = 0; $i <= 4; $i++)
	{
		my $temps=$$lines_ref[$i];
		foreach my $temp (@$temps)
		{
			if(not defined $temp){
				print OUT " ";
			}
			elsif($temp eq "*")
			{
				print OUT " ";
			}
			else{
				print OUT $temp;
			}
		}
		print OUT "\n";
	}

	close(OUT);
}


1;

__END__

=head1 NAME

Acme::Letter - Perl extension for drawing beautiful letter

=head1 SYNOPSIS

  use Acme::Letter;
  #create an Acme::Letter object
  $letter = Acme::Letter->new();
  $string = 'PDF::API 2'; 
  $letter->printString($string);

=head1 DESCRIPTION

This module draw several lines which like a letter. It is beautiful! You can draw string with letter, colon and dot. Now I have no idea how to desgin number. So you need to draw it by yourself.

=head2 Methods

=over 4

=item * $letter->printLetter($arg)

get a letter, such as a-z or A-Z, return several lines which like a letter.

=item * $letter->printString($string);

get a string, return several lines which like a letter. The String include dot, colon.

=item * $letter-saveToFile($string,$filename)

get a letter, such as a-z or A-Z, create several lines and put into a file named $filename.

=back

=head2 Examples

=over 4

=item * Examples foreach @Letter.

A.

    _
   / \
  / _ \
 / ___ \
/_/   \_\

B.

 _____
|  _  \
|_|_)_/
| |_) \
|_____/

C.

  _____
 /  ___|
|  /
|  \___
 \_____|

 D.

 _____
|  _  \
| | \  |
| |_/  |
|_____/

E.

 _____
|  ___|
| |__
| |___
|_____|

F.

 _____
|  ___|
| |_
|  _|
|_|

H.

 _   _
| | | |
|_|_|_|
| | | |
|_| |_|

I.

 _____
|__ __|
  | |
 _|_|_
|_____|

J.

 _____
|__ __|
  | |
 _| |
 \_/

K.

 _   _
| | //
| |//
| |\\
|_| \\

L.

 _
| |
| |
| |___
|_____)

N.

 _    _
|  \ | |
| |\\| |
| | \| |
|_|  \_|

O.

  _____  
 /  _  \ 
|  / \  |
|  \_/  | 
 \_____/ 

P.

 ____ 
|  _ \
| |_) |
|  __/
|_|

R.

 ____ 
|  _ \
| |_) |
| |  /
|_|\_\

T.

 _____
|__ __|
  | |
  | |
  |_|

M.

 _      _
|  \  /  |
| |\\//| |
| | \/ | |
|_|    |_|

G.

 _____ 
/  ___|
| / __
| \___|
\_____|


S.

  ___
 /___|
 \\_ 
  __\\
 |___/


U.

 _    _
| |  | |
| |  | |
| \__/ |
 \____/


V.

 __      __
 \ \    / /
  \ \  / /
   \ \/ /
    \__/


X.

 _    _
\ \  / /
 \ \/ /
 / /\ \
/_/  \_\


Y.

 _    _
\ \  / /
 \_\/_/
   | |
   |_|

Z.

 _____
|__   |
|  / /
  / /___
 |______|

Q.

  ____ 
 /  _ \
|  (_| |
 \ __  |
     |_|

=item * Example for dot and colon

dot.

 _
(_)

colon.

 _
(_)
 _
(_)

=item * Example for Number

2.

 ____    
|___ \   
  __) |  
 / __    
|_____|  

=back

=head1 AUTHOR

Lei Xue (carmark@cpan.org/carmark.xue@gmail.com)

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Lei Xue

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

I love my girl, XiaoFu!


=cut
