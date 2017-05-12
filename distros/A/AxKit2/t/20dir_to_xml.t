#!/usr/bin/perl

use utf8;
use AxKit2::Test;

# We need to set up the test files manually as SVN's control files would otherwise break the tests.
rmdir('t/server1/dir/test');
if (mkdir('t/server1/dir/test')) {
    plan tests => 5;

    mkdir('t/server1/dir/1');
    mkdir('t/server1/dir/2');
    mkdir('t/server1/dir/3');
    mkdir('t/server1/dir/4');
    mkdir('t/server1/dir/5');

    open(X,'>','t/server1/dir/2/test');
    close(X);

    mkdir('t/server1/dir/3/test');
} else {
    plan skip_all => 'Could not setup test environment';
}

start_server("t/server1",
    [qw(uri_to_file dir_to_xml demo/serve_xslt)],
    ['XSLT_Style t/server1/style/identity.xsl','XSLT_Match .']
);

sub dir {
    return '^<\?xml version="1\.0"\?>
<filelist xmlns="http://axkit\.org/2002/filelist">
'.join("\n",@_).'
</filelist>$';
}

sub entry {
    my ($type, $name, $regex) = @_;
	if (!$regex) {
        $name =~ s/\\/\\\\/g;
        $name =~ s/([][().?*+])/\\$1/g;
    }
    return '<'.$type.' size="[0-9]*" atime="[0-9]*" mtime="[0-9]*" ctime="[0-9]*"' .
        '(?: readable="1")?(?: writable="1")?(?: executable="1")?>' .
        $name . '</' . $type . ">";
}

# If we parse and sort the resulting XML, we could do tests that may differ in order.
content_matches('/dir/1/',dir(entry('directory','.'),entry('directory','..')),
    'empty directory');
content_matches('/dir/2/',dir(entry('directory','.'),entry('directory','..'),entry('file','test')),
    'directory with file content');
content_matches('/dir/3/',dir(entry('directory','.'),entry('directory','..'),entry('directory','test')),
    'directory with dir content');

# this cannot safely be transported in SVN and it may fail on some platforms; moreover, check different normalization forms
if (do { no utf8; use bytes; open(X,'>','t/server1/dir/4/testä'); }) {
    content_matches('/dir/4/',dir(entry('directory','.'),entry('directory','..'),entry('file','test(?:ä|a\x{0308}|a&#x308;)',1)),
        'directory with UTF-8 content');
} else {
    skip($!);
}

# likewise
if (do { no utf8; use bytes; open(X,'>',"t/server1/dir/5/test\xa4"); }) {
    content_matches('/dir/5/',dir(entry('directory','.'),entry('directory','..'),entry('file',"test\x{20ac}")),
        'directory with ISO-8859-15 content');
} else {
    skip($!);
}

close(X);

# be nice, clean up
rmdir('t/server1/dir/1');
unlink('t/server1/dir/2/test');
rmdir('t/server1/dir/2');
rmdir('t/server1/dir/3/test');
rmdir('t/server1/dir/3');
do { no utf8; use bytes; unlink('t/server1/dir/4/testä'); };
rmdir('t/server1/dir/4');
do { no utf8; use bytes; unlink("t/server1/dir/5/test\xa4"); };
rmdir('t/server1/dir/5');
