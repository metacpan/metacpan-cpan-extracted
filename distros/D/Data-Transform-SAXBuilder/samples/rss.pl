# vim: filetype=perl

use strict;
use warnings;

use POE qw(
  Wheel::ReadWrite
  Driver::SysRW
);

use XML::SAX::IncrementalBuilder::LibXML;
use Data::Transform::SAXBuilder;

use IO::Handle;
use IO::File;
use XML::LibXML::XPathContext;

autoflush STDOUT 1;

my $session = POE::Session->create(
  inline_states => {
    _start => \&start,
    input => \&input,
    error => \&error,
  },
);

my $xpc = XML::LibXML::XPathContext->new;
$xpc->registerNs(a => "http://purl.org/rss/1.0/");
$xpc->registerNs(rdf => "http://www.w3.org/1999/02/22-rdf-syntax-ns#");
POE::Kernel->run();
exit;

sub start {
  my ($kernel, $heap) = @_[KERNEL, HEAP];

  sysseek(DATA, tell(DATA), 0);

  my $builder = XML::SAX::IncrementalBuilder::LibXML->new(godepth => 1);
  my $filter = Data::Transform::SAXBuilder->new(handler => $builder);

  my $wheel = POE::Wheel::ReadWrite->new (
    Handle => \*DATA,
    Driver => POE::Driver::SysRW->new (BlockSize => 100),
    InputFilter => $filter,
    InputEvent => 'input',
    ErrorEvent => 'error',
  );
  $heap->{'wheel'} = $wheel;
}

sub input {
  my ($kernel, $heap, $data) = @_[KERNEL, HEAP, ARG0];

  if ($data->nodeName eq 'channel') {
  	my @items = $xpc->findnodes('./a:items/rdf:Seq/rdf:li/@rdf:resource', $data);
	foreach my $item (@items) {
		print $item->value, "\n";
	}
  	print "\n";
  }
  if ($data->nodeName eq 'item') {
  	print $xpc->findvalue ('./a:title', $data), "\n";
  	print $xpc->findvalue ('./a:link', $data), "\n\n";
  }
}

