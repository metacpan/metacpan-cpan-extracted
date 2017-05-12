package DTL::Fast::Filter::Urlize;
use strict; use utf8; use warnings FATAL => 'all'; 
use parent 'DTL::Fast::Filter';

$DTL::Fast::FILTER_HANDLERS{'urlize'} = __PACKAGE__;

use DTL::Fast::Utils qw(unescape);

our $DOMAINS_RE = qr/com|org|net|gov|mil|biz|info|mobi|name|aero|jobs|museum|travel|ru|рф|[a-z]{2,3}/;

our $URL_RE = qr
{
    (?:(?:http|ftp|https)\://)?  # protocol
    (?:\w+\:\w+\@)?              # username and password
    (?:(?:www|ftp)\.)?           # domain prefixes
    (?:[-\w]+\.)+                # domain name
    (?:$DOMAINS_RE)              # top level domain
    (?:\:\d{1,5})?               # port number
    (?:/[-\w~._]*)*?             # directories and files
    (?:\?[^\s#]+?)?              # query string no spaces or sharp
    (?:\#[^\s]+?)?               # anchor
}x;

our $EMAIL_RE = qr
{
    (?:[-\w_~\.]+\@)             # user name
    (?:[-\w]+\.)+                # domain name
    (?:$DOMAINS_RE)              # top level domain
}x;

#@Override
sub filter
{
    my $self = shift;  # self
    my $filter_manager = shift;  # filter_manager
    my $value = shift;  # value
    shift;    #context
    
    $value =~ s
    {
        (?:($EMAIL_RE)|($URL_RE))
        ($|\s|\.|,|!)                   # after link
    }{
        $self->wrap_email($1,$3).$self->wrap_url($2,$3)
    }gxesi;
    
    $filter_manager->{'safe'} = 1;
    
    return $value;
}

sub wrap_url
{
    my $self = shift;
    my $text = shift;
    return '' if not $text;
    my $appendix = shift // '';
    
    my $uri = $text;
    $uri = 'http://'.$uri if
        $uri !~ m{^(http|ftp|https)://}i;
        
    return sprintf '<a href="%s" rel="nofollow">%s</a>%s'
        , $uri // 'undef'
        , DTL::Fast::html_protect(unescape($self->normalize_text($text)))
        , $appendix
        ;
}

sub wrap_email
{
    my $self = shift;
    my $text = shift;
    return '' if not $text;
    my $appendix = shift // '';
    
    my $uri = $text;
    
    return sprintf '<a href="mailto:%s" rel="nofollow">%s</a>%s'
        , $uri
        , DTL::Fast::html_protect(unescape($self->normalize_text($text)))
        , $appendix
        ;
}

sub normalize_text
{
    shift;
    return shift;
}

1;