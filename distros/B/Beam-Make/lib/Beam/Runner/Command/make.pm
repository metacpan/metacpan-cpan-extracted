package Beam::Runner::Command::make;
our $VERSION = '0.003';
# ABSTRACT: Build recipes and their dependencies

#pod =head1 SYNOPSIS
#pod
#pod     beam make [-v|-q] [<recipe...>|<variable...>]
#pod
#pod =head1 DESCRIPTION
#pod
#pod Run a service from the given container, passing in any arguments.
#pod
#pod =head1 ARGUMENTS
#pod
#pod =head2 <recipe>
#pod
#pod The name of a recipe in the C<Beamfile> to build. See L<Beam::Make> for
#pod how to write a C<Beamfile>.
#pod
#pod =head2 <variable>
#pod
#pod A C<< <NAME>=<VALUE> >> pair. Will be set as an environment variable for
#pod recipes to use.
#pod
#pod =head1 OPTIONS
#pod
#pod =head2 -v | --verbose
#pod
#pod Increase the verbosity of the output. By default, writes logs at the
#pod C<warning> level to C<STDERR>. May be specified up to 3 times for
#pod increased verbosity (C<info>, C<debug>, C<trace>).
#pod
#pod =head2 -q | --quiet
#pod
#pod Decrease the verbosity of the log output to C<error> (from the default,
#pod C<warning>).
#pod
#pod =head1 SEE ALSO
#pod
#pod L<Beam::Make>, L<beam>
#pod
#pod =cut

use v5.20;
use warnings;
use Beam::Make;
use Log::Any::Adapter;
use Getopt::Long qw( GetOptionsFromArray :config pass_through bundling );

sub run {
    my ( $class, @args ) = @_;
    my %opt = (
        verbose => 1,
        quiet => 0,
    );
    GetOptionsFromArray( \@args, \%opt,
        'verbose|v+',
        'quiet|q',
    );
    my @log_levels = qw( error warning info debug trace );
    Log::Any::Adapter->set( Stderr => ( log_level => $log_levels[ $opt{verbose} - $opt{quiet} ] ) );

    my $make = Beam::Make->new();
    $make->run( @args );
}

1;

__END__

=pod

=head1 NAME

Beam::Runner::Command::make - Build recipes and their dependencies

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    beam make [-v|-q] [<recipe...>|<variable...>]

=head1 DESCRIPTION

Run a service from the given container, passing in any arguments.

=head1 ARGUMENTS

=head2 <recipe>

The name of a recipe in the C<Beamfile> to build. See L<Beam::Make> for
how to write a C<Beamfile>.

=head2 <variable>

A C<< <NAME>=<VALUE> >> pair. Will be set as an environment variable for
recipes to use.

=head1 OPTIONS

=head2 -v | --verbose

Increase the verbosity of the output. By default, writes logs at the
C<warning> level to C<STDERR>. May be specified up to 3 times for
increased verbosity (C<info>, C<debug>, C<trace>).

=head2 -q | --quiet

Decrease the verbosity of the log output to C<error> (from the default,
C<warning>).

=head1 SEE ALSO

L<Beam::Make>, L<beam>

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
