# ABSTRACT: Corolocal for Syntax::Feature
package Syntax::Feature::Corolocal;
{
  $Syntax::Feature::Corolocal::VERSION = '0.1.2';
}
use common::sense;
use Coro::Localize ();

sub install {
    my $class = shift;
    my %args = @_;
    Coro::Localize->import_into( $args{'into'} );
}

1;


__END__
=pod

=encoding utf-8

=head1 NAME

Syntax::Feature::Corolocal - Corolocal for Syntax::Feature

=head1 VERSION

version 0.1.2

=head1 SYNOPSIS

    use syntax qw( corolocal );
    
    async {    
        corolocal $/ = \2_048;
        while (<STDIN>) {
            # ...
        }
    }

=head1 DESCRIPTION

This allows you to load L<Coro::Localize> using L<Syntax::Feature>. 
L<Syntax::Feature> provides a single point of entry for loading various
syntax extensions.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Coro::Localize|Coro::Localize>

=item *

L<Coro::Localize|Coro::Localize>

=item *

L<Syntax::Feature|Syntax::Feature>

=back

=head1 SOURCE

The development version is on github at L<http://https://github.com/iarna/Coro-Localize>
and may be cloned from L<git://https://github.com/iarna/Coro-Localize.git>

=head1 AUTHOR

Rebecca Turner <becca@referencethis.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Rebecca Turner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT
WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER
PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND,
EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE
SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME
THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE
TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE
SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES.

=cut

