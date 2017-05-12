package Apache::SiteConfig;
use strict;
use warnings;
our $VERSION = '0.03';
use Apache::SiteConfig::Statement;
use Apache::SiteConfig::Section;
use Apache::SiteConfig::Directive;
use Apache::SiteConfig::Root;


1;
__END__

=head1 NAME

Apache::SiteConfig - Apache site deployment tool

=head1 SYNOPSIS

    use Apache::SiteConfig::Deploy;

    name 'projectA';

    su 'www-data';

    domain 'foo.com';

    domain_alias 'foo.com';

    source git => 'git@git.foo.com:projectA.git',
           branch => 'master';

    source hg  => 'http://.........';

    # relative web document path of repository
    webroot 'webroot/';


Do deploy

    $ perl siteA deploy

Do update
    
    $ perl siteA update

Clean up

    $ perl siteA clean


=head1 DESCRIPTION

Apache::SiteConfig is a simple tool for apache website deployment.

=head1 AUTHOR

Yo-An Lin E<lt>cornelius.howl {at} gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
