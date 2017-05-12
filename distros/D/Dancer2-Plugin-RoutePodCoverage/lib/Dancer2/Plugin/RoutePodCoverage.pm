package Dancer2::Plugin::RoutePodCoverage;

use strict;
use warnings;

use Dancer2;
use Dancer2::Plugin;
use Pod::Simple::Search;
use Pod::Simple::SimpleTree;
use Carp 'croak';

our $VERSION = '0.071';

my $PACKAGES_TO_COVER = [];

register 'packages_to_cover' => sub {
    my ( $dsl, $packages_to_cover ) = @_;
    croak "no package(s) provided for 'packages_to_cover' "
      if ( !$packages_to_cover
        || ref $packages_to_cover ne 'ARRAY'
        || !@$packages_to_cover );
    $PACKAGES_TO_COVER = $packages_to_cover;
};

register 'routes_pod_coverage' => sub {
    return _get_routes(@_);
};

sub _get_routes {
    my ($dsl) = @_;
    my @apps = @{ $dsl->runner->apps };
    my $all_routes = {};

    for my $app (@apps) {
        next
          if ( @$PACKAGES_TO_COVER && !grep { $app->name eq $_ }
            @$PACKAGES_TO_COVER );
        my $routes           = $app->routes;
        my $available_routes = [];
        foreach my $method ( sort { $b cmp $a } keys %$routes ) {
            foreach my $r ( @{ $routes->{$method} } ) {

                # we don't need pod coverage for head
                next if $method eq 'head';
                push @$available_routes, $method . ' ' . $r->spec_route;
            }
        }
        next unless @$available_routes;

        ## copy unreferenced array
        $all_routes->{ $app->name }{routes} = [@$available_routes];

        my $undocumented_routes = [];
        my $file                = Pod::Simple::Search->new->find( $app->name );
        if ($file) {
            $all_routes->{ $app->name }{ has_pod } = 1;
            my $parser       = Pod::Simple::SimpleTree->new->parse_file($file);
            my $pod_dataref  = $parser->root;
            my $found_routes = {};
            for ( my $i = 0 ; $i < @$available_routes ; $i++ ) {

                my $r          = $available_routes->[$i];
                my $app_string = lc $r;
                $app_string =~ s/\*/_REPLACED_STAR_/g;

                for ( my $idx = 0 ; $idx < @$pod_dataref ; $idx++ ) {
                    my $pod_part = $pod_dataref->[$idx];

                    next if ref $pod_part ne 'ARRAY';
                    foreach my $ref_part (@$pod_part) {
                        if (ref($ref_part) eq "ARRAY") {
                            push @$pod_dataref, $ref_part;
                        }
                    }

                    my $pod_string = lc $pod_part->[2];
                    $pod_string =~ s/['|"|\s]+/ /g;
                    $pod_string =~ s/\s$//g;
                    $pod_string =~ s/\*/_REPLACED_STAR_/g;
                    if ( $pod_string =~ m/^$app_string$/ ) {
                        $found_routes->{$app_string} = 1;
                        next;
                    }
                }
                if ( !$found_routes->{$app_string} ) {
                    push @$undocumented_routes, $r;
                }
            }
        }
        else { ### no POD found
            $all_routes->{ $app->name }{ has_pod } = 0;
        }
        if (@$undocumented_routes) {
            $all_routes->{ $app->name }{undocumented_routes} = $undocumented_routes;
        }
        elsif (! $all_routes->{ $app->name }{ has_pod }
            && @{$all_routes->{ $app->name }{routes}} ){
            ## copy dereferenced array
            $all_routes->{ $app->name }{undocumented_routes} = [@{$all_routes->{ $app->name }{routes}}];
        }
    }
    return $all_routes;
}

register_plugin;

1;

__END__

=pod

=head1 NAME

Dancer2::Plugin::RoutePodCoverage - Plugin to verify pod coverage in our app routes.

=head1 SYNOPSYS

    package MyApp::Route;

    use Dancer2;
    use Dancer2::Plugin::RoutePodCoverage;

    get '/' => sub {
        my $routes_couverage = routes_pod_coverage();

        # or 

        packages_to_cover(['MYAPP::Routes','MYAPP::Routes::Something']);
        my $routes_couverage = routes_pod_coverage();

    };

=head1 DESCRIPTION

Plugin to verify pod coverage in our app routes.

=head1 KEYWORDS

=head2 packages_to_cover

Keyword to define which packages to check coverage

=head2 routes_pod_coverage

Keyword that returns all routes e all undocumented routes for each package of the app or packages defined with 'packages_to_cover' 

=head1 LICENSE

This module is released under the same terms as Perl itself.

=head1 AUTHOR

Dinis Rebolo C<< <drebolo@cpan.org> >>

=cut
