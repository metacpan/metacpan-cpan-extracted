use strict ;
; package Bundle::Application::Magic

__END__

=head1 NAME

Bundle::Application::Magic - A bundle to install CGI::Application::Magic plus all related prerequisites.

=head1 SYNOPSIS

    perl -MCPAN -e 'install Bundle::Application::Magic'

=head1 CONTENTS

HTML::Tagset            - used by HTML::Parser

HTML::Parser            - used by HTML::FillInForm and HTML::TableTiler

HTML::TableTiler        - used by HTML::MagicTemplate

HTML::FillInForm        - used by HTML::MagicTemplate

Class::constr           - used by Template::Magic::Zone

Class::props            - used by Template::Magic::Zone

Object::props           - used by Template::Magic::Zone

Object::groups          - used by CGI::Application::Magic

Template::Magic         - the Template::Magic distribution

Data::FormValidator     - used by CGI::Application::CheckRM

CGI::Application::Plus  - used by CGI::Applicatio::Magic

=head1 DESCRIPTION

This bundle gathers together the CGI::Application::Magic and all the related prerequisites.

Note: A Bundle is a module that simply defines a collection of other modules. It is used by the CPAN module to automate the fetching, building and installing of modules from the CPAN ftp archive sites.

=head1 AUTHOR and COPYRIGHT

© 2004 by Domizio Demichelis.

All Rights Reserved. This module is free software. It may be used, redistributed and/or modified under the same terms as perl itself.
