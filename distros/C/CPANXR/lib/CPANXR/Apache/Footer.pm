# $Id: Footer.pm,v 1.5 2003/09/28 08:09:31 clajac Exp $

package CPANXR::Apache::Footer;
use strict;

my $footer = q{
<p>
<table border="0" width="730" cellspacing="0" cellpadding="0">
<tr align="right">

<td width="590" valign="middle">
<br>

<div class="FOOTER">

    <a href="/">Perl.org</A> sites
     : <!-- <a href="http://books.perl.org/" title="books.perl.org">books</a>
     | --> <a href="http://rt.perl.org/perlbug/">bugs</a>
     | <a href="http://dev.perl.org/">dev</a>
     | <a href="http://history.perl.org/">history</a>
     | <a href="http://jobs.perl.org/">jobs</a>
     | <a href="http://learn.perl.org/">learn</a>
     | <a href="http://lists.perl.org/">lists</a>
     | <a href="http://use.perl.org/">use</a>
    <br>
  <small>
   &#169; Copyright 2002-2003 <a href="http://www.perlfoundation.org">The&nbsp;Perl&nbsp;Foundation</a><BR>
   <a href="http://www.perl.org/siteinfo.html"
    >Site Information and Contacts</A>
  </small>

<div align="LEFT">

</div>

</div>
</td>
<td valign="middle" align="center">

<img src="/simages/lcamel.gif" alt="the camel">

</td>
</tr>
</table>

</body>
</html>
};

sub footer {
  my ($self, $r) = @_;
 
  $r->print($footer);
}

1;
