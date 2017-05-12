package Catalyst::Helper::View::TT::Filters::LazyLoader;

use strict;
use warnings;
use File::Spec;

sub mk_compclass {
    my ( $s , $helper ) = @_;
    my $file = $helper->{file};
    my $base = $helper->{base};
    my $app  = $helper->{app} ;

    $helper->render_file( 'compclass', $file );

    $helper->render_file( 'lazy', File::Spec->catfile( $base , 'lib' , $app , 'TTFilters.pm' ) );
}

1;

=head1 NAME

Catalyst::Helper::View::TT::Filters::LazyLoader - Helper for TT Views with L<Template::Filters::LazyLoader> support. 

=head1 SYNOPSIS

 script/create.pl view TT TT::Filters::LazyLoader

=head1 DESCRIPTION

Helper for TT Views with  L<Template::Filters::LazyLoader> support.

=head1 METHOD

=head2 mk_compclass

=cut

__DATA__

__compclass__
package [% class %];

use strict;
use warnings;
use base 'Catalyst::View::TT::Filters::LazyLoader';

__PACKAGE__->config(
    TEMPLATE_EXTENSION => '.tt',
    FILTERS_LAZYLOADER => {
        pkg => '[% app %]::TTFilters',
    }
);

1;

=head1 NAME

[% class %] - TT View for [% app %] with L<Template::Filters::LazyLoader> support.

=head1 DESCRIPTION

L<Template::Filters::LazyLoader> View for [% app %]

=head1 AUTHOR

[% author %]

=head1 SEE ALSO

L<[% app %]>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__lazy__
package [% app %]::TTFilters;

use strict;
use warnings;

1;

=head1 NAME

[% app %]::TTFilters -  L<Template::Filters::LazyLoader> Filters class

=head1 DESCRIPTION

Template-Toolkit Fliter modules.

=head1 SEE ALSO

L<Catalyst::TT::Filters::LazyLoader>
L<Template::Filters::LazyLoader>

=head1 AUTHOR

[% author %]

=cut
