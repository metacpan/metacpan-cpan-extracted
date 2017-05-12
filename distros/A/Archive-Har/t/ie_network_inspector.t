#!perl -T

use strict;
use warnings;
use Archive::Har();
use Test::More tests => 2;

my $har = Archive::Har->new();
$har->xml(<<'__XML__');
<?xml version="1.0" encoding="UTF-8"?>
<log>
    <version>1.1</version>
    <creator>
        <name>Internet Explorer Network Inspector</name>
        <version>10.0.9200.16720</version>
    </creator>
    <browser>
        <name>Internet Explorer</name>
        <version>10.0.9200.16720</version>
    </browser>
    <pages>
        <page>
            <startedDateTime>2013-10-27T14:47:53.543+00:00</startedDateTime>
            <id>0</id>
            <title/>
            <pageTimings>
                <onContentLoad>507</onContentLoad>
                <onLoad>688</onLoad>
            </pageTimings>
        </page>
    </pages>
    <entries>
        <entry>
            <pageref>0</pageref>
            <startedDateTime>2013-10-27T14:47:53.543+00:00</startedDateTime>
            <time>437</time>
            <request>
                <method>POST</method>
                <url>http://127.0.0.1:8080/history</url>
                <httpVersion>HTTP/1.1</httpVersion>
                <cookies>
                    <cookie>
                        <name>s_pers</name>
                        <value>%20s_fid%3D66B8301EC09E9D87-0B811F10F3FCB850%7C1436988064901%3B%20s_vs%3D1%7C1373917864913%3B%20s_nr%3D1373916064925-New%7C1405452064925%3B</value>
                    </cookie>
                </cookies>
                <headers>
                    <header>
                        <name>Accept</name>
                        <value>text/html, application/xhtml+xml, */*</value>
                    </header>
                    <header>
                        <name>Referer</name>
                        <value>http://127.0.0.1:8080/history</value>
                    </header>
                    <header>
                        <name>Accept-Language</name>
                        <value>en-GB</value>
                    </header>
                    <header>
                        <name>User-Agent</name>
                        <value>Mozilla/5.0 (compatible; MSIE 10.0; Windows NT 6.1; WOW64; Trident/6.0)</value>
                    </header>
                    <header>
                        <name>Content-Type</name>
                        <value>application/x-www-form-urlencoded</value>
                    </header>
                    <header>
                        <name>Accept-Encoding</name>
                        <value>gzip, deflate</value>
                    </header>
                    <header>
                        <name>Host</name>
                        <value>127.0.0.1:8080</value>
                    </header>
                    <header>
                        <name>Content-Length</name>
                        <value>580</value>
                    </header>
                    <header>
                        <name>DNT</name>
                        <value>1</value>
                    </header>
                    <header>
                        <name>Connection</name>
                        <value>Keep-Alive</value>
                    </header>
                    <header>
                        <name>Cache-Control</name>
                        <value>no-cache</value>
                    </header>
                    <header>
                        <name>Cookie</name>
                        <value>s_pers=%20s_fid%3D66B8301EC09E9D87-0B811F10F3FCB850%7C1436988064901%3B%20s_vs%3D1%7C1373917864913%3B%20s_nr%3D1373916064925-New%7C1405452064925%3B</value>
                    </header>
                </headers>
                <queryString/>
                <postData>
                    <mimeType>application/x-www-form-urlencoded</mimeType>
                    <text>search=&amp;sort=inserted&amp;negate=&amp;session=A44xUm5oA&amp;start_message=0&amp;filter=&amp;rowid_1715=1715&amp;reclassify_1715=&amp;rowid_1716=1716&amp;reclassify_1716=&amp;rowid_1718=1718&amp;reclassify_1718=&amp;rowid_1723=1723&amp;undo_1723=Undo&amp;rowid_1734=1734&amp;reclassify_1734=&amp;rowid_1762=1762&amp;reclassify_1762=&amp;rowid_1767=1767&amp;reclassify_1767=&amp;rowid_1769=1769&amp;rowid_1770=1770&amp;reclassify_1770=&amp;rowid_1771=1771&amp;reclassify_1771=&amp;rowid_1772=1772&amp;reclassify_1772=&amp;rowid_1773=1773&amp;reclassify_1773=&amp;rowid_1774=1774&amp;reclassify_1774=&amp;rowid_1775=1775&amp;reclassify_1775=&amp;rowid_1776=1776&amp;reclassify_1776=&amp;rowid_1777=1777&amp;reclassify_1777=</text>
                </postData>
                <headersSize>559</headersSize>
                <bodySize>580</bodySize>
            </request>
            <response>
                <status>200</status>
                <statusText>OK</statusText>
                <httpVersion>HTTP/1.0</httpVersion>
                <cookies/>
                <headers>
                    <header>
                        <name>Connection</name>
                        <value>close</value>
                    </header>
                    <header>
                        <name>Content-Type</name>
                        <value>text/html; charset=ISO-8859-1</value>
                    </header>
                    <header>
                        <name>Date</name>
                        <value>Sun, 27 Oct 2013 14:47:53 GMT</value>
                    </header>
                    <header>
                        <name>Expires</name>
                        <value>0</value>
                    </header>
                    <header>
                        <name>Pragma</name>
                        <value>no-cache</value>
                    </header>
                    <header>
                        <name>Cache-Control</name>
                        <value>no-cache</value>
                    </header>
                    <header>
                        <name>Content-Length</name>
                        <value>46208</value>
                    </header>
                </headers>
                <content>
                    <size>46208</size>
                    <mimeType>text/html; charset=ISO-8859-1</mimeType>
                    <text>&lt;!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd"&gt;
&lt;html lang="en"&gt;
&lt;head&gt;
    &lt;title&gt;POPFile Control Center&lt;/title&gt;
    &lt;link rel="icon" href="favicon.ico"&gt;
    &lt;link rel="stylesheet" type="text/css" href="skins/simplyblue/style.css" title="POPFile"&gt;
    &lt;meta http-equiv="Content-Script-Type" content="text/javascript"&gt;
&lt;script type="text/javascript"&gt;
&lt;!--
function OnLoadHandler(){ return 0; }
// --&gt;
&lt;/script&gt;

&lt;/head&gt;

&lt;body dir="ltr" onLoad="OnLoadHandler()"&gt;
    &lt;table class="shellTop" align="center" width="100%" summary=""&gt;
        &lt;tr class="shellTopRow"&gt;
            &lt;td class="shellTopLeft"&gt;&lt;/td&gt;
            &lt;td class="shellTopCenter"&gt;&lt;/td&gt;
            &lt;td class="shellTopRight"&gt;&lt;/td&gt;
        &lt;/tr&gt;
        &lt;tr&gt;
            &lt;td class="shellLeft"&gt;&lt;/td&gt;
            &lt;td class="naked"&gt;
                &lt;table class="head" cellspacing="0" summary=""&gt;
                    &lt;tr&gt;
                        &lt;td class="head"&gt;POPFile Control Center&lt;/td&gt;
                        &lt;td class="headShutdown" align="right" valign="bottom"&gt;&lt;a class="shutdownLink" href="/shutdown"&gt;Shutdown POPFile&lt;/a&gt;&amp;nbsp;&lt;/td&gt;
                    &lt;/tr&gt;
                &lt;/table&gt;
            &lt;/td&gt;
            &lt;td class="shellRight"&gt;&lt;/td&gt;
        &lt;/tr&gt;
        &lt;tr class="shellBottomRow"&gt;
            &lt;td class="shellBottomLeft"&gt;&lt;/td&gt;
            &lt;td class="shellBottomCenter"&gt;&lt;/td&gt;
            &lt;td class="shellBottomRight"&gt;&lt;/td&gt;
        &lt;/tr&gt;
    &lt;/table&gt;
    &lt;br /&gt;
    &lt;table class="menu" cellspacing="0" summary="This table is the navigation menu which allows access to each of the different pages of the control center."&gt;
        &lt;tr&gt;
            &lt;td class="menuIndent"&gt;&amp;nbsp;&lt;/td&gt;
            &lt;td class="menuSelected" align="center"&gt;
                &lt;a class="menuLink" href="/history?session=A44xUm5oA"&gt;History&lt;/a&gt;
            &lt;/td&gt;
            &lt;td class="menuSpacer"&gt;&lt;/td&gt;
            &lt;td class="menuStandard" align="center"&gt;
                &lt;a class="menuLink" href="/buckets?session=A44xUm5oA"&gt;Buckets&lt;/a&gt;
            &lt;/td&gt;
            &lt;td class="menuSpacer"&gt;&lt;/td&gt;
            &lt;td class="menuStandard" align="center"&gt;
                &lt;a class="menuLink" href="/magnets?session=A44xUm5oA&amp;amp;start_magnet=0"&gt;Magnets&lt;/a&gt;
            &lt;/td&gt;
            &lt;td class="menuSpacer"&gt;&lt;/td&gt;
            &lt;td class="menuStandard" align="center"&gt;
                &lt;a class="menuLink" href="/configuration?session=A44xUm5oA"&gt;Configuration&lt;/a&gt;
            &lt;/td&gt;
            &lt;td class="menuSpacer"&gt;&lt;/td&gt;
            &lt;td class="menuStandard" align="center"&gt;
                &lt;a class="menuLink" href="/security?session=A44xUm5oA"&gt;Security&lt;/a&gt;
            &lt;/td&gt;
            &lt;td class="menuSpacer"&gt;&lt;/td&gt;
            &lt;td class="menuStandard" align="center"&gt;
                &lt;a class="menuLink" href="/advanced?session=A44xUm5oA"&gt;Advanced&lt;/a&gt;
            &lt;/td&gt;
            &lt;td class="menuIndent"&gt;&amp;nbsp;&lt;/td&gt;
        &lt;/tr&gt;
    &lt;/table&gt;
    &lt;table class="shell" align="center" width="100%" summary=""&gt;
        &lt;tr class="shellTopRow"&gt;
            &lt;td class="shellTopLeft"&gt;&lt;/td&gt;
            &lt;td class="shellTopCenter"&gt;&lt;/td&gt;
            &lt;td class="shellTopRight"&gt;&lt;/td&gt;
        &lt;/tr&gt;
        &lt;tr&gt;
            &lt;td class="shellLeft"&gt;&lt;/td&gt;
            &lt;td class="naked"&gt;

               

               








&lt;table width="100%" summary=""&gt;
    &lt;tr&gt;
        &lt;td align="left"&gt;
            &lt;h2 class="history" style="margin-top: 0pt;"&gt;Recent Messages (16) &lt;/h2&gt;
        &lt;/td&gt;
        &lt;td class="historyNavigatorTop" style="vertical-align: top;" align="right"&gt;

       

            &lt;div class="refreshLink"&gt;
            (&lt;a class="history" href="/history?session=A44xUm5oA"&gt;Refresh&lt;/a&gt;)
            &lt;/div&gt;

        &lt;/td&gt;
    &lt;/tr&gt;
    &lt;tr&gt;
        &lt;td colspan="6"&gt;
            &lt;!-- the following html was history-search-filter-widget.thtml --&gt;
           
     
&lt;form action="/history" method="post"&gt;
    &lt;label class="historyLabel" for="historySearch"&gt;
        Search From/Subject:
    &lt;/label&gt;

   

    &lt;input type="text" id="historySearch" name="search" value="" /&gt;

   

    &lt;input type="submit" class="submit" name="setsearch" value="Find" /&gt;
    &amp;nbsp;&amp;nbsp;
    &lt;label class="historyLabel" for="historyFilter"&gt;
        Filter By:
    &lt;/label&gt;
    &lt;input type="hidden" name="sort" value="inserted" /&gt;
    &lt;input type="hidden" name="session" value="A44xUm5oA" /&gt;
    &lt;select name="filter" id="historyFilter"&gt;
        &lt;option value=""&gt;&amp;nbsp;&lt;/option&gt;

       

        &lt;option value="real-mail"  style="color: green"&gt;
            real-mail
        &lt;/option&gt;

       

        &lt;option value="trash"  style="color: red"&gt;
            trash
        &lt;/option&gt;

       

        &lt;option value="__filter__magnet" &gt;
            &amp;lt;magnetized&amp;gt;
        &lt;/option&gt;
        &lt;option value="unclassified" &gt;
            &amp;lt;unclassified&amp;gt;
        &lt;/option&gt;
        &lt;option value="__filter__reclassified" &gt;
            &amp;lt;reclassified&amp;gt;
        &lt;/option&gt;
    &lt;/select&gt;
    &lt;input type="submit" class="submit" name="setfilter" value="Filter" /&gt;
    &lt;input type="hidden" name="negate" value="" /&gt;
    &lt;input type="checkbox" name="negate" id="negate" class="checkbox"  /&gt;
    &lt;label class="historyLabel" for="negate"&gt;
        Invert search/filter
    &lt;/label&gt;
    &lt;input type="submit" class="submit" name="reset_filter_search" value="Reset" /&gt;
&lt;/form&gt;


            &lt;!-- end of history-search-filter-widget.thtml content --&gt;
        &lt;/td&gt;
    &lt;/tr&gt;
&lt;/table&gt;
&lt;br /&gt;
&lt;form action="/history" method="post" class="historyForm" name="historyForm"&gt;
    &lt;input type="hidden" name="search" value="" /&gt;
    &lt;input type="hidden" name="sort" value="inserted" /&gt;
    &lt;input type="hidden" name="negate" value="" /&gt;
    &lt;input type="hidden" name="session" value="A44xUm5oA" /&gt;
    &lt;input type="hidden" name="start_message" value="0" /&gt;
    &lt;input type="hidden" name="filter" value="" /&gt;

    &lt;input type="submit" class="submit removeButton" name="clearchecked" value="Remove Checked" /&gt;
    &lt;input type="submit" class="submit removeButton" name="clearpage" value="Remove Page" /&gt;
    &lt;input type="submit" class="submit removeButton" name="clearall" value="Remove All (16)" /&gt;

    &lt;table class="historyTable" width="100%" summary="This table shows the sender and subject of recently received messages and allows them to be reviewed and reclassified.  Clicking on the subject line will show the full message text, along with information about why it was classified as it was.  The 'Should be' column allows you to specify which bucket the message belongs in, or to undo that change.  The 'Delete' column allows you to delete specific messages from the history if you don't need them anymore."&gt;
        &lt;tr class="rowHeader"&gt;
            &lt;th id="removeChecks" scope="col" align="left"&gt;&lt;/th&gt;

           

            &lt;th class="historyLabel" scope="col" align="left"&gt;
                &lt;a href="/history?session=A44xUm5oA&amp;amp;setsort=-inserted"&gt;

                   

                    &lt;em class="historyLabelSort"&gt;

                       

                        &amp;gt;&amp;nbsp;Arrived

                       

                    &lt;/em&gt;

                   

                &lt;/a&gt;
            &lt;/th&gt;

           

            &lt;th class="historyLabel" scope="col" align="left"&gt;
                &lt;a href="/history?session=A44xUm5oA&amp;amp;setsort=from"&gt;

                   

                    From

                   

                &lt;/a&gt;
            &lt;/th&gt;

           

            &lt;th class="historyLabel" scope="col" align="left"&gt;
                &lt;a href="/history?session=A44xUm5oA&amp;amp;setsort=to"&gt;

                   

                    To

                   

                &lt;/a&gt;
            &lt;/th&gt;

           

            &lt;th class="historyLabel" scope="col" align="left"&gt;
                &lt;a href="/history?session=A44xUm5oA&amp;amp;setsort=subject"&gt;

                   

                    Subject

                   

                &lt;/a&gt;
            &lt;/th&gt;

           

            &lt;th class="historyLabel" scope="col" align="left"&gt;
                &lt;a href="/history?session=A44xUm5oA&amp;amp;setsort=bucket"&gt;

                   

                    Bucket

                   

                &lt;/a&gt;
            &lt;/th&gt;

           

            &lt;td class="historyLabel" scope="col" align="left"&gt;
                &lt;input type="submit" class="submit reclassifyButton" name="change" value="Reclassify" /&gt;
            &lt;/td&gt;
        &lt;/tr&gt;

       

           

           
            &lt;tr class="rowOdd"&gt;
           

            &lt;td&gt;
                &lt;input type="checkbox" id="remove_1715" class="checkbox" name="remove_1715"/&gt;
                &lt;input type="hidden" id="rowid_1715" name="rowid_1715" value="1715"/&gt;
            &lt;/td&gt;
           
            &lt;td&gt;
                &lt;span title="Fri 14:45 "&gt;Fri 14:45 &lt;/span&gt;
            &lt;/td&gt;
           
           
            &lt;td&gt;
                &lt;span title="&amp;quot;The National Lottery&amp;quot; &amp;lt;play@play.national-lottery.co.uk&amp;gt;"&gt;&amp;quot;The National Lottery&amp;quot; &amp;lt;play@play.nation...&lt;/span&gt;
            &lt;/td&gt;
           
           
            &lt;td&gt;
                &lt;span title="keith@keith64.co.uk"&gt;keith@keith64.co.uk&lt;/span&gt;
            &lt;/td&gt;
           
           
           
            &lt;td&gt;
                &lt;a class="messageLink" title="[SPAM] Tonight&amp;#39;s EuroMillions jackpot is ÃÂ£26m*. Grab your ticket now!" href="/view?view=1715&amp;amp;start_message=0&amp;amp;session=A44xUm5oA&amp;amp;sort=inserted"&gt;
                    [SPAM] Tonight&amp;#39;s EuroMillions jackpot is...
                &lt;/a&gt;
            &lt;/td&gt;
           
           
           

           
            &lt;td&gt;

               

               

                &lt;a href="/buckets?session=A44xUm5oA&amp;amp;showbucket=real-mail"&gt;

               

                &lt;span style="color:green"&gt;
                    real-mail
                &lt;/span&gt;

               

                &lt;/a&gt;

               

            &lt;/td&gt;
           
            &lt;td&gt;

               

               

                &lt;select name="reclassify_1715"&gt;
                    &lt;option value="" selected="selected"&gt;&amp;nbsp;&lt;/option&gt;

                   

                    &lt;option value="real-mail" style="color: green"&gt;
                        real-mail
                    &lt;/option&gt;

                   

                    &lt;option value="trash" style="color: red"&gt;
                        trash
                    &lt;/option&gt;

                   

                &lt;/select&gt;

               

               
            &lt;/td&gt;
        &lt;/tr&gt;

       

       

           
            &lt;tr class="rowBoundary"&gt;&lt;td colspan="7"&gt;&lt;/td&gt;&lt;/tr&gt;
           

           
            &lt;tr class="rowEven"&gt;
           

            &lt;td&gt;
                &lt;input type="checkbox" id="remove_1716" class="checkbox" name="remove_1716"/&gt;
                &lt;input type="hidden" id="rowid_1716" name="rowid_1716" value="1716"/&gt;
            &lt;/td&gt;
           
            &lt;td&gt;
                &lt;span title="Fri 15:24 "&gt;Fri 15:24 &lt;/span&gt;
            &lt;/td&gt;
           
           
            &lt;td&gt;
                &lt;span title="&amp;quot;Which?&amp;quot; &amp;lt;info@mail.which.co.uk&amp;gt;"&gt;&amp;quot;Which?&amp;quot; &amp;lt;info@mail.which.co.uk&amp;gt;&lt;/span&gt;
            &lt;/td&gt;
           
           
            &lt;td&gt;
                &lt;span title="&amp;lt;keith@keith64.co.uk&amp;gt;"&gt;&amp;lt;keith@keith64.co.uk&amp;gt;&lt;/span&gt;
            &lt;/td&gt;
           
           
           
            &lt;td&gt;
                &lt;a class="messageLink" title="Your Money weekly update from Which?" href="/view?view=1716&amp;amp;start_message=0&amp;amp;session=A44xUm5oA&amp;amp;sort=inserted"&gt;
                    Your Money weekly update from Which?
                &lt;/a&gt;
            &lt;/td&gt;
           
           
           

           
            &lt;td&gt;

               

               

                &lt;a href="/buckets?session=A44xUm5oA&amp;amp;showbucket=real-mail"&gt;

               

                &lt;span style="color:green"&gt;
                    real-mail
                &lt;/span&gt;

               

                &lt;/a&gt;

               

            &lt;/td&gt;
           
            &lt;td&gt;

               

               

                &lt;select name="reclassify_1716"&gt;
                    &lt;option value="" selected="selected"&gt;&amp;nbsp;&lt;/option&gt;

                   

                    &lt;option value="real-mail" style="color: green"&gt;
                        real-mail
                    &lt;/option&gt;

                   

                    &lt;option value="trash" style="color: red"&gt;
                        trash
                    &lt;/option&gt;

                   

                &lt;/select&gt;

               

               
            &lt;/td&gt;
        &lt;/tr&gt;

       

       

           
            &lt;tr class="rowBoundary"&gt;&lt;td colspan="7"&gt;&lt;/td&gt;&lt;/tr&gt;
           

           
            &lt;tr class="rowOdd"&gt;
           

            &lt;td&gt;
                &lt;input type="checkbox" id="remove_1718" class="checkbox" name="remove_1718"/&gt;
                &lt;input type="hidden" id="rowid_1718" name="rowid_1718" value="1718"/&gt;
            &lt;/td&gt;
           
            &lt;td&gt;
                &lt;span title="Fri 15:41 "&gt;Fri 15:41 &lt;/span&gt;
            &lt;/td&gt;
           
           
            &lt;td&gt;
                &lt;span title="&amp;quot;Team Which? Connect&amp;quot; &amp;lt;noreply@whichconnect.co.uk&amp;gt;"&gt;&amp;quot;Team Which? Connect&amp;quot; &amp;lt;noreply@whichconn...&lt;/span&gt;
            &lt;/td&gt;
           
           
            &lt;td&gt;
                &lt;span title="keith@keith64.co.uk"&gt;keith@keith64.co.uk&lt;/span&gt;
            &lt;/td&gt;
           
           
           
            &lt;td&gt;
                &lt;a class="messageLink" title="Do you ever save, store or preserve fruit &amp;amp; vegetables?" href="/view?view=1718&amp;amp;start_message=0&amp;amp;session=A44xUm5oA&amp;amp;sort=inserted"&gt;
                    Do you ever save, store or preserve frui...
                &lt;/a&gt;
            &lt;/td&gt;
           
           
           

           
            &lt;td&gt;

               

               

                &lt;a href="/buckets?session=A44xUm5oA&amp;amp;showbucket=real-mail"&gt;

               

                &lt;span style="color:green"&gt;
                    real-mail
                &lt;/span&gt;

               

                &lt;/a&gt;

               

            &lt;/td&gt;
           
            &lt;td&gt;

               

               

                &lt;select name="reclassify_1718"&gt;
                    &lt;option value="" selected="selected"&gt;&amp;nbsp;&lt;/option&gt;

                   

                    &lt;option value="real-mail" style="color: green"&gt;
                        real-mail
                    &lt;/option&gt;

                   

                    &lt;option value="trash" style="color: red"&gt;
                        trash
                    &lt;/option&gt;

                   

                &lt;/select&gt;

               

               
            &lt;/td&gt;
        &lt;/tr&gt;

       

       

           
            &lt;tr class="rowBoundary"&gt;&lt;td colspan="7"&gt;&lt;/td&gt;&lt;/tr&gt;
           

           
            &lt;tr class="rowEven"&gt;
           

            &lt;td&gt;
                &lt;input type="checkbox" id="remove_1723" class="checkbox" name="remove_1723"/&gt;
                &lt;input type="hidden" id="rowid_1723" name="rowid_1723" value="1723"/&gt;
            &lt;/td&gt;
           
            &lt;td&gt;
                &lt;span title="Fri 16:14 "&gt;Fri 16:14 &lt;/span&gt;
            &lt;/td&gt;
           
           
            &lt;td&gt;
                &lt;span title="Windows and Office &amp;lt;newsletters@techrepublic.online.com&amp;gt;"&gt;Windows and Office &amp;lt;newsletters@techrepu...&lt;/span&gt;
            &lt;/td&gt;
           
           
            &lt;td&gt;
                &lt;span title="keith@keith64.co.uk"&gt;keith@keith64.co.uk&lt;/span&gt;
            &lt;/td&gt;
           
           
           
            &lt;td&gt;
                &lt;a class="messageLink" title="[TechRepublic] How Windows 8 Hybrid Shutdown / Fast Boot feature works" href="/view?view=1723&amp;amp;start_message=0&amp;amp;session=A44xUm5oA&amp;amp;sort=inserted"&gt;
                    [TechRepublic] How Windows 8 Hybrid Shut...
                &lt;/a&gt;
            &lt;/td&gt;
           
           
           

           
            &lt;td&gt;

               

               

                &lt;a href="/buckets?session=A44xUm5oA&amp;amp;showbucket=real-mail"&gt;

               

                &lt;span style="color:green"&gt;
                    real-mail
                &lt;/span&gt;

               

                &lt;/a&gt;

               

            &lt;/td&gt;
           
            &lt;td&gt;

               

               

                &lt;select name="reclassify_1723"&gt;
                    &lt;option value="" selected="selected"&gt;&amp;nbsp;&lt;/option&gt;

                   

                    &lt;option value="real-mail" style="color: green"&gt;
                        real-mail
                    &lt;/option&gt;

                   

                    &lt;option value="trash" style="color: red"&gt;
                        trash
                    &lt;/option&gt;

                   

                &lt;/select&gt;

               

               
            &lt;/td&gt;
        &lt;/tr&gt;

       

       

           
            &lt;tr class="rowBoundary"&gt;&lt;td colspan="7"&gt;&lt;/td&gt;&lt;/tr&gt;
           

           
            &lt;tr class="rowOdd"&gt;
           

            &lt;td&gt;
                &lt;input type="checkbox" id="remove_1734" class="checkbox" name="remove_1734"/&gt;
                &lt;input type="hidden" id="rowid_1734" name="rowid_1734" value="1734"/&gt;
            &lt;/td&gt;
           
            &lt;td&gt;
                &lt;span title="Fri 19:02 "&gt;Fri 19:02 &lt;/span&gt;
            &lt;/td&gt;
           
           
            &lt;td&gt;
                &lt;span title="Zen Customer Services &amp;lt;customerservices@zen.co.uk&amp;gt;"&gt;Zen Customer Services &amp;lt;customerservices@...&lt;/span&gt;
            &lt;/td&gt;
           
           
            &lt;td&gt;
                &lt;span title="keith@keith64.co.uk"&gt;keith@keith64.co.uk&lt;/span&gt;
            &lt;/td&gt;
           
           
           
            &lt;td&gt;
                &lt;a class="messageLink" title="Broadband Usage Alert - 50.02% Used - 0.096923000" href="/view?view=1734&amp;amp;start_message=0&amp;amp;session=A44xUm5oA&amp;amp;sort=inserted"&gt;
                    Broadband Usage Alert - 50.02% Used - 02...
                &lt;/a&gt;
            &lt;/td&gt;
           
           
           

           
            &lt;td&gt;

               

               

                &lt;a href="/buckets?session=A44xUm5oA&amp;amp;showbucket=real-mail"&gt;

               

                &lt;span style="color:green"&gt;
                    real-mail
                &lt;/span&gt;

               

                &lt;/a&gt;

               

            &lt;/td&gt;
           
            &lt;td&gt;

               

               

                &lt;select name="reclassify_1734"&gt;
                    &lt;option value="" selected="selected"&gt;&amp;nbsp;&lt;/option&gt;

                   

                    &lt;option value="real-mail" style="color: green"&gt;
                        real-mail
                    &lt;/option&gt;

                   

                    &lt;option value="trash" style="color: red"&gt;
                        trash
                    &lt;/option&gt;

                   

                &lt;/select&gt;

               

               
            &lt;/td&gt;
        &lt;/tr&gt;

       

       

           
            &lt;tr class="rowBoundary"&gt;&lt;td colspan="7"&gt;&lt;/td&gt;&lt;/tr&gt;
           

           
            &lt;tr class="rowEven"&gt;
           

            &lt;td&gt;
                &lt;input type="checkbox" id="remove_1762" class="checkbox" name="remove_1762"/&gt;
                &lt;input type="hidden" id="rowid_1762" name="rowid_1762" value="1762"/&gt;
            &lt;/td&gt;
           
            &lt;td&gt;
                &lt;span title="Sat 09:36 "&gt;Sat 09:36 &lt;/span&gt;
            &lt;/td&gt;
           
           
            &lt;td&gt;
                &lt;span title="&amp;quot;Snapfish UK&amp;quot; &amp;lt;snapfish@info.snapfish.com&amp;gt;"&gt;&amp;quot;Snapfish UK&amp;quot; &amp;lt;snapfish@info.snapfish.co...&lt;/span&gt;
            &lt;/td&gt;
           
           
            &lt;td&gt;
                &lt;span title="keith@keith64.co.uk"&gt;keith@keith64.co.uk&lt;/span&gt;
            &lt;/td&gt;
           
           
           
            &lt;td&gt;
                &lt;a class="messageLink" title="Super Savings - up to ÃÂ£20 off your next order!" href="/view?view=1762&amp;amp;start_message=0&amp;amp;session=A44xUm5oA&amp;amp;sort=inserted"&gt;
                    Super Savings - up to ÃÂ£20 off your next...
                &lt;/a&gt;
            &lt;/td&gt;
           
           
           

           
            &lt;td&gt;

               

               

                &lt;a href="/buckets?session=A44xUm5oA&amp;amp;showbucket=real-mail"&gt;

               

                &lt;span style="color:green"&gt;
                    real-mail
                &lt;/span&gt;

               

                &lt;/a&gt;

               

            &lt;/td&gt;
           
            &lt;td&gt;

               

               

                &lt;select name="reclassify_1762"&gt;
                    &lt;option value="" selected="selected"&gt;&amp;nbsp;&lt;/option&gt;

                   

                    &lt;option value="real-mail" style="color: green"&gt;
                        real-mail
                    &lt;/option&gt;

                   

                    &lt;option value="trash" style="color: red"&gt;
                        trash
                    &lt;/option&gt;

                   

                &lt;/select&gt;

               

               
            &lt;/td&gt;
        &lt;/tr&gt;

       

       

           
            &lt;tr class="rowBoundary"&gt;&lt;td colspan="7"&gt;&lt;/td&gt;&lt;/tr&gt;
           

           
            &lt;tr class="rowOdd"&gt;
           

            &lt;td&gt;
                &lt;input type="checkbox" id="remove_1767" class="checkbox" name="remove_1767"/&gt;
                &lt;input type="hidden" id="rowid_1767" name="rowid_1767" value="1767"/&gt;
            &lt;/td&gt;
           
            &lt;td&gt;
                &lt;span title="Sat 11:18 "&gt;Sat 11:18 &lt;/span&gt;
            &lt;/td&gt;
           
           
            &lt;td&gt;
                &lt;span title="&amp;quot;Team Which? Connect&amp;quot; &amp;lt;noreply@whichconnect.co.uk&amp;gt;"&gt;&amp;quot;Team Which? Connect&amp;quot; &amp;lt;noreply@whichconn...&lt;/span&gt;
            &lt;/td&gt;
           
           
            &lt;td&gt;
                &lt;span title="keith@keith64.co.uk"&gt;keith@keith64.co.uk&lt;/span&gt;
            &lt;/td&gt;
           
           
           
            &lt;td&gt;
                &lt;a class="messageLink" title="Help Which? develop itÃ¢ÂÂs research and testing programme" href="/view?view=1767&amp;amp;start_message=0&amp;amp;session=A44xUm5oA&amp;amp;sort=inserted"&gt;
                    Help Which? develop itÃ¢ÂÂs research and ...
                &lt;/a&gt;
            &lt;/td&gt;
           
           
           

           
            &lt;td&gt;

               

               

                &lt;a href="/buckets?session=A44xUm5oA&amp;amp;showbucket=real-mail"&gt;

               

                &lt;span style="color:green"&gt;
                    real-mail
                &lt;/span&gt;

               

                &lt;/a&gt;

               

            &lt;/td&gt;
           
            &lt;td&gt;

               

               

                &lt;select name="reclassify_1767"&gt;
                    &lt;option value="" selected="selected"&gt;&amp;nbsp;&lt;/option&gt;

                   

                    &lt;option value="real-mail" style="color: green"&gt;
                        real-mail
                    &lt;/option&gt;

                   

                    &lt;option value="trash" style="color: red"&gt;
                        trash
                    &lt;/option&gt;

                   

                &lt;/select&gt;

               

               
            &lt;/td&gt;
        &lt;/tr&gt;

       

       

           
            &lt;tr class="rowBoundary"&gt;&lt;td colspan="7"&gt;&lt;/td&gt;&lt;/tr&gt;
           

           
            &lt;tr class="rowEven"&gt;
           

            &lt;td&gt;
                &lt;input type="checkbox" id="remove_1769" class="checkbox" name="remove_1769"/&gt;
                &lt;input type="hidden" id="rowid_1769" name="rowid_1769" value="1769"/&gt;
            &lt;/td&gt;
           
            &lt;td&gt;
                &lt;span title="Sat 22:34 "&gt;Sat 22:34 &lt;/span&gt;
            &lt;/td&gt;
           
           
            &lt;td&gt;
                &lt;span title="VA Loans &amp;lt;VALoans@opendoorseven.me&amp;gt;"&gt;VA Loans &amp;lt;VALoans@opendoorseven.me&amp;gt;&lt;/span&gt;
            &lt;/td&gt;
           
           
            &lt;td&gt;
                &lt;span title="zoom@keith64.co.uk"&gt;zoom@keith64.co.uk&lt;/span&gt;
            &lt;/td&gt;
           
           
           
            &lt;td&gt;
                &lt;a class="messageLink" title="Match with approved VA loan lenders" href="/view?view=1769&amp;amp;start_message=0&amp;amp;session=A44xUm5oA&amp;amp;sort=inserted"&gt;
                    Match with approved VA loan lenders
                &lt;/a&gt;
            &lt;/td&gt;
           
           
           

           
            &lt;td&gt;

               


               

               

                &lt;a href="/buckets?session=A44xUm5oA&amp;amp;showbucket=trash"&gt;

               

                &lt;span style="color:red"&gt;
                    trash
                &lt;/span&gt;

               

                &lt;/a&gt;

               

            &lt;/td&gt;
           
            &lt;td&gt;

               

               
                    &lt;div class="historyMagnetUsed"&gt;
                         &lt;img title="zoom@keith64.co.uk" alt="zoom@keith64.co.uk" src="/skins/default/magnet.png"&gt;
                         &lt;span&gt;Magnet used&lt;/span&gt;
                    &lt;/div&gt;
               

               
            &lt;/td&gt;
        &lt;/tr&gt;

       

       

           
            &lt;tr class="rowBoundary"&gt;&lt;td colspan="7"&gt;&lt;/td&gt;&lt;/tr&gt;
           

           
            &lt;tr class="rowOdd"&gt;
           

            &lt;td&gt;
                &lt;input type="checkbox" id="remove_1770" class="checkbox" name="remove_1770"/&gt;
                &lt;input type="hidden" id="rowid_1770" name="rowid_1770" value="1770"/&gt;
            &lt;/td&gt;
           
            &lt;td&gt;
                &lt;span title="Sun 04:40 "&gt;Sun 04:40 &lt;/span&gt;
            &lt;/td&gt;
           
           
            &lt;td&gt;
                &lt;span title="&amp;quot;John Hatcher&amp;quot; &amp;lt;johnhatcher@btinternet.com&amp;gt;"&gt;&amp;quot;John Hatcher&amp;quot; &amp;lt;johnhatcher@btinternet.c...&lt;/span&gt;
            &lt;/td&gt;
           
           
            &lt;td&gt;
                &lt;span title="&amp;quot;Keith Ward&amp;quot; &amp;lt;keith@keith64.co.uk&amp;gt;"&gt;&amp;quot;Keith Ward&amp;quot; &amp;lt;keith@keith64.co.uk&amp;gt;&lt;/span&gt;
            &lt;/td&gt;
           
           
           
            &lt;td&gt;
                &lt;a class="messageLink" title="Re: USB drives" href="/view?view=1770&amp;amp;start_message=0&amp;amp;session=A44xUm5oA&amp;amp;sort=inserted"&gt;
                    Re: USB drives
                &lt;/a&gt;
            &lt;/td&gt;
           
           
           

           
            &lt;td&gt;

               

               

                &lt;a href="/buckets?session=A44xUm5oA&amp;amp;showbucket=real-mail"&gt;

               

                &lt;span style="color:green"&gt;
                    real-mail
                &lt;/span&gt;

               

                &lt;/a&gt;

               

            &lt;/td&gt;
           
            &lt;td&gt;

               

               

                &lt;select name="reclassify_1770"&gt;
                    &lt;option value="" selected="selected"&gt;&amp;nbsp;&lt;/option&gt;

                   

                    &lt;option value="real-mail" style="color: green"&gt;
                        real-mail
                    &lt;/option&gt;

                   

                    &lt;option value="trash" style="color: red"&gt;
                        trash
                    &lt;/option&gt;

                   

                &lt;/select&gt;

               

               
            &lt;/td&gt;
        &lt;/tr&gt;

       

       

           
            &lt;tr class="rowBoundary"&gt;&lt;td colspan="7"&gt;&lt;/td&gt;&lt;/tr&gt;
           

           
            &lt;tr class="rowEven"&gt;
           

            &lt;td&gt;
                &lt;input type="checkbox" id="remove_1771" class="checkbox" name="remove_1771"/&gt;
                &lt;input type="hidden" id="rowid_1771" name="rowid_1771" value="1771"/&gt;
            &lt;/td&gt;
           
            &lt;td&gt;
                &lt;span title="Sun 05:01 "&gt;Sun 05:01 &lt;/span&gt;
            &lt;/td&gt;
           
           
            &lt;td&gt;
                &lt;span title="Eudora-Win Digest &amp;lt;eudora-win-commands@hades.listmoms.net&amp;gt;"&gt;Eudora-Win Digest &amp;lt;eudora-win-commands@h...&lt;/span&gt;
            &lt;/td&gt;
           
           
            &lt;td&gt;
                &lt;span title="Eudora-Win Digest Recipients &amp;lt;eudora-win@hades.listmoms.net&amp;gt;"&gt;Eudora-Win Digest Recipients &amp;lt;eudora-win...&lt;/span&gt;
            &lt;/td&gt;
           
           
           
            &lt;td&gt;
                &lt;a class="messageLink" title="Eudora-Win Digest for Sat 26 Oct 2013" href="/view?view=1771&amp;amp;start_message=0&amp;amp;session=A44xUm5oA&amp;amp;sort=inserted"&gt;
                    Eudora-Win Digest for Sat 26 Oct 2013
                &lt;/a&gt;
            &lt;/td&gt;
           
           
           

           
            &lt;td&gt;

               

               

                &lt;a href="/buckets?session=A44xUm5oA&amp;amp;showbucket=real-mail"&gt;

               

                &lt;span style="color:green"&gt;
                    real-mail
                &lt;/span&gt;

               

                &lt;/a&gt;

               

            &lt;/td&gt;
           
            &lt;td&gt;

               

               

                &lt;select name="reclassify_1771"&gt;
                    &lt;option value="" selected="selected"&gt;&amp;nbsp;&lt;/option&gt;

                   

                    &lt;option value="real-mail" style="color: green"&gt;
                        real-mail
                    &lt;/option&gt;

                   

                    &lt;option value="trash" style="color: red"&gt;
                        trash
                    &lt;/option&gt;

                   

                &lt;/select&gt;

               

               
            &lt;/td&gt;
        &lt;/tr&gt;

       

       

           

           
            &lt;tr class="rowOdd"&gt;
           

            &lt;td&gt;
                &lt;input type="checkbox" id="remove_1772" class="checkbox" name="remove_1772"/&gt;
                &lt;input type="hidden" id="rowid_1772" name="rowid_1772" value="1772"/&gt;
            &lt;/td&gt;
           
            &lt;td&gt;
                &lt;span title="Sun 05:01 "&gt;Sun 05:01 &lt;/span&gt;
            &lt;/td&gt;
           
           
            &lt;td&gt;
                &lt;span title="Photoshop Digest &amp;lt;photoshop-commands@hades.listmoms.net&amp;gt;"&gt;Photoshop Digest &amp;lt;photoshop-commands@had...&lt;/span&gt;
            &lt;/td&gt;
           
           
            &lt;td&gt;
                &lt;span title="Photoshop Digest Recipients &amp;lt;photoshop@hades.listmoms.net&amp;gt;"&gt;Photoshop Digest Recipients &amp;lt;photoshop@h...&lt;/span&gt;
            &lt;/td&gt;
           
           
           
            &lt;td&gt;
                &lt;a class="messageLink" title="No Photoshop Digest for Sat 26 Oct 2013" href="/view?view=1772&amp;amp;start_message=0&amp;amp;session=A44xUm5oA&amp;amp;sort=inserted"&gt;
                    No Photoshop Digest for Sat 26 Oct 2013
                &lt;/a&gt;
            &lt;/td&gt;
           
           
           

           
            &lt;td&gt;

               

               

                &lt;a href="/buckets?session=A44xUm5oA&amp;amp;showbucket=real-mail"&gt;

               

                &lt;span style="color:green"&gt;
                    real-mail
                &lt;/span&gt;

               

                &lt;/a&gt;

               

            &lt;/td&gt;
           
            &lt;td&gt;

               

               

                &lt;select name="reclassify_1772"&gt;
                    &lt;option value="" selected="selected"&gt;&amp;nbsp;&lt;/option&gt;

                   

                    &lt;option value="real-mail" style="color: green"&gt;
                        real-mail
                    &lt;/option&gt;

                   

                    &lt;option value="trash" style="color: red"&gt;
                        trash
                    &lt;/option&gt;

                   

                &lt;/select&gt;

               

               
            &lt;/td&gt;
        &lt;/tr&gt;

       

       

           
            &lt;tr class="rowBoundary"&gt;&lt;td colspan="7"&gt;&lt;/td&gt;&lt;/tr&gt;
           

           
            &lt;tr class="rowEven"&gt;
           

            &lt;td&gt;
                &lt;input type="checkbox" id="remove_1773" class="checkbox" name="remove_1773"/&gt;
                &lt;input type="hidden" id="rowid_1773" name="rowid_1773" value="1773"/&gt;
            &lt;/td&gt;
           
            &lt;td&gt;
                &lt;span title="Sun 06:46 "&gt;Sun 06:46 &lt;/span&gt;
            &lt;/td&gt;
           
           
            &lt;td&gt;
                &lt;span title="&amp;quot;day2dayshop.com&amp;quot; &amp;lt;info@news.day2dayshop.com&amp;gt;"&gt;&amp;quot;day2dayshop.com&amp;quot; &amp;lt;info@news.day2dayshop...&lt;/span&gt;
            &lt;/td&gt;
           
           
            &lt;td&gt;
                &lt;span title="&amp;lt;keith@keith64.co.uk&amp;gt;"&gt;&amp;lt;keith@keith64.co.uk&amp;gt;&lt;/span&gt;
            &lt;/td&gt;
           
           
           
            &lt;td&gt;
                &lt;a class="messageLink" title="Slimline Bluetooth Handsfree Kit simply perfect for car, home and even office conference calls" href="/view?view=1773&amp;amp;start_message=0&amp;amp;session=A44xUm5oA&amp;amp;sort=inserted"&gt;
                    Slimline Bluetooth Handsfree Kit simply ...
                &lt;/a&gt;
            &lt;/td&gt;
           
           
           

           
            &lt;td&gt;

               

               

                &lt;a href="/buckets?session=A44xUm5oA&amp;amp;showbucket=real-mail"&gt;

               

                &lt;span style="color:green"&gt;
                    real-mail
                &lt;/span&gt;

               

                &lt;/a&gt;

               

            &lt;/td&gt;
           
            &lt;td&gt;

               

               

                &lt;select name="reclassify_1773"&gt;
                    &lt;option value="" selected="selected"&gt;&amp;nbsp;&lt;/option&gt;

                   

                    &lt;option value="real-mail" style="color: green"&gt;
                        real-mail
                    &lt;/option&gt;

                   

                    &lt;option value="trash" style="color: red"&gt;
                        trash
                    &lt;/option&gt;

                   

                &lt;/select&gt;

               

               
            &lt;/td&gt;
        &lt;/tr&gt;

       

       

           
            &lt;tr class="rowBoundary"&gt;&lt;td colspan="7"&gt;&lt;/td&gt;&lt;/tr&gt;
           

           
            &lt;tr class="rowOdd"&gt;
           

            &lt;td&gt;
                &lt;input type="checkbox" id="remove_1774" class="checkbox" name="remove_1774"/&gt;
                &lt;input type="hidden" id="rowid_1774" name="rowid_1774" value="1774"/&gt;
            &lt;/td&gt;
           
            &lt;td&gt;
                &lt;span title="Sun 09:01 "&gt;Sun 09:01 &lt;/span&gt;
            &lt;/td&gt;
           
           
            &lt;td&gt;
                &lt;span title="Thompson &amp;amp; Morgan &amp;lt;newsletter@email.thompson-morgan.com&amp;gt;"&gt;Thompson &amp;amp; Morgan &amp;lt;newsletter@email.thom...&lt;/span&gt;
            &lt;/td&gt;
           
           
            &lt;td&gt;
                &lt;span title="keith@keith64.co.uk"&gt;keith@keith64.co.uk&lt;/span&gt;
            &lt;/td&gt;
           
           
           
            &lt;td&gt;
                &lt;a class="messageLink" title="Don&amp;#39;t forget, your vouchers expire at midnight tonight!" href="/view?view=1774&amp;amp;start_message=0&amp;amp;session=A44xUm5oA&amp;amp;sort=inserted"&gt;
                    Don&amp;#39;t forget, your vouchers expire at mi...
                &lt;/a&gt;
            &lt;/td&gt;
           
           
           

           
            &lt;td&gt;

               

               

                &lt;a href="/buckets?session=A44xUm5oA&amp;amp;showbucket=trash"&gt;

               

                &lt;span style="color:red"&gt;
                    trash
                &lt;/span&gt;

               

                &lt;/a&gt;

               

            &lt;/td&gt;
           
            &lt;td&gt;

               

               

                &lt;select name="reclassify_1774"&gt;
                    &lt;option value="" selected="selected"&gt;&amp;nbsp;&lt;/option&gt;

                   

                    &lt;option value="real-mail" style="color: green"&gt;
                        real-mail
                    &lt;/option&gt;

                   

                    &lt;option value="trash" style="color: red"&gt;
                        trash
                    &lt;/option&gt;

                   

                &lt;/select&gt;

               

               
            &lt;/td&gt;
        &lt;/tr&gt;

       

       

           
            &lt;tr class="rowBoundary"&gt;&lt;td colspan="7"&gt;&lt;/td&gt;&lt;/tr&gt;
           

           
            &lt;tr class="rowEven"&gt;
           

            &lt;td&gt;
                &lt;input type="checkbox" id="remove_1775" class="checkbox" name="remove_1775"/&gt;
                &lt;input type="hidden" id="rowid_1775" name="rowid_1775" value="1775"/&gt;
            &lt;/td&gt;
           
            &lt;td&gt;
                &lt;span title="Sun 09:13 "&gt;Sun 09:13 &lt;/span&gt;
            &lt;/td&gt;
           
           
            &lt;td&gt;
                &lt;span title="&amp;quot;Booking.com&amp;quot; &amp;lt;email.campaign@sg.booking.com&amp;gt;"&gt;&amp;quot;Booking.com&amp;quot; &amp;lt;email.campaign@sg.booking...&lt;/span&gt;
            &lt;/td&gt;
           
           
            &lt;td&gt;
                &lt;span title="keith@keith64.co.uk"&gt;keith@keith64.co.uk&lt;/span&gt;
            &lt;/td&gt;
           
           
           
            &lt;td&gt;
                &lt;a class="messageLink" title="[SPAM] Ã¢ÂÂŒ Last-minute deals for London and Paris. Get  them before they&amp;#39;re gone!" href="/view?view=1775&amp;amp;start_message=0&amp;amp;session=A44xUm5oA&amp;amp;sort=inserted"&gt;
                    [SPAM] Ã¢ÂÂŒ Last-minute deals for London ...
                &lt;/a&gt;
            &lt;/td&gt;
           
           
           

           
            &lt;td&gt;

               

               

                &lt;a href="/buckets?session=A44xUm5oA&amp;amp;showbucket=trash"&gt;

               

                &lt;span style="color:red"&gt;
                    trash
                &lt;/span&gt;

               

                &lt;/a&gt;

               

            &lt;/td&gt;
           
            &lt;td&gt;

               

               

                &lt;select name="reclassify_1775"&gt;
                    &lt;option value="" selected="selected"&gt;&amp;nbsp;&lt;/option&gt;

                   

                    &lt;option value="real-mail" style="color: green"&gt;
                        real-mail
                    &lt;/option&gt;

                   

                    &lt;option value="trash" style="color: red"&gt;
                        trash
                    &lt;/option&gt;

                   

                &lt;/select&gt;

               

               
            &lt;/td&gt;
        &lt;/tr&gt;

       

       

           
            &lt;tr class="rowBoundary"&gt;&lt;td colspan="7"&gt;&lt;/td&gt;&lt;/tr&gt;
           

           
            &lt;tr class="rowOdd"&gt;
           

            &lt;td&gt;
                &lt;input type="checkbox" id="remove_1776" class="checkbox" name="remove_1776"/&gt;
                &lt;input type="hidden" id="rowid_1776" name="rowid_1776" value="1776"/&gt;
            &lt;/td&gt;
           
            &lt;td&gt;
                &lt;span title="Sun 09:40 "&gt;Sun 09:40 &lt;/span&gt;
            &lt;/td&gt;
           
           
            &lt;td&gt;
                &lt;span title="rentalcars.com &amp;lt;email@email.sg.rentalcars.com&amp;gt;"&gt;rentalcars.com &amp;lt;email@email.sg.rentalcar...&lt;/span&gt;
            &lt;/td&gt;
           
           
            &lt;td&gt;
                &lt;span title="keith@keith64.co.uk"&gt;keith@keith64.co.uk&lt;/span&gt;
            &lt;/td&gt;
           
           
           
            &lt;td&gt;
                &lt;a class="messageLink" title="DonÃ¢ÂÂt miss out Ã¢ÂÂ only 4 days left to book with your Low Deposit Offer." href="/view?view=1776&amp;amp;start_message=0&amp;amp;session=A44xUm5oA&amp;amp;sort=inserted"&gt;
                    DonÃ¢ÂÂt miss out Ã¢ÂÂ only 4 days left to...
                &lt;/a&gt;
            &lt;/td&gt;
           
           
           

           
            &lt;td&gt;

               

               

                &lt;a href="/buckets?session=A44xUm5oA&amp;amp;showbucket=trash"&gt;

               

                &lt;span style="color:red"&gt;
                    trash
                &lt;/span&gt;

               

                &lt;/a&gt;

               

            &lt;/td&gt;
           
            &lt;td&gt;

               

               

                &lt;select name="reclassify_1776"&gt;
                    &lt;option value="" selected="selected"&gt;&amp;nbsp;&lt;/option&gt;

                   

                    &lt;option value="real-mail" style="color: green"&gt;
                        real-mail
                    &lt;/option&gt;

                   

                    &lt;option value="trash" style="color: red"&gt;
                        trash
                    &lt;/option&gt;

                   

                &lt;/select&gt;

               

               
            &lt;/td&gt;
        &lt;/tr&gt;

       

       

           
            &lt;tr class="rowBoundary"&gt;&lt;td colspan="7"&gt;&lt;/td&gt;&lt;/tr&gt;
           

           
            &lt;tr class="rowEven"&gt;
           

            &lt;td&gt;
                &lt;input type="checkbox" id="remove_1777" class="checkbox" name="remove_1777"/&gt;
                &lt;input type="hidden" id="rowid_1777" name="rowid_1777" value="1777"/&gt;
            &lt;/td&gt;
           
            &lt;td&gt;
                &lt;span title="Sun 10:22 "&gt;Sun 10:22 &lt;/span&gt;
            &lt;/td&gt;
           
           
            &lt;td&gt;
                &lt;span title="&amp;quot;John Lewis&amp;quot; &amp;lt;John_Lewis@em.johnlewis.com&amp;gt;"&gt;&amp;quot;John Lewis&amp;quot; &amp;lt;John_Lewis@em.johnlewis.co...&lt;/span&gt;
            &lt;/td&gt;
           
           
            &lt;td&gt;
                &lt;span title="keith@keith64.co.uk"&gt;keith@keith64.co.uk&lt;/span&gt;
            &lt;/td&gt;
           
           
           
            &lt;td&gt;
                &lt;a class="messageLink" title="Bold and beautiful lighting to illuminate your home, plus our latest designs in tech" href="/view?view=1777&amp;amp;start_message=0&amp;amp;session=A44xUm5oA&amp;amp;sort=inserted"&gt;
                    Bold and beautiful lighting to illuminat...
                &lt;/a&gt;
            &lt;/td&gt;
           
           
           

           
            &lt;td&gt;

               

               

                &lt;a href="/buckets?session=A44xUm5oA&amp;amp;showbucket=real-mail"&gt;

               

                &lt;span style="color:green"&gt;
                    real-mail
                &lt;/span&gt;

               

                &lt;/a&gt;

               

            &lt;/td&gt;
           
            &lt;td&gt;

               

               

                &lt;select name="reclassify_1777"&gt;
                    &lt;option value="" selected="selected"&gt;&amp;nbsp;&lt;/option&gt;

                   

                    &lt;option value="real-mail" style="color: green"&gt;
                        real-mail
                    &lt;/option&gt;

                   

                    &lt;option value="trash" style="color: red"&gt;
                        trash
                    &lt;/option&gt;

                   

                &lt;/select&gt;

               

               
            &lt;/td&gt;
        &lt;/tr&gt;

       

       

        &lt;tr&gt;
            &lt;td colspan="6"&gt;
                &lt;div class="removeButtonsBottom"&gt;
                &lt;input type="submit" class="submit removeButton" name="clearchecked" value="Remove Checked" /&gt;
                &lt;input type="submit" class="submit removeButton" name="clearpage" value="Remove Page" /&gt;
                &lt;input type="submit" class="submit removeButton" name="clearall" value="Remove All (16)" /&gt;
                &lt;/div&gt;
            &lt;/td&gt;
            &lt;td&gt;
                &lt;input type="submit" class="submit reclassifyButton" name="change" value="Reclassify" /&gt;
            &lt;/td&gt;
        &lt;/tr&gt;
        &lt;tr&gt;
            &lt;td colspan="6"&gt;
                &lt;br /&gt;
                &lt;span class="historyLabel"&gt;
                    Change width of From, To, Cc and Subject columns:
                &lt;/span&gt;
                &lt;input type="submit" class="submit" name="increase" value="Increase" /&gt;
                &lt;input type="submit" class="submit" name="decrease" value="Decrease" /&gt;
                &lt;input type="submit" class="submit" name="automatic" value="Automatic" /&gt;
            &lt;/td&gt;
            &lt;td&gt;&lt;/td&gt;
        &lt;/tr&gt;
    &lt;/table&gt;
&lt;/form&gt;



 &lt;!-- if some messages --&gt;

&lt;script type="text/javascript"&gt;
&lt;!--
function OnLoadHandler() {    // redefine default OnLoadHandler
    if (document.getElementById("removeChecks"))
         document.getElementById("removeChecks").innerHTML = "&lt;input type='checkbox' class='checkbox' onclick='javascript:toggleChecks(this);' title='Select All' /&gt;";
}

function toggleChecks(x) {
    var d = document.forms;
    for (var i=0; i &lt; d.length; i++) {
         for (var j=0; j &lt; d[i].elements.length; j++)
              if (d[i].elements[j].name.substr(0,7) == "remove_")
                    d[i].elements[j].checked = x.checked;
    }
    return 0;
}
// --&gt;
&lt;/script&gt;

            &lt;/td&gt;
            &lt;td class="shellRight"&gt;&lt;/td&gt;
        &lt;/tr&gt;
        &lt;tr class="shellBottomRow"&gt;
            &lt;td class="shellBottomLeft"&gt;&lt;/td&gt;
            &lt;td class="shellBottomCenter"&gt;&lt;/td&gt;
            &lt;td class="shellBottomRight"&gt;&lt;/td&gt;
        &lt;/tr&gt;
    &lt;/table&gt;
    &lt;table class="footer" summary=""&gt;
    &lt;tr&gt;
        &lt;td class="footerBody"&gt;
            &lt;a class="bottomLink" href="http://getpopfile.org/"&gt;POPFile Home Page&lt;/a&gt;
            &lt;br /&gt;
            &lt;a class="bottomLink" href="http://getpopfile.org/docs/index.php"&gt;Documentation&lt;/a&gt;
            &lt;br /&gt;
            &lt;a class="bottomLink" href="http://getpopfile.org/docs/FAQ"&gt;FAQ&lt;/a&gt;
            &lt;br /&gt;
        &lt;/td&gt;
        &lt;td class="footerBody"&gt;
            &lt;a class="bottomLink" href="http://getpopfile.org/"&gt;
                &lt;img src="otto.png" border="0" alt="" /&gt;&lt;/a&gt;
            &lt;br /&gt;
            v1.1.3
            &lt;br /&gt;
            (10/27/13 14:47 - )
        &lt;/td&gt;
        &lt;td class="footerBody"&gt;
            &lt;a class="bottomLink" href="http://getpopfile.org/docs/RequestFeature"&gt;Request Feature&lt;/a&gt;
            &lt;br /&gt;
            &lt;a class="bottomLink" href="http://getpopfile.org/docs/mailing_lists"&gt;Mailing List&lt;/a&gt;
            &lt;br /&gt;
            &lt;a class="bottomLink" href="http://getpopfile.org/docs/Donate"&gt;Donate&lt;/a&gt;
        &lt;/td&gt;
    &lt;/tr&gt;
    &lt;/table&gt;
&lt;/body&gt;
&lt;/html&gt;

</text>
                </content>
                <redirectionURL/>
                <headersSize>198</headersSize>
                <bodySize>46208</bodySize>
            </response>
            <cache/>
            <timings>
                <send>0</send>
                <wait>422</wait>
                <receive>15</receive>
            </timings>
        </entry>
        <entry>
            <pageref>0</pageref>
            <startedDateTime>2013-10-27T14:47:53.980+00:00</startedDateTime>
            <time>0</time>
            <request>
                <method>GET</method>
                <url>http://127.0.0.1:8080/skins/simplyblue/style.css</url>
                <httpVersion>HTTP/1.1</httpVersion>
                <cookies/>
                <headers>
                    <header>
                        <name>Accept</name>
                        <value>text/css</value>
                    </header>
                    <header>
                        <name>Referer</name>
                        <value>http://127.0.0.1:8080/history</value>
                    </header>
                    <header>
                        <name>Accept-Language</name>
                        <value>en-GB</value>
                    </header>
                    <header>
                        <name>User-Agent</name>
                        <value>Mozilla/5.0 (compatible; MSIE 10.0; Windows NT 6.1; WOW64; Trident/6.0)</value>
                    </header>
                    <header>
                        <name>Accept-Encoding</name>
                        <value>gzip, deflate</value>
                    </header>
                    <header>
                        <name>Host</name>
                        <value>127.0.0.1:8080</value>
                    </header>
                </headers>
                <queryString/>
                <headersSize>265</headersSize>
                <bodySize>0</bodySize>
            </request>
            <response>
                <status>304</status>
                <statusText>Not Modified</statusText>
                <httpVersion>HTTP/1.1</httpVersion>
                <cookies/>
                <headers>
                    <header>
                        <name>Content-Type</name>
                        <value>text/css</value>
                    </header>
                    <header>
                        <name>Content-Length</name>
                        <value>4638</value>
                    </header>
                    <header>
                        <name>Expires</name>
                        <value>Sun, 27 Oct 2013 15:33:21 GMT</value>
                    </header>
                </headers>
                <content>
                    <size>0</size>
                    <mimeType>text/css</mimeType>
                    <text>/*********************************************************/
