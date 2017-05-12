package Catalyst::View::TT::Filters::LazyLoader;

use strict;
use base qw(Catalyst::View::TT);
use Template::Filters::LazyLoader 0.05;

our $VERSION = '0.07';

sub new {
    my ($class, $c, $arguments) = @_;
    my $lazy = Template::Filters::LazyLoader->new();

    my $config = {
        %{ $class->config->{FILTERS_LAZYLOADER} || {} },
        %{ $arguments->{FILTERS_LAZYLOADER} || {} },
    };

    if ( $config->{base_pkg} ) {
        $lazy->base_pkg( $config->{base_pkg} );
    }
    elsif( $config->{pkg} ) {
        $lazy->pkg( $config->{pkg}  );
    }
    elsif( $config->{pkgs} ) {
        $lazy->pkgs( $config->{pkgs}  );
    }
    else {
        die 'please set base_pkg or pkg or pkgs';
    }

    if ( defined $config->{static_filter_prefix} ) {
        $lazy->static_filter_prefix( $config->{static_filter_prefix} ) 
    }
    if ( defined $config->{dynamic_filter_prefix} ) {
        $lazy->dynamic_filter_prefix( $config->{dynamic_filter_prefix} ) 
    }

    if ( defined $config->{lib_path} ) {
        $lazy->lib_path( $config->{lib_path} );
    }

    $arguments->{FILTERS} = $lazy->load() ;

    my $self = $class->SUPER::new($c, $arguments);

    return $self ;

}


1;

=head1 NAME

Catalyst::View::TT::Filters::LazyLoader - TT View Class with Template::Filters::LazyLoader support.

=head1 SYNOPSIS

 package MyApp::View::TT;
 
 use strict;
 use base 'Catalyst::View::TT::Filters::LazyLoader';
 
 __PACKAGE__->config({
    FILTERS_LAZYLOADER => {
        pkg => 'MyApp::TTFilters',
    },
 });

=head1 DESCRIPTION

TT View Class with Template::Filters::LazyLoader support.

=head1 METHOD

=head2 new

this class override new().

=head1 SEE ALSO

L<Template::Filters::LazyLoader>

=head1 AUTHOR

Tomohiro Teranishi E<lt>tomohiro.teranishi@gmail.comE<gt>

=cut
