package Catalyst::View::PHP;

use strict;
use base qw/Catalyst::Base/;
use PHP::Interpreter;
use NEXT;

our $VERSION = '0.01';

=head1 NAME

Catalyst::View::PHP - Template View Class

=head1 SYNOPSIS

    # use the helper
    myapp_create.pl view PHP PHP

    # lib/MyApp/View/PHP.pm
    package MyApp::View::PHP;

    use base 'Catalyst::View::PHP';

    # To set the override the PHP include path set the path in the config.
    __PACKAGE__->config->{INCLUDE_PATH} =
       '/usr/local/generic/templates:/usr/local/myapp/templates';

    1;
    
    # Meanwhile, maybe in a private C<end> action
    $c->forward('MyApp::View::PHP');

=head1 DESCRIPTION

This is the Catalyst view class for the L<PHP::Interpreter>. Your
application subclass should inherit from this class. This plugin
renders the template specified in C<$c-E<gt>stash-E<gt>{template}>, or
failing that, C<$c-E<gt>request-E<gt>match>. The template variables
are set up from the contents of C<$c-E<gt>stash>, augmented with
template variable C<base> set to Catalyst's C<$c-E<gt>req-E<gt>base>,
template variable C<c> to Catalyst's C<$c>, and template variable
C<name> to Catalyst's C<$c-E<gt>config-E<gt>{name}>. The output is
stored in C<$c-E<gt>response-E<gt>output>.

If you want to override PHP config settings, you can do it in your
application's view class by setting
C<__PACKAGE__-E<gt>config-E<gt>{OPTION}>, as shown in the Synopsis.
See the available options document on the L<PHP::Interpreter>
documentation.

In PHP the variables exported are the requests parameters for C<$_GET>
and C<$_POST> depending on the method used to send the request.  Also all
of the stash is exported just like in TemplateToolkit, and you can
access the current context by calling C<$c>.

For example to read the CGI parameter 'test' you can use:

C<$_GET['test']>

or

C<print $c-E<gt>request-E<gt>parameters['test']>

Or to get the method of the request try:

C<print $c-E<gt>request-E<gt>method>

=head1 BUGS

There are probably a few as this module is very new along with
PHP::Interpreter being very new.  Feel free to discuss this module on
the Catalyst mailing list catalyst@lists.rawmode.org.

This module has been tested with PHP 5.1.0RC1 (cli).

=head1 METHODS

=over 4

=item new

The constructor for the PHP view. Sets up the template provider, 
and reads the application config.

=cut

sub new {
    my $self = shift;
    my $c    = shift;
    $self = $self->NEXT::new(@_);
    my $root   = $c->config->{root};
    
    return $self;
}

=item process

Renders the template specified in C<$c-E<gt>stash-E<gt>{template}> or
C<$c-E<gt>request-E<gt>match>. Template variables are set up from the
contents of C<$c-E<gt>stash>, augmented with C<base> set to
C<$c-E<gt>req-E<gt>base>, C<c> to C<$c> and C<name> to
C<$c-E<gt>config-E<gt>{name}>. Output is stored in
C<$c-E<gt>response-E<gt>output>.

Being that there is no clear way to reset the interpreter between
requests, each request is processed in a new interpreter instance.  As
L<PHP::Interpreter> matures this may change.

=cut

sub process {
    my ( $self, $c ) = @_;

    my $template = $c->stash->{template} || $c->request->match;

    unless ($template) {
        $c->log->debug('No template specified for rendering') if $c->debug;
        return 0;
    }

    $c->log->debug(qq/Rendering template "$template"/) if $c->debug;
    
    my $output;

    my $interpreter_params = {
      c => $c,
      %{$c->stash},
      OUTPUT => \$output,
      COOKIE => $c->req->cookies,
      INCLUDE_PATH => $c->config->{root} . ":" . $c->config->{root} . '/base',
    };


    if ($c->req->method eq 'POST') {
      $interpreter_params->{POST} = $c->req->parameters;
    } else {
      $interpreter_params->{GET} = $c->req->parameters;
    }

    my $interpreter = PHP::Interpreter->new($interpreter_params);

    eval {
      $interpreter->include($template);
    };
    if($@) {
      my $error = qq/Couldn't render template "$@"/;
      $c->log->error($error);
      $c->error($error);
      return 0;
    }
    
    
    unless ( $c->response->content_type ) {
      $c->response->content_type('text/html; charset=utf-8');
    }

    $c->response->body($output);
    
    return 1;
  }

=item config

This allows your view subclass to pass additional settings to the PHP
config hash.

=back

=head1 SEE ALSO

L<Catalyst>, L<PHP::Interpreter>, L<http://www.php.net>

=head1 AUTHOR

Rusty Conover, C<rconover@infogears.com>

Based off of L<Catalyst::View::TT> by:

Sebastian Riedel, C<sri@cpan.org>
Marcus Ramberg, C<mramberg@cpan.org>
Jesse Sheidlower, C<jester@panix.com>

=head1 COPYRIGHT

Copyright (c) 2005 InfoGears, Inc. All Rights Reserved. L<http://www.infogears.com/>

This program is free software, you can redistribute it and/or modify it 
under the same terms as Perl itself.

=cut

1;
