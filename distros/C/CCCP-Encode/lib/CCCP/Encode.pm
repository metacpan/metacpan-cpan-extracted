package CCCP::Encode;

use strict;
use warnings;

use Encode;
use Text::Unidecode;

our $VERSION = '0.03';

$CCCP::Encode::ToText = 0;
$CCCP::Encode::Entities = 'xml';
$CCCP::Encode::CharMap = {};
$CCCP::Encode::Regexp = '[^\p{Cyrillic}|\p{IsLatin}|\p{InBasic_Latin}]';

my $xml_entities = {
	'&' => '&amp;',
	'"' => '&#x22;',
	"'" => '&#x27;',
	'>' => '&gt;',
	'<' => '&lt;'
};

my $f = find_encoding('utf-8');
my $t = undef;
__err_msg("Unknown encoding 'utf-8'") unless defined $f;

sub utf2cyrillic {
    my ( $class, $str, $to ) = @_;
    
    if ($CCCP::Encode::ToText and not UNIVERSAL::isa($CCCP::Encode::CharMap,'HASH') ) {
        __err_msg("\$CCCP::Encode::CharMap must be hash ref");
    };
    
    return undef unless defined $str;
    
    __err_msg("missing 'to' argument") unless $to;
    return $str if ($to =~ /^utf/i);

    $t = find_encoding($to) unless ($t and $t->name eq $to);
    __err_msg("Unknown encoding '$to'") unless defined $t;
	
    Encode::_utf8_off($str);
    
    unless ($CCCP::Encode::ToText) {
	    # decode with html entities
        $CCCP::Encode::Entities ||= 'xml';
    	my $str = $t->encode($f->decode($str), $CCCP::Encode::Entities eq 'xml' ? Encode::FB_XMLCREF : Encode::FB_HTMLCREF);
    	if ($CCCP::Encode::Entities eq 'xml') {
    		$str =~ s/('|"|<|>|&(?!#x))/$xml_entities->{$1}/geo;
    	};
    	return $str;
    } else {
    	# decode in text mode
	    ($str = $f->decode($str)) =~ s/($CCCP::Encode::Regexp)/exists $CCCP::Encode::CharMap->{$1} ? $CCCP::Encode::CharMap->{$1} : unidecode($1)/sexg;
	    return $t->encode($str);
    };
}

sub __err_msg {
	my ($str) = @_;
	
    require Carp;
    Carp::croak(__PACKAGE__.": ".$str);	
}

1;
__END__

=encoding utf-8

=head1 NAME

B<CCCP::Encode> - Perl extension for character encodings from utf-8 to any cyrillic (koi8-r, windows-1251, etc.)

I<Version 0.03>

=head1 SYNOPSIS
    
    use CCCP::Encode;
    
    $CCCP::Encode::ToText = 0; # default
    $CCCP::Encode::Entities = 'xml'; # default    
    my $str = "если в слове 'хлеб' поменять 4 буквы, то получится — ПИВО";
    print CCCP::Encode->utf2cyrillic($str,'koi8-r');
    # output in koi8-r:
    # если в слове &#x27;хлеб&#x27; поменять 4 буквы, то получится &#x2014; ПИВО
    
    $str = "Иероглифы: 牡 マ キ グ ナ ル フ";
    print CCCP::Encode->utf2cyrillic($str,'windows-1251');
    # output in windows-1251:
    # Иероглифы: &#x7261; &#x30de; &#x30ad; &#x30b0; &#x30ca; &#x30eb; &#x30d5; 
	
	--------------------------
	
	$CCCP::Encode::ToText = 0; # default
	$CCCP::Encode::Entities = 'html';	     
    print CCCP::Encode->utf2cyrillic($str,'koi8-r');
    # output in koi8-r:
    # если в слове 'хлеб' поменять 4 буквы, то получится &#8212; ПИВО

    $str = "Иероглифы: 牡 マ キ グ ナ ル フ";
    print CCCP::Encode->utf2cyrillic($str,'windows-1251');
    # output in windows-1251:
    # Иероглифы: &#29281; &#12510; &#12461; &#12464; &#12490; &#12523; &#12501;
    
    --------------------------
    	 
    $CCCP::Encode::ToText = 1;
    print CCCP::Encode->utf2cyrillic($str,'koi8-r');
    # output in koi8-r:
    # если в слове 'хлеб' поменять 4 буквы, то получится -- ПИВО  
    
    $CCCP::Encode::CharMap = {"\x{2014}" => '-'};
    print CCCP::Encode->utf2cyrillic($str,'koi8-r');
    # output in koi8-r:
    # если в слове 'хлеб' поменять 4 буквы, то получится - ПИВО  
    
=head1 DESCRIPTION

This module convert utf string to cyrillic in two mode:

=over 4

=item *

convert to cyrillic string with html entites,

=item *

convert to cyrillic string to only plain/text character.

=back

By default for unknown character used C<HTML::Entities> for html entites and for plain/text encoding used C<Text::Unidecode>.
You can override the map to encoding for any character.
And can override regexp for replace character.

=head2 INTRODUCTION

Ajax library (on frontend) send data in utf-8. If you have backend on C<koi8-r>, C<windows-1251>, etc. You have problem:

    use Encode;
    ...
    my $data = $post->param('any');
    # $data = "если в слове 'хлеб' поменять 4 буквы, то получится — ПИВО";
    Encode::from_to($data,'utf-8','koi8-r');
    print $data;
    # output:
    # если в слове 'хлеб' поменять 4 буквы, то получится ? ПИВО

Method C<from_to> from module C<Encode> replace uncnown character on 'B<?>'. This data go to save in your database.
And you write a guano-magic code for fixing this problem. 
All developers, who have database not in utf, known about this problem.  

And another case:

Getting data from rss-channels in utf-8 and saving in C<cyrillic> database 
(for example mysql with default charset C<koi8-r> or C<windows-1251>).

B<CCCP::Encode> fix this problem.

=head2 METHODS

=head3 utf2cyrillic($str,$to)

C<$str> target string. C<$to> encoding name, analogue C<$to> in C<Encode::from_to($str,'utf-8',$to)> 

=head2 PACKAGE VARIABLES

=head3 $CCCP::Encode::Entities

Ignored if $CCCP::Encode::ToText is true.
Default value 'xml'.
'xml' mode - replace all uncnown character in traget charset to valid xml numeric entities (i.e. &#x2014;).
'html' mode - replace all uncnown character in traget charset to html numeric entities (i.e. &#8212;).

=head3 $CCCP::Encode::ToText

Default is false. 

If C<$CCCP::Encode::ToText> is false, when C<utf2cyrillic> 
return decode string whis replace uncnown character from you definition (see C<$CCCP::Encode::CharMap>) 
or html entities from C<HTML::Entities>.

If C<$CCCP::Encode::ToText> is true, when C<utf2cyrillic> 
return decode string in plain/text format whis replace uncnown character from you definition (see C<$CCCP::Encode::CharMap>) 
or used C<Text::Unidecode>.

=head3 $CCCP::Encode::CharMap

Default is empty hashref. 

You can custom define map for any characters. 
This is wery flexible if you need custom replace (different of C<HTML::Entities> or C<Text::Unidecode>).
Example:

    $CCCP::Encode::CharMap = {
    	"\x{2014}" => '-',
    	"\x{2015}" => 'foo'
    };

=head3 $CCCP::Encode::Regexp

By default value is C<[^\p{Cyrillic}|\p{IsLatin}|\p{InBasic_Latin}]>  - replace any character which not in Cyrillic or Latin map exist. 
You can override this expression. 

See more on C<http://www.regular-expressions.info/unicode.html>

=head1 OVERHEAD

    CCCP::Encode with $CCCP::Encode::Entities eq "html":  
        2 wallclock secs ( 1.63 usr +  0.01 sys =  1.64 CPU) @ 60975.61/s (n=100000)
    
    CCCP::Encode with $CCCP::Encode::Entities eq "xml":  
        3 wallclock secs ( 2.49 usr +  0.00 sys =  2.49 CPU) @ 40160.64/s (n=100000)
    
    CCCP::Encode with $CCCP::Encode::ToText eq "1":  
        4 wallclock secs ( 3.85 usr +  0.02 sys =  3.87 CPU) @ 25839.79/s (n=100000)
            
    Encode::from_to(...) :  
        2 wallclock secs ( 1.93 usr +  0.01 sys =  1.94 CPU) @ 51546.39/s (n=100000)

=head1 SEE ALSO

=over 4

=item *

C<Encode>

=item *

C<Text::Unidecode>

=back

=head1 AUTHOR

Ivan Sivirinov

=cut
