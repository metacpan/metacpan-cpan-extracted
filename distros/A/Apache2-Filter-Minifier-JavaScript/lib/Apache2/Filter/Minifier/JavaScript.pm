package Apache2::Filter::Minifier::JavaScript;

###############################################################################
# Required inclusions.
use strict;
use warnings;
use Apache2::Filter qw();           # $f
use Apache2::RequestRec qw();       # $r
use Apache2::RequestUtil qw();      # $r->dir_config
use Apache2::Log qw();              # $log->*()
use APR::Table qw();                # dir_config->get() and headers_out->unset()
use Apache2::Const -compile => qw(OK DECLINED);
use Time::HiRes qw(gettimeofday tv_interval);

###############################################################################
# Load up the JS minifier modules.
use JavaScript::Minifier;
eval { require JavaScript::Minifier::XS; };

###############################################################################
# Version number.
our $VERSION = '1.05';

###############################################################################
# MIME-Types we're willing to minify.
my %mime_types = (
    'text/javascript'           => 1,
    'text/ecmascript'           => 1,
    'application/javascript'    => 1,
    'application/ecmascript'    => 1,
    'application/x-javascript'  => 1,
    );

###############################################################################
# Subroutine:   handler($filter)
###############################################################################
# JavaScript minification output filter.
sub handler {
    my $f = shift;
    my $r = $f->r;
    my $log = $r->log;

    # assemble list of acceptable MIME-Types
    my %types = (
        %mime_types,
        map { $_=>1 } $r->dir_config->get('JsMimeType'),
        );

    # determine Content-Type of document
    my ($ctype) = ($r->content_type =~ /^(.+?)(?:;.*)?$/);
    unless ($ctype) {
        $log->info( "unable to determine content type; skipping : URL ", $r->uri );
        return Apache2::Const::DECLINED;
    }

    # only process JS documents
    unless (exists $types{$ctype}) {
        $log->info( "skipping request to ", $r->uri, " (not a JS document)" );
        return Apache2::Const::DECLINED;
    }

    # figure out which minifier module/function we're supposed to be using;
    # either an explicit minifier function/package, or our list of acceptable
    # minifiers
    my $minifier;
    my @possible = $r->dir_config->get('JsMinifier') || (
        'JavaScript::Minifier::XS',
        'JavaScript::Minifier',
        );
    foreach my $maybe (@possible) {
        no strict 'refs';
        # explicit function name
        if (defined &{"$maybe"}) {
            $minifier = sub { $maybe->(shift) };
            last;
        }
        # package name; look for "minify()" function
        if (defined &{"${maybe}::minify"}) {
            my $func = \&{"${maybe}::minify"};
            $minifier = ($maybe eq 'JavaScript::Minifier')
                            ? sub { $func->(input=>shift) }
                            : sub { $func->(shift) };
            last;
        }
    }
    unless ($minifier) {
        $log->info( "no JavaScript minifier available; declining" );
        return Apache2::Const::DECLINED;
    }

    # gather up entire document
    my $ctx = $f->ctx;
    while ($f->read(my $buffer, 4096)) {
        $ctx .= $buffer;
    }

    # unless we're at the end, store the JS for our next invocation
    unless ($f->seen_eos) {
        $f->ctx( $ctx );
        return Apache2::Const::OK;
    }

    # if we've got JS to minify, minify it
    if ($ctx) {
        my $t_st = [gettimeofday()];
        my $min  = eval { $minifier->($ctx) };
        if ($@) {
            # minification failed; log error and send original JS
            $log->error( "error minifying: $@" );
            $f->print( $ctx );
        }
        else {
            # minification ok; log results and send minified JS
            my $t_dif = tv_interval($t_st);
            my $l_min = length($min);
            my $l_js  = length($ctx);
            $log->debug( "JS minified $l_js to $l_min : t:$t_dif : URL ", $r->uri );
            $r->headers_out->unset( 'Content-Length' );
            $f->print( $min );
        }
    }

    return Apache2::Const::OK;
}

1;

=head1 NAME

Apache2::Filter::Minifier::JavaScript - JS minifying output filter

=head1 SYNOPSIS

  <LocationMatch "\.js$">
      PerlOutputFilterHandler   Apache2::Filter::Minifier::JavaScript

      # if you need to supplement MIME-Type list
      PerlSetVar                JsMimeType  text/json

      # if you want to explicitly specify the minifier to use
      #PerlSetVar               JsMinifier  JavaScript::Minifier::XS
      #PerlSetVar               JsMinifier  JavaScript::Minifier
      #PerlSetVar               JsMinifier  MY::Minifier::function
  </LocationMatch>

=head1 DESCRIPTION

C<Apache2::Filter::Minifier::JavaScript> is a Mod_perl2 output filter which
minifies JavaScript using C<JavaScript::Minifier> or
C<JavaScript::Minifier::XS>.

Only JavaScript documents are minified, all others are passed through
unaltered.  C<Apache2::Filter::Minifier::JavaScript> comes with a list of
several known acceptable MIME-Types for JavaScript documents, but you can
supplement that list yourself by setting the C<JsMimeType> PerlVar
appropriately (use C<PerlSetVar> for a single new MIME-Type, or C<PerlAddVar>
when you want to add multiple MIME-Types).

Given a choice, using C<JavaScript::Minifier::XS> is preferred over
C<JavaScript::Minifier>, but we'll use whichever one you've got available.  If
you want to explicitly specify which minifier you want to use, set the
C<JsMinifier> PerlVar to the name of the package/function that implements the
minifier.  Minification functions are expected to accept a single parameter
(the JavaScript to be minified) and to return the minified JavaScript on
completion.  If you specify a package name, we look for a C<minify()> function
in that package.

=head2 Caching

Minification does require additional CPU resources, and it is recommended that
you use some sort of cache in order to keep this to a minimum.

Being that you're already running Apache2, though, here's some examples of a
mod_cache setup:

Disk Cache

  # Cache root directory
  CacheRoot /path/to/your/disk/cache
  # Enable cache for "/js/" location
  CacheEnable disk /js/

Memory Cache

  # Cache size: 4 MBytes
  MCacheSize 4096
  # Min object size: 128 Bytes
  MCacheMinObjectSize 128
  # Max object size: 512 KBytes
  MCacheMaxObjectSize 524288
  # Enable cache for "/js/" location
  CacheEnable mem /js/

=head1 METHODS

=over

=item handler($filter)

JavaScript minification output filter. 

=back

=head1 AUTHOR

Graham TerMarsch (cpan@howlingfrog.com)

Many thanks to Geoffrey Young for writing C<Apache::Clean>, from which several
things were lifted. :)

=head1 COPYRIGHT

Copyright (C) 2007, Graham TerMarsch.  All Rights Reserved.

This is free software; you can redistribute it and/or modify it under the same
license as Perl itself.

=head1 SEE ALSO

L<JavaScript::Minifier>,
L<JavaScript::Minifier::XS>,
L<Apache2::Filter::Minifier::CSS>,
L<Apache::Clean>.

=cut