/* Main Body */

body {
  color: #000000;
  background-color: #ffffff;
  font-family: sans-serif;
  font-size: 100%;
}

/*********************************************************/
/* General element settings */

hr {
  color: #88b5dd;
  background-color: transparent;
}

a:link {
  color: #000000;
  background-color: transparent;
  text-decoration: underline;
}

a:visited {
  color: #333333;
  background-color: transparent;
  text-decoration: underline;
}

a:hover {
  color: #000000;
  background-color: transparent;
  text-decoration: none;
}

/*********************************************************/
/* Shell structure */

.shell, .shellTop {
  color: #000000;
  background-color: #bcd5ea;
  border: 2px #ffffff groove;
  margin: 0;
}

table.head {
  width: 100%;
}

td.head {
  font-weight: normal;
  font-size: 1.8em;
}

table.footer {
  width: 100%;
}

td.footerBody {
  width:33%;
  text-align: center;
}

td.naked {
  padding: 0;
  margin: 0;
  border: 0;
}

td.logo2menuSpace {
  height: 0.8em;
}

/*********************************************************/
/* Menu Settings */

.menu {
  font-size: 1.2em;
  font-weight: bold;
  width: 100%;
}

.menuSelected {
  color: #000000;
  background-color: #88b5dd;
  width: 14%;
  border-color: #ffffff;
  border-style: groove groove none groove;
  border-width: 2px;
}

