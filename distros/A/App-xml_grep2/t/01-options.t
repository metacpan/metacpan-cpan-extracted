#!/usr/bin/perl

use strict;
use warnings;

use utf8;
use XML::LibXML;

binmode STDOUT, ':utf8';
binmode STDERR, ':utf8';

use Test::More tests => 90;

sub is_fuzzy($$$);

my $PERL= $^X;
my $OS  = $^O;
my $WIN = $OS =~ m{^MSWin} ? 1 : 0;

my $XML_GREP2 = "$PERL bin/xml_grep2";
my $TEST_DIR  = "t";
my $TEST_FILE = "test.xml";
my $DATA      = "$TEST_DIR/$TEST_FILE";
my $HTML      = "$TEST_DIR/test.html";
my $MALFORMED = "$TEST_DIR/malformed.xml";
my $LATIN1    = "$TEST_DIR/test_latin1.lxml";
my $TMP       = "$TEST_DIR/tmp";

# used to generate coverage data even though xml_grep2 is a separate script
if( $ENV{PERL5OPT} && !$WIN) { $XML_GREP2= "PERL5OPT=$ENV{PERL5OPT} $XML_GREP2"; }

my( $Q, $QQ)=  $WIN ? ( q{"}, q{'} ) : ( q{'}, q{"});

# it's so much fun trying to be compatible with everything!
my $xel2 = qq#$Q//e1[\@id=${QQ}e1-2${QQ}]$Q#;
my $xelx = qq#$Q//e1[\@id=${QQ}e1-x${QQ}]$Q#;
my $xel1 = qq#$Q//e1[\@att1=${QQ}val2${QQ}]$Q#;
my $foo  = qq#$Q//fooq$Q#;
my $nse1 = qq#$Q//tt:e1$Q#;
my $xdoc = qq#$Q/doc$Q#;
my $xs1  = qq#$Q//s1$Q#;
my $xp   = qq#$Q//p$Q#;
my $xdocument= qq#$Q document($QQ$QQ)$Q#;

my $RECURSE= "-r --include=$Q*.xml$Q";

my $CAT  = qq{$PERL -p -e1}; # we can't assume cat is available

my $re1_2= wrapped( qq{<e1 id="e1-2" att1="val2">text e1-2</e1>});
is_fuzzy( `$XML_GREP2 $xel2 $DATA`,      $re1_2,           'default');
is_fuzzy( `$XML_GREP2 -r $xel2 $DATA`,   $re1_2,           '-r');
is_fuzzy( `$XML_GREP2 -f 0 $xel2 $DATA`, $re1_2,           '-f 0');
is_fuzzy( `$XML_GREP2 -f 1 $xel2 $DATA`, wrapped( qq{  <e1 id="e1-2" att1="val2">text e1-2</e1>}), '-f 1');
is_fuzzy( `$XML_GREP2 -f 2 $xel2 $DATA`, wrapped( qq{  <e1 id="e1-2" att1="val2">text e1-2</e1>}), '-f 2');
is_fuzzy( `$XML_GREP2 -x $xel2 $DATA`,   qq{<e1 id="e1-2" att1="val2">text e1-2</e1>\n},           '-x'  );
 
is_fuzzy( `$XML_GREP2 -t $xel2 $DATA`,       "text e1-2\n", '-t option'); 
is_fuzzy( `$XML_GREP2 -t $xel2 $DATA`,       "text e1-2\n", '-text_only option');
is_fuzzy(  `$XML_GREP2 -c $xel2 $DATA`,      "1\n",         '-c option');
is_fuzzy(  `$XML_GREP2 --count $xel2 $DATA`, "1\n",         '--count option');
is_fuzzy(  `$XML_GREP2 -c $foo $DATA`,       "0\n",         '-c option (no result)');

is_fuzzy( `$XML_GREP2 -g $xel2 $DATA`, $re1_2, '-g');
is_fuzzy( `$XML_GREP2 -g $xelx $DATA`, wrapped( '' ), '-g no result');

my $hit_on_file= file_wrapped( qq{<e1 id="e1-2" att1="val2">text e1-2</e1>});
is_fuzzy( `$XML_GREP2 -H $xel2 $DATA`, wrapped( $hit_on_file), '-H 1 file');
is_fuzzy( `$XML_GREP2 -H $xel2 $DATA $DATA`, wrapped( join( "\n", $hit_on_file, $hit_on_file)), '-H 2 files');

