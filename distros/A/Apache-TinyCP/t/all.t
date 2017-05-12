#
# this is lame testing, but at least there are tests
#
package Local::FakeRequest; # Apache::FakeRequest isn't good enough
sub new {bless {}, shift};
sub dir_config { {
    ContentDir => '/path',
}->{$_[1]} }
sub uri { 
    my $self=shift;
    $self->{uri} = $_[0] if defined $_[0];
    $self->{uri};
}

#========================================================================

package main;
use Test::More 'no_plan';
use Text::KwikiFormatish;

use_ok( 'Apache::TinyCP' );

#------------------------------------------------------------------------
diag( 'testing get_filename' );

my $f = Local::FakeRequest->new;
my %urls = (
    '/Testing' => '/path/Testing',
    '/Testing' => '/path/Testing',
);

while ( my ($in,$out) = each %urls ) {
    $f->uri($in);
    is( Apache::TinyCP->get_filename($f), $out );
}

#------------------------------------------------------------------------
diag( 'testing format_content' );

is( Text::KwikiFormatish::format(<<IN), <<OUT );
== hey
*test*
IN
<h2>hey</h2>
<p>
<strong>test</strong>

</p>
OUT

#------------------------------------------------------------------------
diag( 'testing get_content_type' );

isnt( Apache::TinyCP->get_content_type, undef );
like( Apache::TinyCP->get_content_type, qr#/# );

