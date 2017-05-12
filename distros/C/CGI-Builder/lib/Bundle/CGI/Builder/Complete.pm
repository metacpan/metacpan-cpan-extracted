use strict ;
; package Bundle::CGI::Builder::Complete



__END__

=pod

=head1 NAME

Bundle::CGI::Builder::Complete - A bundle to install the complete CGI::Builder framework.

=head1 SYNOPSIS

    perl -MCPAN -e 'install Bundle::CGI::Builder::Complete'

=head1 CONTENTS

HTML::Tagset            - used by HTML::Parser

HTML::Parser            - used by HTML::FillInForm and HTML::TableTiler

HTML::TableTiler        - used by Template::Magic::HTML

HTML::FillInForm        - used by Template::Magic::HTML

Class::constr           - used by Template::Magic::Zone

Class::props            - used by Template::Magic::Zone

Class::groups           - used by Template::Magic::Zone

Object::groups          - used by Template::Magic::Zone

Object::props           - used by Template::Magic::Zone

IO::Util                - used by Template::Magic

File::Spec              - used by Template::Magic

CGI::Builder            - main distribution

CGI::Builder::CgiAppAPI - cgiapp compatible API

Apache::CGI::Builder    - Apache/mod_perl integration

CGI::Builder::Auth      - Authentication and authorization

Template::Magic         - used by CGI::Builder::Magic

CGI::Builder::Magic     - Template::Magic integration

Data::FormValidator     - used by CGI::Builder::DFVCheck

CGI::Builder::DFVCheck  - Data::FormValidator integration

HTML::Template          - used by CGI::Builder::HTMLtmpl

CGI::Builder::HTMLtmpl  - HTML::Template integration

CGI::Session				        - used by CGI::Builder::Session

CGI::Builder::Session   - CGI::Session integration


=head1 DESCRIPTION

This bundle gathers together all the modules plus all related prerequisites for the CGI::Builder framework. Please, notice that the Bundle will install A LOT of modules that you might not need, so use it specially if you want to extensively try the CBF.

Note: A Bundle is a module that simply defines a collection of other modules. It is used by the CPAN module to automate the fetching, building and installing of modules from the CPAN ftp archive sites.

=head1 AUTHOR and COPYRIGHT

© 2004 by Domizio Demichelis (L<http://perl.4pro.net>)

All Rights Reserved. This module is free software. It may be used, redistributed and/or modified under the same terms as perl itself.

=cut