$hit_on_file= qq{<e1 id="e1-2" att1="val2">text e1-2</e1>};
is_fuzzy( `$XML_GREP2 -h $xel2 $DATA $DATA`, wrapped( join( "\n", $hit_on_file, $hit_on_file)), '-h 2 files');

$hit_on_file= "$DATA:text e1-2\n";
is_fuzzy( `$XML_GREP2 -H -t $xel2 $DATA`, $hit_on_file, '-H -t 1 file');
is_fuzzy( `$XML_GREP2 -H -t $xel2 $DATA $DATA`, $hit_on_file x 2, '-H -t 2 files');
is_fuzzy( `$XML_GREP2 -t $xel2 $DATA $DATA`, $hit_on_file x 2, '2 files');

is( `$XML_GREP2 -l $xel2 $DATA`, "$DATA\n", '-l');
is( `$XML_GREP2 -l $xelx $DATA`, "", '-l no hits');
is( `$XML_GREP2 -L $xel2 $DATA`, "", '-L');
is( `$XML_GREP2 -L $xelx $DATA`, "$DATA\n", '-L no hits');

is_fuzzy( `$XML_GREP2 -m 1 -t $xel2 $DATA $DATA`, "$DATA:text e1-2\n$DATA:text e1-2\n", '-m 1 -t');
is_fuzzy( `$XML_GREP2 -m 5 -t $xel2 $DATA $DATA`, "$DATA:text e1-2\n$DATA:text e1-2\n", '-m 5 -t (a single hit)');
is_fuzzy( `$XML_GREP2 -g -m 1 $xel1 $DATA`, wrapped( qq{<e1 id="e1-1" att1="val2">text e1-1</e1>}), '-g -m 1');
$hit_on_file= file_wrapped( qq{<e1 id="e1-1" att1="val2">text e1-1</e1>});
is_fuzzy( `$XML_GREP2 -g -m 1 $xel1 $DATA $DATA`, wrapped( join( "\n", $hit_on_file, $hit_on_file)), '-g -m 1 2 files');


is( `$XML_GREP2 -s $foo no_file`, '', 'unexisting file, -s');
is( `$XML_GREP2 $foo no_file 2>&1`, "xml_grep2: no_file: No such file or directory\n", 'unexisting file');
is( `$XML_GREP2 $foo no_file 2>&1`, "xml_grep2: no_file: No such file or directory\n", 'unexisting file, -q');

is( `$XML_GREP2 -v -c 2>&1`, "cannot use -v, --invert-match and -c, --count\n", 'incompatible options -v and -c');
is( `$XML_GREP2 -v -t 2>&1`, "cannot use -v, --invert-match and -t, --text-only\n", 'incompatible options -v and -t');
is( `$XML_GREP2 -v -m 1 2>&1`, "cannot use -v, --invert-match and -m, --max-count\n", 'incompatible options -v and -m');

is( `$XML_GREP2 -N tt=http://xmltwig.org/xg -t $nse1 $DATA`, "text e1-7\n", '-N');

(my $v= `$XML_GREP2 -v -x '//s1' $DATA`)=~ s{>\s*<}{><}g;
is( $v, qq{<?xml version="1.0"?><doc></doc>\n\n}, '-v');

is( `$XML_GREP2 -t -r --include $TEST_FILE $xel2 $TEST_DIR`, "text e1-2\n", '-r');
is( `$XML_GREP2 -t -r --include $TEST_FILE --exclude $TEST_FILE $xel2 $TEST_DIR`, "", '-r --exclude');

like( `$XML_GREP2 -t -r $xel2 $TEST_DIR/* 2>&1`, qr{^xml_grep2: .*?parser error.*?\n$DATA:text e1-2\n}s, 'unparsable file');
is( `$XML_GREP2 -s -t -r $xel2 $TEST_DIR/* 2>&1`, "$DATA:text e1-2\n", '-s, unparsable file');

is( `$XML_GREP2 --unexisting-option 2>&1`, "Unknown option: unexisting-option\n", 'wrong option');
like( `$XML_GREP2 --help`, qr{OPTIONS}i, '--help');
like( `$XML_GREP2 --man`,  qr{EXAMPLES}i, '--man');
is( `$XML_GREP2 2>&1`, "xml_grep2 [options] <xpath> <files>\n", 'usage');

is_fuzzy( `$CAT $DATA | $XML_GREP2 -t $xel2`, "text e1-2\n", '-t, from stdin');
is_fuzzy( `$CAT $DATA | $XML_GREP2 -l $xel2`, "(stdin)\n", '-l, from stdin');
is_fuzzy( `$CAT $DATA | $XML_GREP2 --label=toto -l $xel2`, "toto\n", '--label');

