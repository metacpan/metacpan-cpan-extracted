package Dancer::Middleware::Rebase;
BEGIN {
  $Dancer::Middleware::Rebase::VERSION = '0.8.0';
}

# ABSTRACT: a Plack middleware to be used for Dancer

use strict;
use parent qw( Plack::Middleware );
use URI ();

sub call {
   my ($self, $env) = @_;

   # prepare cached data if it's the first call
   if (!$self->{replacement}) {
      my $uri         = URI->new($self->{base});
      $self->{replacement} = {
         'psgi.url_scheme' => $uri->scheme(),
         'HTTP_HOST'       => $uri->authority(),
         'SCRIPT_NAME'     => $uri->path(),
      };

      $self->{strip} = $uri->path()
        if $self->{strip} && substr($self->{strip}, 0, 1) ne '/';
   } ## end if (!$self->{replacement...

   # override due variables in $env
   while (my ($k, $v) = each %{$self->{replacement}}) {
      $env->{$k} = $v;
   }

   # strip prefix from PATH_INFO if applicable
   $env->{PATH_INFO} =~ s/\A $self->{strip}//mxs if $self->{strip};

   return $self->app()->($env);
} ## end sub call

1;


=pod

=head1 NAME

Dancer::Middleware::Rebase - a Plack middleware to be used for Dancer

=head1 VERSION

version 0.8.0

=head1 DESCRIPTION

This is a L<Plack::Middleware> specifically geared to the L<Dancer>
framework. The goal is to let you rebase your application easily, i.e.
let you move your application that usually lives in
C<http://example.com/> into C<http://example.com/some/prefix/> or
even C<http://whatever.example.com/other/prefix/>.

This can be particularly useful in a reverse-proxy deployment, where
the application is called by the proxy HTTP server and thus lives
in a different namespace with respect to the one available to the
end user.

Suppose for example that you have a reverse-proxy deployment, where
the end user calls route C</homepage> in your application using the
URI C<http://example.com/app/homepage>. If you are using Apache with
the following configuration:

   ProxyPass        /app/ http://internal:3000/
   ProxyPassReverse /app/ http://internal:3000/

then the route in your application will be called as
C<http://internal:3000/homepage>. This leads to two problems:

=over

=item *

both C<uri_for()> and C<request.base()> refer to C<http://internal:3000/>.
This means that it's very likely that your links will be wrong, e.g.
consider the link to the CSS file in a standard Dancer application:

   <link rel="stylesheet" href="<% request.base %>/css/style.css" />

This will be expanded to C<http://internal:3000//css/style.css> which
will not be accessible by the end user. This particular problem
can be addressed using L<Plack::Middleware::ReverseProxy>, which
massages C<$env> in order to restore the originally requested
scheme, host and port;

=item *

the additional path prefix C</app/> has been stripped by Apache and
there is no reference to it. While the problem above can be addressed
with L<Plack::Middleware::ReverseProxy>, there is no standard solution
for addressing this issue and you have to work out your own.

=back

You might think that you can address the latter problem with a proper
Apache configuration:

   ProxyPass        /app/ http://internal:3000/app/
   ProxyPassReverse /app/ http://internal:3000/app/

but with this configuration you receive a request towards
C<http://internal:3000/app/homepage>, which is not going to work
smoothly for different reasons:

=over

=item *

you have to set a proper prefix for rebasing all the routes;

=item *

even so, you are not able to rebase the static part of the site,
i.e. your CSS files are still ruled out unless you address them
specifically in the Apache configuration.

=back

Dancer::Middleware::Rebase addresses all these problems at the same time.
You can set a base URI that will be propagated in the C<$env> passed to your
application. In particular, it will set all 
the proper variables that are then used by L<Dancer::Request> methods
C<base()> and C<uri_for()> in order to establish the URI where all
stuff can be referred.

In case you like keeping the prefix part in the Apache configuration,
anyway, you still have the problem of stripping it before giving it
to the application. In this case, you can set a C<strip> parameter
to eliminate the prefix from the C<PATH_INFO> component of C<$env>.

=head1 CONFIGURATION

This module is a C<Plack::Middleware>, so you have to configure it
inside C<plack_middlewares> like this:

   plack_middlewares:
      -
         - "+Dancer::Middleware::Rebase"
         - base
         - "http://example.com/app"
         - strip
         - 1

Please note that you have to put a plus sign before the module name,
otherwise L<Plack> will think that it is a name to be referred to the
L<Plack::Middleware> namespace.

You can set the following options:

=over

=item B<< base >>

the URI that has to be set as the base one. This will be what you
eventually get when you call C<request.base> in your code and in
your templates, and it is also used by C<uri_for>.

=item B<< strip >>

either a true value or a string that starts with C</>. In the
first case, the C<path> portion of the C<base> URI will be used
as a prefix to be stripped from C<PATH_INFO>, otherwise the
specified string is used. You should only need the first
approach, anyway.

=back

=begin whatever

=head2 call

What L<Plack::Middleware> wants us to override. It sets the proper stuff
in C<$env> and passes the control to the wrapped application.


=end whatever

=head1 AUTHOR

Flavio Poletti <polettix@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Flavio Poletti <polettix@cpan.org>.

This module is free software.  You can redistribute it and/or
modify it under the terms of the Artistic License 2.0.

This program is distributed in the hope that it will be useful,
but without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut


__END__

