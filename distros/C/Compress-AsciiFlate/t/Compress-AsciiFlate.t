# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Compress-AsciiFlate.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';
use Test::More tests => 9;
BEGIN { use_ok('Compress::AsciiFlate') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

$o = new Compress::AsciiFlate;

ok(defined $o,"Object creation");

$text = q/some words some words some words some words _underscore under_score/;
$expected = q/some words _1 _2 _1 _2 _1 _2 __underscore under_score/;
$length = length($text);

$o->deflate($text);

ok($text eq $expected, 'expected output');
ok($o->olength == $length,'original length');
ok($o->dlength == length($text),'defated length');
%table = $o->table;
ok($o->count == scalar(keys %table),'table count');

$html = q{<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
 <head>
  <link rel="stylesheet" href="/s/style.css" type="text/css">
  <link rel="alternate" type="application/rss+xml" title="RSS 1.0" href="http://search.cpan.org/uploads.rdf">
  <title>Archiving Compression Conversion - search.cpan.org</title>
 </head>
 <body id="cpansearch">
<center><div class="logo"><a href="/"><img src="/s/img/cpan-10.jpg" alt="CPAN"></a></div></center>
<div class="menubar">

 <a href="/">Home</a>
&middot; <a href="/author/">Authors</a>
&middot; <a href="/recent">Recent</a>
&middot; <a href="http://log.perl.org/cpansearch/">News</a>
&middot; <a href="/mirror">Mirrors</a>
&middot; <a href="/faq.html">FAQ</a>

&middot; <a href="/feedback">Feedback</a>
</div>
<form method="get" action="/search" name="f" class="searchbox">
<input type="text" name="query" value="" size="35">
<br>in <select name="mode">
 <option value="all">All</option>
 <option value="module" >Modules</option>
 <option value="dist" >Distributions</option>

 <option value="author" >Authors</option>
</select>&nbsp;<input type="submit" value="CPAN Search">
</form>


 
 <div class=path>
  <a href="/">Top</a> >
  Archiving Compression Conversion
 </div>

 


 <center class=categories><table>

  <tr>
   <td><a href="/modlist/Archiving_Compression_Conversion/Archive">Archive::</a></td>
   <td><a href="/modlist/Archiving_Compression_Conversion/Compress">Compress::</a></td>
   <td><a href="/modlist/Archiving_Compression_Conversion/Convert">Convert::</a></td>
   <td><a href="/modlist/Archiving_Compression_Conversion/RPM">RPM::</a></td>
  </tr>
 </table></center>

 <table width="100%">
  <tr class=r>
   <td><a href="/search%3fmodule=Algorithm::Munkre">Algorithm::Munkre</a></td>
   <td><small><code><a href="/dlsip?apmOg">apmOg</a></code></small></td>
   <td width="80%">Solution to classical Assignment Problem</td>
   <td><small><a href="/~anaghakk">ANAGHAKK</a></small></td>

  </tr>
  <tr class=s>
   <td><a href="/search%3fmodule=Algorithm::Munkres">Algorithm::Munkres</a></td>
   <td><small><code><a href="/dlsip?apmOg">apmOg</a></code></small></td>
   <td width="80%">Solution to classical Assignment Problem</td>
   <td><small><a href="/~anaghakk">ANAGHAKK</a></small></td>
  </tr>

  <tr class=r>
   <td><a href="/search%3fmodule=AppleII::DOS33">AppleII::DOS33</a></td>
   <td><small><code><a href="/dlsip?i">i</a></code></small></td>
   <td width="80%">Manipulate files on DOS 3.3 disk images</td>
   <td><small><a href="/~cjm">CJM</a></small></td>
  </tr>
  <tr class=s>

   <td><a href="/search%3fmodule=AppleII::Disk">AppleII::Disk</a></td>
   <td><small><code><a href="/dlsip?bpdO">bpdO</a></code></small></td>
   <td width="80%">Read/write Apple II disk image files</td>
   <td><small><a href="/~cjm">CJM</a></small></td>
  </tr>
  <tr class=r>
   <td><a href="/search%3fmodule=AppleII::Pascal">AppleII::Pascal</a></td>

   <td><small><code><a href="/dlsip?i">i</a></code></small></td>
   <td width="80%">Manipulate files on Apple Pascal disk images</td>
   <td><small><a href="/~cjm">CJM</a></small></td>
  </tr>
  <tr class=s>
   <td><a href="/search%3fmodule=AppleII::ProDOS">AppleII::ProDOS</a></td>
   <td><small><code><a href="/dlsip?bpdO">bpdO</a></code></small></td>

   <td width="80%">Manipulate files on ProDOS disk images</td>
   <td><small><a href="/~cjm">CJM</a></small></td>
  </tr>
  <tr class=r>
   <td><a href="/search%3fmodule=Cache::BerkeleyDB">Cache::BerkeleyDB</a></td>
   <td><small><code><a href="/dlsip?bpdOp">bpdOp</a></code></small></td>
   <td width="80%">implements the Cache::Cache interface</td>

   <td><small><a href="/~baldur">BALDUR</a></small></td>
  </tr>
  <tr class=s>
   <td><a href="/search%3fmodule=Cache::Bounded">Cache::Bounded</a></td>
   <td><small><code><a href="/dlsip?RpdOg">RpdOg</a></code></small></td>
   <td width="80%">A speed optimized in-memory size-aware cache</td>
   <td><small><a href="/~bennie">BENNIE</a></small></td>

  </tr>
  <tr class=r>
   <td><a href="/search%3fmodule=Cache::Cache">Cache::Cache</a></td>
   <td><small><code><a href="/dlsip?RpdOp">RpdOp</a></code></small></td>
   <td width="80%">Generic cache interface and implementations</td>
   <td><small><a href="/~dclinton">DCLINTON</a></small></td>
  </tr>

  <tr class=s>
   <td><a href="/search%3fmodule=Cache::FastMemoryCache">Cache::FastMemoryCache</a></td>
   <td><small><code><a href="/dlsip?bpdOo">bpdOo</a></code></small></td>
   <td width="80%">In-memory cache plugin for Cache::Cache</td>
   <td><small><a href="/~millaway">MILLAWAY</a></small></td>
  </tr>
  <tr class=r>

   <td><a href="/search%3fmodule=Cache::Mmap">Cache::Mmap</a></td>
   <td><small><code><a href="/dlsip?bhdOp">bhdOp</a></code></small></td>
   <td width="80%">Shared data cache using memory mapped files</td>
   <td><small><a href="/~pmh">PMH</a></small></td>
  </tr>
  <tr class=s>
   <td><a href="/search%3fmodule=Cache::Repository">Cache::Repository</a></td>

   <td><small><code><a href="/dlsip?bpdOp">bpdOp</a></code></small></td>
   <td width="80%">Generic file repository handling</td>
   <td><small><a href="/~dmcbride">DMCBRIDE</a></small></td>
  </tr>
  <tr class=r>
   <td><a href="/search%3fmodule=PPM">PPM</a></td>
   <td><small><code><a href="/dlsip?Rpdf">Rpdf</a></code></small></td>

   <td width="80%">Perl Package Manager</td>
   <td><small><a href="/~murray">MURRAY</a></small></td>
  </tr>
  <tr class=s>
   <td><a href="/search%3fmodule=PPM::Make">PPM::Make</a></td>
   <td><small><code><a href="/dlsip?bpdOp">bpdOp</a></code></small></td>
   <td width="80%">Make a PPM package from a CPAN distribution</td>

   <td><small><a href="/~rkobes">RKOBES</a></small></td>
  </tr>
 </table>

<div class="footer">
Hosted by <a href="http://www.digitalcraftsmen.net/">craftsmen</a><br/>
<a href="http://www.digitalcraftsmen.net/"><img src="/s/img/DC-LOGO-S.gif"></a>
</div>
<!-- Sun Mar 12 00:28:08 2006 GMT (0.0105438232421875) @eu1 -->
 </body>

</html>
};

$o->deflate($html);
ok($o->ratio < 0.9,'ratio');
$o2 = $o->new(class=>'\w');
ok(defined $o2, 'new from object');
$o2->deflate($html);
ok($o2->ratio != $o->ratio,'class=>\w ratio');