my $rep_ns= "bar";
(my $re1_2_ns= $re1_2)=~ s{xg2}{$rep_ns}g;
is_fuzzy( `$XML_GREP2 -n $rep_ns $xel2 $DATA`, $re1_2_ns, '-n');

($re1_2_ns=  wrapped( file_wrapped( q{<e1 id="e1-2" att1="val2">text e1-2</e1>})))=~ s{xg2}{$rep_ns}g;
is_fuzzy( `$XML_GREP2 -n $rep_ns -H $xel2 $DATA`, $re1_2_ns, "-H -n $rep_ns");
$re1_2_ns=~ s{$rep_ns:}{}g;
$re1_2_ns=~ s{ xmlns:$rep_ns="[^"]*"}{}g;
is_fuzzy( `$XML_GREP2 -n '' -H $xel2 $DATA`, $re1_2_ns, "-H -n no name space");

is(  `$XML_GREP2 -q $xel2 $DATA`, '', '-q');
ok(  !system( "$XML_GREP2 -q $xel2 $DATA"), '-q (exit code)');
is(  `$XML_GREP2 -q -c $xel2 $DATA`, '', '-q -c');
ok(  !system( "$XML_GREP2 -q -c $xel2 $DATA"), '-q -c (exit code)');

is(  `$XML_GREP2 -q $foo $DATA`, '', '-q no hit');
ok(  system( "$XML_GREP2 -q $foo $DATA"), '-q no hit (exit code)');
is(  `$XML_GREP2 -q -c $foo $DATA`, '', '-q -c no hit');
ok(  system( "$XML_GREP2 -q -c $foo $DATA"), '-q -c no hit (exit code)');
is(  `$XML_GREP2 -q -t $foo $DATA`, '', '-q -c no hit');
ok(  system( "$XML_GREP2 -q -t $foo $DATA"), '-q -c no hit (exit code)');

is(  `$XML_GREP2 -q -v $xel2 $DATA`, '', '-q -v');
is(  system( "$XML_GREP2 -q $xel2 $DATA"), 0, '-q -v (exit code)');
is(  `$XML_GREP2 -q -v $xdoc $DATA`, '', '-q -v on doc');
ok(  system( "$XML_GREP2 -q -v $xdoc $DATA"), '-q -v on doc (exit code)');
is(  `$XML_GREP2 -q -v $xdocument $DATA`, '', '-q -v entire document');
ok(  system( "$XML_GREP2 -q -v $xdocument $DATA"), '-q -v entire document (exit code)');
is(  `$XML_GREP2 -q -v $foo $DATA`, '', '-q -v regular hit');
is(  system( "$XML_GREP2 -q -v $foo $DATA"), 0, '-q -v regular hit (exit code)');

like( `$XML_GREP2 $RECURSE -c $xdoc $TEST_DIR 2>&1`, 
    qr{xml_grep2: t/malformed.xml:2: parser error : Premature end of data in tag doc line 1\n},
    'malformed XML'
  );
is( `$XML_GREP2 $RECURSE -c -s $xdoc $TEST_DIR 2>&1`, "t/test.xml:1\n", 'malformed XML (-s)');

is( `$XML_GREP2 $RECURSE -q $xdoc $TEST_DIR 2>&1`, '', '-q with malformed XML');
is(  system( "$XML_GREP2 $RECURSE -q $xdoc $TEST_DIR 2>&1"), 0, '-q with malformed XML (exit code)');
is( `$XML_GREP2 $RECURSE -q $foo $TEST_DIR 2>&1`, '', '-q with malformed XML, no hit');
ok(  system( "$XML_GREP2 $RECURSE -q $foo $TEST_DIR 2>&1"), '-q with malformed XML, no hit (exit code)');

like( `$XML_GREP2 -v $foo $MALFORMED 2>&1`, qr{xml_grep2: t/malformed.xml:2: parser error : Premature end of data in tag doc line 1}, '-v on malformed data');
is( `$XML_GREP2 -v -s $foo $MALFORMED 2>&1`, '', '-v -s on malformed data');

is( `$CAT $DATA | $XML_GREP2 -v $xdoc`, '', '-v on entire doc');
like( `$CAT $DATA | $XML_GREP2 -v $xs1`, qr{<\?xml[^>]*>\s*<doc>\s*</doc>\s*$}, '-v on entire doc');

