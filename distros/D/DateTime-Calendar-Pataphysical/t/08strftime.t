# test suite stolen shamelessly from DateTime distro

use strict;
BEGIN { $^W = 1 }

use Test::More tests => 40;
use DateTime::Calendar::Pataphysical;

#########################

my $dt;
my $params;
while (<DATA>)
{
    chomp;
    if (/^year =>/)
    {
        $params = $_;
        $dt = eval "DateTime::Calendar::Pataphysical->new( $params, locale => 'English' )";
        next;
    }

    my ($fmt, $res) = split /\t+/,$_;

    is( $dt->strftime($fmt), $res );
}

# test use of strftime with multiple params - in list and scalar
# context
{
    my $dt = DateTime::Calendar::Pataphysical->new(
                year => 1800, month => 1, day => 10 );

    my ($y, $d) = $dt->strftime( '%Y', '%d' );
    is( $y, 1800 );
    is( $d, 10 );

    $y = $dt->strftime( '%Y', '%d' );
    is( $y, 1800 );
}

# add these if we do roman-numeral stuff
# %Od	VII
# %Oe	VII
# %OH	XIII
# %OI	I
# %Oj	CCL
# %Ok	XIII
# %Ol	I
# %Om	IX
# %OM	II
# %Oq	III
# %OY	MCMXCIX
# %Oy	XCIX

__DATA__
year => 124, month => 9, day => 7
%%	%
%A	Saturday
%B	Palotin
%C	1
%d	07
%e	 7
%D	09/07/24
%F	124-09-07
%j	239
%m	09
%u	7
%U	33
%V	33
%w	6
%W	33
%y	24
%Y	124
year => 124, month => 6, day => 29
%%	%
%A	Hunyadi
%B	Gueules
%C	1
%d	29
%e	29
%D	06/29/24
%F	124-06-29
%j	174
%m	06
%u	H
%U	  
%V	  
%w	H
%W	  
%y	24
%Y	124
%*	Mouvement Perpétuel
%z	z
%-	%-
