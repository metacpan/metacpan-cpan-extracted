NAME
    Apache::Access::Headers - mod_perl HTTP header authorization module

SYNOPSIS
     # in httpd.conf
     PerlSetVar HeadersAccessConf conf/headers_access.conf
        
     DocumentRoot /usr/local/apache/htdocs
     <Directory "/usr/local/apache/htdocs">
        PerlModule Apache::Access::Headers
        PerlAccessHandler Apache::Access::Headers
     </Directory>

DESCRIPTION
    This module is intended to be used as a mod_perl PerlAccessHandler. It's
    function is to authorize requests for server resources based on the
    existence of and content of HTTP headers.

    Authorizing HTTP headers may be be set by a web browser, a software
    agent, or an authenitcating proxy server. This module was originally
    written to work with the latter.

    Note: The default reponse from the handler is currently FORBIDDEN. This
    behavior is not yet configurable.

CONFIGURING APACHE
    Module configuration is simple ( read: limited ). Currently, the module
    only works with a single configuration file, and works best when
    configured for a server's document root. See the LIMITATIONS section for
    an explanation of the modules current short-comings.

    Add the following line to httpd.conf outside all Directory, Location and
    VirtualHost blocks:

     PerlSetVar HeadersAccessConf /path/to/conf/headers_access.conf
 
    And add the following lines to the DocumentRoot Directory block:

      PerlModule Apache::Access::Headers
      PerlAccessHandler Apache::Access::Headers 

CONFIGURATION FILE
  General Options

    Although the modules is currently limited to a single xml-based
    configuration file, this configuration file is quite flexible.

    The shell of the conf file is:

     <headers_authz>
      <headers>
      [...]
      </headers>
     </headers_authz>  

    The important part of the conf file is the <header> blocks within the
    <headers> block. Each <header> block must contain two items: an <id> tag
    and a <path> tag.

    The <id> tag specifies the name of the HTTP header that that must be set
    to allow access to the urls matched by the <path> tags. <path> tags are
    treated as regular expressions ( i.e., m|^$k$| where $k is the value of
    the <path> tag ).

    Using the Sample Configuration File below, a request for
    /secrets/index.html must contain an X-Can-View-Secret-Stuff header with
    a non-zero value in order to be successfully authorized.

    Likewise, a request for /secrets.html requires that either an
    X-Can-View-Secret-Stuff header or an X-Can-View-Super-Secret-Stuff
    header is present and set to a non-zero value.

    As mentioned above, <path> tags are treated as regular expressions.
    You'll notice, then, that the <path> tag for <id>X-Secret-User-I1 in the
    sample conf contains parantheses. Parentheses tells the module to
    require that the value assigned to the needed header ( i.e.
    X-Secret-User-ID ) equal $1.

    For example, using the sample conf, a request for /users/jeffo/ must
    have an X-Secret-User-ID header set to 'jeffo'. If X-Secret-User-ID
    header is present but set to 'tori', the request will be denied.

  Other Options

    There are three special configuration options. They are outlined here:

    ALL
       If the <id> of a <header> block is 'ALL', then _all_ requests for
       resources matched by the attached <path> tags. This is useful for
       allowing access to <path>/</path> and <path>index.html</path>, etc.

    REFERER
       If the <id> of a <header> block is 'REFERER', then the referer header
       is checked against an array of referer values specified by <referer>
       tags in the <header> block.

       For example, using the sample conf file, requests for
       /images/background.gif coming from a page on http://www.rulez.com/,
       or http://www.picnicman.com/ will be accepted.

       <referer> tags are treated as regexes ( like <path> tags ). The regex
       used is 'm|^$ar|' where $ar is the contents of the <referer> tags.

       One little trick is to use 'https?://' at the start of the regex to
       allow connections from either secure or insecure pages.

       Note: If the referer is not matched, FORBIDDEN will not be
       automatically returned. In this case, the module continues to loop
       over <path> values, looking for a secondary match.

       i.e. if a request for /images/button.gif does not come from a valid
       referer, but contains a X-Can-View-Secret-Stuff header, the image
       will be served.

       This behavior is open to debate. Admittedly, it's a hack meant to
       overcome some problems with the original spec. If you don't like it,
       then don't use REFERER as an <id>. :)

    <prefix></prefix>
       You'll notice a commented-out <prefix> tag in the sample conf file.
       The prefix tag was added because some - *cough* - authenticating
       proxies prepend a string to header values defined in the
       authtencation database.

       If the <prefix> tag is set, then all header checks will look for
       $PREFIX . $HEADER.

       For example, if <prefix> is set to 'Rulez-', requests for
       /secret/index.html would require not a X-Can-View-Secret-Stuff
       header, but a Rulez-X-Can-View-Secret-Stuff header.

  Sample Configuration File

     <header_access>
      <headers>
       <!-- <prefix>Rulez-</prefix> -->
       <header>
        <id>ALL</id>
        <path>/</path>
        <path>/index.html</path>
       </header>
       <header>
        <id>REFERER</id>
        <referer>https?://www.rulez.com/</referer>
        <referer>https?://ww.picnicman.com/</referer>
        <path>/images/.*</path>
        <path>/cgi/*.cgi</path>
       </header>
       <header>
        <id>X-Can-View-Secret-Stuff</id>
        <path>/secret/.*</path>
        <path>/secrets.html</path>
        <path>/images/.*</path>
       </header>
       <header>
        <id>X-Can-View-Super-Secret-Stuff</id>
        <path>/super-secret/.*</path>
        <path>/secrets.html</path>
       </header>
       <header>
        <id>X-Secret-User-ID</id>
        <path>/users/(.*?)/.*(</path>
       </header>
      </headers>
    </header_access>

  Configuration File DTD

     <?xml version="1.0" ?>
     <!DOCTYPE header_access [
      <!ELEMENT header_access ( headers+ ) >
      <!ELEMENT headers ( header+ ) >
      <!ELEMENT header ( id, path+, referer+ ) >
      <!ELEMENT id ( #PCDATA ) >
      <!ELEMENT path ( #PCDATA ) >
      <!ELEMENT referer ( #PCDATA ) >
     ]>

TESTING & DEBUGGING
    If you set Apache's LogLevel to 'debug', the module will spit out a
    bunch of information regarding it's handling of the request.

     ErrorLog ./logs/error_log
     LogLevel debug

    This is particularly useful if you're creating complicated <path> tag
    regexes, or if you really have no idea why a request is getting though.
    :)

LIMITATIONS & THE FUTURE
    This module was originally written to cover the entire document root of
    a web server. And right now, that's all it does. This was a
    security-driven decision. The down-side is that the module is not
    VirtualHost or Directory friendly.

    I wanted to release this first version before adding support for use in
    VirtualHosts and Directory blocks with separate conf files.

    If interest - and time - allow, these will be the key features of the
    next release. ( Not to mention configuration of the default return
    policy and inversion of deny, allow rules, etc. )

RESOURCES
    For an example of a commercial authentication proxy, see
    SecureComputing's PremierAccess product. http://securecomputing.com/. I
    don't necessarily recommend it; I just know it because I wrote this to
    work with it. :)


AUTHOR
    Jeffrey O'Connell, Jr. <jeffo@rulez.com>

COPYRIGHT
    Copyright (c) 2003 Jeffrey O'Connell, Jr., Rulez New Media

    This library is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

