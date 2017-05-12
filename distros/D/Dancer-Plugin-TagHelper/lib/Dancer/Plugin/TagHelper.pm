package Dancer::Plugin::TagHelper;

use 5.006;
use strict;
use warnings FATAL => 'all';
use Dancer ':syntax';
use HTML::TagHelper;

=head1 NAME

Dancer::Plugin::TagHelper - Useful routines for generating HTML for use with Dancer + TT/Xslate ...

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

In your Dancer application's MyApp.pm file ...

    use Dancer::Plugin::TagHelper;

and in your application's views ...

    <: css('bootstrap') :>

    or

    <% js(jquery) %>

=cut

my %methods;
my $ht = HTML::TagHelper->new();
for my $method ( $ht->meta->get_all_methods ) {
    next if $method->fully_qualified_name !~ /^HTML::TagHelper::[a-z]/;
    $methods{ $method->name } = $method;
}
delete $methods{$_} for qw/after around extends has before with new/;

my $template = setting('template');
if ( $template eq 'simple' ) {
    warn "$template donot support taghelper";
}
elsif ( $template eq 'xslate' ) {
    my $functions;
    for my $name ( keys %methods ) {
        my $method = $methods{$name};
        $functions->{$name} = Text::Xslate::html_builder(sub { $method->execute( $ht, @_ ) });
    }
    set engines => {
        xslate => {
            function  => $functions
        }
    };
};


hook 'before_template' => sub {
    my $tokens = shift;
    for my $name ( keys %methods ) {
        my $method = $methods{$name};
        $tokens->{$name} = sub { $method->execute( $ht, @_ ) };
    }
};


=head1 AUTHOR

chenryn, C<< <rao.chenlin at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dancer-plugin-taghelper at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dancer-Plugin-TagHelper>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

By now, you must set template in C<config.yml>, but not set by C<< set template => ''>> in c<<MyApp.pm>>.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dancer::Plugin::TagHelper


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dancer-Plugin-TagHelper>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dancer-Plugin-TagHelper>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dancer-Plugin-TagHelper>

=item * Search CPAN

L<http://search.cpan.org/dist/Dancer-Plugin-TagHelper/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 chenryn.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Dancer::Plugin::TagHelper
