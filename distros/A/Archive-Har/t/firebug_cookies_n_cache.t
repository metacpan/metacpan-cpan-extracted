#!perl -T

use strict;
use warnings;
use Test::More tests => 19;
use Archive::Har();
use JSON();

my $har = Archive::Har->new();

my $firebug_gmail_string = <<'_FIREBUG_RESULTS_';
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
        "startedDateTime": "2012-04-03T10:22:44.027+10:00",
        "id": "page_7372",
        "title": "Google Account Recovery",
        "pageTimings": {
          "onContentLoad": 1425,
          "onLoad": 1904
        }
      }
    ],
    "entries": [
      {
        "pageref": "page_7372",
        "startedDateTime": "2012-04-03T10:22:44.027+10:00",
        "time": 171,
        "request": {
          "method": "GET",
          "url": "https://accounts.google.com/RecoverAccount?service=mail&continue=https%3A%2F%2Fmail.google.com%2Fmail%2F",
          "httpVersion": "HTTP/1.1",
          "cookies": [
            {
              "name": "GAPS",
              "value": "1:DDqz846LwmuAAEMnC2gyLWhWKFcnVw:gbYgam4NP7QziTrv"
            },
            {
              "name": "GALX",
              "value": "TIEGS2iZCMA"
            },
            {
              "name": "__utma",
              "value": "72592003.926212856.1333412463.1333412463.1333412463.1"
            },
            {
              "name": "__utmb",
              "value": "72592003.1.10.1333412463"
            },
            {
              "name": "__utmc",
              "value": "72592003"
            },
            {
              "name": "__utmz",
              "value": "72592003.1333412463.1.1.utmcsr=(direct)|utmccn=(direct)|utmcmd=(none)"
            },
            {
              "name": "GMAIL_RTT",
              "value": "270"
            }
          ],
          "headers": [
            {
              "name": "Accept",
              "value": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"
            },
            {
              "name": "Accept-Encoding",
              "value": "gzip, deflate"
            },
            {
              "name": "Accept-Language",
              "value": "en-us,en;q=0.5"
            },
            {
              "name": "Connection",
              "value": "keep-alive"
            },
            {
              "name": "Cookie",
              "value": "GAPS=1:DDqz846LwmuAAEMnC2gyLWhWKFcnVw:gbYgam4NP7QziTrv; GALX=TIEGS2iZCMA; __utma=72592003.926212856.1333412463.1333412463.1333412463.1; __utmb=72592003.1.10.1333412463; __utmc=72592003; __utmz=72592003.1333412463.1.1.utmcsr=(direct)|utmccn=(direct)|utmcmd=(none); GMAIL_RTT=270"
            },
            {
              "name": "Host",
              "value": "accounts.google.com"
            },
            {
              "name": "Referer",
              "value": "https://accounts.google.com/ServiceLogin?service=mail&passive=true&rm=false&continue=https://mail.google.com/mail/&ss=1&scc=1&ltmpl=default&ltmplcache=2"
            },
            {
              "name": "User-Agent",
              "value": "Mozilla/5.0 (Windows NT 6.1; WOW64; rv:11.0) Gecko/20100101 Firefox/11.0"
            }
          ],
          "queryString": [
            {
              "name": "continue",
              "value": "https://mail.google.com/mail/"
            },
            {
              "name": "service",
              "value": "mail"
            }
          ],
          "headersSize": 819,
          "bodySize": -1
        },
        "response": {
          "status": 302,
          "statusText": "Moved Temporarily",
          "httpVersion": "HTTP/1.1",
          "cookies": [
            {
              "name": "GAPS",
              "value": "1:7lNRDK-IDqGcYJ9p96pYz3uxutH5Wg:M0u1gFR0z-Ip0Cf5;Path"
            }
          ],
          "headers": [
            {
              "name": "Cache-Control",
              "value": "private, max-age=0"
            },
            {
              "name": "Content-Encoding",
              "value": "gzip"
            },
            {
              "name": "Content-Length",
              "value": "322"
            },
            {
              "name": "Content-Type",
              "value": "text/html; charset=UTF-8"
            },
            {
              "name": "Date",
              "value": "Tue, 03 Apr 2012 00:22:41 GMT"
            },
            {
              "name": "Expires",
              "value": "Tue, 03 Apr 2012 00:22:41 GMT"
            },
            {
              "name": "Location",
              "value": "https://www.google.com/accounts/recovery?hl=en&gaps=AHwGkRnIr9MHrtSt185ONR1lo-pCrkYz6yM6OsQ7bVzmMns3l13BWiR9PLWiDq0l6rLX2DvH8M3twg6yaZyOdFqKlMIWNA9HmA&service=mail&continue=https%3A%2F%2Fmail.google.com%2Fmail%2F"
            },
            {
              "name": "Server",
              "value": "GSE"
            },
            {
              "name": "Set-Cookie",
              "value": "GAPS=1:7lNRDK-IDqGcYJ9p96pYz3uxutH5Wg:M0u1gFR0z-Ip0Cf5;Path=/;Expires=Thu, 03-Apr-2014 00:22:41 GMT;Secure;HttpOnly"
            },
            {
              "name": "Strict-Transport-Security",
              "value": "max-age=2592000; includeSubDomains"
            },
            {
              "name": "X-Content-Type-Options",
              "value": "nosniff"
            },
            {
              "name": "X-XSS-Protection",
              "value": "1; mode=block"
            }
          ],
          "content": {
            "mimeType": "text/html",
            "size": 322
          },
          "redirectURL": "https://www.google.com/accounts/recovery?hl=en&gaps=AHwGkRnIr9MHrtSt185ONR1lo-pCrkYz6yM6OsQ7bVzmMns3l13BWiR9PLWiDq0l6rLX2DvH8M3twg6yaZyOdFqKlMIWNA9HmA&service=mail&continue=https%3A%2F%2Fmail.google.com%2Fmail%2F",
          "headersSize": 726,
          "bodySize": 322
        },
        "cache": {},
        "timings": {
          "blocked": 1,
          "dns": 0,
          "connect": 0,
          "send": 0,
          "wait": 169,
          "receive": 1
        },
        "serverIPAddress": "173.194.72.84",
        "connection": "443"
      },
      {
        "pageref": "page_7372",
        "startedDateTime": "2012-04-03T10:22:44.212+10:00",
        "time": 971,
        "request": {
          "method": "GET",
          "url": "https://www.google.com/accounts/recovery?hl=en&gaps=AHwGkRnIr9MHrtSt185ONR1lo-pCrkYz6yM6OsQ7bVzmMns3l13BWiR9PLWiDq0l6rLX2DvH8M3twg6yaZyOdFqKlMIWNA9HmA&service=mail&continue=https%3A%2F%2Fmail.google.com%2Fmail%2F",
          "httpVersion": "HTTP/1.1",
          "cookies": [
            {
              "name": "GMAIL_RTT",
              "value": "270"
            }
          ],
          "headers": [
            {
              "name": "Host",
              "value": "www.google.com"
            },
            {
              "name": "User-Agent",
              "value": "Mozilla/5.0 (Windows NT 6.1; WOW64; rv:11.0) Gecko/20100101 Firefox/11.0"
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
            },
            {
              "name": "Referer",
              "value": "https://accounts.google.com/ServiceLogin?service=mail&passive=true&rm=false&continue=https://mail.google.com/mail/&ss=1&scc=1&ltmpl=default&ltmplcache=2"
            },
            {
              "name": "Cookie",
              "value": "GMAIL_RTT=270"
            }
          ],
          "queryString": [
            {
              "name": "continue",
              "value": "https://mail.google.com/mail/"
            },
            {
              "name": "gaps",
              "value": "AHwGkRnIr9MHrtSt185ONR1lo-pCrkYz6yM6OsQ7bVzmMns3l13BWiR9PLWiDq0l6rLX2DvH8M3twg6yaZyOdFqKlMIWNA9HmA"
            },
            {
              "name": "hl",
              "value": "en"
            },
            {
              "name": "service",
              "value": "mail"
            }
          ],
          "headersSize": 663,
          "bodySize": -1
        },
        "response": {
          "status": 200,
          "statusText": "OK",
          "httpVersion": "HTTP/1.1",
          "cookies": [
            {
              "name": "accountrecoverylocale",
              "value": "en",
              "expires": "2012-04-10T10:22:42.000+10:00",
              "path": "/accounts/recovery",
              "httpOnly": true
            },
            {
              "name": "mainpageaccountrecoveryparamscookie",
              "value": "CmJBSHdHa1JuSXI5TUhydFN0MTg1T05SMWxvLXBDcmtZejZ5TTZPc1E3YlZ6bU1uczNsMTNCV2lSOVBMV2lEcTBsNnJMWDJEdkg4TTN0d2c2eWFaeU9kRnFLbE1JV05BOUhtQRIdaHR0cHM6Ly9tYWlsLmdvb2dsZS5jb20vbWFpbC8gspOJo8ub6qNN",
              "expires": "2012-04-10T10:22:42.000+10:00",
              "path": "/accounts/recovery",
              "httpOnly": true
            },
            {
              "name": "S",
              "value": "account-recovery",
              "domain": ".google.com",
              "path": "/",
              "httpOnly": true
            }
          ],
          "headers": [
            {
              "name": "Cache-Control",
              "value": "no-cache, max-age=0, must-revalidate"
            },
            {
              "name": "Pragma",
              "value": "no-cache"
            },
            {
              "name": "Expires",
              "value": "Fri, 01 Jan 1990 00:00:00 GMT"
            },
            {
              "name": "Date",
              "value": "Tue, 03 Apr 2012 00:22:42 GMT"
            },
            {
              "name": "Set-Cookie",
              "value": "accountrecoverylocale=en; Expires=Tue, 10-Apr-2012 00:22:42 GMT; Path=/accounts/recovery; Secure; HttpOnly\nmainpageaccountrecoveryparamscookie=CmJBSHdHa1JuSXI5TUhydFN0MTg1T05SMWxvLXBDcmtZejZ5TTZPc1E3YlZ6bU1uczNsMTNCV2lSOVBMV2lEcTBsNnJMWDJEdkg4TTN0d2c2eWFaeU9kRnFLbE1JV05BOUhtQRIdaHR0cHM6Ly9tYWlsLmdvb2dsZS5jb20vbWFpbC8gspOJo8ub6qNN; Expires=Tue, 10-Apr-2012 00:22:42 GMT; Path=/accounts/recovery; Secure; HttpOnly\nS=account-recovery=bD7NAj-9Icg; Domain=.google.com; Path=/; Secure; HttpOnly"
            },
            {
              "name": "Content-Type",
              "value": "text/html; charset=UTF-8"
            },
            {
              "name": "Content-Encoding",
              "value": "gzip"
            },
            {
              "name": "X-Content-Type-Options",
              "value": "nosniff"
            },
            {
              "name": "X-Frame-Options",
              "value": "SAMEORIGIN"
            },
            {
              "name": "X-XSS-Protection",
              "value": "1; mode=block"
            },
            {
              "name": "Content-Length",
              "value": "2533"
            },
            {
              "name": "Server",
              "value": "GSE"
            }
          ],
          "content": {
            "mimeType": "text/html",
            "size": 2533
          },
          "redirectURL": "",
          "headersSize": 865,
          "bodySize": 2533
        },
        "cache": {},
        "timings": {
          "blocked": 1,
          "dns": 0,
          "connect": 709,
          "send": 0,
          "wait": 260,
          "receive": 1
        },
        "serverIPAddress": "74.125.237.116",
        "connection": "443"
      },
      {
        "pageref": "page_7372",
        "startedDateTime": "2012-04-03T10:22:45.260+10:00",
        "time": 63,
        "request": {
          "method": "GET",
          "url": "https://www.google.com/accounts/recovery/resources/3135485014-options_bin.js",
          "httpVersion": "HTTP/1.1",
          "cookies": [
            {
              "name": "accountrecoverylocale",
              "value": "en"
            },
            {
              "name": "mainpageaccountrecoveryparamscookie",
              "value": "CmJBSHdHa1JuSXI5TUhydFN0MTg1T05SMWxvLXBDcmtZejZ5TTZPc1E3YlZ6bU1uczNsMTNCV2lSOVBMV2lEcTBsNnJMWDJEdkg4TTN0d2c2eWFaeU9kRnFLbE1JV05BOUhtQRIdaHR0cHM6Ly9tYWlsLmdvb2dsZS5jb20vbWFpbC8gspOJo8ub6qNN"
            },
            {
              "name": "GMAIL_RTT",
              "value": "270"
            },
            {
              "name": "S",
              "value": "account-recovery=bD7NAj-9Icg"
            }
          ],
          "headers": [
            {
              "name": "Host",
              "value": "www.google.com"
            },
            {
              "name": "User-Agent",
              "value": "Mozilla/5.0 (Windows NT 6.1; WOW64; rv:11.0) Gecko/20100101 Firefox/11.0"
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
              "value": "https://www.google.com/accounts/recovery?hl=en&gaps=AHwGkRnIr9MHrtSt185ONR1lo-pCrkYz6yM6OsQ7bVzmMns3l13BWiR9PLWiDq0l6rLX2DvH8M3twg6yaZyOdFqKlMIWNA9HmA&service=mail&continue=https%3A%2F%2Fmail.google.com%2Fmail%2F"
            },
            {
              "name": "Cookie",
              "value": "accountrecoverylocale=en; mainpageaccountrecoveryparamscookie=CmJBSHdHa1JuSXI5TUhydFN0MTg1T05SMWxvLXBDcmtZejZ5TTZPc1E3YlZ6bU1uczNsMTNCV2lSOVBMV2lEcTBsNnJMWDJEdkg4TTN0d2c2eWFaeU9kRnFLbE1JV05BOUhtQRIdaHR0cHM6Ly9tYWlsLmdvb2dsZS5jb20vbWFpbC8gspOJo8ub6qNN; GMAIL_RTT=270; S=account-recovery=bD7NAj-9Icg"
            }
          ],
          "queryString": [],
          "headersSize": 811,
          "bodySize": -1
        },
        "response": {
          "status": 200,
          "statusText": "OK",
          "httpVersion": "HTTP/1.1",
          "cookies": [],
          "headers": [
            {
              "name": "Expires",
              "value": "Fri, 27 Apr 2012 14:27:20 GMT"
            },
            {
              "name": "Date",
              "value": "Wed, 28 Mar 2012 14:27:20 GMT"
            },
            {
              "name": "Last-Modified",
              "value": "Sat, 24 Mar 2012 08:58:08 GMT"
            },
            {
              "name": "Content-Type",
              "value": "text/javascript; charset=utf-8"
            },
            {
              "name": "Content-Encoding",
              "value": "gzip"
            },
            {
              "name": "X-Content-Type-Options",
              "value": "nosniff"
            },
            {
              "name": "X-Frame-Options",
              "value": "SAMEORIGIN"
            },
            {
              "name": "X-XSS-Protection",
              "value": "1; mode=block"
            },
            {
              "name": "Server",
              "value": "GSE"
            },
            {
              "name": "Cache-Control",
              "value": "public, max-age=2592000"
            },
            {
              "name": "Content-Length",
              "value": "15612"
            },
            {
              "name": "Age",
              "value": "467722"
            }
          ],
          "content": {
            "mimeType": "text/javascript",
            "size": 39903,
            "text": "(function (){ function e(a){throw a;}var l=void 0,m=!0,n=null,p=!1,aa=window,r=Error,ba=parseInt,s=parseFloat,da=Function,ea=document,fa=Array,t=Math;function ga(a,b){return a.width=b}function ha(a,b){return a.innerHTML=b}function ia(a,b){return a.value=b}function ja(a,b){return a.currentTarget=b}function v(a,b){return a.left=b}function ka(a,b){return a.keyCode=b}function la(a,b){return a.type=b}function ma(a,b){return a.visibility=b}function na(a,b){return a.toString=b}function oa(a,b){return a.length=b}\nfunction pa(a,b){return a.className=b}function qa(a,b){return a.target=b}function ra(a,b){return a.bottom=b}function sa(a,b){return a.display=b}function ta(a,b){return a.height=b}function ua(a,b){return a.right=b}\nvar va=\"appendChild\",wa=\"push\",xa=\"activeElement\",ya=\"getBoundingClientRect\",w=\"width\",za=\"slice\",x=\"replace\",Aa=\"nodeType\",Ba=\"offsetWidth\",Ca=\"preventDefault\",Da=\"targetTouches\",y=\"indexOf\",Ea=\"dispatchEvent\",Fa=\"capture\",A=\"left\",Ha=\"getElementsByClassName\",Ia=\"screenX\",Ja=\"screenY\",Ka=\"getBoxObjectFor\",La=\"createElement\",Ma=\"keyCode\",Na=\"clientLeft\",Oa=\"setAttribute\",Pa=\"clientTop\",Qa=\"handleEvent\",B=\"type\",Ra=\"parentWindow\",Sa=\"defaultView\",Ta=\"bind\",Ua=\"documentElement\",Va=\"scrollTop\",Wa=\"toString\",\nC=\"length\",Xa=\"propertyIsEnumerable\",F=\"prototype\",Ya=\"clientWidth\",Za=\"document\",$a=\"split\",ab=\"stopPropagation\",G=\"style\",H=\"body\",bb=\"target\",I=\"call\",db=\"clientHeight\",eb=\"scrollLeft\",J=\"bottom\",fb=\"currentStyle\",K=\"apply\",gb=\"tagName\",hb=\"parentNode\",ib=\"append\",L=\"height\",jb=\"join\",kb=\"unshift\",M=\"right\",N,O=this,mb=function(a,b,c){a=a[$a](\".\");c=c||O;!(a[0]in c)&&c.execScript&&c.execScript(\"var \"+a[0]);for(var d;a[C]&&(d=a.shift());)!a[C]&&lb(b)?c[d]=b:c=c[d]?c[d]:c[d]={}},nb=function(){},\nob=function(a){a.jb=function(){return a.kb?a.kb:a.kb=new a}},pb=function(a){var b=typeof a;if(\"object\"==b)if(a){if(a instanceof fa)return\"array\";if(a instanceof Object)return b;var c=Object[F][Wa][I](a);if(\"[object Window]\"==c)return\"object\";if(\"[object Array]\"==c||\"number\"==typeof a[C]&&\"undefined\"!=typeof a.splice&&\"undefined\"!=typeof a[Xa]&&!a[Xa](\"splice\"))return\"array\";if(\"[object Function]\"==c||\"undefined\"!=typeof a[I]&&\"undefined\"!=typeof a[Xa]&&!a[Xa](\"call\"))return\"function\"}else return\"null\";\nelse if(\"function\"==b&&\"undefined\"==typeof a[I])return\"object\";return b},lb=function(a){return a!==l},qb=function(a){return\"array\"==pb(a)},rb=function(a){var b=pb(a);return\"array\"==b||\"object\"==b&&\"number\"==typeof a[C]},P=function(a){return\"string\"==typeof a},sb=function(a){return\"number\"==typeof a},tb=function(a){return\"function\"==pb(a)},ub=function(a){var b=typeof a;return\"object\"==b&&a!=n||\"function\"==b},xb=function(a){return a[vb]||(a[vb]=++wb)},vb=\"closure_uid_\"+t.floor(2147483648*t.random())[Wa](36),\nwb=0,yb=function(a,b,c){return a[I][K](a[Ta],arguments)},zb=function(a,b,c){a||e(r());if(2<arguments[C]){var d=fa[F][za][I](arguments,2);return function(){var c=fa[F][za][I](arguments);fa[F][kb][K](c,d);return a[K](b,c)}}return function(){return a[K](b,arguments)}},Ab=function(a,b,c){Ab=da[F][Ta]&&-1!=da[F][Ta][Wa]()[y](\"native code\")?yb:zb;return Ab[K](n,arguments)},Db=function(a,b){var c=fa[F][za][I](arguments,1);return function(){var b=fa[F][za][I](arguments);b[kb][K](b,c);return a[K](this,b)}},\nEb=Date.now||function(){return+new Date},Q=function(a,b){function c(){}c.prototype=b[F];a.d=b[F];a.prototype=new c;a[F].constructor=a};da[F].bind=da[F][Ta]||function(a,b){if(1<arguments[C]){var c=fa[F][za][I](arguments,1);c[kb](this,a);return Ab[K](n,c)}return Ab(this,a)};var Fb=function(a){this.stack=r().stack||\"\";a&&(this.message=\"\"+a)};Q(Fb,r);Fb[F].name=\"CustomError\";var Gb=function(a,b){for(var c=1;c<arguments[C];c++)var d=(\"\"+arguments[c])[x](/\\$/g,\"$$$$\"),a=a[x](/\\%s/,d);return a},Mb=function(a,b){if(b)return a[x](Hb,\"&amp;\")[x](Ib,\"&lt;\")[x](Jb,\"&gt;\")[x](Kb,\"&quot;\");if(!Lb.test(a))return a;-1!=a[y](\"&\")&&(a=a[x](Hb,\"&amp;\"));-1!=a[y](\"<\")&&(a=a[x](Ib,\"&lt;\"));-1!=a[y](\">\")&&(a=a[x](Jb,\"&gt;\"));-1!=a[y]('\"')&&(a=a[x](Kb,\"&quot;\"));return a},Hb=/&/g,Ib=/</g,Jb=/>/g,Kb=/\\\"/g,Lb=/[&<>\\\"]/,Nb={},Ob=function(a){return Nb[a]||(Nb[a]=(\"\"+a)[x](/\\-([a-z])/g,function(a,\nc){return c.toUpperCase()}))};var Pb=function(a,b){b[kb](a);Fb[I](this,Gb[K](n,b));b.shift()};Q(Pb,Fb);Pb[F].name=\"AssertionError\";var R=function(a,b,c){if(!a){var d=fa[F][za][I](arguments,2),g=\"Assertion failed\";if(b)var g=g+(\": \"+b),f=d;e(new Pb(\"\"+g,f||[]))}return a};var S=fa[F],Qb=S[y]?function(a,b,c){R(a[C]!=n);return S[y][I](a,b,c)}:function(a,b,c){c=c==n?0:0>c?t.max(0,a[C]+c):c;if(P(a))return!P(b)||1!=b[C]?-1:a[y](b,c);for(;c<a[C];c++)if(c in a&&a[c]===b)return c;return-1},Rb=S.forEach?function(a,b,c){R(a[C]!=n);S.forEach[I](a,b,c)}:function(a,b,c){for(var d=a[C],g=P(a)?a[$a](\"\"):a,f=0;f<d;f++)f in g&&b[I](c,g[f],f,a)},Sb=S.filter?function(a,b,c){R(a[C]!=n);return S.filter[I](a,b,c)}:function(a,b,c){for(var d=a[C],g=[],f=0,h=P(a)?a[$a](\"\"):a,i=0;i<d;i++)if(i in\nh){var k=h[i];b[I](c,k,i,a)&&(g[f++]=k)}return g},Tb=S.map?function(a,b,c){R(a[C]!=n);return S.map[I](a,b,c)}:function(a,b,c){for(var d=a[C],g=fa(d),f=P(a)?a[$a](\"\"):a,h=0;h<d;h++)h in f&&(g[h]=b[I](c,f[h],h,a));return g},Ub=function(a,b){var c=Qb(a,b),d;if(d=0<=c){var g=a;R(g[C]!=n);S.splice[I](g,c,1)}return d},Vb=function(a){return S.concat[K](S,arguments)},Wb=function(a){if(qb(a))return Vb(a);for(var b=[],c=0,d=a[C];c<d;c++)b[c]=a[c];return b},Xb=function(a,b,c){R(a[C]!=n);return 2>=arguments[C]?\nS[za][I](a,b):S[za][I](a,b,c)};var T=function(a,b){this.x=lb(a)?a:0;this.y=lb(b)?b:0};T[F].W=function(){return new T(this.x,this.y)};na(T[F],function(){return\"(\"+this.x+\", \"+this.y+\")\"});var Yb=function(a,b){return new T(a.x-b.x,a.y-b.y)};var Zb=function(a,b){ga(this,a);ta(this,b)};N=Zb[F];N.W=function(){return new Zb(this[w],this[L])};na(N,function(){return\"(\"+this[w]+\" x \"+this[L]+\")\"});N.ceil=function(){ga(this,t.ceil(this[w]));ta(this,t.ceil(this[L]));return this};N.floor=function(){ga(this,t.floor(this[w]));ta(this,t.floor(this[L]));return this};N.round=function(){ga(this,t.round(this[w]));ta(this,t.round(this[L]));return this};N.scale=function(a){ga(this,this[w]*a);ta(this,this[L]*a);return this};var $b=function(a,b,c){for(var d in a)b[I](c,a[d],d,a)},ac=\"constructor,hasOwnProperty,isPrototypeOf,propertyIsEnumerable,toLocaleString,toString,valueOf\".split(\",\"),bc=function(a,b){for(var c,d,g=1;g<arguments[C];g++){d=arguments[g];for(c in d)a[c]=d[c];for(var f=0;f<ac[C];f++)c=ac[f],Object[F].hasOwnProperty[I](d,c)&&(a[c]=d[c])}},cc=function(a){var b=arguments[C];if(1==b&&qb(arguments[0]))return cc[K](n,arguments[0]);b%2&&e(r(\"Uneven number of arguments\"));for(var c={},d=0;d<b;d+=2)c[arguments[d]]=\narguments[d+1];return c};var dc,ec,fc,gc,hc,ic,jc,kc=function(){return O.navigator?O.navigator.userAgent:n},lc=function(){return O.navigator};hc=gc=fc=ec=dc=p;var mc;if(mc=kc()){var nc=lc();dc=0==mc[y](\"Opera\");ec=!dc&&-1!=mc[y](\"MSIE\");gc=(fc=!dc&&-1!=mc[y](\"WebKit\"))&&-1!=mc[y](\"Mobile\");hc=!dc&&!fc&&\"Gecko\"==nc.product}var oc=dc,U=ec,V=hc,W=fc,pc=gc,qc,rc=lc(),sc=qc=rc&&rc.platform||\"\";ic=-1!=sc[y](\"Mac\");jc=!!lc()&&-1!=(lc().appVersion||\"\")[y](\"X11\");var tc=ic,uc=jc,vc;\na:{var wc=\"\",xc;if(oc&&O.opera)var yc=O.opera.version,wc=\"function\"==typeof yc?yc():yc;else if(V?xc=/rv\\:([^\\);]+)(\\)|;)/:U?xc=/MSIE\\s+([^\\);]+)(\\)|;)/:W&&(xc=/WebKit\\/(\\S+)/),xc)var zc=xc.exec(kc()),wc=zc?zc[1]:\"\";if(U){var Ac,Bc=O[Za];Ac=Bc?Bc.documentMode:l;if(Ac>s(wc)){vc=\"\"+Ac;break a}}vc=wc}\nvar Cc=vc,Dc={},X=function(a){var b;if(!(b=Dc[a])){b=Dc;for(var c=a,d=a,g=0,a=(\"\"+Cc)[x](/^[\\s\\xa0]+|[\\s\\xa0]+$/g,\"\")[$a](\".\"),d=(\"\"+d)[x](/^[\\s\\xa0]+|[\\s\\xa0]+$/g,\"\")[$a](\".\"),f=t.max(a[C],d[C]),h=0;0==g&&h<f;h++){var i=a[h]||\"\",k=d[h]||\"\",o=RegExp(\"(\\\\d*)(\\\\D*)\",\"g\"),j=RegExp(\"(\\\\d*)(\\\\D*)\",\"g\");do{var D=o.exec(i)||[\"\",\"\",\"\"],q=j.exec(k)||[\"\",\"\",\"\"];if(0==D[0][C]&&0==q[0][C])break;var g=0==D[1][C]?0:ba(D[1],10),u=0==q[1][C]?0:ba(q[1],10),g=(g<u?-1:g>u?1:0)||((0==D[2][C])<(0==q[2][C])?-1:(0==D[2][C])>\n(0==q[2][C])?1:0)||(D[2]<q[2]?-1:D[2]>q[2]?1:0)}while(0==g)}a=g;b=b[c]=0<=a}return b},Ec={},Fc=function(a){return Ec[a]||(Ec[a]=U&&!!ea.documentMode&&ea.documentMode>=a)};var Gc,Hc=!U||Fc(9);!V&&!U||U&&Fc(9)||V&&X(\"1.9.1\");U&&X(\"9\");var Ic=function(a){a=a.className;return P(a)&&a.match(/\\S+/g)||[]},Jc=function(a,b){for(var c=Ic(a),d=Xb(arguments,1),g=c[C]+d[C],f=c,h=0;h<d[C];h++)0<=Qb(f,d[h])||f[wa](d[h]);pa(a,c[jb](\" \"));return c[C]==g},Lc=function(a,b){var c=Ic(a),d=Xb(arguments,1),g=Kc(c,d);pa(a,g[jb](\" \"));return g[C]==c[C]-d[C]},Kc=function(a,b){return Sb(a,function(a){return!(0<=Qb(b,a))})};var Z=function(a){return a?new Mc(Y(a)):Gc||(Gc=new Mc)},Oc=function(a){return a.querySelectorAll&&a.querySelector&&(!W||Nc(ea)||X(\"528\"))},Qc=function(a,b){$b(b,function(b,d){\"style\"==d?a[G].cssText=b:\"class\"==d?pa(a,b):\"for\"==d?a.htmlFor=b:d in Pc?a[Oa](Pc[d],b):0==d.lastIndexOf(\"aria-\",0)?a[Oa](d,b):a[d]=b})},Pc={cellpadding:\"cellPadding\",cellspacing:\"cellSpacing\",colspan:\"colSpan\",rowspan:\"rowSpan\",valign:\"vAlign\",height:\"height\",width:\"width\",usemap:\"useMap\",frameborder:\"frameBorder\",maxlength:\"maxLength\",\ntype:\"type\"},Sc=function(a,b,c,d){function g(c){c&&b[va](P(c)?a.createTextNode(c):c)}for(;d<c[C];d++){var f=c[d];rb(f)&&!(ub(f)&&0<f[Aa])?Rb(Rc(f)?Wb(f):f,g):g(f)}},Nc=function(a){return\"CSS1Compat\"==a.compatMode},Tc=function(a,b){a[va](b)},Uc=function(a,b){Sc(Y(a),a,arguments,1)},Vc=function(a){return a&&a[hb]?a[hb].removeChild(a):n},Wc=function(a,b){if(a.contains&&1==b[Aa])return a==b||a.contains(b);if(\"undefined\"!=typeof a.compareDocumentPosition)return a==b||Boolean(a.compareDocumentPosition(b)&\n16);for(;b&&a!=b;)b=b[hb];return b==a},Y=function(a){return 9==a[Aa]?a:a.ownerDocument||a[Za]},Rc=function(a){if(a&&\"number\"==typeof a[C]){if(ub(a))return\"function\"==typeof a.item||\"string\"==typeof a.item;if(tb(a))return\"function\"==typeof a.item}return p},Mc=function(a){this.g=a||O[Za]||ea};N=Mc[F];N.$=Z;N.t=function(){return this.g};N.a=function(a){return P(a)?this.g.getElementById(a):a};\nN.N=function(a,b){var c=b||this.g,d;d=a;var g=c||ea,f=n;if(Oc(g))d=g.querySelector(\".\"+d);else{g=c||ea;if(Oc(g))d=g.querySelectorAll(\".\"+d);else if(g[Ha])d=g[Ha](d);else if(g=c||ea,c=\"\",Oc(g)&&(c||d))d=c+(d?\".\"+d:\"\"),d=g.querySelectorAll(d);else if(d&&g[Ha])if(g=g[Ha](d),c){for(var f={},h=0,i=0,k;k=g[i];i++)c==k.nodeName&&(f[h++]=k);oa(f,h);d=f}else d=g;else if(g=g.getElementsByTagName(c||\"*\"),d){f={};for(i=h=0;k=g[i];i++)c=k.className,\"function\"==typeof c[$a]&&0<=Qb(c[$a](/\\s+/),d)&&(f[h++]=k);oa(f,\nh);d=f}else d=g;d=d[0]}return d=(f=d)||n};N.uc=function(a){var a=a||this.na()||aa,b=a[Za];if(W&&!X(\"500\")&&!pc){\"undefined\"==typeof a.innerHeight&&(a=aa);var b=a.innerHeight,c=a[Za][Ua].scrollHeight;a==a.top&&c<b&&(b-=15);a=new Zb(a.innerWidth,b)}else a=Nc(b)?b[Ua]:b[H],a=new Zb(a[Ya],a[db]);return a};\nN.U=function(a,b,c){var d;d=this.g;var g=arguments,f=g[0],h=g[1];if(!Hc&&h&&(h.name||h[B])){f=[\"<\",f];h.name&&f[wa](' name=\"',Mb(h.name),'\"');if(h[B]){f[wa](' type=\"',Mb(h[B]),'\"');var i={};bc(i,h);h=i;delete h[B]}f[wa](\">\");f=f[jb](\"\")}f=d[La](f);h&&(P(h)?pa(f,h):qb(h)?Jc[K](n,[f].concat(h)):Qc(f,h));2<g[C]&&Sc(d,f,g,2);return d=f};N.createElement=function(a){return this.g[La](a)};N.createTextNode=function(a){return this.g.createTextNode(a)};N.ta=function(){return Nc(this.g)};\nN.na=function(){return this.g[Ra]||this.g[Sa]};N.tc=function(){return!W&&Nc(this.g)?this.g[Ua]:this.g[H]};N.sa=function(){var a,b=this.g;a=!W&&Nc(b)?b[Ua]:b[H];b=b[Ra]||b[Sa];return a=new T(b.pageXOffset||a[eb],b.pageYOffset||a[Va])};N.appendChild=Tc;N.append=Uc;N.removeNode=Vc;N.contains=Wc;var $=function(a,b,c,d){this.top=a;ua(this,b);ra(this,c);v(this,d)};$[F].W=function(){return new $(this.top,this[M],this[J],this[A])};na($[F],function(){return\"(\"+this.top+\"t, \"+this[M]+\"r, \"+this[J]+\"b, \"+this[A]+\"l)\"});$[F].contains=function(a){a=!this||!a?p:a instanceof $?a[A]>=this[A]&&a[M]<=this[M]&&a.top>=this.top&&a[J]<=this[J]:a.x>=this[A]&&a.x<=this[M]&&a.y>=this.top&&a.y<=this[J];return a};\n$[F].expand=function(a,b,c,d){ub(a)?(this.top-=a.top,ua(this,this[M]+a[M]),ra(this,this[J]+a[J]),v(this,this[A]-a[A])):(this.top-=a,ua(this,this[M]+b),ra(this,this[J]+c),v(this,this[A]-d));return this};var Xc=function(a,b,c,d){v(this,a);this.top=b;ga(this,c);ta(this,d)};N=Xc[F];N.W=function(){return new Xc(this[A],this.top,this[w],this[L])};N.Ob=function(){var a=this[A]+this[w],b=this.top+this[L];return new $(this.top,a,b,this[A])};na(N,function(){return\"(\"+this[A]+\", \"+this.top+\" - \"+this[w]+\"w x \"+this[L]+\"h)\"});\nN.Lb=function(a){var b=t.max(this[A],a[A]),c=t.min(this[A]+this[w],a[A]+a[w]);if(b<=c){var d=t.max(this.top,a.top),a=t.min(this.top+this[L],a.top+a[L]);if(d<=a)return v(this,b),this.top=d,ga(this,c-b),ta(this,a-d),m}return p};N.contains=function(a){return a instanceof Xc?this[A]<=a[A]&&this[A]+this[w]>=a[A]+a[w]&&this.top<=a.top&&this.top+this[L]>=a.top+a[L]:a.x>=this[A]&&a.x<=this[A]+this[w]&&a.y>=this.top&&a.y<=this.top+this[L]};var Zc=function(a,b,c){P(b)?Yc(a,c,b):$b(b,Db(Yc,a))},Yc=function(a,b,c){a[G][Ob(c)]=b},ad=function(a,b){var c=Y(a);return c[Sa]&&c[Sa].getComputedStyle&&(c=c[Sa].getComputedStyle(a,n))?c[b]||c.getPropertyValue(b):\"\"},bd=function(a,b){return ad(a,b)||(a[fb]?a[fb][b]:n)||a[G]&&a[G][b]},cd=function(a){var b=a[ya]();U&&(a=a.ownerDocument,v(b,b[A]-(a[Ua][Na]+a[H][Na])),b.top-=a[Ua][Pa]+a[H][Pa]);return b},dd=function(a){if(U&&!Fc(8))return a.offsetParent;for(var b=Y(a),c=bd(a,\"position\"),d=\"fixed\"==c||\n\"absolute\"==c,a=a[hb];a&&a!=b;a=a[hb])if(c=bd(a,\"position\"),d=d&&\"static\"==c&&a!=b[Ua]&&a!=b[H],!d&&(a.scrollWidth>a[Ya]||a.scrollHeight>a[db]||\"fixed\"==c||\"absolute\"==c||\"relative\"==c))return a;return n},gd=function(a){for(var b=new $(0,Infinity,Infinity,0),c=Z(a),d=c.t()[H],g=c.t()[Ua],f=c.tc();a=dd(a);)if((!U||0!=a[Ya])&&(!W||0!=a[db]||a!=d)&&a!=d&&a!=g&&\"visible\"!=bd(a,\"overflow\")){var h=ed(a),i;i=a;if(V&&!X(\"1.9\")){var k=s(ad(i,\"borderLeftWidth\"));if(fd(i))var o=i[Ba]-i[Ya]-k-s(ad(i,\"borderRightWidth\")),\nk=k+o;i=new T(k,s(ad(i,\"borderTopWidth\")))}else i=new T(i[Na],i[Pa]);h.x+=i.x;h.y+=i.y;b.top=t.max(b.top,h.y);ua(b,t.min(b[M],h.x+a[Ya]));ra(b,t.min(b[J],h.y+a[db]));v(b,t.max(b[A],h.x))}d=f[eb];f=f[Va];v(b,t.max(b[A],d));b.top=t.max(b.top,f);c=c.uc();ua(b,t.min(b[M],d+c[w]));ra(b,t.min(b[J],f+c[L]));return 0<=b.top&&0<=b[A]&&b[J]>b.top&&b[M]>b[A]?b:n},ed=function(a){var b,c=Y(a),d=bd(a,\"position\"),g=V&&c[Ka]&&!a[ya]&&\"absolute\"==d&&(b=c[Ka](a))&&(0>b[Ia]||0>b[Ja]),f=new T(0,0),h;b=c?9==c[Aa]?c:Y(c):\nea;h=U&&!Fc(9)&&!Z(b).ta()?b[H]:b[Ua];if(a==h)return f;if(a[ya])b=cd(a),a=Z(c).sa(),f.x=b[A]+a.x,f.y=b.top+a.y;else if(c[Ka]&&!g)b=c[Ka](a),a=c[Ka](h),f.x=b[Ia]-a[Ia],f.y=b[Ja]-a[Ja];else{b=a;do{f.x+=b.offsetLeft;f.y+=b.offsetTop;b!=a&&(f.x+=b[Na]||0,f.y+=b[Pa]||0);if(W&&\"fixed\"==bd(b,\"position\")){f.x+=c[H][eb];f.y+=c[H][Va];break}b=b.offsetParent}while(b&&b!=a);if(oc||W&&\"absolute\"==d)f.y-=c[H].offsetTop;for(b=a;(b=dd(b))&&b!=c[H]&&b!=h;)if(f.x-=b[eb],!oc||\"TR\"!=b[gb])f.y-=b[Va]}return f},id=function(a,\nb){var c=hd(a),d=hd(b);return new T(c.x-d.x,c.y-d.y)},hd=function(a){var b=new T;if(1==a[Aa])if(a[ya])a=cd(a),b.x=a[A],b.y=a.top;else{var c=Z(a).sa(),a=ed(a);b.x=a.x-c.x;b.y=a.y-c.y}else{var c=tb(a.Ba),d=a;a[Da]?d=a[Da][0]:c&&a.Ba()[Da]&&(d=a.Ba()[Da][0]);b.x=d.clientX;b.y=d.clientY}return b},jd=function(a,b){\"number\"==typeof a&&(a=(b?t.round(a):a)+\"px\");return a},ld=function(a){if(\"none\"!=bd(a,\"display\"))return kd(a);var b=a[G],c=b.display,d=b.visibility,g=b.position;ma(b,\"hidden\");b.position=\"absolute\";\nsa(b,\"inline\");a=kd(a);sa(b,c);b.position=g;ma(b,d);return a},kd=function(a){var b=a[Ba],c=a.offsetHeight,d=W&&!b&&!c;return(!lb(b)||d)&&a[ya]?(a=cd(a),new Zb(a[M]-a[A],a[J]-a.top)):new Zb(b,c)},md=function(a){var b=ed(a),a=ld(a);return new Xc(b.x,b.y,a[w],a[L])},nd=function(a,b){sa(a[G],b?\"\":\"none\")},fd=function(a){return\"rtl\"==bd(a,\"direction\")},od=function(a,b,c,d){if(/^\\d+px?$/.test(b))return ba(b,10);var g=a[G][c],f=a.runtimeStyle[c];a.runtimeStyle[c]=a[fb][c];a[G][c]=b;b=a[G][d];a[G][c]=g;a.runtimeStyle[c]=\nf;return b},pd=function(a,b){return od(a,a[fb]?a[fb][b]:n,\"left\",\"pixelLeft\")},qd={thin:2,medium:4,thick:6},rd=function(a,b){if(\"none\"==(a[fb]?a[fb][b+\"Style\"]:n))return 0;var c=a[fb]?a[fb][b+\"Width\"]:n;return c in qd?qd[c]:od(a,c,\"left\",\"pixelLeft\")};var sd=function(){};sd[F].eb=p;sd[F].k=function(){this.eb||(this.eb=m,this.c())};sd[F].c=function(){this.yc&&td[K](n,this.yc)};var ud=function(a){a&&\"function\"==typeof a.k&&a.k()},td=function(a){for(var b=0,c=arguments[C];b<c;++b){var d=arguments[b];rb(d)?td[K](n,d):ud(d)}};var vd=[],wd=p;var xd=function(a){xd[\" \"](a);return a};xd[\" \"]=nb;var yd=!U||Fc(9),zd=!U||Fc(9),Ad=U&&!X(\"8\");!W||X(\"528\");V&&X(\"1.9b\")||U&&X(\"8\")||oc&&X(\"9.5\")||W&&X(\"528\");V&&!X(\"8\")||U&&X(\"9\");var Bd=function(a,b){la(this,a);qa(this,b);ja(this,this[bb])};Q(Bd,sd);N=Bd[F];N.c=function(){delete this[B];delete this[bb];delete this.currentTarget};N.z=p;N.defaultPrevented=p;N.ha=m;N.stopPropagation=function(){this.z=m};N.preventDefault=function(){this.defaultPrevented=m;this.ha=p};var Cd=function(a,b){a&&this.ca(a,b)};Q(Cd,Bd);var Dd=[1,4,2];N=Cd[F];qa(N,n);N.relatedTarget=n;N.offsetX=0;N.offsetY=0;N.clientX=0;N.clientY=0;N.screenX=0;N.screenY=0;N.button=0;ka(N,0);N.charCode=0;N.ctrlKey=p;N.altKey=p;N.shiftKey=p;N.metaKey=p;N.s=n;\nN.ca=function(a,b){var c=la(this,a[B]);Bd[I](this,c);qa(this,a[bb]||a.srcElement);ja(this,b);var d=a.relatedTarget;if(d){if(V){var g;a:{try{xd(d.nodeName);g=m;break a}catch(f){}g=p}g||(d=n)}}else\"mouseover\"==c?d=a.fromElement:\"mouseout\"==c&&(d=a.toElement);this.relatedTarget=d;this.offsetX=W||a.offsetX!==l?a.offsetX:a.layerX;this.offsetY=W||a.offsetY!==l?a.offsetY:a.layerY;this.clientX=a.clientX!==l?a.clientX:a.pageX;this.clientY=a.clientY!==l?a.clientY:a.pageY;this.screenX=a[Ia]||0;this.screenY=\na[Ja]||0;this.button=a.button;ka(this,a[Ma]||0);this.charCode=a.charCode||(\"keypress\"==c?a[Ma]:0);this.ctrlKey=a.ctrlKey;this.altKey=a.altKey;this.shiftKey=a.shiftKey;this.metaKey=a.metaKey;this.state=a.state;this.s=a;a.defaultPrevented&&this[Ca]();delete this.z};N.zc=function(a){return yd?this.s.button==a:\"click\"==this[B]?0==a:!!(this.s.button&Dd[a])};N.lc=function(){return this.zc(0)&&!(W&&tc&&this.ctrlKey)};\nN.stopPropagation=function(){Cd.d[ab][I](this);this.s[ab]?this.s[ab]():this.s.cancelBubble=m};N.preventDefault=function(){Cd.d[Ca][I](this);var a=this.s;if(a[Ca])a[Ca]();else if(a.returnValue=p,Ad)try{(a.ctrlKey||112<=a[Ma]&&123>=a[Ma])&&ka(a,-1)}catch(b){}};N.Ba=function(){return this.s};N.c=function(){Cd.d.c[I](this);this.s=n;qa(this,n);ja(this,n);this.relatedTarget=n};var Ed=function(){},Fd=0;N=Ed[F];N.key=0;N.w=p;N.za=p;N.ca=function(a,b,c,d,g,f){tb(a)?this.$a=m:a&&a[Qa]&&tb(a[Qa])?this.$a=p:e(r(\"Invalid listener argument\"));this.o=a;this.Ta=b;this.src=c;la(this,d);this.capture=!!g;this.ba=f;this.za=p;this.key=++Fd;this.w=p};N.handleEvent=function(a){return this.$a?this.o[I](this.ba||this.src,a):this.o[Qa][I](this.o,a)};var Gd={},Hd={},Id={},Jd=\"on\",Kd={},Ld=function(a,b,c,d,g){if(b){if(qb(b)){for(var f=0;f<b[C];f++)Ld(a,b[f],c,d,g);return n}var d=!!d,h=Hd;b in h||(h[b]={j:0,h:0});h=h[b];d in h||(h[d]={j:0,h:0},h.j++);var h=h[d],i=xb(a),k;h.h++;if(h[i]){k=h[i];for(f=0;f<k[C];f++)if(h=k[f],h.o==c&&h.ba==g){if(h.w)break;return k[f].key}}else k=h[i]=[],h.j++;f=Md();f.src=a;h=new Ed;h.ca(c,f,a,b,d,g);c=h.key;f.key=c;k[wa](h);Gd[c]=h;Id[i]||(Id[i]=[]);Id[i][wa](h);a.addEventListener?(a==O||!a.Ra)&&a.addEventListener(b,\nf,d):a.attachEvent(b in Kd?Kd[b]:Kd[b]=Jd+b,f);return c}e(r(\"Invalid event type\"))},Md=function(){var a=Nd,b=zd?function(c){return a[I](b.src,b.key,c)}:function(c){c=a[I](b.src,b.key,c);if(!c)return c};return b},Od=function(a,b,c,d,g){if(qb(b)){for(var f=0;f<b[C];f++)Od(a,b[f],c,d,g);return n}a=Ld(a,b,c,d,g);b=Gd[a];b.za=m;return a},Pd=function(a,b,c,d,g){if(qb(b)){for(var f=0;f<b[C];f++)Pd(a,b[f],c,d,g);return n}d=!!d;a=Qd(a,b,d);if(!a)return p;for(f=0;f<a[C];f++)if(a[f].o==c&&a[f][Fa]==d&&a[f].ba==\ng)return Rd(a[f].key);return p},Rd=function(a){if(!Gd[a])return p;var b=Gd[a];if(b.w)return p;var c=b.src,d=b[B],g=b.Ta,f=b[Fa];c.removeEventListener?(c==O||!c.Ra)&&c.removeEventListener(d,g,f):c.detachEvent&&c.detachEvent(d in Kd?Kd[d]:Kd[d]=Jd+d,g);c=xb(c);g=Hd[d][f][c];if(Id[c]){var h=Id[c];Ub(h,b);0==h[C]&&delete Id[c]}b.w=m;g.ab=m;Td(d,f,c,g);delete Gd[a];return m},Td=function(a,b,c,d){if(!d.ga&&d.ab){for(var g=0,f=0;g<d[C];g++)if(d[g].w){var h=d[g].Ta;h.src=n}else g!=f&&(d[f]=d[g]),f++;oa(d,\nf);d.ab=p;0==f&&(delete Hd[a][b][c],Hd[a][b].j--,0==Hd[a][b].j&&(delete Hd[a][b],Hd[a].j--),0==Hd[a].j&&delete Hd[a])}},Ud=function(a,b,c){var d=0,g=a==n,f=b==n,h=c==n,c=!!c;if(g)$b(Id,function(a){for(var g=a[C]-1;0<=g;g--){var i=a[g];if((f||b==i[B])&&(h||c==i[Fa]))Rd(i.key),d++}});else if(a=xb(a),Id[a]){a=Id[a];for(g=a[C]-1;0<=g;g--){var i=a[g];if((f||b==i[B])&&(h||c==i[Fa]))Rd(i.key),d++}}return d},Qd=function(a,b,c){var d=Hd;return b in d&&(d=d[b],c in d&&(d=d[c],a=xb(a),d[a]))?d[a]:n},Wd=function(a,\nb,c,d,g){var f=1,b=xb(b);if(a[b]){a.h--;a=a[b];a.ga?a.ga++:a.ga=1;try{for(var h=a[C],i=0;i<h;i++){var k=a[i];k&&!k.w&&(f&=Vd(k,g)!==p)}}finally{a.ga--,Td(c,d,b,a)}}return Boolean(f)},Vd=function(a,b){var c=a[Qa](b);a.za&&Rd(a.key);return c},Nd=function(a,b){if(!Gd[a])return m;var c=Gd[a],d=c[B],g=Hd;if(!(d in g))return m;var g=g[d],f,h;if(!zd){var i;if(!(i=b))a:{i=[\"window\",\"event\"];for(var k=O;f=i.shift();)if(k[f]!=n)k=k[f];else{i=n;break a}i=k}f=i;i=m in g;k=p in g;if(i){if(0>f[Ma]||f.returnValue!=\nl)return m;a:{var o=f,j=p;if(0==o[Ma])try{ka(o,-1);break a}catch(D){j=m}if(j||o.returnValue==l)o.returnValue=m}}o=new Cd;o.ca(f,this);f=m;try{if(i){for(var q=[],u=o.currentTarget;u;u=u[hb])q[wa](u);h=g[m];h.h=h.j;for(var z=q[C]-1;!o.z&&0<=z&&h.h;z--)ja(o,q[z]),f&=Wd(h,q[z],d,m,o);if(k){h=g[p];h.h=h.j;for(z=0;!o.z&&z<q[C]&&h.h;z++)ja(o,q[z]),f&=Wd(h,q[z],d,p,o)}}else f=Vd(c,o)}finally{q&&oa(q,0),o.k()}return f}d=new Cd(b,this);try{f=Vd(c,d)}finally{d.k()}return f};\nif(wd)for(var Xd=0;Xd<vd[C];Xd++)var Yd=Ab(vd[Xd].Dc,vd[Xd]),Nd=Yd(Nd);var Zd=function(a){this.f=a;this.ea=[]};Q(Zd,sd);var $d=[];N=Zd[F];N.e=function(a,b,c,d,g){qb(b)||($d[0]=b,b=$d);for(var f=0;f<b[C];f++){var h=Ld(a,b[f],c||this,d||p,g||this.f||this);this.ea[wa](h)}return this};N.ob=function(a,b,c,d,g){b.e(a,c,d,g||this.f,this);return this};\nN.O=function(a,b,c,d,g){if(qb(b))for(var f=0;f<b[C];f++)this.O(a,b[f],c,d,g);else{a:{c=c||this;g=g||this.f||this;d=!!d;if(a=Qd(a,b,d))for(b=0;b<a[C];b++)if(!a[b].w&&a[b].o==c&&a[b][Fa]==d&&a[b].ba==g){a=a[b];break a}a=n}a&&(a=a.key,Rd(a),Ub(this.ea,a))}return this};N.oa=function(){Rb(this.ea,Rd);oa(this.ea,0)};N.c=function(){Zd.d.c[I](this);this.oa()};N.handleEvent=function(){e(r(\"EventHandler.handleEvent not implemented\"))};var ae=function(){};Q(ae,sd);N=ae[F];N.Ra=m;N.ya=n;N.Ya=function(){return this.ya};N.va=function(a){this.ya=a};N.addEventListener=function(a,b,c,d){Ld(this,a,b,c,d)};N.removeEventListener=function(a,b,c,d){Pd(this,a,b,c,d)};\nN.dispatchEvent=function(a){var b=a[B]||a,c=Hd;if(b in c){if(P(a))a=new Bd(a,this);else if(a instanceof Bd)qa(a,a[bb]||this);else{var d=a,a=new Bd(b,this);bc(a,d)}var d=1,g,c=c[b],b=m in c,f;if(b){g=[];for(f=this;f;f=f.Ya())g[wa](f);f=c[m];f.h=f.j;for(var h=g[C]-1;!a.z&&0<=h&&f.h;h--)ja(a,g[h]),d&=Wd(f,g[h],a[B],m,a)&&a.ha!=p}if(f=p in c)if(f=c[p],f.h=f.j,b)for(h=0;!a.z&&h<g[C]&&f.h;h++)ja(a,g[h]),d&=Wd(f,g[h],a[B],p,a)&&a.ha!=p;else for(g=this;!a.z&&g&&f.h;g=g.Ya())ja(a,g),d&=Wd(f,g,a[B],p,a)&&a.ha!=\np;a=Boolean(d)}else a=m;return a};N.c=function(){ae.d.c[I](this);Ud(this);this.ya=n};var be=O.window,ce=function(a,b,c){tb(a)?c&&(a=Ab(a,c)):a&&\"function\"==typeof a[Qa]?a=Ab(a[Qa],a):e(r(\"Invalid listener argument\"));return 2147483647<b?-1:be.setTimeout(a,b||0)};var de=function(){};ob(de);de[F].Ac=0;de[F].vc=function(){return\":\"+(this.Ac++)[Wa](36)};de.jb();var ee=function(a){this.r=a||Z()};Q(ee,ae);N=ee[F];N.wc=de.jb();N.fa=n;N.A=p;N.b=n;N.m=n;N.Z=n;N.S=n;N.Da=p;N.Pb=function(){return this.fa||(this.fa=this.wc.vc())};N.a=function(){return this.b};N.Ma=function(a){this.b=a};N.N=function(a){return this.b?this.r.N(a,this.b):n};N.ka=function(){return this.C||(this.C=new Zd(this))};\nN.Qb=function(a){this==a&&e(r(\"Unable to set parent component\"));a&&this.m&&this.fa&&this.m.Ja(this.fa)&&this.m!=a&&e(r(\"Unable to set parent component\"));this.m=a;ee.d.va[I](this,a)};N.getParent=function(){return this.m};N.va=function(a){this.m&&this.m!=a&&e(r(\"Method not supported\"));ee.d.va[I](this,a)};N.$=function(){return this.r};N.P=function(){return this.A};N.U=function(){this.b=this.r[La](\"div\")};N.ic=function(a){this.Bc(a)};\nN.Bc=function(a,b){this.A&&e(r(\"Component already rendered\"));this.b||this.U();a?a.insertBefore(this.b,b||n):this.r.t()[H][va](this.b);(!this.m||this.m.P())&&this.u()};N.xc=function(a){this.A&&e(r(\"Component already rendered\"));if(a&&this.dc(a)){this.Da=m;if(!this.r||this.r.t()!=Y(a))this.r=Z(a);this.ma(a);this.u()}else e(r(\"Invalid element to decorate\"))};N.dc=function(){return m};N.ma=function(a){this.b=a};N.u=function(){this.A=m;this.ja(function(a){!a.P()&&a.a()&&a.u()})};\nN.M=function(){this.ja(function(a){a.P()&&a.M()});this.C&&this.C.oa();this.A=p};N.c=function(){ee.d.c[I](this);this.A&&this.M();this.C&&(this.C.k(),delete this.C);this.ja(function(a){a.k()});!this.Da&&this.b&&Vc(this.b);this.m=this.b=this.S=this.Z=n};N.lb=function(){return this.b};N.Ja=function(a){return this.S&&a?(a in this.S?this.S[a]:l)||n:n};N.ja=function(a,b){this.Z&&Rb(this.Z,a,b)};\nN.removeChild=function(a,b){if(a){var c=P(a)?a:a.Pb(),a=this.Ja(c);if(c&&a){var d=this.S;c in d&&delete d[c];Ub(this.Z,a);b&&(a.M(),a.b&&Vc(a.b));a.Qb(n)}}a||e(r(\"Child is not in parent component\"));return a};var fe=function(a,b){this.r=b||Z();this.n=a||\"\"};Q(fe,ee);fe[F].K=n;var ge=\"placeholder\"in ea[La](\"input\");N=fe[F];N.D=p;N.U=function(){this.Ma(this.$().U(\"input\",{type:\"text\"}))};N.ma=function(a){fe.d.ma[I](this,a);this.n||(this.n=a.getAttribute(\"label\")||\"\");var b;a:{var c=Y(a);try{b=c&&c[xa];break a}catch(d){}b=n}b==a&&(this.D=m,Lc(this.a(),this.T));ge?this.a().placeholder=this.n:this.a()[Oa](\"aria-label\",this.n)};N.u=function(){fe.d.u[I](this);this.Eb();this.aa();this.a().vb=this};\nN.M=function(){fe.d.M[I](this);this.La();this.a().vb=n};N.Eb=function(){var a=new Zd(this);a.e(this.a(),\"focus\",this.Ia);a.e(this.a(),\"blur\",this.zb);if(ge)this.v=a;else{V&&a.e(this.a(),[\"keypress\",\"keydown\",\"keyup\"],this.Ab);var b=Y(this.a()),b=b?b[Ra]||b[Sa]:aa;a.e(b,\"load\",this.Bb);this.v=a;this.Ha()}};N.Ha=function(){!this.Hb&&this.v&&this.a().form&&(this.v.e(this.a().form,\"submit\",this.Jb),this.Hb=m)};N.La=function(){this.v&&(this.v.k(),this.v=n)};N.c=function(){fe.d.c[I](this);this.La()};\nN.T=\"label-input-label\";N.Ia=function(){this.D=m;Lc(this.a(),this.T);if(!ge&&!this.I()&&!this.wb){var a=this,b=function(){ia(a.a(),\"\")};U?ce(b,10):b()}};N.zb=function(){ge||(this.v.O(this.a(),\"click\",this.Ia),this.K=n);this.D=p;this.aa()};N.Ab=function(a){27==a[Ma]&&(\"keydown\"==a[B]?this.K=this.a().value:\"keypress\"==a[B]?ia(this.a(),this.K):\"keyup\"==a[B]&&(this.K=n),a[Ca]())};N.Jb=function(){this.I()||(ia(this.a(),\"\"),ce(this.bc,10,this))};N.bc=function(){this.I()||ia(this.a(),this.n)};N.Bb=function(){this.aa()};\nN.hasFocus=function(){return this.D};N.I=function(){return!!this.a()&&\"\"!=this.a().value&&this.a().value!=this.n};N.clear=function(){ia(this.a(),\"\");this.K!=n&&(this.K=\"\")};N.reset=function(){this.I()&&(this.clear(),this.aa())};N.aa=function(){ge?this.a().placeholder!=this.n&&(this.a().placeholder=this.n):(this.Ha(),this.a()[Oa](\"aria-label\",this.n));this.I()?Lc(this.a(),this.T):(!this.wb&&!this.D&&Jc(this.a(),this.T),ge||ce(this.xb,10,this))};N.isEnabled=function(){return!this.a().disabled};\nN.xb=function(){this.a()&&!this.I()&&!this.D&&ia(this.a(),this.n)};var he=function(){},ie=new he,je=[\"click\",V?\"keypress\":\"keydown\"];he[F].e=function(a,b,c,d,g){c=function(a){if(\"click\"==a[B]&&a.lc())b[I](d,a);else if(13==a[Ma]||3==a[Ma])la(a,\"keypress\"),b[I](d,a)};c.ec=b;c.fc=d;g?g.e(a,je,c):Ld(a,je,c)};he[F].O=function(a,b,c,d,g){for(var f=0;c=je[f];f++)for(var h=Qd(a,c,p)||[],i,k=0;i=h[k];k++)if(i.o.ec==b&&i.o.fc==d){g?g.O(a,c,i.o):Pd(a,c,i.o);break}};var ke=function(){this.Ca=0;this.startTime=n};Q(ke,ae);N=ke[F];N.Vb=function(){this.Ca=1};N.ac=function(){this.Ca=0};N.Sa=function(){return 1==this.Ca};N.Sb=function(){this.X(\"begin\")};N.Yb=function(){this.X(\"end\")};N.Zb=function(){this.X(\"finish\")};N.Tb=function(){this.X(\"play\")};N.$b=function(){this.X(\"stop\")};N.X=function(a){this[Ea](a)};var le,ne=function(a,b){qb(b)||(b=[b]);R(0<b[C],\"At least one Css3Property should be specified.\");var c=Tb(b,function(a){if(P(a))return a;R(a&&a.hb&&sb(a.duration)&&a.ib&&sb(a.gb));return a.hb+\" \"+a.duration+\"s \"+a.ib+\" \"+a.gb+\"s\"});me(a,c[jb](\",\"))},me=function(a,b){a[G].WebkitTransition=b;a[G].MozTransition=b;a[G].Rb=b};var oe=function(a,b,c,d,g){ke[I](this);this.b=a;this.Wb=b;this.Fb=c;this.Qa=d;this.Xb=qb(g)?g:[g]};Q(oe,ke);N=oe[F];\nN.play=function(){if(this.Sa())return p;this.Sb();this.Tb();this.startTime=Eb();this.Vb();var a;lb(le)||(a=ea[La](\"div\"),ha(a,'<div style=\"-webkit-transition:opacity 1s linear;-moz-transition:opacity 1s linear;-o-transition:opacity 1s linear\">'),a=a.firstChild,le=lb(a[G].WebkitTransition)||lb(a[G].MozTransition)||lb(a[G].Rb));if(a=le)return Zc(this.b,this.Fb),ce(this.Ub,l,this),m;this.qa(p);return p};N.Ub=function(){ne(this.b,this.Xb);Zc(this.b,this.Qa);this.ua=ce(Ab(this.qa,this,p),1E3*this.Wb)};\nN.stop=function(){this.Sa()&&(this.ua&&(be.clearTimeout(this.ua),this.ua=0),this.qa(m))};N.qa=function(a){me(this.b,\"\");Zc(this.b,this.Qa);Eb();this.ac();a?this.$b():this.Zb();this.Yb()};N.c=function(){this.stop();oe.d.c[I](this)};N.pause=function(){R(p,\"Css3 transitions does not support pause action.\")};var pe=function(a,b,c,d,g){return new oe(a,b,{opacity:d},{opacity:g},{hb:\"opacity\",duration:b,ib:c,gb:0})};var re=function(a,b,c,d){d=d||Z();d=d[La](\"DIV\");ha(d,a(b||qe,l,c));return 1==d.childNodes[C]&&(a=d.firstChild,1==a[Aa])?a:d},qe={};var se=function(){};se[F].l=function(){};var te=function(a,b){this.f=new Zd(this);this.Ka(a||n);b&&this.pc(b)};Q(te,ae);N=te[F];N.b=n;N.qb=m;N.Wa=n;N.F=p;N.sc=p;N.mb=-1;N.rb=p;N.cc=m;N.H=\"toggle_display\";N.Ib=function(){return this.H};N.pc=function(a){this.H=a};N.a=function(){return this.b};N.Ka=function(a){this.hc();this.b=a};N.Cb=function(a,b){this.B=a;this.G=b};N.hc=function(){this.F&&e(r(\"Can not change this state of the popup while showing.\"))};N.V=function(){return this.F};\nN.R=function(a){this.B&&this.B.stop();this.G&&this.G.stop();a?this.oc():this.da()};N.l=nb;\nN.oc=function(){if(!this.F&&this.sb()){this.b||e(r(\"Caller must call setElement before trying to show the popup\"));this.l();var a=Y(this.b);this.rb&&this.f.e(a,\"keydown\",this.tb,m);if(this.qb)if(this.f.e(a,\"mousedown\",this.Fa,m),U){var b;try{b=a[xa]}catch(c){}for(;b&&\"IFRAME\"==b.nodeName;){try{var d,g=b.contentDocument||b.contentWindow[Za];d=g}catch(f){break}a=d;b=a[xa]}this.f.e(a,\"mousedown\",this.Fa,m);this.f.e(a,\"deactivate\",this.Ea)}else this.f.e(a,\"blur\",this.Ea);\"toggle_display\"==this.H?this.ub():\n\"move_offscreen\"==this.H&&this.l();this.F=m;this.B?(Od(this.B,\"end\",this.Ga,p,this),this.B.play()):this.Ga()}};N.da=function(a){if(!this.F||!this.gc(a))return p;this.f&&this.f.oa();this.F=p;this.G?(Od(this.G,\"end\",Db(this.Za,a),p,this),this.G.play()):this.Za(a);return m};N.Za=function(a){\"toggle_display\"==this.H?this.sc?ce(this.fb,0,this):this.fb():\"move_offscreen\"==this.H&&this.qc();this.rc(a)};N.ub=function(){ma(this.b[G],\"visible\");nd(this.b,m)};\nN.fb=function(){ma(this.b[G],\"hidden\");nd(this.b,p)};N.qc=function(){v(this.b[G],\"-200px\");this.b[G].top=\"-200px\"};N.sb=function(){return this[Ea](\"beforeshow\")};N.Ga=function(){this.mb=Eb();this[Ea](\"show\")};N.gc=function(a){return this[Ea]({type:\"beforehide\",target:a})};N.rc=function(a){Eb();this[Ea]({type:\"hide\",target:a})};N.Fa=function(a){a=a[bb];!Wc(this.b,a)&&(!this.Wa||Wc(this.Wa,a))&&!this.Va()&&this.da(a)};N.tb=function(a){27==a[Ma]&&this.da(a[bb])&&(a[Ca](),a[ab]())};\nN.Ea=function(a){if(this.cc){var b=Y(this.b);if(U||oc){if(a=b[xa],!a||Wc(this.b,a)||\"BODY\"==a[gb])return}else if(a[bb]!=b)return;this.Va()||this.da()}};N.Va=function(){return 150>Eb()-this.mb};N.c=function(){te.d.c[I](this);this.f.k();ud(this.B);ud(this.G);delete this.b;delete this.f};var ue=function(a,b){this.Gb=4;this.ra=b||l;te[I](this,a)};Q(ue,te);ue[F].Q=function(a){this.ra=a||l;this.V()&&this.l()};ue[F].l=function(){if(this.ra){var a=!this.V()&&\"move_offscreen\"!=this.Ib(),b=this.a();a&&(ma(b[G],\"hidden\"),nd(b,m));this.ra.l(b,this.Gb,this.Cc);a&&nd(b,p)}};var ve=function(a){this.q=a;this.bb=cc(0,this.q+\"-arrowright\",1,this.q+\"-arrowup\",2,this.q+\"-arrowdown\",3,this.q+\"-arrowleft\")};Q(ve,se);N=ve[F];N.Mb=p;N.xa=2;N.cb=20;N.ia=3;N.pa=-5;N.wa=function(a){this.L=a};N.Q=function(a,b,c,d){a!=n&&(this.ia=a);b!=n&&(this.xa=b);sb(c)&&(this.cb=t.max(c,15));sb(d)&&(this.pa=d)};N.pb=function(a,b){this.J=a;this.Xa=b};N.l=function(a,b,c){R(this.Xa,\"Must call setElements first.\");var a=this.ia,b=this.mc(this.ia,this.xa),d=this.nc();this.Oa(a,b,d,c)};\nN.nc=function(){return 2==this.xa?we(this.ia)?this.J.offsetHeight/2:this.J[Ba]/2:this.cb};N.mc=function(a,b){2==b&&(b=0);return b};\nN.Oa=function(a,b,c,d,g){if(this.L){var f=xe(a,b),h,i=this.L,k=a,o=c;h=f;var j=ld(i),j=we(k)?j[L]/2:j[w]/2,o=j-o;h=(h&4&&fd(i)?h^2:h)&-5;if(j=gd(i))i=md(i).Ob(),we(k)?i.top<j.top&&!(h&1)?o-=j.top-i.top:i[J]>j[J]&&h&1&&(o-=i[J]-j[J]):i[A]<j[A]&&!(h&2)?o-=j[A]-i[A]:i[M]>j[M]&&h&2&&(o-=i[M]-j[M]);h=o;var o=we(a)?new T(this.pa,h):new T(h,this.pa),D=we(a)?6:9;h=a^3;var q,i=this.L,j=xe(h,b);h=this.J;var k=f,u=o,o=d,f=this.Mb?D:0,z;if(D=h.offsetParent){var E=\"HTML\"==D[gb]||\"BODY\"==D[gb];if(!E||\"static\"!=\nbd(D,\"position\"))if(z=ed(D),!E){var E=D,Ga=fd(E),E=Ga&&V?-E[eb]:Ga&&(!U||!X(\"8\"))?E.scrollWidth-E[Ya]-E[eb]:E[eb];z=Yb(z,new T(E,D[Va]))}}E=i;D=md(E);(E=gd(E))&&D.Lb(new Xc(E[A],E.top,E[M]-E[A],E[J]-E.top));var E=D,Ga=Z(i),ca=Z(h);if(Ga.t()!=ca.t()){var Bb=Ga.t()[H],ca=ca.na(),Cb=new T(0,0),cb=Y(Bb)?Y(Bb)[Ra]||Y(Bb)[Sa]:aa,$c=Bb;do{var Sd=cb==ca?ed($c):hd($c);Cb.x+=Sd.x;Cb.y+=Sd.y}while(cb&&cb!=ca&&($c=cb.frameElement)&&(cb=cb.parent));ca=Cb;ca=Yb(ca,ed(Bb));U&&!Ga.ta()&&(ca=Yb(ca,Ga.sa()));v(E,E[A]+\nca.x);E.top+=ca.y}i=(j&4&&fd(i)?j^2:j)&-5;j=new T(i&2?D[A]+D[w]:D[A],i&1?D.top+D[L]:D.top);z&&(j=Yb(j,z));u&&(j.x+=(i&2?-1:1)*u.x,j.y+=(i&1?-1:1)*u.y);if(f&&(q=gd(h))&&z)q.top-=z.y,ua(q,q[M]-z.x),ra(q,q[J]-z.y),v(q,q[A]-z.x);a:{i=j;z=h;h=k;j=o;k=q;o=f;i=i.W();q=0;u=(h&4&&fd(z)?h^2:h)&-5;h=ld(z);f=h.W();if(j||0!=u)(u&2?i.x-=f[w]+(j?j[M]:0):j&&(i.x+=j[A]),u&1)?i.y-=f[L]+(j?j[J]:0):j&&(i.y+=j.top);if(o){if(k){q=i;j=f;u=0;if(65==(o&65)&&(q.x<k[A]||q.x>=k[M]))o&=-2;if(132==(o&132)&&(q.y<k.top||q.y>=k[J]))o&=\n-5;q.x<k[A]&&o&1&&(q.x=k[A],u|=1);q.x<k[A]&&q.x+j[w]>k[M]&&o&16&&(ga(j,t.max(j[w]-(q.x+j[w]-k[M]),0)),u|=4);q.x+j[w]>k[M]&&o&1&&(q.x=t.max(k[M]-j[w],k[A]),u|=1);o&2&&(u|=(q.x<k[A]?16:0)|(q.x+j[w]>k[M]?32:0));q.y<k.top&&o&4&&(q.y=k.top,u|=2);q.y>=k.top&&q.y+j[L]>k[J]&&o&32&&(ta(j,t.max(j[L]-(q.y+j[L]-k[J]),0)),u|=8);q.y+j[L]>k[J]&&o&4&&(q.y=t.max(k[J]-j[L],k.top),u|=2);o&8&&(u|=(q.y<k.top?64:0)|(q.y+j[L]>k[J]?128:0));q=u}else q=256;if(q&496)break a}k=z;j=i;i=V&&(tc||uc)&&X(\"1.9\");j instanceof T?(o=\nj.x,j=j.y):(o=j,j=l);v(k[G],jd(o,i));k[G].top=jd(j,i);if(!(h==f||(!h||!f?0:h[w]==f[w]&&h[L]==f[L])))(h=z,z=f,f=Y(h),k=Z(f).ta(),U&&(!k||!X(\"8\")))?(f=h[G],k)?(j=h,u=\"padding\",U?(k=pd(j,u+\"Left\"),o=pd(j,u+\"Right\"),i=pd(j,u+\"Top\"),j=pd(j,u+\"Bottom\"),k=new $(i,o,j,k)):(k=ad(j,u+\"Left\"),o=ad(j,u+\"Right\"),i=ad(j,u+\"Top\"),j=ad(j,u+\"Bottom\"),k=new $(s(i),s(o),s(j),s(k))),j=h,U?(h=rd(j,\"borderLeft\"),o=rd(j,\"borderRight\"),i=rd(j,\"borderTop\"),j=rd(j,\"borderBottom\"),h=new $(i,o,j,h)):(h=ad(j,\"borderLeftWidth\"),\no=ad(j,\"borderRightWidth\"),i=ad(j,\"borderTopWidth\"),j=ad(j,\"borderBottomWidth\"),h=new $(s(i),s(o),s(j),s(h))),f.pixelWidth=z[w]-h[A]-k[A]-k[M]-h[M],f.pixelHeight=z[L]-h.top-k.top-k[J]-h[J]):(f.pixelWidth=z[w],f.pixelHeight=z[L]):(f=\"border-box\",h=h[G],V?h.MozBoxSizing=f:W?h.WebkitBoxSizing=f:h.boxSizing=f,ga(h,t.max(z[w],0)+\"px\"),ta(h,t.max(z[L],0)+\"px\"))}if(!g&&q&496){this.Oa(a^3,b,c,d,m);return}}this.Nb(a,b,c)};\nN.Nb=function(a,b,c){var d=this.Xa;$b(this.bb,function(a){var b=d;Lc(b,a)},this);Jc(d,this.bb[a]);d[G].top=v(d[G],ua(d[G],ra(d[G],\"\")));this.L?(c=id(this.L,this.J),b=ye(this.L,a),we(a)?(a=t.min(t.max(c.y+b.y,15),this.J.offsetHeight-15),d[G].top=a+\"px\"):(a=t.min(t.max(c.x+b.x,15),this.J[Ba]-15),v(d[G],a+\"px\"))):(a=0==b?we(a)?\"top\":\"left\":we(a)?\"bottom\":\"right\",d[G][a]=c+\"px\")};\nvar xe=function(a,b){switch(a){case 2:return 0==b?1:3;case 1:return 0==b?0:2;case 0:return 0==b?6:7;default:return 0==b?4:5}},ye=function(a,b){var c=0,d=0,g=ld(a);switch(b){case 2:c=g[w]/2;break;case 1:c=g[w]/2;d=g[L];break;case 0:d=g[L]/2;break;case 3:c=g[w],d=g[L]/2}return new T(c,d)},we=function(a){return 0==a||3==a};U&&X(8);var ze,Ae=\"ScriptEngine\"in O;(ze=Ae&&\"JScript\"==O.ScriptEngine())&&(O.ScriptEngineMajorVersion(),O.ScriptEngineMinorVersion(),O.ScriptEngineBuildVersion());var Be=ze;var Ce=function(a,b){this.i=Be?[]:\"\";a!=n&&this[ib][K](this,arguments)};Ce[F].set=function(a){this.clear();this[ib](a)};Be?(Ce[F].Aa=0,Ce[F].append=function(a,b,c){b==n?this.i[this.Aa++]=a:(this.i[wa][K](this.i,arguments),this.Aa=this.i[C]);return this}):Ce[F].append=function(a,b,c){this.i+=a;if(b!=n)for(var d=1;d<arguments[C];d++)this.i+=arguments[d];return this};Ce[F].clear=function(){if(Be){oa(this.i,0);this.Aa=0}else this.i=\"\"};\nna(Ce[F],function(){if(Be){var a=this.i[jb](\"\");this.clear();a&&this[ib](a);return a}return this.i});var De=Ce;var Ee=function(a,b){var c=b||new De;c[ib]('<div class=\"',\"jfk-bubble\",'\"><div class=\"',\"jfk-bubble-content-id\",'\"></div>');a.Db&&c[ib]('<div class=\"',\"jfk-bubble-closebtn-id\",\" \",\"jfk-bubble-closebtn\",'\" aria-label=\"',\"Close\",'\" role=button tabindex=0></div>');c[ib]('<div class=\"',\"jfk-bubble-arrow-id\",\" \",\"jfk-bubble-arrow\",'\"><div class=\"',\"jfk-bubble-arrowimplbefore\",'\"></div><div class=\"',\"jfk-bubble-arrowimplafter\",'\"></div></div></div>');return b?\"\":c[Wa]()};var Fe=function(a){this.r=a||Z();this.Y=new ve(this.q);this.p=new ue;this.Na=0};Q(Fe,ee);N=Fe[F];N.q=\"jfk-bubble\";N.la=m;N.Kb=p;N.wa=function(a){this.Y.wa(a);this.l()};N.Q=function(a,b,c,d){R(!this.P(),\"Must call setPosition() before rendering\");this.Y.Q(a,b,c,d)};N.kc=function(a){R(!this.P(),\"Must call setShowClosebox() before rendering\");this.la=a};N.jc=function(a){R(P(a)||a[Aa],\"Content must be a string or HTML.\");this.yb=a;this.Pa(a)};\nN.Pa=function(a){var b=this.lb();a&&b&&(P(a)?ha(b,a):(ha(b,\"\"),b[va](a)))};N.lb=function(){return this.N(this.q+\"-content-id\")};N.U=function(){this.Ma(re(Ee,{Db:this.la},l,this.$()));this.Pa(this.yb);nd(this.a(),p);this.p.Ka(this.a());this.p.Cb(pe(this.a(),0.218,\"ease-out\",0,1),pe(this.a(),0.218,\"ease-in\",1,0))};\nN.u=function(){Fe.d.u[I](this);this.ka().e(this.p,[\"beforeshow\",\"show\",\"beforehide\",\"hide\"],this.nb);this.la&&this.ka().ob(this.N(this.q+\"-closebtn-id\"),ie,Db(this.R,p));var a=this.a();R(a,\"getElement() returns null.\");var b=this.N(this.q+\"-arrow-id\");R(b,\"No arrow element is found!\");this.Y.pb(a,b);this.p.Q(this.Y)};N.R=function(a){this.p.R(a)};N.V=function(){return this.p.V()};N.l=function(){this.V()&&this.p.l()};N.c=function(){this.p.k();delete this.p;Fe.d.c[I](this)};\nN.Ua=function(){var a=hd(this.a());this.Na&&a.y<this.Na&&this.R(p);return p};N.nb=function(a){if(\"show\"==a[B]||\"hide\"==a[B]){var b=this.ka(),c=this.$(),c=U?c.na():c.t();\"show\"==a[B]?b.e(c,\"scroll\",this.Ua):b.O(c,\"scroll\",this.Ua)}b=this[Ea](a[B]);this.Kb&&\"hide\"==a[B]&&this.k();return b};var Ge=function(a,b,c){b=new fe(b);b.T=c;b.xc(a)},He=n,Ie=function(){He&&(ud(He),He=n)},Je=function(a,b){Ld(a,\"focus\",function(){var c=a,d=b;He&&ud(He);var g=He=new Fe;g.wa(c);g.kc(p);g.jc(d);g.Q(3,0,20,-15);g.ic();g.R(m)});Ld(a,\"blur\",Ie)},Ke=function(a,b,c){(b=ea.getElementById(b))&&sa(b[G],a.checked&&c||!a.checked&&!c?\"\":\"none\")};mb(\"registerInfoMessage\",Je,l);mb(\"setInputPlaceholder\",Ge,l);mb(\"showHideByCheckedValue\",Ke,l); })()\n"
          },
          "redirectURL": "",
          "headersSize": 396,
          "bodySize": 15612
        },
        "cache": {},
        "timings": {
          "blocked": 0,
          "dns": 0,
          "connect": 0,
          "send": 0,
          "wait": 32,
          "receive": 31
        },
        "serverIPAddress": "74.125.237.116",
        "connection": "443"
      },
      {
        "pageref": "page_7372",
        "startedDateTime": "2012-04-03T10:22:45.260+10:00",
        "time": 171,
        "request": {
          "method": "GET",
          "url": "https://www.google.com/accounts/recovery/resources/2134501236-all-css-kennedy.css",
          "httpVersion": "HTTP/1.1",
          "cookies": [
            {
              "name": "accountrecoverylocale",
              "value": "en"
            },
            {
              "name": "mainpageaccountrecoveryparamscookie",
              "value": "CmJBSHdHa1JuSXI5TUhydFN0MTg1T05SMWxvLXBDcmtZejZ5TTZPc1E3YlZ6bU1uczNsMTNCV2lSOVBMV2lEcTBsNnJMWDJEdkg4TTN0d2c2eWFaeU9kRnFLbE1JV05BOUhtQRIdaHR0cHM6Ly9tYWlsLmdvb2dsZS5jb20vbWFpbC8gspOJo8ub6qNN"
            },
            {
              "name": "GMAIL_RTT",
              "value": "270"
            },
            {
              "name": "S",
              "value": "account-recovery=bD7NAj-9Icg"
            }
          ],
          "headers": [
            {
              "name": "Host",
              "value": "www.google.com"
            },
            {
              "name": "User-Agent",
              "value": "Mozilla/5.0 (Windows NT 6.1; WOW64; rv:11.0) Gecko/20100101 Firefox/11.0"
            },
            {
              "name": "Accept",
              "value": "text/css,*/*;q=0.1"
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
              "value": "https://www.google.com/accounts/recovery?hl=en&gaps=AHwGkRnIr9MHrtSt185ONR1lo-pCrkYz6yM6OsQ7bVzmMns3l13BWiR9PLWiDq0l6rLX2DvH8M3twg6yaZyOdFqKlMIWNA9HmA&service=mail&continue=https%3A%2F%2Fmail.google.com%2Fmail%2F"
            },
            {
              "name": "Cookie",
              "value": "accountrecoverylocale=en; mainpageaccountrecoveryparamscookie=CmJBSHdHa1JuSXI5TUhydFN0MTg1T05SMWxvLXBDcmtZejZ5TTZPc1E3YlZ6bU1uczNsMTNCV2lSOVBMV2lEcTBsNnJMWDJEdkg4TTN0d2c2eWFaeU9kRnFLbE1JV05BOUhtQRIdaHR0cHM6Ly9tYWlsLmdvb2dsZS5jb20vbWFpbC8gspOJo8ub6qNN; GMAIL_RTT=270; S=account-recovery=bD7NAj-9Icg"
            }
          ],
          "queryString": [],
          "headersSize": 831,
          "bodySize": -1
        },
        "response": {
          "status": 200,
          "statusText": "OK",
          "httpVersion": "HTTP/1.1",
          "cookies": [],
          "headers": [
            {
              "name": "Expires",
              "value": "Wed, 02 May 2012 07:47:55 GMT"
            },
            {
              "name": "Date",
              "value": "Mon, 02 Apr 2012 07:47:55 GMT"
            },
            {
              "name": "Last-Modified",
              "value": "Wed, 28 Mar 2012 12:40:40 GMT"
            },
            {
              "name": "Content-Type",
              "value": "text/css; charset=utf-8"
            },
            {
              "name": "Content-Encoding",
              "value": "gzip"
            },
            {
              "name": "X-Content-Type-Options",
              "value": "nosniff"
            },
            {
              "name": "X-Frame-Options",
              "value": "SAMEORIGIN"
            },
            {
              "name": "X-XSS-Protection",
              "value": "1; mode=block"
            },
            {
              "name": "Server",
              "value": "GSE"
            },
            {
              "name": "Cache-Control",
              "value": "public, max-age=2592000"
            },
            {
              "name": "Content-Length",
              "value": "5128"
            },
            {
              "name": "Age",
              "value": "59687"
            }
          ],
          "content": {
            "mimeType": "text/css",
            "size": 33756,
            "text": "/* Copyright 2012 Google Inc. All Rights Reserved. */\n.goog-inline-block{position:relative;display:-moz-inline-box;display:inline-block}* html .goog-inline-block{display:inline}*:first-child+html .goog-inline-block{display:inline}.jfk-bubble{-webkit-box-shadow:0 1px 3px rgba(0,0,0,.2);-moz-box-shadow:0 1px 3px rgba(0,0,0,.2);box-shadow:0 1px 3px rgba(0,0,0,.2);background-color:#fff;border:1px solid;border-color:#bbb #bbb #a8a8a8;padding:16px;position:absolute;z-index:1201!important}.jfk-bubble-closebtn{background:url(\"//ssl.gstatic.com/ui/v1/icons/common/x_8px.png\") no-repeat;border:1px solid transparent;height:21px;opacity:.4;outline:0;position:absolute;right:2px;top:2px;width:21px}.jfk-bubble-closebtn:focus{border:1px solid #4d90fe;opacity:.8}.jfk-bubble-arrow{position:absolute}.jfk-bubble-arrow .jfk-bubble-arrowimplbefore,.jfk-bubble-arrow .jfk-bubble-arrowimplafter{display:block;height:0;position:absolute;width:0}.jfk-bubble-arrow .jfk-bubble-arrowimplbefore{border:9px solid}.jfk-bubble-arrow .jfk-bubble-arrowimplafter{border:8px solid}.jfk-bubble-arrowdown{bottom:0}.jfk-bubble-arrowup{top:-9px}.jfk-bubble-arrowleft{left:-9px}.jfk-bubble-arrowright{right:0}.jfk-bubble-arrowdown .jfk-bubble-arrowimplbefore,.jfk-bubble-arrowup .jfk-bubble-arrowimplbefore{border-color:#bbb transparent;left:-9px}.jfk-bubble-arrowdown .jfk-bubble-arrowimplbefore{border-color:#a8a8a8 transparent}.jfk-bubble-arrowdown .jfk-bubble-arrowimplafter,.jfk-bubble-arrowup .jfk-bubble-arrowimplafter{border-color:#fff transparent;left:-8px}.jfk-bubble-arrowdown .jfk-bubble-arrowimplbefore{border-bottom-width:0}.jfk-bubble-arrowdown .jfk-bubble-arrowimplafter{border-bottom-width:0}.jfk-bubble-arrowup .jfk-bubble-arrowimplbefore{border-top-width:0}.jfk-bubble-arrowup .jfk-bubble-arrowimplafter{border-top-width:0;top:1px}.jfk-bubble-arrowleft .jfk-bubble-arrowimplbefore,.jfk-bubble-arrowright .jfk-bubble-arrowimplbefore{border-color:transparent #bbb;top:-9px}.jfk-bubble-arrowleft .jfk-bubble-arrowimplafter,.jfk-bubble-arrowright .jfk-bubble-arrowimplafter{border-color:transparent #fff;top:-8px}.jfk-bubble-arrowleft .jfk-bubble-arrowimplbefore{border-left-width:0}.jfk-bubble-arrowleft .jfk-bubble-arrowimplafter{border-left-width:0;left:1px}.jfk-bubble-arrowright .jfk-bubble-arrowimplbefore{border-right-width:0}.jfk-bubble-arrowright .jfk-bubble-arrowimplafter{border-right-width:0}html,body{position:absolute;height:100%;min-width:100%}.wrapper{position:relative;min-height:100%}.content{padding:0 44px}.google-header-bar{height:71px;background:#f5f5f5;border-bottom:1px solid #e5e5e5;overflow:hidden;width:100%}.header .logo{margin:16px 0 0 1px;float:left}.header .signin,.header .signup{margin:28px 0 0;float:right;font-weight:bold}.header .signin-button,.header .signup-button{margin:22px 0 0;float:right}.header .signin-button a{color:#333;font-size:13px;font-weight:normal}.header .signup-button a{position:relative;top:-1px;margin:0 0 0 1em}.main{margin:0 auto;width:650px;padding-top:23px;padding-bottom:100px}.main h1:first-child{margin:0 0 .92em}.google-footer-bar{position:absolute;bottom:0;height:35px;width:100%;border-top:1px solid #ebebeb;overflow:hidden}.footer{padding-top:9px;font-size:.85em;white-space:nowrap;line-height:0}.footer ul{color:#999;float:left;max-width:80%}.footer ul li{display:inline;padding:0 1.5em 0 0}.footer a{color:#333}.footer form{text-align:right}.footer form .lang-chooser{max-width:20%}.redtext{color:#dd4b39}.greytext{color:#555}.secondary{font-size:11px;color:#666}.source{color:#093}.hidden{display:none}.announce-bar{position:absolute;bottom:35px;height:33px;z-index:2;width:100%;background:#f9edbe;border-top:1px solid #efe1ac;border-bottom:1px solid #efe1ac;overflow:hidden}.announce-bar .message{font-size:.85em;line-height:33px;margin:0}.announce-bar a{margin:0 0 0 1em}.clearfix:after{visibility:hidden;display:block;font-size:0;content:'.';clear:both;height:0}* html .clearfix{zoom:1}*:first-child+html .clearfix{zoom:1}.english-text{direction:ltr;text-align:left}.recovery .hideable-box{margin-top:10px;margin-left:40px;line-height:17px}.recovery .disabledtext{color:#b8b8b8}.recovery .hideable-box div{margin-top:5px;margin-bottom:5px}.recovery .hideable-box .left{margin-right:5px;float:left}.recovery .hideable-box .right{margin-left:0px;float:left}.recovery .hideable-box .confirmation-box{margin-bottom:5px}.recovery .hideable-box .secret-question-text{font-weight:bold}.recovery .recovery-submit{margin-top:20px}.recovery .additional-recovery-option-text{margin-left:20px}.tool-tip-bubble{width:255px;line-height:17px}.internal-header{font-size:1.4em;position:absolute;color:red;font-weight:bold;text-align:center;left:50%;margin-left:-5em;margin-top:2px}.recaptcha-widget #recaptcha_image{height:57px;text-align:center;overflow:hidden;background:whiteSmoke}.recaptcha-widget #recaptcha_image a{line-height:17px}.recaptcha-widget .recaptcha-main{position:relative}.recaptcha-widget .recaptcha-main label strong{display:block}.recaptcha-widget .recaptcha-buttons{position:absolute;top:2.69em;left:18em}.recaptcha-widget .recaptcha-buttons a{display:inline-block;height:21px;width:21px;margin-left:2px;background:#fff;background-position:center center;background-repeat:no-repeat;line-height:0;opacity:.55}.recaptcha-widget .recaptcha-buttons a:hover{opacity:.8}.recaptcha-widget #recaptcha_reload_btn{background:url(//ssl.gstatic.com/accounts/recaptcha-sprite.png) -63px}.recaptcha-widget #recaptcha_switch_audio_btn{background:url(//ssl.gstatic.com/accounts/recaptcha-sprite.png) -42px}.recaptcha-widget #recaptcha_switch_img_btn{background:url(//ssl.gstatic.com/accounts/recaptcha-sprite.png) -21px}.recaptcha-widget #recaptcha_whatsthis_btn{background:url(//ssl.gstatic.com/accounts/recaptcha-sprite.png)}.recaptcha-widget .recaptcha-buttons span{position:absolute;left:-99999em}.recaptcha-widget.recaptcha_is_showing_audio .recaptcha_only_if_image,.recaptcha-widget.recaptcha_isnot_showing_audio .recaptcha_only_if_audio{display:none!important}.footer form .lang-chooser{max-width:20%}html,body,div,h1,h2,h3,h4,h5,h6,p,img,dl,dt,dd,ol,ul,li,table,tr,td,form,object,embed,article,aside,canvas,command,details,figcaption,figure,footer,group,header,hgroup,mark,menu,meter,nav,output,progress,section,summary,time,audio,video{margin:0;padding:0;border:0}article,aside,details,figcaption,figure,footer,header,hgroup,menu,nav,section{display:block}html{font:81.25% arial,helvetica,sans-serif;background:#fff;color:#333;line-height:1;direction:ltr}a{color:#15c;text-decoration:none}a:active{color:#d14836}a:hover{text-decoration:underline}h1,h2,h3,h4,h5,h6{color:#222;font-size:1.54em;font-weight:normal;line-height:24px;margin:0 0 .46em}p{line-height:17px;margin:0 0 1em}ol,ul{list-style:none;line-height:17px;margin:0 0 1em}li{margin:0 0 .5em}table{border-collapse:collapse;border-spacing:0}strong{color:#222}button,input,select,textarea{font-family:inherit;font-size:inherit}button::-moz-focus-inner,input::-moz-focus-inner{border:0}input[type=email],input[type=number],input[type=password],input[type=text],input[type=url]{display:inline-block;height:29px;width:17em;line-height:25px;margin:0;padding-left:8px;background:#fff;border:1px solid #d9d9d9;border-top:1px solid #c0c0c0;-webkit-box-sizing:border-box;-moz-box-sizing:border-box;box-sizing:border-box;-webkit-border-radius:1px;-moz-border-radius:1px;border-radius:1px}input[type=email]:hover,input[type=number]:hover,input[type=password]:hover,input[type=text]:hover,input[type=url]:hover{border:1px solid #b9b9b9;border-top:1px solid #a0a0a0;-webkit-box-shadow:inset 0 1px 2px rgba(0,0,0,0.1);-moz-box-shadow:inset 0 1px 2px rgba(0,0,0,0.1);box-shadow:inset 0 1px 2px rgba(0,0,0,0.1)}input[type=email]:focus,input[type=number]:focus,input[type=password]:focus,input[type=text]:focus,input[type=url]:focus{outline:none;border:1px solid #4d90fe;-webkit-box-shadow:inset 0 1px 2px rgba(0,0,0,0.3);-moz-box-shadow:inset 0 1px 2px rgba(0,0,0,0.3);box-shadow:inset 0 1px 2px rgba(0,0,0,0.3)}input[type=email][disabled=disabled],input[type=number][disabled=disabled],input[type=password][disabled=disabled],input[type=text][disabled=disabled],input[type=url][disabled=disabled]{border:1px solid #e5e5e5;background:#f5f5f5}input[type=email][disabled=disabled]:hover,input[type=number][disabled=disabled]:hover,input[type=password][disabled=disabled]:hover,input[type=text][disabled=disabled]:hover,input[type=url][disabled=disabled]:hover{-webkit-box-shadow:none;-moz-box-shadow:none;box-shadow:none}input[type=\"checkbox\"],input[type=\"radio\"]{-webkit-appearance:none;-moz-appearance:none;width:13px;height:13px;margin:0;cursor:pointer;vertical-align:bottom;background:white;border:1px solid gainsboro;-webkit-border-radius:1px;-moz-border-radius:1px;border-radius:1px;-webkit-box-sizing:border-box;-moz-box-sizing:border-box;box-sizing:border-box;position:relative;border-image:initial}input[type=checkbox]:active,input[type=radio]:active{border-color:#c6c6c6;background:#ebebeb}input[type=checkbox]:hover{border-color:#c6c6c6;-webkit-box-shadow:inset 0 1px 1px rgba(0,0,0,0.1);-moz-box-shadow:inset 0 1px 1px rgba(0,0,0,0.1);box-shadow:inset 0 1px 1px rgba(0,0,0,0.1)}input[type=radio]{-webkit-border-radius:1em;-moz-border-radius:1em;border-radius:1em;width:15px;height:15px}input[type=checkbox]:checked,input[type=radio]:checked{background:#fff}input[type=radio]:checked::after{content:'';display:block;position:relative;top:3px;left:3px;width:7px;height:7px;background:#666;-webkit-border-radius:1em;-moz-border-radius:1em;border-radius:1em}input[type=checkbox]:checked::after{content:url(//ssl.gstatic.com/ui/v1/menu/checkmark.png);display:block;position:absolute;top:-6px;left:-5px}input[type=checkbox]:focus{outline:none;border-color:#4d90fe}.g-button{min-width:46px;text-align:center;color:#444;font-size:11px;font-weight:bold;height:27px;padding:0 8px;line-height:27px;-webkit-border-radius:2px;-moz-border-radius:2px;border-radius:2px;-webkit-transition:all 0.218s;-moz-transition:all 0.218s;-ms-transition:all 0.218s;-o-transition:all 0.218s;transition:all 0.218s;border:1px solid #dcdcdc;border:1px solid rgba(0,0,0,0.1);background-color:#f5f5f5;background-image:-webkit-gradient(linear,left top,left bottom,from(#f5f5f5),to(#f1f1f1));background-image:-webkit-linear-gradient(top,#f5f5f5,#f1f1f1);background-image:-moz-linear-gradient(top,#f5f5f5,#f1f1f1);background-image:-ms-linear-gradient(top,#f5f5f5,#f1f1f1);background-image:-o-linear-gradient(top,#f5f5f5,#f1f1f1);background-image:linear-gradient(top,#f5f5f5,#f1f1f1);-webkit-user-select:none;-moz-user-select:none;-ms-user-select:none;cursor:default}*+html .g-button{min-width:70px}button.g-button,input[type=submit].g-button{height:29px;line-height:25px;vertical-align:middle;margin:0;padding-left:18px;padding-right:18px}*+html button.g-button,*+html input[type=submit].g-button{overflow:visible}.g-button:hover{border:1px solid #c6c6c6;color:#333;text-decoration:none;-webkit-transition:all 0.0s;-moz-transition:all 0.0s;-ms-transition:all 0.0s;-o-transition:all 0.0s;transition:all 0.0s;background-color:#f8f8f8;background-image:-webkit-gradient(linear,left top,left bottom,from(#f8f8f8),to(#f1f1f1));background-image:-webkit-linear-gradient(top,#f8f8f8,#f1f1f1);background-image:-moz-linear-gradient(top,#f8f8f8,#f1f1f1);background-image:-ms-linear-gradient(top,#f8f8f8,#f1f1f1);background-image:-o-linear-gradient(top,#f8f8f8,#f1f1f1);background-image:linear-gradient(top,#f8f8f8,#f1f1f1);-webkit-box-shadow:0 1px 1px rgba(0,0,0,0.1);-moz-box-shadow:0 1px 1px rgba(0,0,0,0.1);box-shadow:0 1px 1px rgba(0,0,0,0.1)}.g-button:active{background-color:#f6f6f6;background-image:-webkit-gradient(linear,left top,left bottom,from(#f6f6f6),to(#f1f1f1));background-image:-webkit-linear-gradient(top,#f6f6f6,#f1f1f1);background-image:-moz-linear-gradient(top,#f6f6f6,#f1f1f1);background-image:-ms-linear-gradient(top,#f6f6f6,#f1f1f1);background-image:-o-linear-gradient(top,#f6f6f6,#f1f1f1);background-image:linear-gradient(top,#f6f6f6,#f1f1f1);-webkit-box-shadow:inset 0 1px 2px rgba(0,0,0,0.1);-moz-box-shadow:inset 0 1px 2px rgba(0,0,0,0.1);box-shadow:inset 0 1px 2px rgba(0,0,0,0.1)}.g-button:visited{color:#666}.g-button-submit{border:1px solid #3079ed;color:#fff;text-shadow:0 1px rgba(0,0,0,0.1);background-color:#4d90fe;background-image:-webkit-gradient(linear,left top,left bottom,from(#4d90fe),to(#4787ed));background-image:-webkit-linear-gradient(top,#4d90fe,#4787ed);background-image:-moz-linear-gradient(top,#4d90fe,#4787ed);background-image:-ms-linear-gradient(top,#4d90fe,#4787ed);background-image:-o-linear-gradient(top,#4d90fe,#4787ed);background-image:linear-gradient(top,#4d90fe,#4787ed)}.g-button-submit:hover{border:1px solid #2f5bb7;color:#fff;text-shadow:0 1px rgba(0,0,0,0.3);background-color:#357ae8;background-image:-webkit-gradient(linear,left top,left bottom,from(#4d90fe),to(#357ae8));background-image:-webkit-linear-gradient(top,#4d90fe,#357ae8);background-image:-moz-linear-gradient(top,#4d90fe,#357ae8);background-image:-ms-linear-gradient(top,#4d90fe,#357ae8);background-image:-o-linear-gradient(top,#4d90fe,#357ae8);background-image:linear-gradient(top,#4d90fe,#357ae8)}.g-button-submit:active{-webkit-box-shadow:inset 0 1px 2px rgba(0,0,0,0.3);-moz-box-shadow:inset 0 1px 2px rgba(0,0,0,0.3);box-shadow:inset 0 1px 2px rgba(0,0,0,0.3)}.g-button-share{border:1px solid #29691d;color:#fff;text-shadow:0 1px rgba(0,0,0,0.1);background-color:#3d9400;background-image:-webkit-gradient(linear,left top,left bottom,from(#3d9400),to(#398a00));background-image:-webkit-linear-gradient(top,#3d9400,#398a00);background-image:-moz-linear-gradient(top,#3d9400,#398a00);background-image:-ms-linear-gradient(top,#3d9400,#398a00);background-image:-o-linear-gradient(top,#3d9400,#398a00);background-image:linear-gradient(top,#3d9400,#398a00)}.g-button-share:hover{border:1px solid #2d6200;color:#fff;text-shadow:0 1px rgba(0,0,0,0.3);background-color:#368200;background-image:-webkit-gradient(linear,left top,left bottom,from(#3d9400),to(#368200));background-image:-webkit-linear-gradient(top,#3d9400,#368200);background-image:-moz-linear-gradient(top,#3d9400,#368200);background-image:-ms-linear-gradient(top,#3d9400,#368200);background-image:-o-linear-gradient(top,#3d9400,#368200);background-image:linear-gradient(top,#3d9400,#368200)}.g-button-share:active{-webkit-box-shadow:inset 0 1px 2px rgba(0,0,0,0.3);-moz-box-shadow:inset 0 1px 2px rgba(0,0,0,0.3);box-shadow:inset 0 1px 2px rgba(0,0,0,0.3)}.g-button-red{border:1px solid transparent;color:#fff;text-shadow:0 1px rgba(0,0,0,0.1);text-transform:uppercase;background-color:#d14836;background-image:-webkit-gradient(linear,left top,left bottom,from(#dd4b39),to(#d14836));background-image:-webkit-linear-gradient(top,#dd4b39,#d14836);background-image:-moz-linear-gradient(top,#dd4b39,#d14836);background-image:-ms-linear-gradient(top,#dd4b39,#d14836);background-image:-o-linear-gradient(top,#dd4b39,#d14836);background-image:linear-gradient(top,#dd4b39,#d14836)}.g-button-red:hover{border:1px solid #b0281a;color:#fff;text-shadow:0 1px rgba(0,0,0,0.3);background-color:#c53727;background-image:-webkit-gradient(linear,left top,left bottom,from(#dd4b39),to(#c53727));background-image:-webkit-linear-gradient(top,#dd4b39,#c53727);background-image:-moz-linear-gradient(top,#dd4b39,#c53727);background-image:-ms-linear-gradient(top,#dd4b39,#c53727);background-image:-o-linear-gradient(top,#dd4b39,#c53727);background-image:linear-gradient(top,#dd4b39,#c53727);-webkit-box-shadow:0 1px 1px rgba(0,0,0,0.2);-moz-box-shadow:0 1px 1px rgba(0,0,0,0.2);-ms-box-shadow:0 1px 1px rgba(0,0,0,0.2);box-shadow:0 1px 1px rgba(0,0,0,0.2)}.g-button-red:active{border:1px solid #992a1b;background-color:#b0281a;background-image:-webkit-gradient(linear,left top,left bottom,from(#dd4b39),to(#b0281a));background-image:-webkit-linear-gradient(top,#dd4b39,#b0281a);background-image:-moz-linear-gradient(top,#dd4b39,#b0281a);background-image:-ms-linear-gradient(top,#dd4b39,#b0281a);background-image:-o-linear-gradient(top,#dd4b39,#b0281a);background-image:linear-gradient(top,#dd4b39,#b0281a);-webkit-box-shadow:inset 0 1px 2px rgba(0,0,0,0.3);-moz-box-shadow:inset 0 1px 2px rgba(0,0,0,0.3);box-shadow:inset 0 1px 2px rgba(0,0,0,0.3)}.g-button-white{border:1px solid #dcdcdc;color:#666;background:#fff}.g-button-white:hover{border:1px solid #c6c6c6;color:#333;background:#fff;-webkit-box-shadow:0 1px 1px rgba(0,0,0,0.1);-moz-box-shadow:0 1px 1px rgba(0,0,0,0.1);box-shadow:0 1px 1px rgba(0,0,0,0.1)}.g-button-white:active{background:#fff;-webkit-box-shadow:inset 0 1px 2px rgba(0,0,0,0.1);-moz-box-shadow:inset 0 1px 2px rgba(0,0,0,0.1);box-shadow:inset 0 1px 2px rgba(0,0,0,0.1)}.g-button-red:visited,.g-button-share:visited,.g-button-submit:visited{color:#fff}.g-button-submit:focus,.g-button-share:focus,.g-button-red:focus{-webkit-box-shadow:inset 0 0 0 1px #fff;-moz-box-shadow:inset 0 0 0 1px #fff;box-shadow:inset 0 0 0 1px #fff}.g-button-share:focus{border-color:#29691d}.g-button-red:focus{border-color:#d14836}.g-button-submit:focus:hover,.g-button-share:focus:hover,.g-button-red:focus:hover{-webkit-box-shadow:inset 0 0 0 1px #fff,0 1px 1px rgba(0,0,0,0.1);-moz-box-shadow:inset 0 0 0 1px #fff,0 1px 1px rgba(0,0,0,0.1);box-shadow:inset 0 0 0 1px #fff,0 1px 1px rgba(0,0,0,0.1)}.goog-menu{-webkit-box-shadow:0 2px 4px rgba(0,0,0,0.2);-moz-box-shadow:0 2px 4px rgba(0,0,0,0.2);box-shadow:0 2px 4px rgba(0,0,0,0.2);-webkit-transition:opacity 0.218s;-moz-transition:opacity 0.218s;-ms-transition:opacity 0.218s;-o-transition:opacity 0.218s;transition:opacity 0.218s;background:#fff;border:1px solid #ccc;border:1px solid rgba(0,0,0,.2);cursor:default;font-size:13px;margin:0;outline:none;padding:0 0 6px;position:absolute;z-index:2;overflow:auto}.goog-menuitem,.goog-tristatemenuitem,.goog-filterobsmenuitem{position:relative;color:#333;cursor:pointer;list-style:none;margin:0;padding:6px 7em 6px 30px;white-space:nowrap}.goog-menuitem-highlight,.goog-menuitem-hover{background-color:#eee;border-color:#eee;border-style:dotted;border-width:1px 0;padding-top:5px;padding-bottom:5px}.goog-menuitem-highlight .goog-menuitem-content,.goog-menuitem-hover .goog-menuitem-content{color:#333}.goog-menuseparator{border-top:1px solid #ebebeb;margin-top:9px;margin-bottom:10px}.goog-inline-block{position:relative;display:-moz-inline-box;display:inline-block}* html .goog-inline-block{display:inline}*:first-child+html .goog-inline-block{display:inline}.dropdown-block{display:block}.goog-flat-menu-button{-webkit-border-radius:2px;-moz-border-radius:2px;border-radius:2px;background-color:#f5f5f5;background-image:-webkit-gradient(linear,left top,left bottom,from(#f5f5f5),to(#f1f1f1));background-image:-webkit-linear-gradient(top,#f5f5f5,#f1f1f1);background-image:-moz-linear-gradient(top,#f5f5f5,#f1f1f1);background-image:-ms-linear-gradient(top,#f5f5f5,#f1f1f1);background-image:-o-linear-gradient(top,#f5f5f5,#f1f1f1);background-image:linear-gradient(top,#f5f5f5,#f1f1f1);border:1px solid #dcdcdc;color:#444;font-size:11px;font-weight:bold;line-height:27px;list-style:none;margin:0 2px;min-width:46px;outline:none;padding:0 18px 0 6px;text-decoration:none;vertical-align:middle}.goog-flat-menu-button-disabled{background-color:#fff;border-color:#f3f3f3;color:#b8b8b8;cursor:default}.goog-flat-menu-button.goog-flat-menu-button-hover{background-color:#f8f8f8;background-image:-webkit-linear-gradient(top,#f8f8f8,#f1f1f1);background-image:-moz-linear-gradient(top,#f8f8f8,#f1f1f1);background-image:-ms-linear-gradient(top,#f8f8f8,#f1f1f1);background-image:-o-linear-gradient(top,#f8f8f8,#f1f1f1);background-image:linear-gradient(top,#f8f8f8,#f1f1f1);-webkit-box-shadow:0 1px 1px rgba(0,0,0,.1);-moz-box-shadow:0 1px 1px rgba(0,0,0,.1);box-shadow:0 1px 1px rgba(0,0,0,.1);border-color:#c6c6c6;color:#333}.goog-flat-menu-button.goog-flat-menu-button-focused{border-color:#4d90fe}.goog-flat-menu-button.goog-flat-menu-button-open,.goog-flat-menu-button.goog-flat-menu-button-active{-webkit-box-shadow:inset 0 1px 2px rgba(0,0,0,.1);-moz-box-shadow:inset 0 1px 2px rgba(0,0,0,.1);box-shadow:inset 0 1px 2px rgba(0,0,0,.1);background-color:#eee;background-image:-webkit-linear-gradient(top,#eee,#e0e0e0);background-image:-moz-linear-gradient(top,#eee,#e0e0e0);background-image:-ms-linear-gradient(top,#eee,#e0e0e0);background-image:-o-linear-gradient(top,#eee,#e0e0e0);background-image:linear-gradient(top,#eee,#e0e0e0);border:1px solid #ccc;color:#333;z-index:2}.goog-flat-menu-button-caption{vertical-align:top;white-space:nowrap}.goog-flat-menu-button-dropdown{border-color:#777 transparent;border-style:solid;border-width:4px 4px 0;height:0;width:0;position:absolute;right:5px;top:12px}.jfk-select .goog-flat-menu-button-dropdown{background:url(//ssl.gstatic.com/ui/v1/disclosure/grey-disclosure-arrow-up-down.png) center no-repeat;border:none;height:11px;margin-top:-4px;width:7px}.goog-menu-nocheckbox .goog-menuitem,.goog-menu-noicon .goog-menuitem{padding-left:16px;vertical-align:middle}::-webkit-scrollbar{height:16px;width:16px;overflow:visible}::-webkit-scrollbar-button{height:0;width:0}::-webkit-scrollbar-track{background-clip:padding-box;border:solid transparent;border-width:0 0 0 7px}::-webkit-scrollbar-track:horizontal{border-width:7px 0 0}::-webkit-scrollbar-track:hover{background-color:rgba(0,0,0,.05);-webkit-box-shadow:inset 1px 0 0 rgba(0,0,0,.1);box-shadow:inset 1px 0 0 rgba(0,0,0,.1)}::-webkit-scrollbar-track:horizontal:hover{-webkit-box-shadow:inset 0 1px 0 rgba(0,0,0,.1);box-shadow:inset 0 1px 0 rgba(0,0,0,.1)}::-webkit-scrollbar-track:active{background-color:rgba(0,0,0,.05);-webkit-box-shadow:inset 1px 0 0 rgba(0,0,0,.14),inset -1px 0 0 rgba(0,0,0,.07);box-shadow:inset 1px 0 0 rgba(0,0,0,.14),inset -1px 0 0 rgba(0,0,0,.07)}::-webkit-scrollbar-track:horizontal:active{-webkit-box-shadow:inset 0 1px 0 rgba(0,0,0,.14),inset 0 -1px 0 rgba(0,0,0,.07);box-shadow:inset 0 1px 0 rgba(0,0,0,.14),inset 0 -1px 0 rgba(0,0,0,.07)}.jfk-scrollbar-dark::-webkit-scrollbar-track:hover{background-color:rgba(255,255,255,.1);-webkit-box-shadow:inset 1px 0 0 rgba(255,255,255,.2);box-shadow:inset 1px 0 0 rgba(255,255,255,.2)}.jfk-scrollbar-dark::-webkit-scrollbar-track:horizontal:hover{-webkit-box-shadow:inset 0 1px 0 rgba(255,255,255,.2);box-shadow:inset 0 1px 0 rgba(255,255,255,.2)}.jfk-scrollbar-dark::-webkit-scrollbar-track:active{background-color:rgba(255,255,255,.1);-webkit-box-shadow:inset 1px 0 0 rgba(255,255,255,.25),inset -1px 0 0 rgba(255,255,255,.15);box-shadow:inset 1px 0 0 rgba(255,255,255,.25),inset -1px 0 0 rgba(255,255,255,.15)}.jfk-scrollbar-dark::-webkit-scrollbar-track:horizontal:active{-webkit-box-shadow:inset 0 1px 0 rgba(255,255,255,.25),inset 0 -1px 0 rgba(255,255,255,.15);box-shadow:inset 0 1px 0 rgba(255,255,255,.25),inset 0 -1px 0 rgba(255,255,255,.15)}::-webkit-scrollbar-thumb{background-color:rgba(0,0,0,.2);background-clip:padding-box;border:solid transparent;border-width:0 0 0 7px;min-height:28px;padding:100px 0 0;-webkit-box-shadow:inset 1px 1px 0 rgba(0,0,0,.1),inset 0 -1px 0 rgba(0,0,0,.07);box-shadow:inset 1px 1px 0 rgba(0,0,0,.1),inset 0 -1px 0 rgba(0,0,0,.07)}::-webkit-scrollbar-thumb:horizontal{border-width:7px 0 0;padding:0 0 0 100px;-webkit-box-shadow:inset 1px 1px 0 rgba(0,0,0,.1),inset -1px 0 0 rgba(0,0,0,.07);box-shadow:inset 1px 1px 0 rgba(0,0,0,.1),inset -1px 0 0 rgba(0,0,0,.07)}::-webkit-scrollbar-thumb:hover{background-color:rgba(0,0,0,.4);-webkit-box-shadow:inset 1px 1px 1px rgba(0,0,0,.25);box-shadow:inset 1px 1px 1px rgba(0,0,0,.25)}::-webkit-scrollbar-thumb:active{background-color:rgba(0,0,0,.5);-webkit-box-shadow:inset 1px 1px 3px rgba(0,0,0,.35);box-shadow:inset 1px 1px 3px rgba(0,0,0,.35)}.jfk-scrollbar-dark::-webkit-scrollbar-thumb{background-color:rgba(255,255,255,.3);-webkit-box-shadow:inset 1px 1px 0 rgba(255,255,255,.15),inset 0 -1px 0 rgba(255,255,255,.1);box-shadow:inset 1px 1px 0 rgba(255,255,255,.15),inset 0 -1px 0 rgba(255,255,255,.1)}.jfk-scrollbar-dark::-webkit-scrollbar-thumb:horizontal{-webkit-box-shadow:inset 1px 1px 0 rgba(255,255,255,.15),inset -1px 0 0 rgba(255,255,255,.1);box-shadow:inset 1px 1px 0 rgba(255,255,255,.15),inset -1px 0 0 rgba(255,255,255,.1)}.jfk-scrollbar-dark::-webkit-scrollbar-thumb:hover{background-color:rgba(255,255,255,.6);-webkit-box-shadow:inset 1px 1px 1px rgba(255,255,255,.37);box-shadow:inset 1px 1px 1px rgba(255,255,255,.37)}.jfk-scrollbar-dark::-webkit-scrollbar-thumb:active{background-color:rgba(255,255,255,.75);-webkit-box-shadow:inset 1px 1px 3px rgba(255,255,255,.5);box-shadow:inset 1px 1px 3px rgba(255,255,255,.5)}.jfk-scrollbar-borderless::-webkit-scrollbar-track{border-width:0 1px 0 6px}.jfk-scrollbar-borderless::-webkit-scrollbar-track:horizontal{border-width:6px 0 1px}.jfk-scrollbar-borderless::-webkit-scrollbar-track:hover{background-color:rgba(0,0,0,.035);-webkit-box-shadow:inset 1px 1px 0 rgba(0,0,0,.14),inset -1px -1px 0 rgba(0,0,0,.07);box-shadow:inset 1px 1px 0 rgba(0,0,0,.14),inset -1px -1px 0 rgba(0,0,0,.07)}.jfk-scrollbar-borderless.jfk-scrollbar-dark::-webkit-scrollbar-track:hover{background-color:rgba(255,255,255,.07);-webkit-box-shadow:inset 1px 1px 0 rgba(255,255,255,.25),inset -1px -1px 0 rgba(255,255,255,.15);box-shadow:inset 1px 1px 0 rgba(255,255,255,.25),inset -1px -1px 0 rgba(255,255,255,.15)}.jfk-scrollbar-borderless::-webkit-scrollbar-thumb{border-width:0 1px 0 6px}.jfk-scrollbar-borderless::-webkit-scrollbar-thumb:horizontal{border-width:6px 0 1px}::-webkit-scrollbar-corner{background:transparent}body::-webkit-scrollbar-track-piece{background-clip:padding-box;background-color:#f5f5f5;border:solid #fff;border-width:0 0 0 3px;-webkit-box-shadow:inset 1px 0 0 rgba(0,0,0,.14),inset -1px 0 0 rgba(0,0,0,.07);box-shadow:inset 1px 0 0 rgba(0,0,0,.14),inset -1px 0 0 rgba(0,0,0,.07)}body::-webkit-scrollbar-track-piece:horizontal{border-width:3px 0 0;-webkit-box-shadow:inset 0 1px 0 rgba(0,0,0,.14),inset 0 -1px 0 rgba(0,0,0,.07);box-shadow:inset 0 1px 0 rgba(0,0,0,.14),inset 0 -1px 0 rgba(0,0,0,.07)}body::-webkit-scrollbar-thumb{border-width:1px 1px 1px 5px}body::-webkit-scrollbar-thumb:horizontal{border-width:5px 1px 1px}body::-webkit-scrollbar-corner{background-clip:padding-box;background-color:#f5f5f5;border:solid #fff;border-width:3px 0 0 3px;-webkit-box-shadow:inset 1px 1px 0 rgba(0,0,0,.14);box-shadow:inset 1px 1px 0 rgba(0,0,0,.14)}.jfk-scrollbar::-webkit-scrollbar{height:16px;overflow:visible;width:16px}.jfk-scrollbar::-webkit-scrollbar-button{height:0;width:0}.jfk-scrollbar::-webkit-scrollbar-track{background-clip:padding-box;border:solid transparent;border-width:0 0 0 7px}.jfk-scrollbar::-webkit-scrollbar-track:horizontal{border-width:7px 0 0}.jfk-scrollbar::-webkit-scrollbar-track:hover{background-color:rgba(0,0,0,.05);-webkit-box-shadow:inset 1px 0 0 rgba(0,0,0,.1);box-shadow:inset 1px 0 0 rgba(0,0,0,.1)}.jfk-scrollbar::-webkit-scrollbar-track:horizontal:hover{-webkit-box-shadow:inset 0 1px 0 rgba(0,0,0,.1);box-shadow:inset 0 1px 0 rgba(0,0,0,.1)}.jfk-scrollbar::-webkit-scrollbar-track:active{background-color:rgba(0,0,0,.05);-webkit-box-shadow:inset 1px 0 0 rgba(0,0,0,.14),inset -1px 0 0 rgba(0,0,0,.07);box-shadow:inset 1px 0 0 rgba(0,0,0,.14),inset -1px 0 0 rgba(0,0,0,.07)}.jfk-scrollbar::-webkit-scrollbar-track:horizontal:active{-webkit-box-shadow:inset 0 1px 0 rgba(0,0,0,.14),inset 0 -1px 0 rgba(0,0,0,.07);box-shadow:inset 0 1px 0 rgba(0,0,0,.14),inset 0 -1px 0 rgba(0,0,0,.07)}.jfk-scrollbar-dark.jfk-scrollbar::-webkit-scrollbar-track:hover{background-color:rgba(255,255,255,.1);-webkit-box-shadow:inset 1px 0 0 rgba(255,255,255,.2);box-shadow:inset 1px 0 0 rgba(255,255,255,.2)}.jfk-scrollbar-dark.jfk-scrollbar::-webkit-scrollbar-track:horizontal:hover{-webkit-box-shadow:inset 0 1px 0 rgba(255,255,255,.2);box-shadow:inset 0 1px 0 rgba(255,255,255,.2)}.jfk-scrollbar-dark.jfk-scrollbar::-webkit-scrollbar-track:active{background-color:rgba(255,255,255,.1);-webkit-box-shadow:inset 1px 0 0 rgba(255,255,255,.25),inset -1px 0 0 rgba(255,255,255,.15);box-shadow:inset 1px 0 0 rgba(255,255,255,.25),inset -1px 0 0 rgba(255,255,255,.15)}.jfk-scrollbar-dark.jfk-scrollbar::-webkit-scrollbar-track:horizontal:active{-webkit-box-shadow:inset 0 1px 0 rgba(255,255,255,.25),inset 0 -1px 0 rgba(255,255,255,.15);box-shadow:inset 0 1px 0 rgba(255,255,255,.25),inset 0 -1px 0 rgba(255,255,255,.15)}.jfk-scrollbar::-webkit-scrollbar-thumb{background-color:rgba(0,0,0,.2);background-clip:padding-box;border:solid transparent;border-width:0 0 0 7px;min-height:28px;padding:100px 0 0;-webkit-box-shadow:inset 1px 1px 0 rgba(0,0,0,.1),inset 0 -1px 0 rgba(0,0,0,.07);box-shadow:inset 1px 1px 0 rgba(0,0,0,.1),inset 0 -1px 0 rgba(0,0,0,.07)}.jfk-scrollbar::-webkit-scrollbar-thumb:horizontal{border-width:7px 0 0;padding:0 0 0 100px;-webkit-box-shadow:inset 1px 1px 0 rgba(0,0,0,.1),inset -1px 0 0 rgba(0,0,0,.07);box-shadow:inset 1px 1px 0 rgba(0,0,0,.1),inset -1px 0 0 rgba(0,0,0,.07)}.jfk-scrollbar::-webkit-scrollbar-thumb:hover{background-color:rgba(0,0,0,.4);-webkit-box-shadow:inset 1px 1px 1px rgba(0,0,0,.25);box-shadow:inset 1px 1px 1px rgba(0,0,0,.25)}.jfk-scrollbar::-webkit-scrollbar-thumb:active{background-color:rgba(0,0,0,0.5);-webkit-box-shadow:inset 1px 1px 3px rgba(0,0,0,0.35);box-shadow:inset 1px 1px 3px rgba(0,0,0,0.35)}.jfk-scrollbar-dark.jfk-scrollbar::-webkit-scrollbar-thumb{background-color:rgba(255,255,255,.3);-webkit-box-shadow:inset 1px 1px 0 rgba(255,255,255,.15),inset 0 -1px 0 rgba(255,255,255,.1);box-shadow:inset 1px 1px 0 rgba(255,255,255,.15),inset 0 -1px 0 rgba(255,255,255,.1)}.jfk-scrollbar-dark.jfk-scrollbar::-webkit-scrollbar-thumb:horizontal{-webkit-box-shadow:inset 1px 1px 0 rgba(255,255,255,.15),inset -1px 0 0 rgba(255,255,255,.1);box-shadow:inset 1px 1px 0 rgba(255,255,255,.15),inset -1px 0 0 rgba(255,255,255,.1)}.jfk-scrollbar-dark.jfk-scrollbar::-webkit-scrollbar-thumb:hover{background-color:rgba(255,255,255,.6);-webkit-box-shadow:inset 1px 1px 1px rgba(255,255,255,.37);box-shadow:inset 1px 1px 1px rgba(255,255,255,.37)}.jfk-scrollbar-dark.jfk-scrollbar::-webkit-scrollbar-thumb:active{background-color:rgba(255,255,255,.75);-webkit-box-shadow:inset 1px 1px 3px rgba(255,255,255,.5);box-shadow:inset 1px 1px 3px rgba(255,255,255,.5)}.jfk-scrollbar-borderless.jfk-scrollbar::-webkit-scrollbar-track{border-width:0 1px 0 6px}.jfk-scrollbar-borderless.jfk-scrollbar::-webkit-scrollbar-track:horizontal{border-width:6px 0 1px}.jfk-scrollbar-borderless.jfk-scrollbar::-webkit-scrollbar-track:hover{background-color:rgba(0,0,0,.035);-webkit-box-shadow:inset 1px 1px 0 rgba(0,0,0,.14),inset -1px -1px 0 rgba(0,0,0,.07);box-shadow:inset 1px 1px 0 rgba(0,0,0,.14),inset -1px -1px 0 rgba(0,0,0,.07)}.jfk-scrollbar-borderless.jfk-scrollbar-dark.jfk-scrollbar::-webkit-scrollbar-track:hover{background-color:rgba(255,255,255,.07);-webkit-box-shadow:inset 1px 1px 0 rgba(255,255,255,.25),inset -1px -1px 0 rgba(255,255,255,.15);box-shadow:inset 1px 1px 0 rgba(255,255,255,.25),inset -1px -1px 0 rgba(255,255,255,.15)}.jfk-scrollbar-borderless.jfk-scrollbar::-webkit-scrollbar-thumb{border-width:0 1px 0 6px}.jfk-scrollbar-borderless.jfk-scrollbar::-webkit-scrollbar-thumb:horizontal{border-width:6px 0 1px}.jfk-scrollbar::-webkit-scrollbar-corner{background:transparent}body.jfk-scrollbar::-webkit-scrollbar-track-piece{background-clip:padding-box;background-color:#f5f5f5;border:solid #fff;border-width:0 0 0 3px;-webkit-box-shadow:inset 1px 0 0 rgba(0,0,0,.14),inset -1px 0 0 rgba(0,0,0,.07);box-shadow:inset 1px 0 0 rgba(0,0,0,.14),inset -1px 0 0 rgba(0,0,0,.07)}body.jfk-scrollbar::-webkit-scrollbar-track-piece:horizontal{border-width:3px 0 0;-webkit-box-shadow:inset 0 1px 0 rgba(0,0,0,.14),inset 0 -1px 0 rgba(0,0,0,.07);box-shadow:inset 0 1px 0 rgba(0,0,0,.14),inset 0 -1px 0 rgba(0,0,0,.07)}body.jfk-scrollbar::-webkit-scrollbar-thumb{border-width:1px 1px 1px 5px}body.jfk-scrollbar::-webkit-scrollbar-thumb:horizontal{border-width:5px 1px 1px}body.jfk-scrollbar::-webkit-scrollbar-corner{background-clip:padding-box;background-color:#f5f5f5;border:solid #fff;border-width:3px 0 0 3px;-webkit-box-shadow:inset 1px 1px 0 rgba(0,0,0,.14);box-shadow:inset 1px 1px 0 rgba(0,0,0,.14)}.g-button img{display:inline-block;margin:-3px 0 0;opacity:.55;vertical-align:middle}*+html .g-button img{margin:4px 0 0}.g-button:hover img{opacity:.72}.g-button:active img{opacity:1}.errormsg{margin:.5em 0 0;display:block;color:#dd4b39;line-height:17px}.errortext{color:#dd4b39}input[type=email].form-error,input[type=number].form-error,input[type=password].form-error,input[type=text].form-error,input[type=url].form-error{border:1px solid #dd4b39}.help-link{background:#dd4b39;padding:0 5px;color:#fff;font-weight:bold;display:inline-block;-webkit-border-radius:1em;-moz-border-radius:1em;border-radius:1em;text-decoration:none;position:relative;top:0px}.help-link:visited{color:#fff}.help-link:hover{opacity:.7;color:#fff}form .knowledge-test-section{margin-bottom:1.5em}form .knowledge-test-input{margin:.3em 0 .8em}.knowledge-test-page-title{font-size:135%}form .knowledge-service-sub-input{float:left}.progressbar-container{height:20px;width:45%;border-radius:10px;margin:0px auto 0px auto;background-color:lightgray}.progressbar{height:100%;width:10%;background-color:blue;border-radius:10px 0px 0px 10px}.progressbar-full{height:100%;width:10%;background-color:blue;border-radius:10px}.date-input-day{width:60px!important}.date-input-year{width:80px!important}.shadowList{padding:6px;list-style:disc inside}.shadowList>li{position:relative;margin-bottom:0px}.butter-note{font-size:0.90em;background:#f9edbe;border:1px solid #f0c36d}.butter-note ul{list-style:disc;margin-left:17px;margin-bottom:0px}.butter-note li{position:relative}"
          },
          "redirectURL": "",
          "headersSize": 387,
          "bodySize": 5128
        },
        "cache": {},
        "timings": {
          "blocked": 0,
          "dns": 0,
          "connect": 134,
          "send": 0,
          "wait": 35,
          "receive": 2
        },
        "serverIPAddress": "74.125.237.116",
        "connection": "443"
      },
      {
        "pageref": "page_7372",
        "startedDateTime": "2012-04-03T10:22:45.579+10:00",
        "time": 346,
        "request": {
          "method": "GET",
          "url": "https://ssl.google-analytics.com/__utm.gif?utmwv=5.2.6&utms=1&utmn=1485686516&utmhn=www.google.com&utmcs=UTF-8&utmsr=1920x1200&utmvp=1920x795&utmsc=24-bit&utmul=en-us&utmje=0&utmfl=11.2%20r202&utmdt=Google%20Account%20Recovery&utmhid=1190382058&utmr=https%3A%2F%2Faccounts.google.com%2FServiceLogin%3Fservice%3Dmail%26passive%3Dtrue%26rm%3Dfalse%26continue%3Dhttps%3A%2F%2Fmail.google.com%2Fmail%2F%26ss%3D1%26scc%3D1%26ltmpl%3Ddefault%26ltmplcache%3D2&utmp=%2Faccounts%2Frecovery%3Fhl%3Den%26gaps%3DAHwGkRnIr9MHrtSt185ONR1lo-pCrkYz6yM6OsQ7bVzmMns3l13BWiR9PLWiDq0l6rLX2DvH8M3twg6yaZyOdFqKlMIWNA9HmA%26service%3Dmail%26continue%3Dhttps%25253A%25252F%25252Fmail.google.com%25252Fmail%25252F&utmac=UA-20013302-1&utmcc=__utma%3D173272373.1583558031.1333412565.1333412565.1333412565.1%3B%2B__utmz%3D173272373.1333412565.1.1.utmcsr%3Daccounts.google.com%7Cutmccn%3D(referral)%7Cutmcmd%3Dreferral%7Cutmcct%3D%2FServiceLogin%3B&utmu=qI~",
          "httpVersion": "HTTP/1.1",
          "cookies": [],
          "headers": [
            {
              "name": "Host",
              "value": "ssl.google-analytics.com"
            },
            {
              "name": "User-Agent",
              "value": "Mozilla/5.0 (Windows NT 6.1; WOW64; rv:11.0) Gecko/20100101 Firefox/11.0"
            },
            {
              "name": "Accept",
              "value": "image/png,image/*;q=0.8,*/*;q=0.5"
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
              "value": "https://www.google.com/accounts/recovery?hl=en&gaps=AHwGkRnIr9MHrtSt185ONR1lo-pCrkYz6yM6OsQ7bVzmMns3l13BWiR9PLWiDq0l6rLX2DvH8M3twg6yaZyOdFqKlMIWNA9HmA&service=mail&continue=https%3A%2F%2Fmail.google.com%2Fmail%2F"
            }
          ],
          "queryString": [
            {
              "name": "utmac",
              "value": "UA-20013302-1"
            },
            {
              "name": "utmcc",
              "value": "__utma=173272373.1583558031.1333412565.1333412565.1333412565.1;+__utmz=173272373.1333412565.1.1.utmcsr=accounts.google.com|utmccn=(referral)|utmcmd=referral|utmcct=/ServiceLogin;"
            },
            {
              "name": "utmcs",
              "value": "UTF-8"
            },
            {
              "name": "utmdt",
              "value": "Google Account Recovery"
            },
            {
              "name": "utmfl",
              "value": "11.2 r202"
            },
            {
              "name": "utmhid",
              "value": "1190382058"
            },
            {
              "name": "utmhn",
              "value": "www.google.com"
            },
            {
              "name": "utmje",
              "value": "0"
            },
            {
              "name": "utmn",
              "value": "1485686516"
            },
            {
              "name": "utmp",
              "value": "/accounts/recovery?hl=en&gaps=AHwGkRnIr9MHrtSt185ONR1lo-pCrkYz6yM6OsQ7bVzmMns3l13BWiR9PLWiDq0l6rLX2DvH8M3twg6yaZyOdFqKlMIWNA9HmA&service=mail&continue=https%253A%252F%252Fmail.google.com%252Fmail%252F"
            },
            {
              "name": "utmr",
              "value": "https://accounts.google.com/ServiceLogin?service=mail&passive=true&rm=false&continue=https://mail.google.com/mail/&ss=1&scc=1&ltmpl=default&ltmplcache=2"
            },
            {
              "name": "utms",
              "value": "1"
            },
            {
              "name": "utmsc",
              "value": "24-bit"
            },
            {
              "name": "utmsr",
              "value": "1920x1200"
            },
            {
              "name": "utmu",
              "value": "qI~"
            },
            {
              "name": "utmul",
              "value": "en-us"
            },
            {
              "name": "utmvp",
              "value": "1920x795"
            },
            {
              "name": "utmwv",
              "value": "5.2.6"
            }
          ],
          "headersSize": 1386,
          "bodySize": -1
        },
        "response": {
          "status": 200,
          "statusText": "OK",
          "httpVersion": "HTTP/1.1",
          "cookies": [],
          "headers": [
            {
              "name": "Date",
              "value": "Wed, 28 Mar 2012 15:58:23 GMT"
            },
            {
              "name": "Content-Length",
              "value": "35"
            },
            {
              "name": "X-Content-Type-Options",
              "value": "nosniff"
            },
            {
              "name": "Pragma",
              "value": "no-cache"
            },
            {
              "name": "Expires",
              "value": "Wed, 19 Apr 2000 11:43:00 GMT"
            },
            {
              "name": "Last-Modified",
              "value": "Wed, 21 Jan 2004 19:51:30 GMT"
            },
            {
              "name": "Content-Type",
              "value": "image/gif"
            },
            {
              "name": "Cache-Control",
              "value": "private, no-cache, no-cache=Set-Cookie, proxy-revalidate"
            },
            {
              "name": "Age",
              "value": "462260"
            },
            {
              "name": "Server",
              "value": "GFE/2.0"
            }
          ],
          "content": {
            "mimeType": "image/gif",
            "size": 35
          },
          "redirectURL": "",
          "headersSize": 341,
          "bodySize": 35
        },
        "cache": {},
        "timings": {
          "blocked": 0,
          "dns": 0,
          "connect": 0,
          "send": 0,
          "wait": 346,
          "receive": 0
        },
        "serverIPAddress": "74.125.237.30",
        "connection": "443"
      },
      {
        "pageref": "page_7372",
        "startedDateTime": "2012-04-03T10:22:46.002+10:00",
        "time": 162,
        "request": {
          "method": "GET",
          "url": "https://www.google.com/csi?v=3&s=account_recovery&action=allpages&rt=prt.70,ol.550",
          "httpVersion": "HTTP/1.1",
          "cookies": [
            {
              "name": "GMAIL_RTT",
              "value": "270"
            },
            {
              "name": "S",
              "value": "account-recovery=bD7NAj-9Icg"
            }
          ],
          "headers": [
            {
              "name": "Host",
              "value": "www.google.com"
            },
            {
              "name": "User-Agent",
              "value": "Mozilla/5.0 (Windows NT 6.1; WOW64; rv:11.0) Gecko/20100101 Firefox/11.0"
            },
            {
              "name": "Accept",
              "value": "image/png,image/*;q=0.8,*/*;q=0.5"
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
              "value": "https://www.google.com/accounts/recovery?hl=en&gaps=AHwGkRnIr9MHrtSt185ONR1lo-pCrkYz6yM6OsQ7bVzmMns3l13BWiR9PLWiDq0l6rLX2DvH8M3twg6yaZyOdFqKlMIWNA9HmA&service=mail&continue=https%3A%2F%2Fmail.google.com%2Fmail%2F"
            },
            {
              "name": "Cookie",
              "value": "GMAIL_RTT=270; S=account-recovery=bD7NAj-9Icg"
            }
          ],
          "queryString": [
            {
              "name": "action",
              "value": "allpages"
            },
            {
              "name": "rt",
              "value": "prt.70,ol.550"
            },
            {
              "name": "s",
              "value": "account_recovery"
            },
            {
              "name": "v",
              "value": "3"
            }
          ],
          "headersSize": 595,
          "bodySize": -1
        },
        "response": {
          "status": 204,
          "statusText": "No Content",
          "httpVersion": "HTTP/1.1",
          "cookies": [],
          "headers": [
            {
              "name": "Content-Length",
              "value": "0"
            },
            {
              "name": "Date",
              "value": "Wed, 21 Jan 2004 19:51:30 GMT"
            },
            {
              "name": "Pragma",
              "value": "no-cache"
            },
            {
              "name": "Cache-Control",
              "value": "private, no-cache"
            },
            {
              "name": "Expires",
              "value": "Wed, 17 Sep 1975 21:32:10 GMT"
            },
            {
              "name": "Content-Type",
              "value": "image/gif"
            },
            {
              "name": "Server",
              "value": "Golfe"
            }
          ],
          "content": {
            "mimeType": "image/gif",
            "size": 0
          },
          "redirectURL": "",
          "headersSize": 215,
          "bodySize": 0
        },
        "cache": {},
        "timings": {
          "blocked": 0,
          "dns": 0,
          "connect": 0,
          "send": 0,
          "wait": 162,
          "receive": 0
        },
        "serverIPAddress": "74.125.237.116",
        "connection": "443"
      }
    ]
  }
}
_FIREBUG_RESULTS_
ok($har->string($firebug_gmail_string), "Successfully read firebug har archive for https://accounts.google.com");
my (undef, $secondEntry) = $har->entries();
ok(scalar $secondEntry->request()->cookies() == 1, "INPUT: Firebug's archive second entry request has a cookie list with 1 entries");
my ($cookie) = $secondEntry->request->cookies();
ok($cookie->name() eq 'GMAIL_RTT', "INPUT: Firebug's archive second entry request cookie has a name of 'GMAIL_RTT'");
ok($cookie->value() eq '270', "INPUT: Firebug's archive second entry request cookie has a value of '270'");
($cookie) = $secondEntry->response()->cookies();
ok($cookie->name() eq 'accountrecoverylocale', "INPUT: Firebug's archive second entry response cookie has a name of 'accountrecoverylocale'");
ok($cookie->value() eq 'en', "INPUT: Firebug's archive second entry response cookie has a name of 'en'");
ok($cookie->expires() eq '2012-04-10T10:22:42.000+10:00', "INPUT: Firebug's archive second entry response cookie has a expires of '2012-04-10T10:22:42.000+10:00'");
ok($cookie->path() eq '/accounts/recovery', "INPUT: Firebug's archive second entry response cookie has a path of '/accounts/recovery'");
ok($cookie->http_only(), "INPUT: Firebug's archive second entry response cookie has httpOnly set to true");
ok(not(defined($cookie->secure())), "INPUT: Firebug's archive second entry response cookie does not have secure set at all");
my $firebug_ref = $har->hashref();
ok(scalar @{$firebug_ref->{log}->{entries}->[1]->{request}->{cookies}} == 1, "OUTPUT: Firebug's archive second entry request has a cookie list with 1 entries");
ok($firebug_ref->{log}->{entries}->[1]->{request}->{cookies}->[0]->{name} eq 'GMAIL_RTT', "OUTPUT: Firebug's archive second entry request has a name of 'GMAIL_RTT'");
ok($firebug_ref->{log}->{entries}->[1]->{request}->{cookies}->[0]->{value} eq '270', "OUTPUT: Firebug's archive second entry request has a value of '270'");
ok($firebug_ref->{log}->{entries}->[1]->{response}->{cookies}->[0]->{name} eq 'accountrecoverylocale', "OUTPUT: Firebug's archive second entry response has a name of 'accountrecoverylocale'");
ok($firebug_ref->{log}->{entries}->[1]->{response}->{cookies}->[0]->{value} eq 'en', "OUTPUT: Firebug's archive second entry request has a value of 'en'");
ok($firebug_ref->{log}->{entries}->[1]->{response}->{cookies}->[0]->{expires} eq '2012-04-10T10:22:42.000+10:00', "OUTPUT: Firebug's archive second entry request has a expires of '2012-04-10T10:22:42.000+10:00'");
ok($firebug_ref->{log}->{entries}->[1]->{response}->{cookies}->[0]->{path} eq '/accounts/recovery', "OUTPUT: Firebug's archive second entry request has a path of '/accounts/recovery'");
ok($firebug_ref->{log}->{entries}->[1]->{response}->{cookies}->[0]->{httpOnly}, "OUTPUT: Firebug's archive second entry request has httpOnly set to true");
ok(not(exists $firebug_ref->{log}->{entries}->[1]->{response}->{cookies}->[0]->{secure}), "OUTPUT: Firebug's archive second entry request does not have a secure key at all");