like( `$XML_GREP2 -v -X $xs1 $DATA`, qr{<\?xml version="1.0" encoding="UTF-8"\?>\s*<xg2:result_set xmlns:xg2="http://xmltwig.org/tools/xml_grep2/">\s*<doc>\s*</doc>\s*</xg2:result_set>\s*}, '-v -X');
is(  `$XML_GREP2 -v $xdocument $DATA`, '', '-q entire document');

test_encoding( "$XML_GREP2 -t $xs1 $LATIN1",    "été\n", "utf-8", "-t latin1 input, utf8 output");
test_encoding( "$XML_GREP2 -t -o $xs1 $LATIN1", "été\n", "iso-8859-1", "-t latin1 input, latin1 output");

test_encoding( "$XML_GREP2    $xs1 $LATIN1", wrapped( "<s1>été</s1>"), 'UTF-8', "latin1 input, utf8 output");
test_encoding( "$XML_GREP2 -o $xs1 $LATIN1", wrapped( "<s1>été</s1>", 'ISO-8859-1'), 'ISO-8859-1', "latin1 input, latin1 output");
test_encoding( "$XML_GREP2 -H -o $xs1 $LATIN1", wrapped( file_wrapped( qq{<s1>été</s1>}, $LATIN1), 'ISO-8859-1'), 'ISO-8859-1', "-H -o latin1");
test_encoding( "$XML_GREP2 -f 1 -H -o $xs1 $LATIN1", wrapped( file_wrapped( qq{    <s1>été</s1>}, $LATIN1), 'ISO-8859-1'), 'ISO-8859-1', "-H -o -f 1 latin1");

my $mode= 0000; chmod $mode, $MALFORMED or die "cannot chmod $mode $MALFORMED: $!";
is( `$XML_GREP2 $RECURSE $foo $TEST_DIR 2>&1`, "xml_grep2: $MALFORMED: Permission denied\n", 'test on unreadable file');
$mode= 0644; chmod $mode, $MALFORMED or die "cannot chmod $mode $MALFORMED: $!";

# prepare the catalog (make uri absolute)
system "$PERL -p -e$Q use Cwd; s{PWD}{cwd()}ge;$Q t/catalog.templ > t/catalog";
is( `$XML_GREP2 -t -C $TEST_DIR/catalog $xs1 $TEST_DIR/with_cat.cxml`, "entity c \n", "-C");

is( `$XML_GREP2 --html -t $xp $HTML`, "bar\n", '--html');
is( `$CAT $HTML | $XML_GREP2 --html -t $xp `, "bar\n", '--html (from STDIN)');



my $version= `$XML_GREP2 -V 1 2>&1`;
chomp $version;
like( `$XML_GREP2 -V 1 2>&1`, qr{xml_grep2 version \d+\.\d+$}, "version '$version' looks ok");


sub test_encoding
  { my( $command, $expected, $encoding, $message)= @_;
    unlink $TMP if -f $TMP;
    system( "$command > $TMP") && die "grep error: $@";
    binmode STDIN; 
    my $got= do { undef $/; open( my $in, "<:encoding($encoding)", $TMP) or die "error opening $TMP: $!"; <$in>; };
    is_fuzzy ( $got, $expected, $message);
    binmode STDIN, ':utf8'; 
   }



sub wrapped
  { my( $result, $encoding)= @_;
    return xmldecl( $encoding) . qq{<xg2:result_set xmlns:xg2="http://xmltwig.org/tools/xml_grep2/">$result</xg2:result_set>\n};
  }

sub xmldecl
  { my($encoding)= @_;
    $encoding ||= 'UTF-8';
    return qq{<?xml version="1.0" encoding="$encoding"?>};
  }

sub file_wrapped
  { my( $to_wrap, $file)= @_;
    $file ||= $DATA; 
    return qq{<xg2:file xg2:filename="$file">$to_wrap</xg2:file>};
  }

sub trace
  { my $command= join( ' ', @_);
    if( grep /-v/, $ARGV[0]) { warn "$command\n"; }
    return `$command`;
  }

sub is_fuzzy($$$)
  { my( $got, $expected, $message)= @_;
    (my $stripped_expected= $expected)=~ s{\s}{}g;
    (my $stripped_got= $got)=~ s{\s}{}g;
    if( $stripped_got eq $stripped_expected)
      { ok( 1, $message); }
    else
      { ok( 0, $message);
        warn "  got     : $got\n  expected:$expected\n";
        #warn "  got     : $stripped_got\n  expected: $stripped_expected\n";
      }
  }
    
