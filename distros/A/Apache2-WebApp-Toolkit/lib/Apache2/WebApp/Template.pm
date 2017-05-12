#----------------------------------------------------------------------------+
#
#  Apache2::WebApp::Template - Interface to the Template Toolkit
#
#  DESCRIPTION
#  Returns to the caller a new template object.
#
#  AUTHOR
#  Marc S. Brooks <mbrooks@cpan.org>
#
#  This module is free software; you can redistribute it and/or
#  modify it under the same terms as Perl itself.
#
#----------------------------------------------------------------------------+

package Apache2::WebApp::Template;

use strict;
use warnings;
use base 'Apache2::WebApp::Base';
use Template;

our $VERSION = 0.05;

#~~~~~~~~~~~~~~~~~~~~~~~~~~[  OBJECT METHODS  ]~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

#----------------------------------------------------------------------------+
# new(\%config)
#
# Constructor method used to instantiate a new template object.

sub new {
    my $class  = shift;
    my $config = (ref $_[0] eq 'HASH') ? shift : { @_ };
    my $self   = bless({}, $class);
    return $self->_init($config) || $class->error;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~[  PRIVATE METHODS  ]~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

#----------------------------------------------------------------------------+
# _init(\%config)
#
# Return to the caller a new template object. 

sub _init {
    my ($self, $config) = @_;
    return Template->new(
        CACHE_SIZE   => $config->{template_cache_size}   || 0,
        COMPILE_DIR  => $config->{template_compile_dir},
        INCLUDE_PATH => $config->{template_include_path},
        STAT_TTL     => $config->{template_stat_ttl},
        ENCODING     => $config->{template_encoding},
        ABSOLUTE     => 1
      )
      or $self->error($Template::ERROR);
}

1;

__END__

=head1 NAME

Apache2::WebApp::Template - Interface to the Template Toolkit

=head1 SYNOPSIS

  $c->template->method( ... );

=head1 DESCRIPTION

A persistent template object that provides methods of the Template Toolkit that
are accessible from within your web application using C<%controller>.  Template
options can be easily configured in your project I<webapp.conf>

=head1 EXAMPLES

=head2 Template processing

=head3 CONFIG

  [template]
  cache_size   = 100                                # total files to store in cache
  compile_dir  = /path/to/project/tmp/templates     # path to template cache
  include_path = /path/to/project/templates         # path to template directory
  stat_ttl     = 60                                 # template to HTML build time (in seconds)
  encoding     = utf8                               # template output encoding

=head3 METHOD

  sub _default {
      my ($self, $c) @_;

      $c->request->content_type('text/html');

      $c->template->process(
          'file.tt', {
              foo => 'bar',
              baz => qw( bucket1 bucket2 bucket3 ),
              qux => {
                  key1 => 'value1',
                  key2 => 'value2',
                  ...
              },
              ...
          }
        )
        or $self->_error($c, 'Template process failed', $c->template->error() );

      exit;
  }

=head3 TEMPLATE

  [% foo %]

  [% FOREACH bucket = baz %]
      [% bucket %]
  [% END %]

  [% qux.key1 %]
  [% qux.key2 %]

=head1 SEE ALSO

L<Apache2::WebApp>, L<Template::Manual::Syntax>, L<Template::Manual::Directives>,
L<Template::Manual::Variables>, L<Template::Manual::Filters>, L<Template::Manual::VMethods>

=head1 AUTHOR

Marc S. Brooks, E<lt>mbrooks@cpan.orgE<gt> L<http://mbrooks.info>

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://dev.perl.org/licenses/artistic.html>

=cut
