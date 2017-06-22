package Beam::Runner::Command::help;
our $VERSION = '0.013';
# ABSTRACT: Get help for the given service(s)

#pod =head1 SYNOPSIS
#pod
#pod     beam help <container> <service>
#pod
#pod =head1 DESCRIPTION
#pod
#pod Show the documentation for the given service from the given container.
#pod
#pod =head1 SEE ALSO
#pod
#pod L<beam>, L<Beam::Runner::Command>, L<Beam::Runner>
#pod
#pod =cut

use strict;
use warnings;
use Beam::Runner::Util qw( find_container_path );
use Pod::Usage qw( pod2usage );
use Pod::Find qw( pod_where );
use Beam::Wire;

sub run {
    my ( $class, $container, $service_name ) = @_;

    if ( !$container || !$service_name ) {
        return pod2usage(
            -message => 'ERROR: <container> and <service> are required',
            -input => pod_where( { -inc => 1 }, __PACKAGE__ ),
            -verbose => 0,
            -exitval => 1,
        );
    }

    my $path = find_container_path( $container );
    my $wire = Beam::Wire->new(
        file => $path,
    );
    my $service_conf = $wire->get_config( $service_name );
    die sprintf qq{Could not find service "%s" in container "%s"\n},
        $service_name, $path
        unless $service_conf;

    my %service_conf = %{ $wire->normalize_config( $service_conf ) };
    %service_conf = $wire->merge_config( %service_conf );
    my $pod_path = pod_where( { -inc => 1 }, $service_conf{class} );
    if ( !$pod_path ) {
        die "Could not find documentation for class '$service_conf{class}'\n";
    }
    pod2usage(
        -input => $pod_path,
        -verbose => 2,
        -exitval => 0,
    );
}

1;

__END__

=pod

=head1 NAME

Beam::Runner::Command::help - Get help for the given service(s)

=head1 VERSION

version 0.013

=head1 SYNOPSIS

    beam help <container> <service>

=head1 DESCRIPTION

Show the documentation for the given service from the given container.

=head1 SEE ALSO

L<beam>, L<Beam::Runner::Command>, L<Beam::Runner>

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