.menuStandard {
  color: #000000;
  background-color: #bcd5ea;
  width: 14%;
  border-color: #ffffff;
  border-style: groove groove none groove;
  border-width: 2px;
}

.menuIndent {
  width: 8%;
}

.menuLink {
  display: block;
  width: 100%;
}

/*********************************************************/
/* Table Settings */

table.settingsTable {
  border: 1px solid #88b5dd;
}

td.settingsPanel {
  border: 1px solid #88b5dd;
}

table.openMessageTable {
  border: 3px solid #88b5dd;
}

td.openMessageBody {
  text-align: left;
}

td.openMessageCloser {
  text-align: right;
}

tr.rowEven {
  color: #000000;
  background-color: #bcd5ea;
}

tr.rowOdd {
  color: #000000;
  background-color: #88b5dd;
}

tr.rowHighlighted {
  color: #eeeeee;
  background-color: #29abff;
}

tr.rowBoundary {
  background-color: #88b5dd;
}

table.lookupResultsTable {
  border: 3px solid #88b5dd;
}

/*********************************************************/
/* Graphics */

td.accuracy0to49 {
  background-color: red;
  color: black;
}

td.accuracy50to93 {
  background-color: yellow;
  color: black;
}

td.accuracy94to100 {
  background-color: green;
  color: black;
}

