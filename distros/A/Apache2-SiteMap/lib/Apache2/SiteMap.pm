package Apache2::SiteMap;

use strict;
use warnings;

use WWW::Google::SiteMap;

use File::Basename;
use Apache2::Module;
use Apache2::RequestUtil ();
use Apache2::RequestRec ();
use Apache2::RequestIO ();
use Apache2::Const qw(DECLINED OK);
use DirHandle;

our $VERSION = '0.1';

sub handler {
    my ($r) = @_;
    my $dir = $r->dir_config('SiteMapDir');
    if (! -d $dir) { return DECLINED; }
    my $base = _get_base($r);
    my @files = _get_files($dir);
    my $map = WWW::Google::SiteMap->new();
    for my $file (@files) {
        $map->add({ 'loc' => $base . $file });
    }
    $r->content_type('text/xml');
    $r->print($map->xml);
    return OK;
}

sub _get_files {
    my ($dir) = @_;
    my $d = DirHandle->new($dir);
    my @items = ();
    while (my $file = $d->read) {
        if ($file =~ /^\./) { next; }
        push @items, $file;
    }
    $d->close;
    return @items;
}

sub _get_base {
    my ($r) = @_;
    if (my $base = $r->dir_config('SiteMapBase')) { return $base; }
    return '/';
}

1;
__END__

=head1 NAME

Apache2::SiteMap - Dynamically create Google SiteMap files

=head1 SYNOPSIS

Create a Google SiteMap much like a mod_dir listing.

  <Location "/sitemap.xml">
      SetHandler modperl
      PerlHandler Apache2::SiteMap
      PerlSetVar SiteMapBase http://host/
      PerlSetVar SiteMapDir /path/to/dir
  </Location>
  
  <Location "/music/sitemap.xml">
      SetHandler modperl
      PerlHandler Apache2::SiteMap
      PerlSetVar SiteMapBase http://host/archives/
      PerlSetVar SiteMapDir /path/to/archives/dir
  </Location>

=head1 PUBLIC FUNCTIONS

=head2 handler

=head1 AUTHOR

Nick Gerakines, C<< <nick at gerakines.net> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-apache2-sitemap at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Apache2-SiteMap>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Apache2::SiteMap

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Apache2-SiteMap>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Apache2-SiteMap>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Apache2-SiteMap>

=item * Search CPAN

L<http://search.cpan.org/dist/Apache2-SiteMap>

=back

=head1 TODO

Add ability to set a flag for recursive file listings.

Add ability to filter files based on file lists and regex.

=head1 COPYRIGHT & LICENSE

Copyright 2006 Nick Gerakines, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
