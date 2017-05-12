package Bundle::Apache::ASP::Extra;

$VERSION = '1.02';

1;

__END__

=head1 NAME

  Bundle::Apache::ASP::Extra - Install modules that provide additional functionality to Apache::ASP

=head1 SYNOPSIS

 perl -MCPAN -e 'install Bundle::Apache::ASP::Extra'

=head1 CONTENTS

Bundle::Apache::ASP  - Base for Apache::ASP installation

CGI		  - Required for file upload, make test, and command line ./cgi/asp script

HTML::Parser      - Required for HTML::FillInForm

HTML::Clean	  - Compress text/html with Clean config or $Response->{Clean} set to 1-9

Net::SMTP	  - Runtime errors can be mailed to the webmaster with MailErrorTo config

Devel::Symdump	  - Used for StatINC setting, which reloads modules dynamically

Apache::DBI	  - Cache database connections per process

Compress::Zlib    - Gzip compress HTML output on the fly

Time::HiRes       - Sub second timing of execution with Debug 3 or -3 enabled

HTML::FillInForm  - FormFill functionality which autofills HTML forms from form data

Apache::Filter    - Required for SSI filtering with Apache::SSI

HTML::SimpleParse - Required for SSI filtering with Apache::SSI

Apache::SSI       - Required for full server side includes support ( SSI ) beyond file includes

Tie::TextDir      - Fast file based cache for CacheDB, good for caching large values for things like XSLT and $Response->Include() caching

Bundle::XML       - Required for XML::XSLT support.

XML::XSLT         - Required for XSLT support.  May also use XML::Sablotron and XML::LibXSLT for this, which are not part of this bundle.

=head1 DESCRIPTION

This bundle contains extra modules used by Apache::ASP.

=head1 AUTHOR

Joshua Chamas