span.graphFont {
  font-size: x-small;
}

/*********************************************************/
/* Messages */

div.error01 {
  background-color: transparent;
  color: red;
  font-size: larger;
}

div.error02 {
  background-color: transparent;
  color: red;
}

div.helpMessage {
  background-color: #88b5dd;
  border: 2px #ffffff groove;
  padding: 0.4em;
}

div.helpMessage form {
  margin: 0;
}

/*********************************************************/
/* Form Labels */

th.historyLabel {
  text-align: left;
  font-weight: bold;
}

th.historyLabel em {
  font-weight: bold;
  font-style: normal;
}

.bucketsLabel {
  font-weight: bold;
}

.magnetsLabel {
  font-weight: bold;
}

.securityLabel {
  font-weight: bold;
}

.configurationLabel {
  font-weight: bold;
}

.advancedLabel {
  font-weight: bold;
}

.passwordLabel {
  font-weight: bold;
}

.sessionLabel {
  font-weight: bold;
}

.bucketsWidgetStateOn, .bucketsWidgetStateOff {
  font-weight: bold;
}

.configWidgetStateOn, .configWidgetStateOff {
  font-weight: bold;
}

.securityWidgetStateOn, .securityWidgetStateOff {
  font-weight: bold;
}

/*********************************************************/
/* Positioning */

