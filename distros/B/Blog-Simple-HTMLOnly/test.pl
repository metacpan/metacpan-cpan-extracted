
use Test;
use strict;
use HTML::TokeParser;

BEGIN { plan tests => 13 };
use Blog::Simple::HTMLOnly;
ok(1); # If we made it this far, we're ok.

#########################
my $tmp;
foreach ($ENV{TEMP}, $ENV{TMP}, '/tmp', '/temp', '/usr/tmp', 'C:/temp'){
	next if not defined $_;
	$tmp = $_;
	last if -d $tmp;
}

if ( not defined $tmp){
	print "Skip all - no temporary directory found.\n";
	exit;
}


my $sbO = Blog::Simple::HTMLOnly->new($tmp);
ok( ref $sbO, "Blog::Simple::HTMLOnly");
$sbO->create_index(); #generally only needs to be called once

my $content = "<p>blah blah blah in XHTM</p><p><b>Better</b> when done in
HTML!</p>";
my $title = 'some title';
my $author = 'a.n. author';
my $email = 'anaouthor@somedomain.net';
my $smmry = 'blah blah';
$sbO->add($title,$author,$email,$smmry,$content);

my $format = {
	simple_blog	=> '<div class="box">',
	title 		=> '<div class="title"><b>',
	author 		=> '<div class="author">',
	email 		=> '<div class="email">',
	ts			=> '<div class="ts">',
	summary		=> '<div class="summary">',
	content		=> '<div class="content">',
};
my $html = $sbO->render_current($format,3);
ok(ref $html,'SCALAR');

my $p = HTML::TokeParser->new($html);
ok( ref $p->get_tag("b"), 'ARRAY');
ok( $p->get_trimmed_text, 'some title');

my $r = $sbO->render_all($format);
ok( ref $r, 'SCALAR');

ok( $$r =~ m|\Q<div class="box">|);
ok( $$r =~ m|\Q<div class="title"><b>some title</b></div>|);
ok( $$r =~ m|\Q<div class="author">a.n. author</div>|);
ok( $$r =~ m|\Q<div class="email">anaouthor\E\@\Qsomedomain.net</div>|);
ok( $$r =~ m|\Q<div class="ts">|);
ok( $$r =~ m|\Q<div class="summary">blah blah</div>|);
ok( $$r =~ m|\Q<div class="content"><p>blah blah blah in XHTM</p><p><b>Better</b> when|);

exit;
__END__

<div class="box">
        <div class="title"><b>some title</b></div>
        <div class="author">a.n. author</div>
        <div class="email">anaouthor@somedomain.net</div>
        <div class="ts">Thu Feb 23 15:23:00 2006</div>
        <div class="summary">blah blah</div>
        <div class="content"><p>blah blah blah in XHTM</p><p><b>Better</b> when
done in
HTML!</p></div>
</div>