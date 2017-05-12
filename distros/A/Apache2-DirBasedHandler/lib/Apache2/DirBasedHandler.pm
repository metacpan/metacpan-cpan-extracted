package Apache2::DirBasedHandler;

use strict;
use warnings;

use Apache2::Response ();
use Apache2::RequestUtil ();
use Apache2::Log ();
use Apache2::RequestIO ();
use Apache2::Const -compile => qw(:common);
use Apache2::Request ();

our $VERSION = '0.04';
my $debug = 0;

sub handler :method {
    my $self = shift;
    my $r = Apache2::Request->new(shift);

    my $uri_bits = $self->parse_uri($r);
    my $args = $self->init($r);

    my $function;
    my $uri_args = [];
    if (@{$uri_bits}) {
        while (@{$uri_bits}) {
            my $try_function = $self->uri_to_function($r,$uri_bits);
            
            $debug && $r->warn(qq[trying $try_function]);
            if ($self->can($try_function)) {
                $debug && $r->warn(qq[$try_function works!]);
                $function = $try_function;
                last;
            }
            else {
                $debug && $r->warn(qq[$try_function not found]);
                unshift @{$uri_args}, pop @{$uri_bits};
            }
        }
        $function ||= q[root_index];
    }
    else {
        $function = q[root_index];
    }
   
    if (!$function) {
        $debug && $r->warn(q[i do not know what to do with ]. $r->uri);
        return Apache2::Const::NOT_FOUND;
    }
    
    $debug && $r->warn(qq[calling $function with path_args (] . join(q[,],@{$uri_args}).q[)]);
    my ($status,$page_out,$content_type) =
        $self->$function($r,$uri_args,$args);

    if ($status ne Apache2::Const::OK) {
        return $status;
    }

    $r->content_type($content_type);
    $r->print($page_out);
    return $status;
}

sub init {
    my ($self,$r) = @_;
    return {};
}

sub parse_uri {
    my ($self,$r) = @_;

    my $loc = $r->location;
    my $uri = $r->uri;
    # replace multiple slashes with single slashes
    $uri =~ s/\/+/\//gixm;
    # strip the location off the start of the uri
    $uri =~ s/^$loc\/?//xm;
    my @split_uri = split m{/}xm, $uri;

    return \@split_uri;
}

sub uri_to_function {
    my ($self,$r,$uri_bits) = @_;

    return join('_', @{$uri_bits}) . q[_page];
}

sub root_index {
    return (
        Apache2::Const::OK,
        q[you might want to override "root_index"],
        'text/html; charset=utf-8'
    );
}

sub set_debug {
    $debug = shift;
    return;
}

1;

__END__

=head1 NAME

Apache2::DirBasedHandler - Directory based Location Handler helper

=head1 VERSION

This documentation refers to <Apache2::DirBasedHandler> version 0.03

=head1 SYNOPSIS

  package My::Thingy

  use strict
  use Apache2::DirBasedHandler
  our @ISA = qw(Apache2::DirBasedHandler);
  use Apache2::Const -compile => qw(:common);

  sub root_index {
      my $self = shift;
      my ($r,$uri_args,$args) = @_;

      if (@$uri_args) {
          return Apache2::Const::NOT_FOUND;
      }

      return (
          Apache2::Const::OK,
          qq[this is the index],
          qq[text/plain; charset=utf-8]
      );
  }

  sub super_page {
      my $self = shift;
      my ($r,$uri_args,$args) = @_;

      return (
          Apache2::Const::OK,
          qq[this is $location/super and all it's contents],
          qq[text/plain; charset=utf-8]
      );
  }

  sub super_dooper_page {
      my $self = shift;
      my ($r,$uri_args,$args) = @_;

      return (
          Apache2::Const::OK,
          qq[this is $location/super/dooper and all it's contents],
          qq[text/plain; charset=utf-8]
      );
  }

  1;

=head1 DESCRIPTION

This module is designed to allow people to more quickly implement uri to function
style handlers.  This module is intended to be subclassed.

A request for 

  $r->location . qq[/foo/bar/baz/]

will be served by the first of the following functions with is defined

  foo_bar_baz_page
  foo_bar_page
  foo_page
  root_index

=head1 METHODS

The following methods (aside from 'handler') are meant to be overridden in your 
subclass if you want to modify its behavoir.

=head2 handler

C<handler> is the guts of DirBasedHandler.  It provides the basic structure of the
module, turning the request uri into an array, which is then turned into possible
function calls.  

=head2 init 

C<init> is used to include objects or data you want to be passed into 
your page functions.  To be most useful it should return a hash reference. 
The default implementation returns a reference to an empty hash.

=head2 parse_uri

C<parse_uri> takes an Apache::RequestRec (or derived) object, and returns a reference to an
array of all the non-slash parts of the uri.  It strips repeated slashes in the 
same manner that they would be stripped if you do a request for static content.

=head2 uri_to_function

C<uri_to_function> converts an Apache2::RequestRec (or derived) object and an
array reference and returns and returns the name of a function to handle the
request it's arguments describe.

=head2 root_index

C<root_index> handles requests for $r->location, and any requests that have no 
other functions defined to handle them.  You must subclass it (or look silly)

=head2 set_debug

C<set_debug> enables or disables debug output to the apache error log

=head1 DEPENDENCIES

This module requires modperl 2 (http://perl.apache.org), and 
libapreq (http://httpd.apache.org/apreq/) which must be installed seperately.

=head1 INCOMPATIBILITIES

There are no known incompatibilities for this module.

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.  Please report any problems through 

http://rt.cpan.org/Public/Dist/Display.html?Name=Apache2-DirBasedHandler

=head1 AUTHOR

Adam Prime (adam.prime@utoronto.ca)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008 by Adam Prime (adam.prime@utoronto.ca).  All rights 
reserved.  This program is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself.  See L<perlartistic>.

This module is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY 
or FITNESS FOR A PARTICULAR PURPOSE.