table.historyWidgetsTop {
  width: 100%;
  margin-left: 1.5em;
  margin-top: 0.6em;
  margin-bottom: 1.0em;
}

table.historyWidgetsBottom {
  width: 100%;
  margin-top: 0.6em;
}

.historyNavigatorTop, .historyNavigatorBottom {
  text-align: right;
  vertical-align: top;
}

.historyNavigatorTop form, .historyNavigatorBottom form {
  display:inline;
}

.refreshLink {
  margin-top: 0.5em;
}

.magnetsTable caption {
  text-align: left;
}

h2.history, h2.buckets, h2.magnets, h2.users {
  margin-top: 0;
  margin-bottom: 0.3em;
}
.removeButtonsTop {
  padding-bottom: 1em;
}
.viewHeadings {
  display: inline;
}

.historyMagnetUsed {
  overflow: hidden;
  white-space: nowrap;
  vertical-align: middle;
}

.historyMagnetUsed img {
  vertical-align: bottom;
}

.historyMagnetUsed span {
  font-size:80%;
  vertical-align: middle;
}

div.historySearchFilterActive {
  background-color: #88b5dd;
}
</text>
                </content>
                <redirectionURL/>
                <headersSize>105</headersSize>
                <bodySize>0</bodySize>
            </response>
            <cache/>
            <timings>
                <send>0</send>
                <wait>0</wait>
                <receive>0</receive>
            </timings>
        </entry>
        <entry>
            <pageref>0</pageref>
            <startedDateTime>2013-10-27T14:47:53.996+00:00</startedDateTime>
            <time>0</time>
            <request>
                <method>GET</method>
                <url>http://127.0.0.1:8080/skins/default/magnet.png</url>
                <httpVersion>HTTP/1.1</httpVersion>
                <cookies/>
                <headers>
                    <header>
                        <name>Accept</name>
                        <value>image/png, image/svg+xml, image/*;q=0.8, */*;q=0.5</value>
                    </header>
                    <header>
                        <name>Referer</name>
                        <value>http://127.0.0.1:8080/history</value>
                    </header>
                    <header>
                        <name>Accept-Language</name>
                        <value>en-GB</value>
                    </header>
                    <header>
                        <name>User-Agent</name>
                        <value>Mozilla/5.0 (compatible; MSIE 10.0; Windows NT 6.1; WOW64; Trident/6.0)</value>
                    </header>
                    <header>
                        <name>Accept-Encoding</name>
                        <value>gzip, deflate</value>
                    </header>
                    <header>
                        <name>Host</name>
                        <value>127.0.0.1:8080</value>
                    </header>
                </headers>
                <queryString/>
                <headersSize>305</headersSize>
                <bodySize>0</bodySize>
            </request>
            <response>
                <status>304</status>
                <statusText>Not Modified</statusText>
                <httpVersion>HTTP/1.1</httpVersion>
                <cookies/>
                <headers>
                    <header>
                        <name>Content-Type</name>
                        <value>image/png</value>
                    </header>
                    <header>
                        <name>Content-Length</name>
                        <value>322</value>
                    </header>
                    <header>
                        <name>Expires</name>
                        <value>Sun, 27 Oct 2013 15:33:21 GMT</value>
                    </header>
                </headers>
                <content>
                    <size>322</size>
                    <mimeType>image/png</mimeType>
                </content>
                <redirectionURL/>
                <headersSize>105</headersSize>
                <bodySize>0</bodySize>
            </response>
            <cache/>
            <timings>
                <send>0</send>
                <wait>0</wait>
                <receive>0</receive>
            </timings>
        </entry>
        <entry>
            <pageref>0</pageref>
            <startedDateTime>2013-10-27T14:47:53.996+00:00</startedDateTime>
            <time>0</time>
            <request>
                <method>GET</method>
                <url>http://127.0.0.1:8080/otto.png</url>
                <httpVersion>HTTP/1.1</httpVersion>
                <cookies/>
                <headers>
                    <header>
                        <name>Accept</name>
                        <value>image/png, image/svg+xml, image/*;q=0.8, */*;q=0.5</value>
                    </header>
                    <header>
                        <name>Referer</name>
                        <value>http://127.0.0.1:8080/history</value>
                    </header>
                    <header>
                        <name>Accept-Language</name>
                        <value>en-GB</value>
                    </header>
                    <header>
                        <name>User-Agent</name>
                        <value>Mozilla/5.0 (compatible; MSIE 10.0; Windows NT 6.1; WOW64; Trident/6.0)</value>
                    </header>
                    <header>
                        <name>Accept-Encoding</name>
                        <value>gzip, deflate</value>
                    </header>
                    <header>
                        <name>Host</name>
                        <value>127.0.0.1:8080</value>
                    </header>
                </headers>
                <queryString/>
                <headersSize>289</headersSize>
                <bodySize>0</bodySize>
            </request>
            <response>
                <status>304</status>
                <statusText>Not Modified</statusText>
                <httpVersion>HTTP/1.1</httpVersion>
                <cookies/>
                <headers>
                    <header>
                        <name>Content-Type</name>
                        <value>image/png</value>
                    </header>
                    <header>
                        <name>Content-Length</name>
                        <value>509</value>
                    </header>
                    <header>
                        <name>Expires</name>
                        <value>Sun, 27 Oct 2013 15:33:21 GMT</value>
                    </header>
                </headers>
                <content>
                    <size>509</size>
                    <mimeType>image/png</mimeType>
                </content>
                <redirectionURL/>
                <headersSize>105</headersSize>
                <bodySize>0</bodySize>
            </response>
            <cache/>
            <timings>
                <send>0</send>
                <wait>0</wait>
                <receive>0</receive>
            </timings>
        </entry>
    </entries>
