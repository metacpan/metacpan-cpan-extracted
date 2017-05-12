package Catalyst::Helper::Model::TextLinkAds;

use strict;
use warnings;

use Carp qw( croak );

our $VERSION = '0.01';


=head1 NAME

Catalyst::Helper::Model::TextLinkAds - Helper for TextLinkAds Catalyst Models


=head1 SYNOPSIS

    script/myapp_create.pl model ModelName TextLinkAds [ tmpdir=/path/to/tmp ] [ nocache ]


=head1 DESCRIPTION

Use this module to set up a new L<Catalyst::Model::TextLinkAds> model for your
Catalyst application.

=head2 Arguments

    ModelName is the short name for the Model class being generated (eg.
    "TextLinkAds")
    
    tmpdir is the path to a directory where temporary files should be stored.
    
    nocache disables caching which is definitely not recommended.


=head1 METHODS

=head2 mk_compclass

This method takes the given arguments and generates a
L<Catalyst::Model::TextLinkAds> model for your application.

=cut

sub mk_compclass {
    my ( $self, $helper, @options ) = @_;
    
    # Extract the arguments...
    foreach (@options) {
        if ( /^tmpdir=(.+)$/ ) {
            $helper->{tmpdir} = $1;
        }
        elsif ( /^nocache$/ ) {
            $helper->{cache} = 0;
        }
    }
    
    $helper->{config_encountered} = (
        exists $helper->{tmpdir}
    );
    
    $helper->render_file( 'tlaclass', $helper->{file} );
}


=head1 SEE ALSO

L<Catalyst>, L<Catalyst::Helper>, L<Catalyst::Model::TextLinkAds>


=head1 BUGS

Please report any bugs or feature requests to
C<bug-catalyst-model-textlinkads at rt.cpan.org>, or through the web interface
at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Catalyst-Model-TextLinkAds>.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Catalyst::Helper::Model::TextLinkAds

You may also look for information at:

=over 4

=item * Catalyst::Model::TextLinkAds

L<http://perlprogrammer.co.uk/module/Catalyst::Model::TextLinkAds/>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Catalyst-Model-TextLinkAds/>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Catalyst-Model-TextLinkAds>

=item * Search CPAN

L<http://search.cpan.org/dist/Catalyst-Model-TextLinkAds/>

=back


=head1 AUTHOR

Dave Cardwell <dcardwell@cpan.org>


=head1 COPYRIGHT AND LICENSE

Copyright (c) 2007 Dave Cardwell. All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.

=cut


1;
__DATA__
=begin pod_to_ignore

__tlaclass__
package [% class %];

use strict;
use warnings;

use base qw/ Catalyst::Model::TextLinkAds /;

[%- IF config_encountered %]
__PACKAGE__->config(
    [% "tmpdir => '" _ tmpdir _ "',\n" IF tmpdir -%]
    [% "cache  => 0" _          ",\n"  IF cache  -%]
);
[%- END %]


=head1 NAME

[% class %] - Text Link Ads Model Class


=head1 SYNOPSIS

See L<[% app %]>.


=head1 DESCRIPTION

Text Link Ads Model Class.


=head1 AUTHOR

[% author %]


=head1 LICENSE

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.

=cut


1;
