package CGI::Untaint::html;
use 5.006;
use strict;
use warnings;
use HTML::Sanitizer;
our $VERSION = "1.0";
# I'll tell you a secret. Modules I write get version 1.0 automatically
# if I've ever used them. If they're 0.x, I've never actually used them
# myself.

our $sanitizer = HTML::Sanitizer->new;
$sanitizer->permit_only(
         em           => 1,
         strong       => 1,
         p            => 1,
         ol           => 1,
         ul           => 1,
         li           => 1,
         tt           => 1,
         a            => 1,
         img          => 1,
         span         => 1,
         blockquote   => { cite => 1 },
         _            => {  
             href     => qr/^(?:http|ftp|mailto|sip):/i,
             src      => qr/^(?:http|ftp|data):/i,
             title    => 1,
             id       => sub { $_ = "x-$_" },
             "xml:lang" => 1,
             lang     => 1,
             "*"        => 0,
         },
         '*'          => 0,     
         script       => undef,
         style        => undef,
);

use base 'CGI::Untaint::object';

sub _untaint_re { qr/(.*)/ }

sub is_valid {
    my $self = shift;
    $self->value($sanitizer->filter_html_fragment($self->value));
}

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

CGI::Untaint::html - validate sanitized HTML

=head1 SYNOPSIS

     use CGI::Untaint;
     my $handler = CGI::Untaint->new($q->Vars);

     my $time = $handler->extract(-as_html => 'description');


=head1 DESCRIPTION

Web forms which take HTML from the user for later display on site open
themselves up to the potential of cross-site scripting attacks, messy sites
due to unclosed tags, or merely big images of Barney the Purple Dinosaur.

L<HTML::Sanitizer> helps eliminate this by tidying up the HTML, and this
module is a wrapper around C<HTML::Sanitizer> for C<CGI::Untaint>. When
you extract C<as_html>, you can be sure that the HTML isn't going to play
havoc with your site.

It does this by using a fairly standard set of configuration parameters to
C<HTML::Sanitizer> - the "stricter" set of rules given in the examples
documentation to that module.

If you want to create your own ruleset, replace
C<$CGI::Untaint::html::sanitizer> with a C<HTML::Sanitizer> object that meets
your needs.

=head1 AUTHOR

Simon Cozens, C<simon@cpan.org>

This module may be distributed under the same terms as Perl itself.

=head1 SEE ALSO

L<CGI::Untaint>, L<HTML::Sanitizer>.

=cut
