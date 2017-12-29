package Dancer2::Plugin::JSManager;
$Dancer2::Plugin::JSManager::VERSION = '0.011';
use strict;
use warnings;

use Dancer2::Plugin;

sub BUILD {
  my $s = shift;

  # default autoload to 1 if not set
  my $autoload = $s->config->{autoload} //= 1;

  if ($autoload) { 
    $s->app->add_hook( Dancer2::Core::Hook->new (
      name => 'before_template',
      code => sub { 
        my $tokens = shift;
        $s->_inject_js($tokens);
      }
    ));
  }
}

sub _inject_js {
  my $s = shift;
  my $tokens = shift;
  my $libraries = $s->config->{libraries};
  $tokens->{js_head} = "<script>function load_js(uri) { var script = document.createElement('script'); script.src = uri; document.head.appendChild(script); }</script>\n";
  foreach my $library( @$libraries ) {
    my ($name, $values) = %$library;

    # default to <head> if no location given
    my $location = 'js_' . ($values->{injection_pt} ||= 'head');

    if ( $values->{fallback} ) { 
      $tokens->{$location} .= sprintf qq(<script onerror="load_js('%s')" src="%s"></script>\n), $values->{fallback}, $values->{uri};
    } else {
      $tokens->{$location} .= sprintf qq(<script src="%s"></script>\n), $values->{uri};
    }
  }
}

1; # Magic true value required at end of module

# ABSTRACT: Manage website javascript files with the Dancer2 configuration file

__END__

=pod

=head1 NAME

Dancer2::Plugin::JSManager - Manage website javascript files with the Dancer2 configuration file

=head1 VERSION

version 0.011

=head1 OVERVIEW

This is a simple plugin for the L<Dancer2|http://perldancer.org/> web application framework. The target audience for this software is Dancer2 website developers looking for an easy way to insert javascript files into their templates using the Dancer2 configuration file. It can also make websites more reliable by falling back to local copies of javascript files hosted on a content delivery network (CDN) if the CDN goes down.

=head1 SYNOPSIS AND CONFIGURATION

In the Dancer2 configuration file, make an entry for each javascript file you are using on the site
in the order you'd like them to appear in the web page like so:

    plugins:
      JSManager:
          ; 'autoload' defaults to 1 if not supplied. Setting to 0 turns off all javascript.  
          autoload: 1                                                

          ; create a variable called 'libraries'  
          libraries:

            ; A name you give to the library, must be preceded by a dash  
            - jquery:                                                

              ; The URL where the js file is hosted on the CDN       
              uri: 'https://code.jquery.com/jquery-1.11.1.min.js'  

              ;Path to local js file in case CDN is unavailable     
              fallback: '/js/jquery-1.11.1.min.js'                 

            ; This library depends on the previous library so we put it second   
            - jqm:                                                   
              uri: 'http://code.jquery.com/mobile/1.4.5/jquery.mobile-1.4.5.min.js'
              fallback: '/js/jquery.mobile-1.4.5.min.js'

            - growler:
              ; if a file is not on a CDN simply put the path to the local file   
              uri: '/js/jquery.growl.min.js'                       

              ; control where in the template the javascript will appear (see below for more explanation)  
              injection_pt: 'body_top'                            

After modifying your config file, all you have to do is put a variable called C<js_head>
in the head portion of your tempalte. So, for example, if you are using L<Template::Toolkit>,
you would add the following into the C<<head\>> section of your HTML template: 

    [% js_head %]

If you want to inject the javascript into different parts of your page, you can do that with a
custom variable determined by the "injection_pt" property, preceded by C<js_>.

So, from the example above, the growler script has the C<injection_pt> set to C<body_top> so you would
place the following in the appropriate place in your template:

    [% js_body_top %]

If you are using templating modules other than L<Template::Toolkit>, consult its ducmentation for the
appropriate syntax.

=head1 DEPENDENCIES

None

=head1 INCOMPATIBILITIES

None reported.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc Dancer2::Plugin::JSManager

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/sdondley/Dancer2-Plugin-JSManager>

  git clone git://github.com/sdondley/Dancer2-Plugin-JSManager.git

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<https://github.com/sdondley/Dancer2-Plugin-JSManager/issues>.

=head1 MOTIVATION

I'm new to Dancer2 development and wrote this plugin to scratch a minor itch and to learn how to write a basic Dancer2 module.

=head1 DEVELOPMENT NOTES

This software is actively maintained. Further releases are expected to help exercise my budding software development skills. Feedback, suggestions, and contributions are greatly appreciated and welcome.

Eventually, I'd like to improve this module to automatically download external javascripts to the local machine and periodically download fresh copies (perhaps once a day) to ensure the local js copy is in sync with the CDN. I also want to add a feature that gives the developer control over which pages the javascript libraries should load on.

Longer term, I'm interested in exploring the possibility of making an admin interface for updating the settings configration file. Another possible future feautre is the selection of a CDN for based on the name of some of the more the popular libraries. Finally, I'd like to expand this to be able to handle css files as well.

=head1 AUTHOR

Steve Dondley <s@dondley.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Steve Dondley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