</log>
__XML__
ok($har->creator()->name() eq 'Internet Explorer Network Inspector', "Correctly identified Internet Explorer Network Inspector");
$har->xml(<<'__XML__');
<?xml version="1.0" encoding="UTF-8"?>
<log>
	<version>1.1</version>
	<creator>
		<name>Internet Explorer Network Inspector</name>
		<version>9.0.8112.16421</version>
	</creator>
	<browser>
		<name>Internet Explorer</name>
		<version>9.0.8112.16421</version>
	</browser>
	<pages>
		<page>
			<startedDateTime>2012-04-05T22:33:13.499+01:00</startedDateTime>
			<id>0</id>
			<title/>
			<pageTimings>
				<onContentLoad>-1</onContentLoad>
				<onLoad>-1</onLoad>
			</pageTimings>
		</page>
	</pages>
	<entries>
		<entry>
			<pageref>0</pageref>
			<startedDateTime>2012-04-05T22:33:16.619+01:00</startedDateTime>
			<time>3120</time>
			<request>
				<method>GET</method>
				<url>https://apis.live.net/v5.0/me/skydrive/files/testfile8.txt?0=T&amp;1=E&amp;2=S&amp;3=T&amp;method=put&amp;callback=WL.Internal.jsonp.WLAPI_REQ_2_1333665196611&amp;pretty=false&amp;return_ssl_resources=false&amp;access_token=EwAwAq1DBAAUlbRWyAJjK5w968Ru3Cyt%2F6GvwXwAAY%2BHz9VXJCw6Mr%2FyfwjsXsHKYQ22YpAe6SCRE5NmBmoBX7V1%2F4dT1NnqjkYG0Y%2ByXL2N2XAI0x2uq7R8I2nFWVzkGqf8E5h1X8pqePFeaCgmnpKAOpwa5QRl%2BtpFIR9GQkA1uL6Z24zQNzW7WqeUeomDwoxp2E3L0FrImwTL3QeaF8e%2BGm2l12CVu5YrEQivauvn9%2BxTVtgZtwWrvyuKM0yA6nJ7G%2F2V6c%2BU6DWy08ssL4lunNx1XMerqNjqzaYUiw3Sdcomae1%2FCJQM0%2BY71AbKYUbbg5eq0qZMm8KSjJ7kdXRVryKT4oiJv3gCaBQvbjKSUEkIhk2G8FyPgOZlVSIDZgAACOtlQTyJqdUlAAGOj5jnrryZDenla1Syo3D0nsnMvSpamnFy8IGJXpoquAiE5Ut%2BG7d6xi8v7h%2Ft4UP2sXHycgDLqvIvg%2FTlpQl3CpohzYYQyxoDCulpNUvCXbU8x8vKN9cI7nfLkGAmnoHN8%2BvfXMsK6eA1g4GpQDpCt8qstOSmlsOBnekdr%2B8o8rrXp5w4o2izI%2F9N974fe%2FgmYDYfhOmmHANaYsrFDG507v9ZswFxMWigqR6ibDtFMzklTQuXs1HbAk0Sa07xSY%2BnySnjulBMLqMJxnaMRJsp0rd6YNqQVbUeP51XCCgLjgGc3zZDqsCHMKqgRKZd%2FV9%2FoMnaKl%2Ftj36it89J2m1%2FAAA%3D&amp;suppress_redirects=true</url>
				<httpVersion>HTTP/1.1</httpVersion>
				<cookies/>
				<headers>
					<header>
						<name>Accept</name>
						<value>application/javascript, */*;q=0.8</value>
					</header>
					<header>
						<name>Referer</name>
						<value>http://myrandomdomain2222.com:52558/default.htm</value>
					</header>
					<header>
						<name>Accept-Language</name>
						<value>nb-NO</value>
					</header>
					<header>
						<name>User-Agent</name>
						<value>Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; WOW64; Trident/5.0)</value>
					</header>
					<header>
						<name>Accept-Encoding</name>
						<value>gzip, deflate</value>
					</header>
					<header>
						<name>Host</name>
						<value>apis.live.net</value>
					</header>
					<header>
						<name>Connection</name>
						<value>Keep-Alive</value>
					</header>
				</headers>
				<queryString>
					<param>
						<name>0</name>
						<value>T</value>
					</param>
					<param>
						<name>1</name>
						<value>E</value>
					</param>
					<param>
						<name>2</name>
						<value>S</value>
					</param>
					<param>
						<name>3</name>
						<value>T</value>
					</param>
					<param>
						<name>method</name>
						<value>put</value>
					</param>
					<param>
						<name>callback</name>
						<value>WL.Internal.jsonp.WLAPI_REQ_2_1333665196611</value>
					</param>
					<param>
						<name>pretty</name>
						<value>false</value>
					</param>
					<param>
						<name>return_ssl_resources</name>
						<value>false</value>
					</param>
					<param>
						<name>access_token</name>
						<value>EwAwAq1DBAAUlbRWyAJjK5w968Ru3Cyt%2F6GvwXwAAY%2BHz9VXJCw6Mr%2FyfwjsXsHKYQ22YpAe6SCRE5NmBmoBX7V1%2F4dT1NnqjkYG0Y%2ByXL2N2XAI0x2uq7R8I2nFWVzkGqf8E5h1X8pqePFeaCgmnpKAOpwa5QRl%2BtpFIR9GQkA1uL6Z24zQNzW7WqeUeomDwoxp2E3L0FrImwTL3QeaF8e%2BGm2l12CVu5YrEQivauvn9%2BxTVtgZtwWrvyuKM0yA6nJ7G%2F2V6c%2BU6DWy08ssL4lunNx1XMerqNjqzaYUiw3Sdcomae1%2FCJQM0%2BY71AbKYUbbg5eq0qZMm8KSjJ7kdXRVryKT4oiJv3gCaBQvbjKSUEkIhk2G8FyPgOZlVSIDZgAACOtlQTyJqdUlAAGOj5jnrryZDenla1Syo3D0nsnMvSpamnFy8IGJXpoquAiE5Ut%2BG7d6xi8v7h%2Ft4UP2sXHycgDLqvIvg%2FTlpQl3CpohzYYQyxoDCulpNUvCXbU8x8vKN9cI7nfLkGAmnoHN8%2BvfXMsK6eA1g4GpQDpCt8qstOSmlsOBnekdr%2B8o8rrXp5w4o2izI%2F9N974fe%2FgmYDYfhOmmHANaYsrFDG507v9ZswFxMWigqR6ibDtFMzklTQuXs1HbAk0Sa07xSY%2BnySnjulBMLqMJxnaMRJsp0rd6YNqQVbUeP51XCCgLjgGc3zZDqsCHMKqgRKZd%2FV9%2FoMnaKl%2Ftj36it89J2m1%2FAAA%3D</value>
					</param>
					<param>
						<name>suppress_redirects</name>
						<value>true</value>
					</param>
				</queryString>
				<headersSize>1296</headersSize>
				<bodySize>0</bodySize>
			</request>
			<response>
				<status>200</status>
				<statusText>OK</statusText>
				<httpVersion>HTTP/1.1</httpVersion>
				<cookies/>
				<headers>
					<header>
						<name>Cache-Control</name>
						<value>private, no-cache, no-store, must-revalidate</value>
					</header>
					<header>
						<name>Transfer-Encoding</name>
						<value>chunked</value>
					</header>
					<header>
						<name>Content-Type</name>
						<value>text/javascript; charset=UTF-8</value>
					</header>
					<header>
						<name>Location</name>
						<value>https://apis.live.net/v5.0/file.10ffe37c6737f99f.10FFE37C6737F99F!132/</value>
					</header>
					<header>
						<name>Server</name>
						<value>Live-API/16.2.1383.402 Microsoft-HTTPAPI/2.0</value>
					</header>
					<header>
						<name>X-Content-Type-Options</name>
						<value>nosniff</value>
					</header>
					<header>
						<name>X-HTTP-Live-Request-Id</name>
						<value>API.96544311-acec-4e25-a802-6ca28dd56af1</value>
					</header>
					<header>
						<name>X-HTTP-Live-Server</name>
						<value>BAYMSG10.0936</value>
					</header>
					<header>
						<name>Date</name>
						<value>Thu, 05 Apr 2012 22:33:16 GMT</value>
					</header>
				</headers>
				<content>
					<size>297</size>
					<mimeType>text/javascript</mimeType>
					<text>WL.Internal.jsonp.WLAPI_REQ_2_1333665196611({"id":"file.10ffe37c6737f99f.10FFE37C6737F99F!132","source":"http://storage.live.com/s1pSssLIc0cxXpzGXmIe1aYlrynvN_x8dOVB3RWpUktTgvpFI4Lz3wWkStRW2voCk_ByhR8A5EDlz-fGGU-Eh2VyWX6cLm5bFvcjzdHXud5il4xL8pZqR0EUA/testfile8.txt:Binary,Default/testfile8.txt"});</text>
				</content>
				<redirectionURL/>
				<headersSize>461</headersSize>
				<bodySize>297</bodySize>
			</response>
			<cache/>
			<timings>
				<send>1872</send>
				<wait>1248</wait>
				<receive>0</receive>
			</timings>
		</entry>
	</entries>
</log>
__XML__
ok($har->creator()->name() eq 'Internet Explorer Network Inspector', "Correctly identified Internet Explorer Network Inspector");
