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

  looks_like_any_email 'israel.batista@univem.edu.br';    # 1
  looks_like_any_email '!$%@&[.B471374@*")..$$#!+=.-';    # 1

  looks_like_any_email 'israel.batistaunivem.edu.br';     # 0
  looks_like_any_email 'israel. batista@univem.edu.br';   # 0
  looks_like_any_email 'israel.batista@univ em.edu.br';   # 0
</pre>

#### Common E-mail
<pre>
  use Data::Format::Validate::Email 'looks_like_common_email';

  looks_like_common_email 'israel.batista@univem.edu.br';         # 1
  looks_like_common_email 'israel.batista42@univem.edu.br';       # 1

  looks_like_common_email 'israel.@univem.edu.br';                # 0
  looks_like_common_email 'israel.batistaunivem.edu.br';          # 0
  looks_like_common_email '!$%@&[.B471374@*")..$$#!+=.-';         # 0
  looks_like_common_email '!srael.batista@un!vem.edu.br';         # 0
  looks_like_common_email 'i%rael.bati%ta@univem.edu.br';         # 0
  looks_like_common_email 'isra&l.batista@univ&m.&du.br';         # 0
  looks_like_common_email 'israel[batista]@univem.edu.br';        # 0
  looks_like_common_email 'israel. batista@univem.edu.br';        # 0
  looks_like_common_email 'israel.batista@univem. edu.br';        # 0
  looks_like_common_email 'israel.batista@univem..edu.br';        # 0
  looks_like_common_email 'israel..batista@univem.edu.br';        # 0
  looks_like_common_email 'israel.batista@@univem.edu.br';        # 0
  looks_like_common_email 'israel.batista@univem.edu.brasilia';   # 0
</pre>

### IP

#### IPV4
<pre>
  use Data::Format::Validate::IP 'looks_like_ipv4';

  looks_like_ipv4 '127.0.0.1';        # 1
  looks_like_ipv4 '192.168.0.1';      # 1
  looks_like_ipv4 '255.255.255.255';  # 1

  looks_like_ipv4 '255255255255';     # 0
  looks_like_ipv4 '255.255.255.256';  # 0
</pre>

#### IPV6
<pre>
  use Data::Format::Validate::IP 'looks_like_ipv6';

  looks_like_ipv6 '1762:0:0:0:0:B03:1:AF18';                  # 1
  looks_like_ipv6 '1762:ABC:464:4564:0:BA03:1000:AA1F';       # 1
  looks_like_ipv6 '1762:4546:A54f:d6fd:5455:B03:1fda:dFde';   # 1

  looks_like_ipv6 '17620000AFFFB031AF187';                    # 0
  looks_like_ipv6 '1762:0:0:0:0:B03:AF18';                    # 0
  looks_like_ipv6 '1762:0:0:0:0:B03:1:Ag18';                  # 0
  looks_like_ipv6 '1762:0:0:0:0:AFFFB03:1:AF187';             # 0
</pre>

### URL

#### Any URL
<pre>
  use Data::Format::Validate::URL 'looks_like_any_url';

  looks_like_any_url 'duckduckgo.com';                              # 1
  looks_like_any_url 'www.duckduckgo.com';                          # 1
  looks_like_any_url 'ftp.duckduckgo.com';                          # 1
  looks_like_any_url 'http://duckduckgo.com';                       # 1
  looks_like_any_url 'ftp://www.duckduckgo.com';                    # 1
  looks_like_any_url 'https://www.duckduckgo.com';                  # 1
  looks_like_any_url 'https://www.youtube.com/watch?v=tqgBN44orKs'; # 1

  looks_like_any_url '.com';                                        # 0
  looks_like_any_url 'www. duckduckgo';                             # 0
  looks_like_any_url 'this is not an url';                          # 0
  looks_like_any_url 'perl.com is the best website';                # 0
</pre>

#### Only full URL
<pre>
  use Data::Format::Validate::URL 'looks_like_full_url';

  looks_like_full_url 'ftp://www.duckduckgo.com';                 # 1
  looks_like_full_url 'http://www.duckduckgo.com';                # 1
  looks_like_full_url 'https://www.duckduckgo.com';               # 1
  looks_like_full_url 'http://www.duckduckgo.com/search?q=perl';  # 1

  looks_like_full_url 'duckduckgo.com';                           # 0
  looks_like_full_url 'www.duckduckgo.com';                       # 0
  looks_like_full_url 'ftp.duckduckgo.com';                       # 0
  looks_like_full_url 'http://duckduckgo.com';                    # 0
</pre>

### URN

<pre>
  use Data::Format::Validate::URN 'looks_like_urn';

  looks_like_urn 'urn:oid:2.16.840';                                  # 1
  looks_like_urn 'urn:ietf:rfc:2648';                                 # 1
  looks_like_urn 'urn:issn:0167-6423';                                # 1
  looks_like_urn 'urn:isbn:0451450523';                               # 1
  looks_like_urn 'urn:mpeg:mpeg7:schema:2001';                        # 1
  looks_like_urn 'urn:uci:I001+SBSi-B10000083052';                    # 1
  looks_like_urn 'urn:lex:br:federal:lei:2008-06-19;11705';           # 1
  looks_like_urn 'urn:isan:0000-0000-9E59-0000-O-0000-0000-2';        # 1
  looks_like_urn 'urn:uuid:6e8bc430-9c3a-11d9-9669-0800200c9a66';     # 1

  looks_like_urn 'oid:2.16.840';                                      # 0
  looks_like_urn 'This is not a valid URN';                           # 0
  looks_like_urn 'urn:-768hgf-0000-0000-0000';                        # 0
  looks_like_urn 'urn:this-is-a-realy-big-URN-maybe-the-bigest';      # 0
</pre>
