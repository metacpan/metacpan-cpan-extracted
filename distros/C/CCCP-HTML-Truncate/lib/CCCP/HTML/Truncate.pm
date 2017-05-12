package CCCP::HTML::Truncate;

use strict;
use warnings;

use XML::LibXML;
use Encode qw();

our $VERSION = '0.04';

$CCCP::HTML::Truncate::enc = 'utf-8';

# ------------------------ EXTEND XML::LibXML::Element -----------------
# return serialize XML::LibXML::Element in correct encoding
sub XML::LibXML::Element::html {
    my ($node, $actualEncoding) = @_;
    
    # correct decode
    my $f = Encode::find_encoding($CCCP::HTML::Truncate::enc || $node->ownerDocument->encoding() || $node->ownerDocument->actualEncoding());
    
    return $f->encode($node->toString,Encode::FB_XMLCREF);
}

# ---------------------------------------- MAIN --------------------------------------------

# parser obj
my $lx;

sub _init_parser {
    return if $lx;
    $lx = XML::LibXML->new();
    $lx->recover_silently(1);
}

# truncate html
sub truncate {
    my ($class,$html_str,$length,$elips) = @_;
    
    return unless $html_str;
    
    $elips ||= "...";
    
    $length ||= 0;
    $length =~ /(\d+)/;
    $length = $1 ? $1 : 0;
    return '' unless $length;
    $html_str =~ s/&amp;/&/gm;
    return $html_str if length $html_str < $length;
    
    my $f = Encode::find_encoding($CCCP::HTML::Truncate::enc);
    $html_str = $f->decode($html_str);
    $elips = $f->decode($elips);
    
    $class->_init_parser();
    my $root = $lx->parse_html_string($html_str);
    my ($body) = $root->documentElement()->findnodes('//body');
    return '' unless $body;
    
    my $add_elips = 0;
    foreach ($body->ownerDocument->findnodes('//child::text()')) {
        if ($length>0) {
            my $str = $_->to_literal;
            my $new_str = substr($str,0,$length);
            $length -= length $str;
            if ($length < 1 and not $add_elips) {
                $new_str .= $elips;
                $add_elips++;
                # and skip all another text child
                my $text_parent = $_->parentNode;                               
                if ($_->nodePath =~ /\[(\d+)]$/) {
                    foreach my $skip_text ($text_parent->findnodes(sprintf('//child::text()[position()>%d]',$1))) {
                        $_->setData('');
                    };
                }
            };
            $_->setData($new_str);          
        } else {
            my $parent = $_->parentNode;
            # add elips
            unless ($add_elips) {
                $add_elips++;
                my $elips_el = XML::LibXML::Element->new('span');
                $elips_el->appendTextNode($elips);
                $parent->addChild($elips_el);
            };
            # skip body
            if ($parent->isSameNode($body)) {
                $_->unbindNode();
            } else {
                my @childs = $parent->findnodes($parent->nodePath.'//child::text()');
                $#childs > 0 ? $_->unbindNode() : $parent->unbindNode();                
            }
        }
    };
    
    my $ret = $body->html();
    $ret =~ s/^<body(.*?)>(<p>)?|(<\/p>)?<\/body>$//igm;
    return $ret; 
}

1;
__END__
=encoding utf-8

=head1 NAME

B<CCCP::HTML::Truncate> - truncate html with html-entities.

I<Version 0.04>

=head1 SYNOPSIS
    
    CCCP::HTML::Truncate;
    
    my $str = "<div>Тут могут быть <b>&mdash; разные entities и &quot; всякие</b> и,\n\n незакрытые теги <div> bla ... bla";
    
    print CCCP::HTML::Truncate->truncate($str,20);
    # <div>Тут могут быть <b>— раз...</b></div>
    
    print CCCP::HTML::Truncate->truncate($str,20,'...конец');
    # <div>Тут могут быть <b>— раз...конец</b></div>
    
=head1 DESCRIPTION

Truncate html string. 
Correct job with html entities.
Validate truncated html.

=head1 METHODS

=head3 truncate($str,$length,$elips)

Class method.
Return truncated html string.

=head1 PACKAGE VARIABLES

=head3 $CCCP::HTML::Truncate::enc

Charset for source html.
Default 'utf-8'.

=head1 BENCHMARK

	Benchmark: timing 10000 iterations of CCCP::HTML::Truncate, HTML::Truncate...
	CCCP::HTML::Truncate:  4 wallclock secs ( 4.55 usr +  0.00 sys =  4.55 CPU) @ 2197.80/s (n=10000)
	HTML::Truncate:        5 wallclock secs ( 4.86 usr +  0.00 sys =  4.86 CPU) @ 2057.61/s (n=10000)
	
	Benchmark: timing 25000 iterations of CCCP::HTML::Truncate, HTML::Truncate...
	CCCP::HTML::Truncate: 12 wallclock secs (11.37 usr +  0.00 sys = 11.37 CPU) @ 2198.77/s (n=25000)
	HTML::Truncate:       12 wallclock secs (12.12 usr +  0.01 sys = 12.13 CPU) @ 2061.01/s (n=25000)


=head1 WARNING

Version oldest 0.04 is DEPRECATED 

=head1 SEE ALSO

C<XML::LibXML>, C<Encode>

=head1 AUTHOR

Ivan Sivirinov

=cut