sub error {
  my $heap = $_[HEAP];
  my ($type, $errno, $errmsg, $id) = @_[ARG0..$#_];

  delete $heap->{wheel};
}

__DATA__
<?xml version="1.0" encoding="ISO-8859-1"?>

<rdf:RDF
 xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
 xmlns="http://purl.org/rss/1.0/"
 xmlns:slash="http://purl.org/rss/1.0/modules/slash/"
 xmlns:taxo="http://purl.org/rss/1.0/modules/taxonomy/"
 xmlns:dc="http://purl.org/dc/elements/1.1/"
 xmlns:syn="http://purl.org/rss/1.0/modules/syndication/"
 xmlns:admin="http://webns.net/mvcb/"
>

<channel rdf:about="http://use.perl.org/">
<title>use Perl</title>
<link>http://use.perl.org/</link>
<description>All the Perl that's Practical to Extract and Report</description>
<dc:language>en-us</dc:language>
<dc:rights>use Perl; is Copyright 1998-2006, Chris Nandor. Stories, comments, journals, and other submissions posted on use Perl; are Copyright their respective owners.</dc:rights>
<dc:date>2008-05-31T06:50:25+00:00</dc:date>
<dc:publisher>pudge</dc:publisher>
<dc:creator>pudge@perl.org</dc:creator>
<dc:subject>Technology</dc:subject>
<syn:updatePeriod>hourly</syn:updatePeriod>
<syn:updateFrequency>1</syn:updateFrequency>
<syn:updateBase>1970-01-01T00:00+00:00</syn:updateBase>
<items>
 <rdf:Seq>
  <rdf:li rdf:resource="http://use.perl.org/article.pl?sid=08/05/31/0627214&amp;from=rss" />
  <rdf:li rdf:resource="http://use.perl.org/article.pl?sid=08/05/30/2119226&amp;from=rss" />
  <rdf:li rdf:resource="http://use.perl.org/article.pl?sid=08/05/29/139215&amp;from=rss" />
  <rdf:li rdf:resource="http://use.perl.org/article.pl?sid=08/05/26/213229&amp;from=rss" />
  <rdf:li rdf:resource="http://use.perl.org/article.pl?sid=08/05/24/1920233&amp;from=rss" />
  <rdf:li rdf:resource="http://use.perl.org/article.pl?sid=08/05/24/1047214&amp;from=rss" />
  <rdf:li rdf:resource="http://use.perl.org/article.pl?sid=08/05/24/1046205&amp;from=rss" />
  <rdf:li rdf:resource="http://use.perl.org/article.pl?sid=08/05/22/103201&amp;from=rss" />
  <rdf:li rdf:resource="http://use.perl.org/article.pl?sid=08/05/21/211253&amp;from=rss" />
  <rdf:li rdf:resource="http://use.perl.org/article.pl?sid=08/05/21/0744213&amp;from=rss" />
 </rdf:Seq>
</items>
<image rdf:resource="http://use.perl.org/images/topics/useperl.gif" />
<textinput rdf:resource="http://use.perl.org/search.pl" />
</channel>

<image rdf:about="http://use.perl.org/images/topics/useperl.gif">
<title>use Perl</title>
<url>http://use.perl.org/images/topics/useperl.gif</url>
<link>http://use.perl.org/</link>
</image>

<item rdf:about="http://use.perl.org/article.pl?sid=08/05/31/0627214&amp;from=rss">
<title>Perl feedback for MySQL Magazine survey</title>
<link>http://use.perl.org/article.pl?sid=08/05/31/0627214&amp;from=rss</link>
<description>brian_d_foy writes "Keith Murphy, the editor of MySQL Magazine, and Mark Schoonover have put together a comprehensive survey about MySQL and they asked me to make sure the Perl community knows about it so they can give their input. They've had over 200 responses so far, the they'll publish the results in the summer issue of MySQL Magazine."&lt;p&gt;&lt;a href="http://use.perl.org/article.pl?sid=08/05/31/0627214&amp;amp;from=rss"&gt;Read more of this story&lt;/a&gt; at use Perl.&lt;/p&gt;</description>
<dc:creator>grinder</dc:creator>
<dc:date>2008-05-31T06:46:00+00:00</dc:date>
<dc:subject>news</dc:subject>
<slash:section>news</slash:section>
<slash:hit_parade>0,0,0,0,0,0,0</slash:hit_parade>
</item>

<item rdf:about="http://use.perl.org/article.pl?sid=08/05/30/2119226&amp;from=rss">
<title>This Week on perl5-porters - 18-24 May 2008</title>
<link>http://use.perl.org/article.pl?sid=08/05/30/2119226&amp;from=rss</link>
<description> This Week on perl5-porters - 18-24 May 2008 &amp;quot;Ah, more details about filenames. Well, this sounds positively weird. Octet strings are not particularly user-friendly if you can't interpret them as characters reliably. From what you say, and what I think I've heard elsewhere, Unix filename interpretation is a mess. Seems like the only bigger mess I've heard about is VMS file handling, where they seem to have a choice of several messes.&amp;quot; -- Glenn Linderman, deep in the heart of Unicode, case conversion, filenames, encodings, character sets, &amp;#223; and other exciting issues.&lt;p&gt;&lt;a href="http://use.perl.org/article.pl?sid=08/05/30/2119226&amp;amp;from=rss"&gt;Read more of this story&lt;/a&gt; at use Perl.&lt;/p&gt;</description>
<dc:creator>grinder</dc:creator>
<dc:date>2008-05-30T21:18:00+00:00</dc:date>
<dc:subject>summaries</dc:subject>
<slash:section>mainpage</slash:section>
<slash:hit_parade>0,0,0,0,0,0,0</slash:hit_parade>
</item>

<item rdf:about="http://use.perl.org/article.pl?sid=08/05/29/139215&amp;from=rss">
<title>Yet another minigrant for Perl 6 development</title>
<link>http://use.perl.org/article.pl?sid=08/05/29/139215&amp;from=rss</link>
<description>DeepText company proposes a minigrant of 1000 &amp;#8364; to Jonathan Worthington for working 40 hours on Rakudo development during July and August of 2008. The purpose of the grant is to support implementing as many of multiple dispatch abilities in Perl 6 design as possible to code having these working hours. Here are initial proposal and Jonathan&amp;#8217;s answer.&lt;p&gt;&lt;a href="http://use.perl.org/article.pl?sid=08/05/29/139215&amp;amp;from=rss"&gt;Read more of this story&lt;/a&gt; at use Perl.&lt;/p&gt;</description>
<dc:creator>andy.sh (posted by brian_d_foy)</dc:creator>
<dc:date>2008-05-29T13:28:00+00:00</dc:date>
<dc:subject>journal</dc:subject>
<slash:section>mainpage</slash:section>
<slash:hit_parade>0,0,0,0,0,0,0</slash:hit_parade>
</item>

<item rdf:about="http://use.perl.org/article.pl?sid=08/05/26/213229&amp;from=rss">
<title>Test Automation Tips</title>
<link>http://use.perl.org/article.pl?sid=08/05/26/213229&amp;from=rss</link>
<description>For some time I thought that the Perl-Tips sent out by Perl Training Australia is a neat idea. To follow my tradition of taking lots of good ideas from the Australians I thought I'd like to have one too. Of course it did not make much sense to create another Perl tips list but now, following the advice of brian d foy, finally the puzzle is complete. So I setup a newsletter to send out tips regarding Test Automation. It will include tips on how to write tests in Perl but also stuff other languages do. For more information you can go to the Test Automation Tips page or to the blog entry I wrote about it or you can skip that too and go directly to the subscrption page as I am going to send out the first message soon.&lt;p&gt;&lt;a href="http://use.perl.org/article.pl?sid=08/05/26/213229&amp;amp;from=rss"&gt;Read more of this story&lt;/a&gt; at use Perl.&lt;/p&gt;</description>
<dc:creator>gabor (posted by brian_d_foy)</dc:creator>
<dc:date>2008-05-26T21:19:00+00:00</dc:date>
<dc:subject>journal</dc:subject>
<slash:section>mainpage</slash:section>
<slash:comments>2</slash:comments>
<slash:hit_parade>2,2,2,2,0,0,0</slash:hit_parade>
</item>

<item rdf:about="http://use.perl.org/article.pl?sid=08/05/24/1920233&amp;from=rss">
<title>This Week on perl5-porters - 11-17 May 2008</title>
<link>http://use.perl.org/article.pl?sid=08/05/24/1920233&amp;from=rss</link>
<description> This Week on perl5-porters - 11-17 May 2008 Dominic Dunlop: Trouble is, some of it is CGI, and people whinge loudly when previously-clean CGI starts warning. Ed Avis: Ha ha ha. I think any possible programmer mistake can be found in a Perl CGI program somewhere.&lt;p&gt;&lt;a href="http://use.perl.org/article.pl?sid=08/05/24/1920233&amp;amp;from=rss"&gt;Read more of this story&lt;/a&gt; at use Perl.&lt;/p&gt;</description>
<dc:creator>grinder</dc:creator>
<dc:date>2008-05-24T19:18:00+00:00</dc:date>
<dc:subject>summaries</dc:subject>
<slash:section>mainpage</slash:section>
<slash:hit_parade>0,0,0,0,0,0,0</slash:hit_parade>
</item>

<item rdf:about="http://use.perl.org/article.pl?sid=08/05/24/1047214&amp;from=rss">
<title>Perl 6 Design Minutes for 21 May 2008</title>
<link>http://use.perl.org/article.pl?sid=08/05/24/1047214&amp;from=rss</link>
<description>The Perl 6 design team met by phone on 21 May 2008. Larry, Allison, Patrick, Jerry, Will, and chromatic attended.&lt;p&gt;&lt;a href="http://use.perl.org/article.pl?sid=08/05/24/1047214&amp;amp;from=rss"&gt;Read more of this story&lt;/a&gt; at use Perl.&lt;/p&gt;</description>
<dc:creator>chromatic (posted by brian_d_foy)</dc:creator>
<dc:date>2008-05-24T11:06:00+00:00</dc:date>
<dc:subject>journal</dc:subject>
<slash:section>mainpage</slash:section>
<slash:hit_parade>0,0,0,0,0,0,0</slash:hit_parade>
</item>

<item rdf:about="http://use.perl.org/article.pl?sid=08/05/24/1046205&amp;from=rss">
<title>Win32::API source code repository and history</title>
<link>http://use.perl.org/article.pl?sid=08/05/24/1046205&amp;from=rss</link>
<description>It required some trial and error on my part due to lack of experience using svn_load_dirs, but at last, we have it. The full Win32::API source code history throughout all CPAN releases. Check it out, it's hosted on google code, together with all others Win32 specific modules. Thanks to Jan for helping me out with this. And if you're wondering, I think it's time to "open up" the source code repository for Win32::API.Lately I've been receiving lots of emails, requests for support, new implementations and bug reports for it. Since I have less and less spare time, I think it's important that people that want or know how to contribute, do it. And do it on the "latest and greatest" version, with all recent bug fixes and/or new features. Of course, a new version is currently in development. It should fix problems using DLL APIs with double or float arguments, together with other minor issues. I will need some more time to finalize these changes, and then hopefully I will release the new version on CPAN in a reasonable time. So, here it is... Enjoy!&lt;p&gt;&lt;a href="http://use.perl.org/article.pl?sid=08/05/24/1046205&amp;amp;from=rss"&gt;Read more of this story&lt;/a&gt; at use Perl.&lt;/p&gt;</description>
<dc:creator>cosimo (posted by brian_d_foy)</dc:creator>
<dc:date>2008-05-24T11:05:00+00:00</dc:date>
<dc:subject>cpan</dc:subject>
<slash:section>mainpage</slash:section>
<slash:hit_parade>0,0,0,0,0,0,0</slash:hit_parade>
</item>

<item rdf:about="http://use.perl.org/article.pl?sid=08/05/22/103201&amp;from=rss">
<title>YAPC::Russia</title>
<link>http://use.perl.org/article.pl?sid=08/05/22/103201&amp;from=rss</link>
<description>VENUEI asked in a mailing list of Moscow.pm if someone could help to find a venue of amphitheatre style. In a couple of "peer-to-peer" steps we met with a guy from the Club "Business in .RU-style" which is a part of State University-Higher School of Economics. They proposed us to take one of the auditoriums of such type. Later I asked for one more auditorium to host a second thread of talks. TALKSNumber of talks is at the same time good and bad element. It it good because we had to find second auditorium for one of days, bad is that attendees sometimes wanted to be at both at the same time. There were several 20 to 40-minutes talks and one longer master-class devoted to using POE. By the way, despite that master-class was moved into a second room, it was preceded by a 20-minute talk in the main room. http://perlrussia.ru/mayperl2008/shots/_MG_4515.JPG One of the speakers received a special prize for the most balanced talk (in the sense of organizers, well, me personally). http://perlrussia.ru/mayperl2008/shots/DSC_0698-webbig.jpg We had three cameras recording the conference (but unfortunately did not manage to organize good sound recording). http://perlrussia.ru/mayperl2008/shots/DSC_0685-webbig.jpg ATTENDEES AND GEOGRAPHY241 people were registered on a website, about 100 of them showed up. It is not possible to say real number because not everyone has checked in their registration desk in the venue: either just missed it or did not appear in the first day. The list of participants includes three countries (Russia, Ukraine and Denmark), about 20 cities and attendees of all ages. http://perlrussia.ru/mayperl2008/shots/IMG_4579.JPG REGISTRATIONFrom the very start of Moscow.pm events the registration process was automated with personal barcodes, which were sent to attendees several days before the event and which should be printed and brought to the venue to speed up registration process. http://perlrussia.ru/mayperl2008/shots/_MG_4443.JPG FREE STUFFParticipation in a conference was free for everyone, and even more: there were two free coffee-breaks, one per day. We also had a possibility to give everyone a conference's T-shirt (thanks to Act that allows to see T-shirt size statistics). We also had free Wi-Fi (but it did not work too well in the first day). http://perlrussia.ru/mayperl2008/shots/DSC_0564-web.jpg LIGHTNING TALKSThanks to Alex Kapranoff, the conference was "equipped" with a lightning session of 10 talks. By the way, we have localized the name and call them "blitz-talks" (well, word is German but is pronounced much easier than "lightning" by local people). Several months earlier Alex had prepared web pages explaining what LTs are (http://perl.lv/lt). Later he lobbied LT session on another IT-conference in Moscow. http://perlrussia.ru/mayperl2008/shots/IMG_4585.JPG Funny thing is the localization of the Gong. We had this musical triangle to stop talks. http://perlrussia.ru/mayperl2008/shots/IMG_4616.JPG YAPC::RUSSIA::GOLFAt the registration desk every attendee received a printed schedule and extra two pages with tasks for the contest, YAPC::Russia::Golf. Its name tells that it is like traditional Perl Golf contest. We gave two algorithmical tasks to be solved with minimum of code. Winners were announced in the end of second day of the conference. Tasks and solutions are located at contest's website http://golf.yapcrussia.org/, and this page will be later expanded to include comments to solutions, as well as video recordings of the process. There were four prized: three one year VPS hosting packages and a license for ActiveStates' Perl Dev Kit. http://perlrussia.ru/mayperl2008/shots/_MG_4561.JPG (thinking of the task) http://perlrussia.ru/mayperl2008/shots/IMG_4735.JPG (analyzing solutions) http://perlrussia.ru/mayperl2008/shots/DSC_0705-webbig.jpg (getting the prize) MISTAKESSeveral mistakes were made during the conference itself and during the preparation to it. Well, they did not break the conference, but are rather things to take more care of next time. While the registration was automated with barcodes (which eliminates the difficulties of speech channel for parsing attendee's names in a noisy room) it was dramatically slowed down because of need to search the badge, it was slow even while we had sorted them alphabetically. Next time we have to be more strict when accepting talks. There were several which could be deleted. Unfortunately two speakers did not showed up at all. Coffee-breaks were great, but lunches were not. We planned one hour lunch each day. But in the first day we (organizers and several people came with us to a cafe outside the venue) spent two hours there (but talks were continued during this lunch, although with a delay). Along with this and problems with Wi-Fi second part of POE master-class was abandoned. We had prepared lots of AC supplies (in fact, wires are just a part of organizers' toolkit). Next time we should add to our own stuff several wireless microphones to be more flexible in the room. ORGANIZERS AND SPONSORSAgain huge thanks to Russian search engine Rambler (http://rambler.ru/) who was the Prime sponsor. Personal thanks to Alex Kapranof (Rambler), Ivan Serezhkin (another search engine, Yandex, http://yandex.ru/) and Andrey Zavyalov who helped with Golf contest. Coincidently, both Alex and Ivan work in web-mail and anti-spam divisions, but in different companies. Thanks to Anatoly Sharifulin with whom we made budges last night before the conference. Thanks to ZSupport (http://zsupport.ru/) company who created and solved problems with Wi-Fi support, and most of others - to the Club "Business in a .RU-style" (http://styleru.net/) and personally to Michael Monashev who pointed me to these people and Peter Fedin for organizing the venue and coffee-breaks. Bonus slide: Ivan Serezhkin vs. R. Geoffrey Avery http://perlrussia.ru/mayperl2008/shots/avery-vany.jpg&lt;p&gt;&lt;a href="http://use.perl.org/article.pl?sid=08/05/22/103201&amp;amp;from=rss"&gt;Read more of this story&lt;/a&gt; at use Perl.&lt;/p&gt;</description>
<dc:creator>andy.sh (posted by brian_d_foy)</dc:creator>
<dc:date>2008-05-22T10:22:00+00:00</dc:date>
<dc:subject>journal</dc:subject>
<slash:section>mainpage</slash:section>
<slash:comments>2</slash:comments>
<slash:hit_parade>2,2,2,0,0,0,0</slash:hit_parade>
</item>

<item rdf:about="http://use.perl.org/article.pl?sid=08/05/21/211253&amp;from=rss">
<title>Perl 6 Design Minutes for 14 May 2008</title>
<link>http://use.perl.org/article.pl?sid=08/05/21/211253&amp;from=rss</link>
<description>The Perl 6 design team met by phone on 14 May 2008. Allison, Richard, Patrick, Jerry, Will, Nicholas, and chromatic attended.&lt;p&gt;&lt;a href="http://use.perl.org/article.pl?sid=08/05/21/211253&amp;amp;from=rss"&gt;Read more of this story&lt;/a&gt; at use Perl.&lt;/p&gt;</description>
<dc:creator>chromatic (posted by KM)</dc:creator>
<dc:date>2008-05-21T21:20:00+00:00</dc:date>
<dc:subject>journal</dc:subject>
<slash:section>mainpage</slash:section>
<slash:comments>1</slash:comments>
<slash:hit_parade>1,1,1,0,0,0,0</slash:hit_parade>
</item>

<item rdf:about="http://use.perl.org/article.pl?sid=08/05/21/0744213&amp;from=rss">
<title>Parrot 0.6.2</title>
<link>http://use.perl.org/article.pl?sid=08/05/21/0744213&amp;from=rss</link>
<description>On behalf of the Parrot team, I'm proud to announce Parrot 0.6.2 &amp;quot;Reverse Sublimation.&amp;quot; Parrot is a virtual machine aimed at running all dynamic languages. Parrot 0.6.2 is available via CPAN (soon), or follow the download instructions. For those who would like to develop on Parrot, or help develop Parrot itself, we recommend using Subversion or SVK on our source code repository to get the latest and best Parrot code. Parrot 0.6.2 News:&lt;p&gt;&lt;a href="http://use.perl.org/article.pl?sid=08/05/21/0744213&amp;amp;from=rss"&gt;Read more of this story&lt;/a&gt; at use Perl.&lt;/p&gt;</description>
<dc:creator>chromatic (posted by grinder)</dc:creator>
<dc:date>2008-05-21T08:02:00+00:00</dc:date>
<dc:subject>parrot</dc:subject>
<slash:section>mainpage</slash:section>
<slash:hit_parade>0,0,0,0,0,0,0</slash:hit_parade>
</item>

<textinput rdf:about="http://use.perl.org/search.pl">
<title>Search use Perl</title>
<description>Search use Perl stories</description>
<name>query</name>
<link>http://use.perl.org/search.pl</link>
</textinput>

</rdf:RDF>
