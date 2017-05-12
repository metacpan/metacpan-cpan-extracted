package Bundle::perlWebSite;

$VERSION = '0.02';

1;

__END__

=head1 NAME

Bundle::perlWebSite - a bundle for perlWebSite

=head1 SYNOPSIS

 perl -MCPAN -e "install 'Bundle::perlWebSite'"

=head1 CONTENTS

 CGI [ 2.89 ]
 CGI::Cache [ 1.40 ]
 CGI::Carp [ 1.24 ]
 CGI::Util [ 1.3 ]
 Cache::Cache [ 1.01 ]
 Digest::SHA1 [ 2.01 ]
 Error [ 0.15 ]
 File::Find::Rule [ 0.08 ]
 File::Temp [ 0.12 ]
 Number::Compare [ 0.01 ]
 Storable [ 2.06 ]
 Template [ 2.08 ]
 Template::Base [ 2.55 ]
 Template::Config [ 2.55 ]
 Template::Constants [ 2.54 ]
 Template::Context [ 2.69 ]
 Template::Directive [ 2.16 ]
 Template::Document [ 2.56 ]
 Template::Exception [ 2.51 ]
 Template::Filters [ 2.59 ]
 Template::Grammar [ 2.17 ]
 Template::Iterator [ 2.53 ]
 Template::Parser [ 2.66 ]
 Template::Plugins [ 2.58 ]
 Template::Provider [ 2.62 ]
 Template::Service [ 2.60 ]
 Template::Stash [ 2.68 ]
 Text::Glob [ 0.05 ]
 Text::WikiFormat [ 0.45 ]
 Time::Piece [ 1.08 ]
 URI::Escape [ 3.16 ]
 XML::Parser [ 2.31 ]
 XML::Parser::Expat [ 2.31 ]
 XML::Simple [ 1.05 ]


=head1 DESCRIPTION

Bundle::perlWebSite will install all the perl modules required to run 
perlWebSite, a mini-CMS. This bundle was created using the following 
procedure:

 h2xs -AXcfn Bundle::perWebSite

and then editing the .pm file appropriately. Then, from a bash prompt:

 perl -d:Modlist -MDevel::Modlist=nocore index.cgi 2>&1|egrep '^[A-Z].*[0-9]$'|awk '{print $1 " [ " $2 " ]"}' >> Bundle::perlWebSite.pm

This output was then moved into the CONTENTS section. This did not eliminate modules that are part of other modules (c.f. Template::*). Close enough for jazz, though.

=head1 AUTHOR

Duncan M. McGreggor <oubiwann at cpan dot org>

=cut
