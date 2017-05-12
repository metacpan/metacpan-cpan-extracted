#!perl -T

use Test::More tests => 52;
use Archive::Har();
use Compress::Zlib();
use JSON();

my $har = Archive::Har->new();

my $firebug_post_string = <<'_FIREBUG_RESULTS_';
{
  "log": {
    "version": "1.1",
    "creator": {
      "name": "Firebug",
      "version": "1.9"
    },
    "browser": {
      "name": "Firefox",
      "version": "11.0"
    },
    "pages": [
      {
        "startedDateTime": "2012-03-23T16:31:05.716+11:00",
        "id": "page_40125",
        "title": "DuckDuckGo",
        "pageTimings": {
          "onContentLoad": 547,
          "onLoad": 3987
        }
      }
    ],
    "entries": [
      {
        "pageref": "page_40125",
        "startedDateTime": "2012-03-23T16:31:05.716+11:00",
        "time": 381,
        "request": {
          "method": "POST",
          "url": "https://duckduckgo.com/",
          "httpVersion": "HTTP/1.1",
          "cookies": [],
          "headers": [
            {
              "name": "Host",
              "value": "duckduckgo.com"
            },
            {
              "name": "User-Agent",
              "value": "Mozilla/5.0 (Windows NT 6.1; WOW64; rv:11.0) Gecko/2010.111 Firefox/11.0"
            },
            {
              "name": "Accept",
              "value": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"
            },
            {
              "name": "Accept-Language",
              "value": "en-us,en;q=0.5"
            },
            {
              "name": "Accept-Encoding",
              "value": "gzip, deflate"
            },
            {
              "name": "Connection",
              "value": "keep-alive"
            }
          ],
          "queryString": [],
          "postData": {
            "mimeType": "application/x-www-form-urlencoded",
            "params": [
              {
                "name": "kg",
                "value": "p"
              },
              {
                "name": "q",
                "value": "http archive format"
              }
            ],
            "text": ""
          },
          "headersSize": 287,
          "bodySize": 97
        },
        "response": {
          "status": 200,
          "statusText": "OK",
          "httpVersion": "HTTP/1.1",
          "cookies": [],
          "headers": [
            {
              "name": "Server",
              "value": "nginx"
            },
            {
              "name": "Date",
              "value": "Fri, 23 Mar 2012 05:27:52 GMT"
            },
            {
              "name": "Content-Type",
              "value": "text/html; charset=UTF-8"
            },
            {
              "name": "Transfer-Encoding",
              "value": "chunked"
            },
            {
              "name": "Connection",
              "value": "keep-alive"
            },
            {
              "name": "Expires",
              "value": "Fri, 23 Mar 2012 05:27:53 GMT"
            },
            {
              "name": "Cache-Control",
              "value": "max-age=1"
            },
            {
              "name": "Content-Encoding",
              "value": "gzip"
            }
          ],
          "content": {
            "mimeType": "text/html",
            "size": 6730,
            "text": "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01//EN\" \"http://www.w3.org/TR/html4/strict.dtd\"><html><head><meta name=\"robots\" content=\"noindex,nofollow\"><meta http-equiv=\"content-type\" content=\"text/html; charset=UTF-8\"><meta http-equiv=\"X-UA-Compatible\" content=\"IE=edge, chrome=1\"><title>http archive format at DuckDuckGo</title><link rel=\"stylesheet\" href=\"/s422.css\" type=\"text/css\"><style id=\"DDG\" type=\"text/css\"></style><link title=\"DuckDuckGo\" type=\"application/opensearchdescription+xml\" rel=\"search\" href=\"/opensearch_ssl.xml\"><link rel=\"image_src\" href=\"/assets/logo_homepage.normal.v101.png\"/><link rel=\"apple-touch-icon\" href=\"/assets/logo_icon128.v101.png\"/><link rel=\"shortcut icon\" href=\"/favicon.ico\"><script type=\"text/javascript\">var fq,r1c,r2c,r3c,ric,rfq,rq,rds,rt,y,y1,ti,tig,ka,kb,kc,kd,ke,kf,kg,kh,ki,kj,kk,kl,km,kn,ko,kp,kq,kr,ks,kt,ku,kv,kw,kx,ky,kz,k1,k2,k3,k4,k5,k6,k7,k8,k9,kaa,kab,kac,kad,kae,kaf,kag,kah,kai,kaj,kak,kal,kam,kan,kao,kap,kaq,kar,kas,kat,kau,kav,kaw,kax,kay,kaz;fq=0;fd=1;it=0;iqa=0;iqm=0;iqs=0;iqq=0;qw=3;r1hc=0;r1c=0;r2c=0;r3c=0;ric=1;rq='http%20archive%20format';rfq=0;rt='';ra='';rv='';rad='';rds=30;rs=0;kl='';kp='';ks='';kw='';ka='';kt='';ky='';kk='';kf='';kc='';ke='';kr='';ko='';kj='';kz='';kg='p';kh='';kd='';ki='';kn='';kb='';km='';ku='';kq='';kv='';kx='';k1='';k2='';k3='';k4='';k5='';k6='',k7='',k8='',k9='';kaa='';kab='';kac='';kad='';kae='';kaf='';kag='';kah='';kai='';kaj='';kak='';kal='';kam='';kan='';kao='';kap='';kaq='';kar='';kas='';kat='';kau='';kav='';kaw='';kax='';kay='';kaz='';</script><meta name=\"viewport\" content=\"width=device-width, initial-scale=1, maximum-scale=1, user-scalable=0\" /><meta name=\"HandheldFriendly\" content=\"true\" /><meta name=\"apple-mobile-web-app-capable\" content=\"yes\" /></head><body class=\"yui-skin-sam\"><input id=\"state_hidden\" name=\"state_hidden\" type=\"text\" size=\"1\"><span class=\"hide\">Ignore this box please.</span><div id=\"spacing_hidden_wrapper\"><div id=\"spacing_hidden\"></div></div><div id=\"add_to_browser\" class=\"add_to_browser\"></div><script type=\"text/javascript\" src=\"/d724.js\"></script><div id=\"header_wrapper\"><div id=\"header\"><div id=\"header_content_wrapper\"><div id=\"header_content\"><div class=\"clear\"></div><a tabindex=\"-1\" href=\"/?t=&kg=p\"><div id=\"header_logo\"></div></a><form id=\"search_form\" name=\"x\" action=\"/\" onSubmit=\"return nbr()\"><div id=\"search_elements_hidden\"></div><div id=\"search_wrapper\"><input id=\"search_button\" type=\"submit\" tabindex=\"3\" value=\"\"/><a id=\"search_dropdown\" href=\"javascript:;\" tabindex=\"4\" onClick=\"nbc(1);\"></a></div><input id=\"search_form_input_clear\" type=\"button\" tabindex=\"2\" value=\"\"/><input type=\"text\" name=\"q\" tabindex=\"1\" autocomplete=\"off\" id=\"search_form_input\" onFocus=\"if ('rc' in window) {nua('nro',rc)};fq=1;\" onBlur=\"fq=0\" onclick=\"if (this.value=='put search terms here') {this.value='';this.style.color='#000000';}\" value=\"http archive format\"><input type=\"hidden\" name=\"kg\" value=\"p\"></form><div id=\"header_button_wrapper\" onclick=\"DDG.toggle('header_button_menu')\"><ul id=\"header_button\"><li><div id=\"header_button_menu_wrapper\"><a class=\"header_button_menu_item\" id=\"header_button_menu_title\" href=\"javascript:;\">More</a><ul id=\"header_button_menu\"><li><a href=\"/settings.html\" tabindex=\"-1\"><img src=\"/f2/us.png\" class=\"inline\"> Settings</a></li><li><a href=\"/goodies.html\" tabindex=\"-1\">Goodies</a></li><li><a href=\"/about.html\" tabindex=\"-1\">About</a></li><li><a href=\"http://help.duckduckgo.com/\" tabindex=\"-1\">Help</a></li><li><a href=\"/feedback.html\" tabindex=\"-1\">Feedback</a></li><li class=\"header_button_menu_header\">PRIVACY</li><li><a href=\"http://donttrack.us/\" tabindex=\"-1\">DontTrack</a></li><li><a href=\"http://dontbubble.us/\" tabindex=\"-1\">DontBubble</a></li><li><a href=\"/privacy.html\" tabindex=\"-1\">Policy</a></li><li class=\"header_button_menu_header\">COMMUNITY</li><li><a href=\"https://dukgo.com/\" tabindex=\"-1\">Platform</a></li><li><a href=\"http://duck.co/\" tabindex=\"-1\">Forum</a></li><li><a href=\"http://webchat.freenode.net/?channels=duckduckgo\" tabindex=\"-1\">Chat</a></li><li><a href=\"/spread.html\" tabindex=\"-1\">Spread</a></li></ul></div></li></ul></div><div class=\"clear\"></div></div></div></div></div><div id=\"bang_wrapper\"><select id=\"bang\" size=\"2\" onChange=\"if (ip) nbb(this);\" onClick=\"if (!ip) nbb(this);\" onBlur=\"nbc(1);\"></select></div><div id=\"content_wrapper\"><div id=\"content\"><div id=\"side_wrapper\"><div id=\"side_wrapper2\"><div id=\"side\"><div id=\"side_sponsored\" class=\"hide\"></div><div id=\"side_suggestions\" class=\"hide\"></div><div id=\"keyboard_shortcuts\" class=\"hide\"><div class=\"spacer_bottom_7\">Search Syntax</div>s:d &nbsp; &nbsp; sort by date<br>r:uk &nbsp; &nbsp; uk region<br>site: &nbsp; &nbsp; domain search<br>\\ search &nbsp; &nbsp; first result<div id=\"keyboard_shortcuts_more\" class=\"spacer_top_3\"><a tabindex=\"-1\" href=\"javascript:;\" onclick=\"nsh('keyboard_shortcuts_more')\">More...</a></div><div id=\"keyboard_shortcuts_more_hidden\" class=\"hide\"><br>r:n &nbsp; &nbsp; turn off region<br>!a search &nbsp; &nbsp; search amazon<br>site:uk &nbsp; &nbsp; .uk pages<br>f: &nbsp; &nbsp; find files<br>t: &nbsp; &nbsp; within title<br>b: &nbsp; &nbsp; within body<br><a target=\"_blank\" href=\"http://help.duckduckgo.com/customer/portal/articles/300304\">More explanation...</a></div></div><div id=\"feedback_wrapper\" class=\"k_float k_bottom k_right\"><a title=\"Give feedback\" tabindex=\"-1\" target=\"_new\" href=\"/feedback.html\" rel=\"nofollow\"><div id=\"feedback\"></div></a></div></div></div></div><div id=\"zero_click_wrapper\" style=\"display:none;visibility:hidden;\"><div id=\"zero_click\"><div id=\"zero_click_wrapper2\"><div id=\"zero_click_plus_wrapper\"><a href=\"javascript:;\" onClick=\"nra4()\" id=\"zero_click_plus\">&nbsp;</a></div><div id=\"zero_click_header\" style=\"display:none;\"></div><div id=\"zero_click_image\" style=\"display:none;\"></div><div id=\"zero_click_abstract\" style=\"display:none;\"></div><div class=\"clear\">&nbsp;</div></div></div></div><div id=\"links_wrapper\"><noscript> &nbsp; &nbsp; This page requires JavaScript. Get the non-JS version <a href=\"https://duckduckgo.com/html/?q=http%20archive%20format\">here</a>.</noscript><div id=\"links\"></div></div><div id=\"powered_by_wrapper\"></div><div id=\"bottom_spacing2\"> </div></div></div><script type=\"text/javascript\">nip();</script><script type=\"text/javascript\">tig=new YAHOO.util.ImageLoader.group('body',null,0.01);</script><script type=\"text/JavaScript\">function nrji() {nrj('/a.js?q=http%20archive%20format&p=1');nrj('/d.js?q=http%20archive%20format&l=us-en&p=1&s=0');};if (ir) window.addEventListener('load', nrji, false);else nrji();</script><div id=\"z2\"> </div><script type=\"text/JavaScript\">if (ip) setTimeout('nuo(1)',500);</script><div id=\"z\"> </div></body></html>"
          },
          "redirectURL": "",
          "headersSize": 253,
          "bodySize": 2673
        },
        "cache": {
          "afterRequest": {
            "expires": "1970-01-01T00:00:00.000Z",
            "lastAccess": "2012-03-23T05:31:06.000Z",
            "eTag": "",
            "hitCount": 119
          }
        },
        "timings": {
          "blocked": 0,
          "dns": 0,
          "connect": 0,
          "send": 0,
          "wait": 381,
          "receive": 0
        },
        "serverIPAddress": "184.72.106.52",
        "connection": "443"
      },
      {
        "pageref": "page_40125",
        "startedDateTime": "2012-03-23T16:31:06.275+11:00",
        "time": 760,
        "request": {
          "method": "GET",
          "url": "https://duckduckgo.com/a.js?q=http%20archive%20format&p=1",
          "httpVersion": "HTTP/1.1",
          "cookies": [],
          "headers": [
            {
              "name": "Host",
              "value": "duckduckgo.com"
            },
            {
              "name": "User-Agent",
              "value": "Mozilla/5.0 (Windows NT 6.1; WOW64; rv:11.0) Gecko/2010.111 Firefox/11.0"
            },
            {
              "name": "Accept",
              "value": "*/*"
            },
            {
              "name": "Accept-Language",
              "value": "en-us,en;q=0.5"
            },
            {
              "name": "Accept-Encoding",
              "value": "gzip, deflate"
            },
            {
              "name": "Connection",
              "value": "keep-alive"
            },
            {
              "name": "Referer",
              "value": "https://duckduckgo.com/"
            }
          ],
          "queryString": [
            {
              "name": "p",
              "value": "1"
            },
            {
              "name": "q",
              "value": "http archive format"
            }
          ],
          "headersSize": 296,
          "bodySize": -1
        },
        "response": {
          "status": 200,
          "statusText": "OK",
          "httpVersion": "HTTP/1.1",
          "cookies": [],
          "headers": [
            {
              "name": "Server",
              "value": "nginx"
            },
            {
              "name": "Date",
              "value": "Fri, 23 Mar 2012 05:27:53 GMT"
            },
            {
              "name": "Content-Type",
              "value": "application/x-javascript; charset=UTF-8"
            },
            {
              "name": "Transfer-Encoding",
              "value": "chunked"
            },
            {
              "name": "Connection",
              "value": "keep-alive"
            },
            {
              "name": "Expires",
              "value": "Fri, 23 Mar 2012 05:27:52 GMT"
            },
            {
              "name": "Cache-Control",
              "value": "no-cache"
            },
            {
              "name": "Content-Encoding",
              "value": "gzip"
            }
          ],
          "content": {
            "mimeType": "application/x-javascript",
            "size": 691,
            "text": "var dna=[{\"u\":\"https://en.wikipedia.org/wiki/Darwin_Core_Archive#Archive_Format\",\"h\":\"Darwin Core <b>Archive</b>: <b>Archive Format</b>\",\"a\":\"Sharing entire datasets instead of using pageable web services like DiGIR and TAPIR allows much simpler and more efficient data transfer. For example, retrieving 260,000 records via TAPIR takes about nine hours, issuing 1,300 <b>http</b> requests to transfer 500 MB of XML-formatted data. The exact same dataset, encoded as DwC-A and zipped, becomes a 3 MB file. Therefore, GBIF highly recommends compressing an <b>archive</b> using ZIP or GZIP when generating a DwC-A.\",\"s\":\"Wikipedia\",\"t\":\"Darwin Core Archive: Archive Format\"}];if (nra) nra(dna);"
          },
          "redirectURL": "",
          "headersSize": 267,
          "bodySize": 451
        },
        "cache": {},
        "timings": {
          "blocked": 0,
          "dns": 0,
          "connect": 0,
          "send": 0,
          "wait": 760,
          "receive": 0
        },
        "serverIPAddress": "184.72.106.52",
        "connection": "443"
      },
      {
        "pageref": "page_40125",
        "startedDateTime": "2012-03-23T16:31:06.275+11:00",
        "time": 1818,
        "request": {
          "method": "GET",
          "url": "https://duckduckgo.com/d.js?q=http%20archive%20format&l=us-en&p=1&s=0",
          "httpVersion": "HTTP/1.1",
          "cookies": [],
          "headers": [
            {
              "name": "Host",
              "value": "duckduckgo.com"
            },
            {
              "name": "User-Agent",
              "value": "Mozilla/5.0 (Windows NT 6.1; WOW64; rv:11.0) Gecko/2010.111 Firefox/11.0"
            },
            {
              "name": "Accept",
              "value": "*/*"
            },
            {
              "name": "Accept-Language",
              "value": "en-us,en;q=0.5"
            },
            {
              "name": "Accept-Encoding",
              "value": "gzip, deflate"
            },
            {
              "name": "Connection",
              "value": "keep-alive"
            },
            {
              "name": "Referer",
              "value": "https://duckduckgo.com/"
            }
          ],
          "queryString": [
            {
              "name": "l",
              "value": "us-en"
            },
            {
              "name": "p",
              "value": "1"
            },
            {
              "name": "q",
              "value": "http archive format"
            },
            {
              "name": "s",
              "value": "0"
            }
          ],
          "headersSize": 308,
          "bodySize": -1
        },
        "response": {
          "status": 200,
          "statusText": "OK",
          "httpVersion": "HTTP/1.1",
          "cookies": [],
          "headers": [
            {
              "name": "Server",
              "value": "nginx"
            },
            {
              "name": "Date",
              "value": "Fri, 23 Mar 2012 05:27:54 GMT"
            },
            {
              "name": "Content-Type",
              "value": "application/x-javascript; charset=UTF-8"
            },
            {
              "name": "Transfer-Encoding",
              "value": "chunked"
            },
            {
              "name": "Connection",
              "value": "keep-alive"
            },
            {
              "name": "Expires",
              "value": "Fri, 23 Mar 2012 05:27:53 GMT"
            },
            {
              "name": "Cache-Control",
              "value": "no-cache"
            },
            {
              "name": "Content-Encoding",
              "value": "gzip"
            }
          ],
          "content": {
            "mimeType": "application/x-javascript",
            "size": 13874,
            "text": "if (nrn) nrn('d',[{\"a\":\"An <b>archive</b> <b>format</b> is the file <b>format</b> of an <b>archive</b> file. The <b>archive</b> <b>format</b> is determined by the file archiver. ... Retrieved from &#x22;<b>http</b>://en.wikipedia.org/w/index.php?title=<b>Archive</b>_<b>format</b>&amp;oldid=421135705&#x22;\",\"d\":\"en.wikipedia.org/wiki/Archive_format\",\"m\":1,\"s\":\"boss\",\"p\":0,\"c\":\"https://en.wikipedia.org/wiki/Archive_format\",\"u\":\"https://en.wikipedia.org/wiki/Archive_format\",\"h\":0,\"k\":null,\"i\":\"en.wikipedia.org\",\"t\":\"<b>Archive</b> <b>format</b> - Wikipedia, the free encyclopedia\"},{\"a\":\"An HTML version of WARC File <b>Format</b> &#x28;Version 0.9&#x29; is at <b>http</b>://<b>archive</b>-access.sourceforge.net/warc/warc_file_<b>format</b>-0.9.html. Subsequent drafts are also available at <b>http</b>://<b>archive</b>-access.sourceforge.net/warc/ in various <b>formats</b>.\",\"d\":\"digitalpreservation.gov/formats/fdd/fdd000236.shtml\",\"m\":0,\"s\":\"boss\",\"p\":0,\"c\":\"http://www.digitalpreservation.gov/formats/fdd/fdd000236.shtml\",\"u\":\"http://www.digitalpreservation.gov/formats/fdd/fdd000236.shtml\",\"h\":0,\"k\":null,\"i\":\"www.digitalpreservation.gov\",\"t\":\"WARC, Web <b>ARChive</b> file <b>format</b> - Digital Preservation &#x28;Library ...\"},{\"a\":\"An <b>archive</b> <b>format</b> originally used mainly for archiving and distribution of the exact, nearly-exact, or custom-modified contents of an ... indicates whether the <b>format</b> can be restored using an extraction tool that is free software. ^ UCA is a PerfectCompress <b>format</b>. More information available at <b>http</b> ...\",\"d\":\"en.wikipedia.org/wiki/List_of_archive_formats\",\"m\":1,\"s\":\"boss\",\"p\":0,\"c\":\"https://en.wikipedia.org/wiki/List_of_archive_formats\",\"u\":\"https://en.wikipedia.org/wiki/List_of_archive_formats\",\"h\":0,\"k\":null,\"i\":\"en.wikipedia.org\",\"t\":\"List of <b>archive</b> <b>formats</b> - Wikipedia, the free encyclopedia\"},{\"a\":\"The <b>Format</b> Change <b>Archive</b> is built upon the personal collection of its webmasters and submissions by you. If you have any <b>format</b> change airchecks in your collection, data regarding any of the changes on the site, or anything else of note you\\u2019d like to see here on the <b>Format</b> Change <b>Archive</b> ...\",\"d\":\"formatchange.com/contact/\",\"m\":0,\"s\":\"boss\",\"p\":0,\"c\":\"http://formatchange.com/contact/\",\"u\":\"http://formatchange.com/contact/\",\"h\":0,\"k\":null,\"i\":\"formatchange.com\",\"t\":\"<b>Format</b> Change <b>Archive</b> | Contact Us\"},{\"a\":\"The complete <b>archive</b> of The New York Times can now be searched from NYTimes.com \\u2014 more than 13 million articles total. ... <b>Formats</b>. Most articles are available as text only. Photos are available for purchase by e-mailing our photo sales department at photosales@nytimes.com.\",\"d\":\"nytimes.com/ref/membercenter/nytarchive.html\",\"m\":0,\"s\":\"boss\",\"p\":0,\"c\":\"https://www.nytimes.com/ref/membercenter/nytarchive.html\",\"u\":\"https://www.nytimes.com/ref/membercenter/nytarchive.html\",\"h\":0,\"k\":null,\"i\":\"www.nytimes.com\",\"t\":\"New York Times Article <b>Archive</b> - NYTimes.com\"},{\"a\":\"Mozilla <b>Archive</b> <b>Format</b>. MAFF and MHT support for your browser, and more. If you saved web pages using Internet Explorer and can&#x27;t open them with Firefox the Mozilla <b>Archive</b> <b>Format</b> add-on is for you.\",\"d\":\"maf.mozdev.org\",\"m\":0,\"s\":\"boss\",\"p\":0,\"c\":\"http://maf.mozdev.org/\",\"u\":\"http://maf.mozdev.org/\",\"h\":0,\"k\":null,\"i\":\"maf.mozdev.org\",\"t\":\"mozdev.org - maf: index\"},{\"a\":\"Tags. Merchandise &#x28;1&#x29; Sale &#x28;1&#x29; T-Shirts &#x28;1&#x29; The <b>Format</b> &#x28;1&#x29; <b>Archive</b> ... NEW STYLES &amp; Huge T-Shirt Sale <b>http</b>://theformatmerch.com ... We have just put out word that we will not be making a new <b>Format</b> album.\",\"d\":\"theformat.com\",\"m\":0,\"s\":\"boss\",\"p\":0,\"c\":\"http://theformat.com/\",\"u\":\"http://theformat.com/\",\"h\":0,\"k\":null,\"i\":\"theformat.com\",\"t\":\"The <b>Format</b> - Home\"},{\"a\":\"Prelinger <b>Archive</b> Mashups What happens when you make close to 2,000 ephemeral public domain films freely available on the Web? ... Re: Cinemascope and wide <b>format</b> movies on <b>archive</b>.org: Vance Capley: 0 : February 27, 2012 06:56:05pm\",\"d\":\"archive.org/details/moviesandfilms\",\"m\":0,\"s\":\"boss\",\"p\":0,\"c\":\"http://www.archive.org/details/moviesandfilms\",\"u\":\"http://www.archive.org/details/moviesandfilms\",\"h\":0,\"k\":null,\"i\":\"www.archive.org\",\"t\":\"Movies : Free Movies : Download &amp; Streaming : Internet <b>Archive</b>\"},{\"a\":\"English Bulgarian Chinese Simpl. Chinese Trad. French German Japanese Polish Portuguese Brazil Russian Ukrainian. 7z <b>Format</b>. 7z is the new <b>archive</b> <b>format</b>, providing high compression ratio.\",\"d\":\"7-zip.org/7z.html\",\"m\":0,\"s\":\"boss\",\"p\":0,\"c\":\"http://www.7-zip.org/7z.html\",\"u\":\"http://www.7-zip.org/7z.html\",\"h\":0,\"k\":null,\"i\":\"www.7-zip.org\",\"t\":\"7z <b>Format</b> - 7-Zip\"},{\"a\":\"Published: October 21st, 2009; Comments: 4 Comments; Category: Firebug, HAR, NetExport, Planet Mozilla; We have been working with Simon Perkins and Steve Souders on an open <b>format</b> for exporting <b>HTTP</b> tracing information.\",\"d\":\"softwareishard.com/blog/firebug/http-archive-specification/\",\"m\":0,\"s\":\"boss\",\"p\":0,\"c\":\"http://www.softwareishard.com/blog/firebug/http-archive-specification/\",\"u\":\"http://www.softwareishard.com/blog/firebug/http-archive-specification/\",\"h\":0,\"k\":null,\"i\":\"www.softwareishard.com\",\"t\":\"Software is hard | <b>HTTP</b> <b>Archive</b> Specification\"},{\"a\":\"If some crawl-time metadata should be archived near the above response, a &#x27;metadata&#x27; record could be used like the following &#x28;with a purely speculative XML <b>format</b>&#x29;: warc/0.9 395 metadata <b>http</b>://www.<b>archive</b>.org/images/logo.jpg 20050.09010101 text/xml uuid:a4acff63-c213-4f35-9652-41a0e2dfc492 ...\",\"d\":\"archive-access.sourceforge.net/warc/warc_file_format-0.9.html\",\"m\":0,\"s\":\"boss\",\"p\":0,\"c\":\"http://archive-access.sourceforge.net/warc/warc_file_format-0.9.html\",\"u\":\"http://archive-access.sourceforge.net/warc/warc_file_format-0.9.html\",\"h\":0,\"k\":null,\"i\":\"archive-access.sourceforge.net\",\"t\":\"IIPC Framework Working Group: The WARC File <b>Format</b> &#x28;Version 0.9&#x29;\"},{\"a\":\"View the National <b>Archives</b> Operating Status for updates and closures.\",\"d\":\"archives.gov/research/\",\"m\":0,\"s\":\"boss\",\"p\":0,\"c\":\"http://www.archives.gov/research/\",\"u\":\"http://www.archives.gov/research/\",\"h\":0,\"k\":null,\"i\":\"www.archives.gov\",\"t\":\"Research Our Records\"},{\"a\":\"Detailed file <b>formats</b> and data <b>formats</b> for programmers. A large collection of programming resources with detailed information. ... <b>Archive</b> Files Binaries Spreadsheet/Database Financial/Stocks Font Files Game Files\",\"d\":\"wotsit.org\",\"m\":0,\"s\":\"boss\",\"p\":0,\"c\":\"http://www.wotsit.org/\",\"u\":\"http://www.wotsit.org/\",\"h\":0,\"k\":null,\"i\":\"www.wotsit.org\",\"t\":\"Wotsit&#x27;s <b>Format</b>\"},{\"a\":\"Property Description; Parameter type: String: Syntax: LOG_<b>ARCHIVE</b>_<b>FORMAT</b> = filename: Default value: Operating system-dependent: Modifiable: No: Range of values: Any string that resolves to a valid filename\",\"d\":\"stanford.edu/dept/itss/docs/oracle/10g/server.101/b1...\",\"m\":0,\"s\":\"boss\",\"p\":0,\"c\":\"http://www.stanford.edu/dept/itss/docs/oracle/10g/server.101/b10755/initparams104.htm\",\"u\":\"http://www.stanford.edu/dept/itss/docs/oracle/10g/server.101/b10755/initparams104.htm\",\"h\":0,\"k\":null,\"i\":\"www.stanford.edu\",\"t\":\"LOG_<b>ARCHIVE</b>_<b>FORMAT</b> - Stanford University\"},{\"a\":\"CHI <b>Formatting</b> Instructions. CHI uses two different <b>formats</b> for most submissions: HCI <b>Archive</b> and Extended Abstract. HCI <b>Archive</b> <b>Format</b>. These templates should be used for submitting CHI Papers and CHI Notes.\",\"d\":\"chi2011.org/authors/format.html\",\"m\":0,\"s\":\"boss\",\"p\":0,\"c\":\"http://chi2011.org/authors/format.html\",\"u\":\"http://chi2011.org/authors/format.html\",\"h\":0,\"k\":null,\"i\":\"chi2011.org\",\"t\":\"Chi 2011\"},{\"a\":\"Converting to a standard raw <b>format</b> is a better choice for image <b>archives</b>. Currently, Adobe DNG <b>format</b> is the only candidate. Keep in mind, even DNG files may need to be migrated to a subsequent DNG version or a replacement <b>format</b> as yet unknown.\",\"d\":\"dpbestflow.org/file-format/archive-file-formats\",\"m\":0,\"s\":\"boss\",\"p\":0,\"c\":\"http://www.dpbestflow.org/file-format/archive-file-formats\",\"u\":\"http://www.dpbestflow.org/file-format/archive-file-formats\",\"h\":0,\"k\":null,\"i\":\"www.dpbestflow.org\",\"t\":\"<b>Archive</b> File <b>Formats</b> | dpBestflow\"},{\"a\":\"Linux <b>Format</b> <b>Archives</b> ... Click here to see all available PDFs. Note: PDFs are &#x28;C&#x29; Future Publishing and may not be redistributed without permission from the editor.\",\"d\":\"linuxformat.com/archives\",\"m\":0,\"s\":\"boss\",\"p\":0,\"c\":\"http://www.linuxformat.com/archives\",\"u\":\"http://www.linuxformat.com/archives\",\"h\":0,\"k\":null,\"i\":\"www.linuxformat.com\",\"t\":\"Linux <b>Format</b> <b>Archives</b> | Linux <b>Format</b>\"},{\"a\":\"Base URL: <b>http</b>://api.remix.bestbuy.com/v1/{<b>archive</b>}.{<b>format</b>}.zip. <b>Format</b>: xml or json: products, stores, categories, or reviews. tsv: storeAvailability\",\"d\":\"bbyopen.com/documentation/archives\",\"m\":0,\"s\":\"boss\",\"p\":0,\"c\":\"http://bbyopen.com/documentation/archives\",\"u\":\"http://bbyopen.com/documentation/archives\",\"h\":0,\"k\":null,\"i\":\"bbyopen.com\",\"t\":\"<b>Archives</b> | BBYOPEN\"},{\"a\":\"Yahoo Messenger <b>Archive</b> 1on1 . One of the better features of yahoo messenger is the <b>archive</b> viewer. Unlike msn messenger, yahoo stores the <b>archive</b> in a structured <b>format</b>.\",\"d\":\"venkydude.com/articles/yarchive.htm\",\"m\":0,\"s\":\"boss\",\"p\":0,\"c\":\"http://www.venkydude.com/articles/yarchive.htm\",\"u\":\"http://www.venkydude.com/articles/yarchive.htm\",\"h\":0,\"k\":null,\"i\":\"www.venkydude.com\",\"t\":\"Yahoo Messenger <b>Archive</b> - Venky\\u2019s World\"},{\"a\":\"8601 Adelphi Road, College Park, MD 20740-6001 Telephone: 1-86-NARA-NARA or 1-866-272-6272 The National <b>Archives</b> Experience; Our Documents; Regulations.gov\",\"d\":\"aad.archives.gov/aad/\",\"m\":0,\"s\":\"boss\",\"p\":0,\"c\":\"http://aad.archives.gov/aad/\",\"u\":\"http://aad.archives.gov/aad/\",\"h\":0,\"k\":null,\"i\":\"aad.archives.gov\",\"t\":\"NARA - AAD - Main Page\"},{\"a\":\"<b>HTTP</b> <b>Archive</b> Specification ... Will browsers eventually let a site request a HAR file from a regular user?\",\"d\":\"groups.google.com/group/http-archive-specification\",\"m\":0,\"s\":\"boss\",\"p\":0,\"c\":\"http://www.groups.google.com/group/http-archive-specification\",\"u\":\"http://www.groups.google.com/group/http-archive-specification\",\"h\":0,\"k\":null,\"i\":\"www.groups.google.com\",\"t\":\"<b>HTTP</b> <b>Archive</b> Specification | Google Groups\"},{\"a\":\"I\\u2019d like to provide some information about a new file <b>format</b> to some of you who have been involved with uploading already-digitized materials to the <b>Archive</b>. ... <b>http</b>://ia700400.us.<b>archive</b>.org/zipview.php?zip=/25/items/hr10.116/hr100106_images.zip\",\"d\":\"raj.blog.archive.org/2011/02/24/new-upload-format-_images-zi...\",\"m\":0,\"s\":\"boss\",\"p\":0,\"c\":\"http://raj.blog.archive.org/2011/02/24/new-upload-format-_images-zip-for-scribe-style-uploads/\",\"u\":\"http://raj.blog.archive.org/2011/02/24/new-upload-format-_images-zip-for-scribe-style-uploads/\",\"h\":0,\"k\":null,\"i\":\"raj.blog.archive.org\",\"t\":\"New Upload <b>Format</b>, *_images.zip, for Scribe-style Uploads ...\"},{\"a\":\"8. Controlling the <b>Archive</b> <b>Format</b> . Due to historical reasons, there are several <b>formats</b> of tar <b>archives</b>. All of them are based on the same principles, but have some subtle differences that often make them incompatible with each other.\",\"d\":\"gnu.org/software/tar/manual/html_section/Format...\",\"m\":0,\"s\":\"boss\",\"p\":0,\"c\":\"http://www.gnu.org/software/tar/manual/html_section/Formats.html\",\"u\":\"http://www.gnu.org/software/tar/manual/html_section/Formats.html\",\"h\":0,\"k\":null,\"i\":\"www.gnu.org\",\"t\":\"GNU tar 1.26: 8. Controlling the <b>Archive</b> <b>Format</b>\"},{\"a\":\"This processor writes the found crawl content as Internet <b>Archive</b> ARC files. The ARC file <b>format</b> is described here: Arc File <b>Format</b>. ... Example: &#x27;heritrix 0.7.1 <b>http</b>://crawler.<b>archive</b>.org&#x27;. The IP of the host that created the ARC file.\",\"d\":\"crawler.archive.org/articles/developer_manual/arcs.html\",\"m\":0,\"s\":\"boss\",\"p\":0,\"c\":\"http://crawler.archive.org/articles/developer_manual/arcs.html\",\"u\":\"http://crawler.archive.org/articles/developer_manual/arcs.html\",\"h\":0,\"k\":null,\"i\":\"crawler.archive.org\",\"t\":\"13. Internet <b>Archive</b> ARC files\"},{\"a\":\"How do I customize my <b>archive</b> filename <b>format</b> in Movable Type 4? - Free tech support help from Ask Dave Taylor ... <b>http</b>://domainname/beginning_of_blog_title.html\",\"d\":\"askdavetaylor.com/how_to_customize_archive_filename_forma...\",\"m\":0,\"s\":\"boss\",\"p\":0,\"c\":\"http://www.askdavetaylor.com/how_to_customize_archive_filename_format_mt4_movable_type_4.html\",\"u\":\"http://www.askdavetaylor.com/how_to_customize_archive_filename_format_mt4_movable_type_4.html\",\"h\":0,\"k\":null,\"i\":\"www.askdavetaylor.com\",\"t\":\"How do I customize my <b>archive</b> filename <b>format</b> in Movable Type ...\"},{\"a\":\"CERT-FI and CPNI Joint Vulnerability Advisory on <b>Archive</b> <b>Formats</b> Vulnerability Research in <b>Archive</b> <b>Formats</b> ... More information about potential impact, affected products and available patches can be found in the advisory FSC-2008-2 located at <b>http</b>://www.f ...\",\"d\":\"cert.fi/haavoittuvuudet/joint-advisory-archive-...\",\"m\":0,\"s\":\"boss\",\"p\":0,\"c\":\"http://www.cert.fi/haavoittuvuudet/joint-advisory-archive-formats.html\",\"u\":\"http://www.cert.fi/haavoittuvuudet/joint-advisory-archive-formats.html\",\"h\":0,\"k\":null,\"i\":\"www.cert.fi\",\"t\":\"CERT-FI and CPNI Joint Vulnerability Advisory on <b>Archive</b> <b>Formats</b>\"},{\"n\":\"d.js?q=http%20archive%20format&l=us-en&p=1&s=30\"}]);\n"
          },
          "redirectURL": "",
          "headersSize": 267,
          "bodySize": 4718
        },
        "cache": {},
        "timings": {
          "blocked": 0,
          "dns": 0,
          "connect": 723,
          "send": 0,
          "wait": 1095,
          "receive": 0
        },
        "serverIPAddress": "184.72.106.52",
        "connection": "443"
      },
      {
        "pageref": "page_40125",
        "startedDateTime": "2012-03-23T16:31:08.319+11:00",
        "time": 1330,
        "request": {
          "method": "GET",
          "url": "https://builder.duckduckgo.com/b.js?q=http%20archive%20format",
          "httpVersion": "HTTP/1.1",
          "cookies": [],
          "headers": [
            {
              "name": "Host",
              "value": "builder.duckduckgo.com"
            },
            {
              "name": "User-Agent",
              "value": "Mozilla/5.0 (Windows NT 6.1; WOW64; rv:11.0) Gecko/2010.111 Firefox/11.0"
            },
            {
              "name": "Accept",
              "value": "*/*"
            },
            {
              "name": "Accept-Language",
              "value": "en-us,en;q=0.5"
            },
            {
              "name": "Accept-Encoding",
              "value": "gzip, deflate"
            },
            {
              "name": "Connection",
              "value": "keep-alive"
            },
            {
              "name": "Referer",
              "value": "https://duckduckgo.com/"
            }
          ],
          "queryString": [
            {
              "name": "q",
              "value": "http archive format"
            }
          ],
          "headersSize": 300,
          "bodySize": -1
        },
        "response": {
          "status": 200,
          "statusText": "OK",
          "httpVersion": "HTTP/1.1",
          "cookies": [],
          "headers": [
            {
              "name": "Server",
              "value": "nginx"
            },
            {
              "name": "Date",
              "value": "Fri, 23 Mar 2012 05:27:55 GMT"
            },
            {
              "name": "Content-Type",
              "value": "application/x-javascript; charset=UTF-8"
            },
            {
              "name": "Transfer-Encoding",
              "value": "chunked"
            },
            {
              "name": "Connection",
              "value": "keep-alive"
            },
            {
              "name": "Expires",
              "value": "Fri, 23 Mar 2012 05:27:54 GMT"
            },
            {
              "name": "Cache-Control",
              "value": "no-cache"
            },
            {
              "name": "Content-Encoding",
              "value": "gzip"
            }
          ],
          "content": {
            "mimeType": "application/x-javascript",
            "size": 225,
            "text": "if (nrq) nrq([{\"r\":\"\",\"s\":\"files\"},{\"r\":\"\",\"s\":\"compression\"},{\"r\":\"\",\"s\":\"please\"},{\"r\":\"\",\"s\":\"javascript\"},{\"r\":\"\",\"s\":\"version\"},{\"r\":\"\",\"s\":\"string\"},{\"r\":\"\",\"s\":\"submitting\"},{\"r\":\"\",\"s\":\"sigchi\"},{\"r\":\"\",\"s\":\"linux\"}])"
          },
          "redirectURL": "",
          "headersSize": 267,
          "bodySize": 126
        },
        "cache": {},
        "timings": {
          "blocked": 1,
          "dns": 0,
          "connect": 910,
          "send": 0,
          "wait": 419,
          "receive": 0
        },
        "serverIPAddress": "176.34.131.233",
        "connection": "443"
      }
    ]
  }
}
_FIREBUG_RESULTS_
ok($har->string($firebug_post_string), "Successfully read firebug har archive for POSTed request for http://duckduckgo.com via Firefox search box");
my $har2 = Archive::Har->new();
$har2->string($firebug_post_string);
my $string1 = "$har";
my $string2 = $har2->string();
ok($string1 eq $string2, "JSON objects have the same sort order for hashes");
my $gzip = $har->gzip();
ok($gzip =~ /^\x1f\x8b/, "Gzipped har file has the correct magic number");
ok($har->gzip($gzip), "Successfully uncompressed a compressed har stream");
($firstEntry) = $har->entries();
ok($firstEntry->request()->method() eq 'POST', "INPUT: Firebug's archive first entry request has a method of 'POST'");
ok($firstEntry->request()->body_size() == 97, "INPUT: Firebug's archive first entry request has a body size of 97");
ok($firstEntry->request()->post_data()->mime_type() eq 'application/x-www-form-urlencoded', "INPUT: Firebug's archive first entry request has a post data mime type of 'application/x-www-form-urlencoded'");
ok(not(defined $firstEntry->request()->post_data()->text()), "INPUT: Firebug's archive first entry request has a post data text that is not defined");
ok(scalar $firstEntry->request()->post_data()->params() == 2, "INPUT: Firebug's archive first entry request has a post data with 2 parameters");
ok(scalar $firstEntry->request()->post_data()->params() == 2, "INPUT: Firebug's archive first entry request has a post data with 2 parameters");
my (undef, $secondParam) = $firstEntry->request()->post_data()->params();
ok($secondParam->name() eq 'q', "INPUT: Firebug's archive first entry request has a post data with the second parameter having a name of 'q'");
ok($secondParam->value() eq 'http archive format', "INPUT: Firebug's archive first entry request has a post data with the second parameter having a name of 'http archive format'");
ok(not(defined $secondParam->file_name()), "INPUT: Firebug's archive first entry request has a post data with the second parameter having a fileName returning undef");
ok(not(defined $secondParam->content_type()), "INPUT: Firebug's archive first entry request has a post data with the second parameter having a contentType returning undef");
ok($firstEntry->response()->status() == 200, "INPUT: Firebug's archive first entry response has a status of 200");
ok($firstEntry->response()->status_text() eq 'OK', "INPUT: Firebug's archive first entry response has a status text of 'OK'");
ok($firstEntry->response()->http_version() eq 'HTTP/1.1', "INPUT: Firebug's archive first entry response has an http version of 'HTTP/1.1'");
ok(scalar $firstEntry->response()->cookies() == 0, "INPUT: Pingdom's archive first entry response has an empty cookie list");
ok(scalar $firstEntry->response()->headers() == 8, "INPUT: Pingdom's archive first entry response has 8 headers");
@headers = $firstEntry->response()->headers();
ok($headers[0]->name() eq 'Server', "INPUT: Firebug's archive first entry response first header has a name of 'Server'");
ok($headers[0]->value() eq 'nginx', "INPUT: Firebug's archive first entry response first header has a value of 'nginx'");
ok($firstEntry->response()->content()->mime_type() eq 'text/html', "INPUT: Firebug's archive first entry response content has a mime type of 'text/html'");
ok($firstEntry->response()->content()->size() == 6730, "INPUT: Firebug's archive first entry response content has a size of 6730");
ok($firstEntry->response()->content()->text() =~ /^<!DOCTYPE HTML PUBLIC/, "INPUT: Firebug's archive first entry response content has a text value beginning with /^<!DOCTYPE HTML PUBLIC/");
ok($firstEntry->response()->redirect_url() eq '', "INPUT: Firebug's archive first entry response has a redirectURL of ''");
ok($firstEntry->response()->headers_size() == 253, "INPUT: Firebug's archive first entry response has a headersSize value of 253");
ok($firstEntry->response()->body_size() == 2673, "INPUT: Firebug's archive first entry response has a bodySize value of 2673");
ok($firstEntry->server_ip_address() eq '184.72.106.52', "INPUT: Firebug's archive first entry has a server ip address of '184.72.106.52'");
ok($firstEntry->connection() eq '443', "INPUT: Firebug's archive first entry has a connection value of '443'");
$firebug_ref = JSON::decode_json($har->string());
ok($firebug_ref->{log}->{entries}->[0]->{request}->{method} eq 'POST', "OUTPUT: Firebug's archive first entry request has method of 'POST'");
ok($firebug_ref->{log}->{entries}->[0]->{request}->{bodySize} eq '97', "OUTPUT: Firebug's archive first entry request has a body size of '97'");
ok($firebug_ref->{log}->{entries}->[0]->{request}->{postData}->{mimeType} eq 'application/x-www-form-urlencoded', "OUTPUT: Firebug's archive first entry request has a post data mime type of 'application/x-www-form-urlencoded'");
ok($firebug_ref->{log}->{entries}->[0]->{request}->{postData}->{text} eq '', "OUTPUT: Firebug's archive first entry request has a post data text of ''");
ok(scalar @{$firebug_ref->{log}->{entries}->[0]->{request}->{postData}->{params}} == 2, "OUTPUT: Firebug's archive first entry request has a post data with 2 parameters");
ok($firebug_ref->{log}->{entries}->[0]->{request}->{postData}->{params}->[1]->{name} eq 'q', "OUTPUT: Firebug's archive first entry request has a post data with the second parameter having a name of 'q'");
ok($firebug_ref->{log}->{entries}->[0]->{request}->{postData}->{params}->[1]->{value} eq 'http archive format', "OUTPUT: Firebug's archive first entry request has a post data with the second parameter having a name of 'http archive format'");
ok(not(exists $firebug_ref->{log}->{entries}->[0]->{request}->{postData}->{params}->[1]->{fileName}), "OUTPUT: Firebug's archive first entry request has a post data with the second parameter not having a fileName attribute");
ok(not(exists $firebug_ref->{log}->{entries}->[0]->{request}->{postData}->{params}->[1]->{contentType}), "OUTPUT: Firebug's archive first entry request has a post data with the second parameter not having a contentType attribute");
ok($firebug_ref->{log}->{entries}->[0]->{response}->{status} == 200, "OUTPUT: Firebug's archive first entry response has a status of 200");
ok($firebug_ref->{log}->{entries}->[0]->{response}->{statusText} eq 'OK', "OUTPUT: Firebug's archive first entry response has a status text of 'OK'");
ok($firebug_ref->{log}->{entries}->[0]->{response}->{httpVersion} eq 'HTTP/1.1', "OUTPUT: Firebug's archive first entry response has an http version of 'HTTP/1.1'");
ok(scalar @{$firebug_ref->{log}->{entries}->[0]->{response}->{cookies}} == 0, "OUTPUT: Firebug's archive first entry response has an empty cookie list");
ok($firebug_ref->{log}->{entries}->[0]->{response}->{headers}->[0]->{name} eq 'Server', "OUTPUT: Firebug's archive first entry response first header has a name of 'Server'");
ok($firebug_ref->{log}->{entries}->[0]->{response}->{headers}->[0]->{value} eq 'nginx', "OUTPUT: Firebug's archive first entry response first header has a name of 'nginx'");
ok($firebug_ref->{log}->{entries}->[0]->{response}->{content}->{mimeType} eq 'text/html', "OUTPUT: Firebug's archive first entry response content has a mime type of 'text/html'");
ok($firebug_ref->{log}->{entries}->[0]->{response}->{content}->{size} == 6730, "OUTPUT: Firebug's archive first entry response content has a size of 6730");
ok($firebug_ref->{log}->{entries}->[0]->{response}->{content}->{text} =~ /^<!DOCTYPE HTML PUBLIC/, "OUTPUT: Firebug's archive first entry response content has a text beginning with /^<!DOCTYPE HTML PUBLIC/");
ok($firebug_ref->{log}->{entries}->[0]->{response}->{redirectURL} eq '', "OUTPUT: Firebug's archive first entry response has a redirect url value of ''");
ok($firebug_ref->{log}->{entries}->[0]->{response}->{headersSize} == 253, "OUTPUT: Firebug's archive first entry response has a headers size of 253");
ok($firebug_ref->{log}->{entries}->[0]->{response}->{bodySize} == 2673, "OUTPUT: Firebug's archive first entry response has a headers size of 2673");
ok($firebug_ref->{log}->{entries}->[0]->{serverIPAddress} eq '184.72.106.52', "OUTPUT: Firebug's archive first entry has a server ip address of '184.72.106.52'");
ok($firebug_ref->{log}->{entries}->[0]->{connection} eq '443', "OUTPUT: Firebug's archive first entry has a connection of '443'");
