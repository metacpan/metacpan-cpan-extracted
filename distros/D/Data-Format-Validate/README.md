# Data::Format::Validate
Data::Format::Validate is a Perl module to validate data

## Instalation

### CPAN

This module is avaliable on CPAN, to install it, just run:

<pre>
  cpan install Data::Format::Validate
</pre>

### Manual

Standard process for building & installing modules:

<pre>
  perl Build.PL
  ./Build
  ./Build test
  ./Build install
</pre>

Or, if you're on a platform (like DOS or Windows) that doesn't require the "./" notation, you can do this:

<pre>
  perl Build.PL
  Build
  Build test
  Build install
</pre>

## Utilities

### E-mail

#### Any E-mail
<pre>
  use Data::Format::Validate::Email 'looks_like_any_email';

  looks_like_any_email 'rozcovo@cpan.org';    # returns 1
  looks_like_any_email 'rozcovo@cpan. org';   # returns 0
</pre>

#### Common E-mail
<pre>
  use Data::Format::Validate::Email 'looks_like_common_email';

  looks_like_common_email 'rozcovo@cpan.org';     # returns 1
  looks_like_common_email 'rozcovo.@cpan.org';    # returns 0
</pre>

### IP

#### IPV4
<pre>
  use Data::Format::Validate::IP 'looks_like_ipv4';

  looks_like_ipv4 '127.0.0.1';    # returns 1
  looks_like_ipv4 '255255255255'; # returns 0
</pre>

#### IPV6
<pre>
  use Data::Format::Validate::IP 'looks_like_ipv6';

  looks_like_ipv6 '1762:0:0:0:0:B03:1:AF18';  # returns 1
  looks_like_ipv6 '17620000AFFFB031AF187';    # returns 0
</pre>

### URL

#### Any URL
<pre>
  use Data::Format::Validate::URL 'looks_like_any_url';

  looks_like_any_url 'duckduckgo.com';    # returns 1
  looks_like_any_url 'www. duckduckgo';   # returns 0
</pre>

#### Only full URL
<pre>
  use Data::Format::Validate::URL 'looks_like_full_url';


  looks_like_full_url 'http://www.duckduckgo.com/search?q=perl';  # returns 1
  looks_like_full_url 'http://duckduckgo.com';                    # returns 0
</pre>

### URN

<pre>
  use Data::Format::Validate::URN 'looks_like_urn';

  looks_like_urn 'urn:oid:2.16.840';          # returns 1
  looks_like_urn 'This is not a valid URN';   # returns 0
</pre>
