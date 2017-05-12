package CGI::Application::Plugin::HTMLPrototype;

use HTML::Prototype;

use strict;
use vars qw($VERSION @EXPORT $PROTOTYPE);

require Exporter;

@EXPORT = qw(
    prototype
);
sub import { goto &Exporter::import }

$VERSION = '0.20';


##############################################
###
###   prototype
###
##############################################
#
# Get an HTML::Prototype object.  The same object
# will be returned everytime this method is called.
#
sub prototype {
    my $class = shift;

    $PROTOTYPE ||= HTML::Prototype->new;
    return $PROTOTYPE;
}

1;
__END__

=head1 NAME

CGI::Application::Plugin::HTMLPrototype - Give easy access to the prototype JavaScript library using HTML::Prototype


=head1 SYNOPSIS

 use base qw(CGI::Application);
 use CGI::Application::Plugin::HTMLPrototype;

 sub myrunmode {
   my $self = shift;

   # Get prototype object
   my $prototype = $self->prototype;

 }

=head1 DESCRIPTION

HTML::Prototype is a JavaScript code generator for the prototype.js JavaScript
library (L<http://prototype.conio.net/>), and the script.aculo.us extensions
to prototype.js (L<http://script.aculo.us/>).  It allows you to easily add AJAX
calls and dynamic elements to your website.

=head1 METHODS

=head2 prototype

Simply returns an L<HTML::Prototype> object.  See the L<HTML::Prototype> docs for information
on the methods that are available to you.


=head1 TEMPLATE TOOLKIT INTEGRATION

This module is very useful when used in concert with the Template Toolkit.  Since version 0.07
The L<CGI::Application::Plugin::TT> module automatically adds a 'c' parameter to your template,
which gives you access to your CGI::Application object from within your templates.  This will
give you easy access to the prototype plugin from within all of your templates.

Here is an example.  The following example will create a hidden 'div' tag and a link that
will make the div fade in when clicked.

  [% c.prototype.define_javascript_functions %]
  <a href="#" onclick="[% c.prototype.visual_effect( 'Appear', 'extra_info' ) %]">Extra Info</a>
  <div style="display: none" id="extra_info">Here is some more extra info</div>


=head1 EXAMPLE

See the examples directory for some examples


=head1 AUTHOR

Cees Hek <ceeshek@gmail.com>


=head1 BUGS

Please report any bugs or feature requests to
C<bug-cgi-application-plugin-htmlprototype@rt.cpan.org>, or through the web
interface at L<http://rt.cpan.org>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 CONTRIBUTING

Patches, questions and feedback are welcome.


=head1 SEE ALSO

L<CGI::Application>, L<CGI::Application::Plugin::TT>, L<HTML::Prototype>, perl(1)


=head1 LICENSE

Copyright (C) 2005 Cees Hek, All Rights Reserved.

This library is free software. You can modify and or distribute it under the same terms as Perl itself.

=cut

