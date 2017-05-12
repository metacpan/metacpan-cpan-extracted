package Apache2::Controller::Dispatch::RenderTemplate;

=head1 NAME

Apache2::Controller::Dispatch::RenderTemplate -
dispatch to controllers mapped by files in primary A2C_Render_Template_Path.

=head1 VERSION

Version 1.001.001

=cut

use version;
our $VERSION = version->new('1.001.001');

=head1 SYNOPSIS

UNIMPLMENTED - AN AMBITIOUS AND INTERESTING SPEC

I am going on to write OpenID auth first but this is an idea for 
an automatic dispatcher based on the template directory tree structure.

You do not need to subclass this A2C dispatch class.  It assumes
controller library structure from the structure of html template files
and renders them with L<Apache2::Controller::Render::Template>.

 # virtualhost.conf:
 PerlSwitches -I/myapp/lib

 <Location '/'>

     # primary path looks like a web site; secondary 'cmp' = component templates:
     A2C_Render_Template_Path   /myapp/html   /myapp/cmp

     # what lib name do we prefix to the ucfirst()ed primary html files?
     A2CControllerLibs       MyApp::C

     # set and go:
     SetHandler              modperl
     PerlInitHandler         Apache2::Controller::Dispatch::RenderTemplate

 </Location>
 # EOF

 shell% find /myapp -type f
 /myapp/cmp/loginbox.html
 /myapp/cmp/newsticker.html
 /myapp/cmp/quickmenu.html
 /myapp/html/index.html
 /myapp/html/foo.html
 /myapp/html/foo/biz.html
 /myapp/html/foo/baz.html
 /myapp/lib/MyApp/C/Foo.pm
 /myapp/lib/MyApp/C/Noz.pm

Except, you do not type the '.html' in the URL.  They are named 
so that you can easily look at the raw files with a local browser.

A URL with a corresponding file in /myapp/html will always render,
whether a specific controller is found or not.

 Foo      allowed_methods() is qw( default bar biz )
 Noz      allowed_methods() is qw( default )

 /              => index.html, no controller 
                         ( would be MyApp::C::Default->default() )

 /yip           => index.html, no controller
                         ( would be MyApp::C::Default->yip() or default() )

 /foo           => foo.html,        MyApp::C::Foo->default()

 /foo/bar       => foo.html,        MyApp::C::Foo->bar()
 /foo/bar/a/b/c => foo.html,        MyApp::C::Foo->bar(qw( a b c ))
 
 /foo/biz/a/b/c => foo/biz.html,    MyApp::C::Foo->biz(qw( a b c ))
 
 # cuts 'baz' from args because baz.html gets used:
 /foo/baz/a/b/c => foo/baz.html,    MyApp::C::Foo->default(qw( a b c )) 

 /noz/a/b/c     => index.html,      MyApp::C::Noz->default(qw( a b c ))
 
=cut

use strict;
use warnings FATAL => 'all';
use English '-no_match_vars';

use Apache2::Const -compile => qw( HTTP_NOT_IMPLEMENTED );

use Log::Log4perl qw(:easy);
use YAML::Syck;
use Carp qw( cluck );

=head1 METHODS

=head2 handler

THIS MODULE IS UNIMPLEMENTED.

=cut

sub handler : method {
    cluck __PACKAGE__." UNIMPLMENTED - AN AMBITIOUS AND INTERESTING SPEC";
    return Apache2::Const::HTTP_NOT_IMPLEMENTED;
}

1;


=head1 SEE ALSO

L<Apache2::Controller::Dispatch>

L<Apache2::Controller>

=head1 AUTHOR

Mark Hedges, C<hedges +(a t)- formdata.biz>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2010 Mark Hedges.  CPAN: markle

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

This software is provided as-is, with no warranty 
and no guarantee of fitness
for any particular purpose.

=cut
