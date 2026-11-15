use v5.36;

package DBIx::Squirrel::Stop;

use Exporter qw(import);

use Ekorn::Pipeline::Stop qw(Stop);

# A plain re-export of Ekorn::Pipeline::Stop's function, from
# DBIx::Squirrel's own list of them, imported from it by name, so a name
# Ekorn::Pipeline drops fails here, as the module loads, and one it adds
# isn't exported until it's listed here.
our @EXPORT = qw(Stop);    ## no critic (Modules::ProhibitAutomaticExportation)

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
    sub ($row) { Ekorn::Pipeline::Stop->throw if $done; ... }

=head1 DESCRIPTION

DBIx::Squirrel's pipeline is L<Ekorn::Pipeline>'s. This module is
DBIx::Squirrel's name for L<Ekorn::Pipeline::Stop>'s function, which
that module describes in full. It exports C<Stop> by default. That's
Ekorn's function, from a list of DBIx::Squirrel's own. The module is
here to stay, so code written with it keeps working. It isn't a class:
a stop is an Ekorn::Pipeline::Stop.

A stop is the exception that ends a pipeline early and quietly. The
rest of the stage that throws it doesn't run. The values already out
of the pipeline are kept. The values the stop carries go on through
the stages after it, and nothing else is processed.

=head1 FUNCTIONS

=head2 Stop

    Stop();
    Stop(@values);

Throws a stop carrying C<@values>. The function is
L<Ekorn::Pipeline::Stop/Stop>, so the stop is an
Ekorn::Pipeline::Stop. To keep it out of your namespace:

    use DBIx::Squirrel::Stop ();

To throw one without importing C<Stop>, or to throw a subclass of your
own, use L<Ekorn::Pipeline::Stop/throw>:

    Ekorn::Pipeline::Stop->throw(@values);
    My::Stop->throw(@values);    # @ISA = ('Ekorn::Pipeline::Stop')

=head2 Catching errors in a stage

A stage that catches errors itself, with C<eval> or C<try>, should
throw a stop on again. Check for Ekorn::Pipeline::Stop. Every stop is
one, whether thrown with C<Stop>, with C<throw>, or by a canned stage
such as C<take>:

    sub ($row) {
        try { ... }
        catch ($e) {
            die $e if $e isa 'Ekorn::Pipeline::Stop';
            ...
        }
    }

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

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
