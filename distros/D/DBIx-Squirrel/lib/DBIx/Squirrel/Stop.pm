use v5.36;

package DBIx::Squirrel::Stop;

use Exporter qw(import);

use Ekorn::Pipeline::Stop qw(Stop);

# A facade over Ekorn::Pipeline::Stop: a subclass of it, exporting
# DBIx::Squirrel's own list of its functions, imported from it by
# name, so a name Ekorn::Pipeline drops fails here, as the module
# loads, and one it adds isn't exported until it's listed here.
our @ISA    = ('Ekorn::Pipeline::Stop');
our @EXPORT = qw(Stop);                    ## no critic (Modules::ProhibitAutomaticExportation)

1;
__END__

=encoding utf8

=head1 NAME

DBIx::Squirrel::Stop - end a DBIx::Squirrel pipeline early

=head1 SYNOPSIS

    use DBIx::Squirrel::Stop;

    # In a stage of a pipeline
    sub ($row) { Stop() if $done; ... }

    # Stop, passing on a last value
    sub ($row) { $row->{id} == $wanted ? Stop($row) : () }

    # The same, without importing Stop
    sub ($row) { DBIx::Squirrel::Stop->throw if $done; ... }

=head1 DESCRIPTION

DBIx::Squirrel's pipeline is L<Ekorn::Pipeline>'s, and this module is
DBIx::Squirrel's name for L<Ekorn::Pipeline::Stop>, which describes the
stop in full. It's a subclass of it, and exports C<Stop>, by default:
Ekorn's function, from a list of DBIx::Squirrel's own. It's here to
stay, so code written with it keeps working.

A stop is the exception that ends a pipeline early and quietly. The
rest of the stage that throws it doesn't run. The values already out of
the pipeline are kept, the values the stop carries go on through the
stages after it, and nothing else is processed.

=head1 FUNCTIONS

=head2 Stop

    Stop();
    Stop(@values);

Throws a stop carrying C<@values>. It's L<Ekorn::Pipeline::Stop/Stop>,
so the stop is an Ekorn::Pipeline::Stop. To keep it out of your
namespace:

    use DBIx::Squirrel::Stop ();

=head1 METHODS

=head2 throw

    DBIx::Squirrel::Stop->throw(@values);
    My::Stop->throw(@values);

Inherited from L<Ekorn::Pipeline::Stop/throw>: throws a stop carrying
C<@values>, blessed into the class it was called on. A subclass of
DBIx::Squirrel::Stop is a subclass of Ekorn::Pipeline::Stop too, so the
pipeline stops for it.

=head2 Catching errors in a stage

A stage that catches errors itself, with C<eval> or C<try>, should
throw a stop on again. Check for Ekorn::Pipeline::Stop, which every
stop is, whether thrown with C<Stop>, by this class, or by a canned
stage such as C<take>:

    sub ($row) {
        try { ... }
        catch ($e) {
            die $e if $e isa 'Ekorn::Pipeline::Stop';
            ...
        }
    }

Checking for DBIx::Squirrel::Stop would miss the stops that aren't
thrown by this class.

=head1 DIAGNOSTICS

=over

=item Stop used outside a pipeline

A stop was thrown where no pipeline was running to catch it.

=back

=head1 SEE ALSO

L<Ekorn::Pipeline::Stop>, L<DBIx::Squirrel>

=head1 AUTHOR

Iain Campbell E<lt>cpanic@cpan.orgE<gt>

=head1 LICENSE

Copyright (c) 2024-2026 by Iain Campbell.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

=cut
