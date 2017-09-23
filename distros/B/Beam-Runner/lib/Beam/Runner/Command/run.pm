package Beam::Runner::Command::run;
our $VERSION = '0.014';
# ABSTRACT: Run the given service with the given arguments

#pod =head1 SYNOPSIS
#pod
#pod     beam run <container> <service> [<args...>]
#pod
#pod =head1 DESCRIPTION
#pod
#pod Run a service from the given container, passing in any arguments.
#pod
#pod =head1 SEE ALSO
#pod
#pod L<beam>, L<Beam::Runner::Command>, L<Beam::Runner>
#pod
#pod =cut

use strict;
use warnings;
use Beam::Wire;
use Path::Tiny qw( path );
use Scalar::Util qw( blessed );
use Beam::Runner::Util qw( find_container_path );

sub run {
    my ( $class, $container, $service_name, @args ) = @_;
    my $path = find_container_path( $container );
    my $wire = Beam::Wire->new(
        file => $path,
    );

    my $service = eval { $wire->get( $service_name ) };
    if ( $@ ) {
        if ( blessed $@ && $@->isa( 'Beam::Wire::Exception::NotFound' ) && $@->name eq $service_name ) {
            die sprintf qq{Could not find service "%s" in container "%s"\n},
                $service_name, $path;
        }
        die sprintf qq{Could not load service "%s" in container "%s": %s\n}, $service_name, $path, $@;
    }

    return $service->run( @args );
}

1;

__END__

=pod

=head1 NAME

Beam::Runner::Command::run - Run the given service with the given arguments

=head1 VERSION

version 0.014

=head1 SYNOPSIS

    beam run <container> <service> [<args...>]

=head1 DESCRIPTION

Run a service from the given container, passing in any arguments.

=head1 SEE ALSO

L<beam>, L<Beam::Runner::Command>, L<Beam::Runner>

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
