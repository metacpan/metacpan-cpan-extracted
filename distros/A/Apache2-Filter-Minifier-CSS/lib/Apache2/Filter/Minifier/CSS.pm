package Apache2::Filter::Minifier::CSS;

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
# Load up the CSS minifier modules.
use CSS::Minifier;
eval { require CSS::Minifier::XS };

###############################################################################
# Version number.
our $VERSION = '1.05';

###############################################################################
# MIME-Types we're willing to minify.
my %mime_types = (
    'text/css'      => 1,
    );

###############################################################################
# Subroutine:   handler($filter)
###############################################################################
# CSS minification output filter.
sub handler {
    my $f = shift;
    my $r = $f->r;
    my $log = $r->log;

    # assemble list of acceptable MIME-Types
    my %types = (
        %mime_types,
        map { $_=>1 } $r->dir_config->get('CssMimeType'),
        );

    # determine Content-Type of document
    my ($ctype) = ($r->content_type =~ /^(.+?)(?:;.*)?$/);
    unless ($ctype) {
        $log->info( "unable to determine content type; skipping : URL ", $r->uri );
        return Apache2::Const::DECLINED;
    }

    # only process CSS documents
    unless (exists $types{$ctype}) {
        $log->info( "skipping request to ", $r->uri, " (not a CSS document)" );
        return Apache2::Const::DECLINED;
    }

    # figure out which minifier module/function we're supposed to be using;
    # either an explicit minifier function/package, or our list of acceptable
    # minifiers
    my $minifier;
    my @possible = $r->dir_config->get('CssMinifier') || (
        'CSS::Minifier::XS',
        'CSS::Minifier',
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
            $minifier = ($maybe eq 'CSS::Minifier')
                            ? sub { $func->(input=>shift) }
                            : sub { $func->(shift) };
            last;
        }
    }
    unless ($minifier) {
        $log->info( "no CSS minifier available; declining" );
        return Apache2::Const::DECLINED;
    }

    # gather up entire document
    my $ctx = $f->ctx;
    while ($f->read(my $buffer, 4096)) {
        $ctx .= $buffer;
    }

    # unless we're at the end, store the CSS for our next invocation
    unless ($f->seen_eos) {
        $f->ctx( $ctx );
        return Apache2::Const::OK;
    }

    # if we've got CSS to minify, minify it
    if ($ctx) {
        my $t_st = [gettimeofday()];
        my $min  = eval { $minifier->($ctx) };
        if ($@) {
            # minification failed; log error and send original CSS
            $log->error( "error minifying: $@" );
            $f->print( $ctx );
        }
        else {
            # minification ok; log results and send minified CSS
            my $t_dif = tv_interval($t_st);
            my $l_min = length($min);
            my $l_css = length($ctx);
            $log->debug( "CSS minified $l_css to $l_min : t:$t_dif : URL ", $r->uri );
            $r->headers_out->unset( 'Content-Length' );
            $f->print( $min );
        }
    }

    return Apache2::Const::OK;
}

1;

=head1 NAME

Apache2::Filter::Minifier::CSS - CSS minifying output filter

=head1 SYNOPSIS

  <LocationMatch "\.css$">
      PerlOutputFilterHandler   Apache2::Filter::Minifier::CSS

      # if you need to supplement MIME-Type list
      PerlSetVar                CssMimeType  text/plain

      # if you want to explicitly specify the minifier to use
      #PerlSetVar               CssMinifier  CSS::Minifier::XS
      #PerlSetVar               CssMinifier  CSS::Minifier
      #PerlSetVar               CssMinifier  MY::Minifier::function
  </LocationMatch>

=head1 DESCRIPTION

C<Apache2::Filter::Minifier::CSS> is a Mod_perl2 output filter which minifies
CSS using C<CSS::Minifier> or C<CSS::Minifier::XS>.

Only CSS style-sheets are minified, all others are passed through
unaltered.  C<Apache2::Filter::Minifier::CSS> comes with a list of known
acceptable MIME-Types for CSS style-sheets, but you can supplement that list
yourself by setting the C<CssMimeType> PerlVar appropriately (use C<PerlSetVar>
for a single new MIME-Type, or C<PerlAddVar> when you want to add multiple
MIME-Types).

Given a choice, using C<CSS::Minifier::XS> is preferred over C<CSS::Minifier>,
but we'll use whichever one you've got available.  If you want to explicitly
specify which minifier you want to use, set the C<CssMinifier> PerlVar to the
name of the package/function that implements the minifier.  Minification
functions are expected to accept a single parameter (the CSS to be minified)
and to return the minified CSS on completion.  If you specify a package name,
we look for a C<minify()> function in that package.

=head2 Caching

Minification does require additional CPU resources, and it is recommended that
you use some sort of cache in order to keep this to a minimum.

Being that you're already running Apache2, though, here's some examples of a
mod_cache setup:

Disk Cache

  # Cache root directory
  CacheRoot /path/to/your/disk/cache
  # Enable cache for "/css/" location
  CacheEnable disk /css/

Memory Cache

  # Cache size: 4 MBytes
  MCacheSize 4096
  # Min object size: 128 Bytes
  MCacheMinObjectSize 128
  # Max object size: 512 KBytes
  MCacheMaxObjectSize 524288
  # Enable cache for "/css/" location
  CacheEnable mem /css/

=head1 METHODS

=over

=item handler($filter)

CSS minification output filter. 

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

L<CSS::Minifier>,
L<CSS::Minifier::XS>,
L<Apache2::Filter::Minifier::JavaScript>,
L<Apache::Clean>.

=cut
