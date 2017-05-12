#!perl
use strict;
use utf8;
use warnings qw(all);

use Test::More;
use URI;
use URI::URL;

BEGIN {
    $ENV{ANSI_COLORS_DISABLED} = 1;
    delete $ENV{DATAPRINTERRC};
    use File::HomeDir::Test;
};

use Data::Printer {
    filters => {
        q(-external) => q(URI),
    },
};

my %cover = map {
    m{^(?:URL|urn::oid)$}x
        ? ()
        : ($_ => 1)
} @Data::Printer::Filter::URI::schemes;

my @uri = map { chomp; URI->new($_) } <DATA>;
push @uri, url(q(http://ifconfig.me));

for my $uri (@uri) {
    is(p($uri), qq($uri), $uri->canonical);

    my $scheme = $uri->scheme;
    delete $cover{$scheme};
}

is(%cover, 0, q(all schemes covered));
diag $_ for sort keys %cover;

done_testing 1 + @uri;

# https://en.wikipedia.org/wiki/Uniform_resource_name
# ack -h --output '$2' "\bURI->new\(([\"'])(\w+:.+?)\1\)" ~/URI-1.60/t/ | sort -u

__DATA__
data:,A%20brief%20note
data:;base64,%51%6D%70%76%5A%58%4A%75
data:application/vnd-xxx-query,select_vcount,fcol_from_fieldtable/local
data:foo
data:image/gif;base64,R0lGODdhMAAwAPAAAAAAAP///ywAAAAAMAAwAAAC8IyPqcvt3wCcDkiLc7C0qwyGHhSWpjQu5yqmCYsapyuvUUlvONmOZtfzgFzByTB10QgxOR0TqBQejhRNzOfkVJ+5YiUqrXF5Y5lKh/DeuNcP5yLWGsEbtLiOSpa/TPg7JpJHxyendzWTBfX0cxOnKPjgBzi4diinWGdkF8kjdfnycQZXZeYGejmJlZeGl9i2icVqaNVailT6F5iJ90m6mvuTS4OK05M0vDk0Q4XUtwvKOzrcd3iq9uisF81M1OIcR7lEewwcLp7tuNNkM3uNna3F2JQFo97Vriy/Xl4/f1cf5VWzXyym7PHhhx4dbgYKAAA7
data:text/plain;charset=iso-8859-7,%be%fg%be
file:///etc/passwd
ftp://ftp.example.com/path
ftp://ftp:@[3ffe:2a00:100:7031::1]
ftp://gisle@aas.no:secret@ftp.example.com/path
gopher://host
gopher://host/7foo%09bar%20baz
gopher://host/7foo	bar%20baz
gopher://host:123/7foo
gopher://host:70
gopher://host:70/
gopher://host:70/1
http://%77%77%77%2e%70%65%72%6c%2e%63%6f%6d/%70%75%62/%61/%32%30%30%31/%30%38/%32%37/%62%6a%6f%72%6e%73%74%61%64%2e%68%74%6d%6c
http://[::1]
http://[FEDC:BA98:7654:3210:FEDC:BA98:7654:3210]:80/index.html
http://Bücher.ch
http://example.com/B%FCcher
http://example.com/Bücher
http://foo.com
http://r%C3%A9sum%C3%A9.example.org
http://search.cpan.org
http://www.example.com/foo/bar
http://www.example.com/foo/bar/
http://www.example.org/D%C3%BCrst
http://www.example.org/D%FCrst
http://www.sol.no?foo=4&bar=5&foo=5
http://xn--99zt52a.example.org/%e2%80%ae
http://xn--rsum-bad.example.org
https://google.com/
ldap://host/dn=base?cn,sn?sub?objectClass=*
ldap://LDAP-HOST:389/o=University%20of%20Michigan,c=US?postalAddress?base?ObjectClass=*?FOO=Bar,bindname=CN%3DManager%CO%3dFoo
ldapi://%2Ftmp%2Fldap.sock/????x-mod=-w--w----
ldaps://host/dn=base?cn,sn?sub?objectClass=*
mailto:gisle@aas.no
mms://wmc1.liquidviewer.net/WEEI
news:comp.lang.perl.misc
nntp:no.perl
pop://aas@pop.sn.no
rlogin://username@somehost.com
rsync://gisle@perl.com/foo/bar
rtsp://media.example.com:554/twister/audiotrack
rtspu://media.example.com/twister/audiotrack
sip:phone@domain.ext
sip:phone@domain.ext;maddr=127.0.0.1;ttl=16
sip:phone@domain.ext?Subject=Meeting&Priority=Urgent
sips:b@B
snews://snews.online.no/no.perl
ssh://localhost
telnet://locis.loc.gov
tn3270:mainframe.accounting.example
urn:ietf:rfc:2648
urn:isan:0000-0000-9E59-0000-O-0000-0000-2
URN:ISBN:0395363411
urn:isbn:0451450523
urn:ISBN:abc
urn:issn:0167-6423
urn:mpeg:mpeg7:schema:2001
urn:nbn:de:bvb:19-146642
urn:oid:2.16.840
urn:uuid:6e8bc430-9c3a-11d9-9669-0800200c9a66
