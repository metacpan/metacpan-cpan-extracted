package CGI::Kwiki::Scripts;
$VERSION = '0.18';
use strict;
use base 'CGI::Kwiki';

sub directory { #XXX
    $_[1] =~ /(.*)\// ? $1 : '.';
}

sub name { #XXX
    $_[1] =~ /.*\/(.*)/ ? $1 : $_[1];
}

sub suffix { '.cgi' }

sub render_template {
    my ($self, $template) = @_;
    return $self->driver->template->render($template,
        start_perl => $Config::Config{startperl},
    );
}
sub perms {
    my ($self, $file) = @_;
    chmod(0755, $file) or die $!;
}

1;

__DATA__

=head1 NAME 

CGI::Kwiki::Scripts - Script container for CGI::Kwiki

=head1 DESCRIPTION

See installed kwiki pages for more information.

=head1 AUTHOR

Brian Ingerson <INGY@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2003. Brian Ingerson. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut

__index__
[% start_perl %] -w
use lib '.';
# use lib '../lib';
use CGI::Kwiki;
CGI::Kwiki::run_cgi();
__pages__
[% start_perl %] -w
use lib '.';
# use lib '../lib';
use CGI::Kwiki::Pages;
CGI::Kwiki::run_cgi();
__admin__
[% start_perl %] -w
use lib '.';
# use lib '../lib';
use CGI::Kwiki;
$CGI::Kwiki::ADMIN = 1;
$CGI::Kwiki::ADMIN = 1;
CGI::Kwiki::run_cgi();
__kwiki__
[% start_perl %] -w
use lib '.';
# use lib '../lib';
use CGI::Kwiki;
CGI::Kwiki::run_cgi();
__blog__
[% start_perl %] -w
use lib '.';
# use lib '../lib';
use CGI::Kwiki::Blog;
CGI::Kwiki::Blog::run_cgi();
