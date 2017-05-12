package Apache2::FixupContentLanguage;

use warnings FATAL => 'all';
use strict;

use Apache2::RequestRec ();
use Apache2::Util       ();
use Apache2::DebugLog   ();

use Apache2::Const  -compile => qw(OK DECLINED);

use APR::Finfo          ();
use APR::Table          ();

=head1 NAME

Apache2::FixupContentLanguage - Fixup handler for Last-Modified header

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    # httpd.conf

    # preload for debug configuration directives
    PerlLoadModule   Apache2::FixupContentLanguage

    # assign to fixup handler
    PerlFixupHandler Apache2::FixupContentLanguage

=head1 DESCRIPTION

Invoked as a Fixup handler, this module will adjust the Content-Language
header of a subrequested resource, should it conflict from the main
request. Apache2::FixupContentLanguage is for use with resources that may
arbitrarily include other resources (i.e. XSLT, server side includes,
etc.) by way of subrequests.

=cut

sub handler {
    my $r = shift;
    my $topr = $r;
    $topr = $topr->main while $topr->main;
    $topr = $topr->main while $topr->main;
    if ($r->main and !$topr->notes->get(__PACKAGE__)) {
        $topr->notes->set(__PACKAGE__, 1);
        my $cnt = 0;
        my %cl  = ();
        for my $cl (@{$r->content_languages}, @{$topr->content_languages}) {
            $cl{$cl} = $cnt++ unless defined $cl{$cl};
        }
        my $ref = [sort { $cl{$a} <=> $cl{$b} } keys %cl];
        my $hdr = join(', ', @$ref);
        $r->log_debug('invoc', 5, "Main request Content-Languages now: $hdr");
        $topr->content_languages($ref); 
        $topr->subprocess_env->set('CONTENT_LANGUAGE', $hdr);
        $topr->notes->unset(__PACKAGE__);
        return Apache2::Const::OK;
    }
    Apache2::Const::DECLINED;
}

=head1 DEBUGGING

Debug levels start at 5 and end at 6. Below are the relevant debugging
categories.

=over 1

=item subreq

Enable for notification of the module's activation.

=item invoc

Enable for notification when the module does or doesn't do its job.

=back

=head1 SEE ALSO

L<Apache2::DebugLog>

=head1 AUTHOR

dorian taylor, C<< <dorian@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-apache2-fixuplastmodified@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Apache2-FixupContentLanguage>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2005 dorian taylor, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Apache2::FixupContentLanguage
