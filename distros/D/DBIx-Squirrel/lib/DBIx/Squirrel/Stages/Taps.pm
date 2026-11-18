use v5.36;

package DBIx::Squirrel::Stages::Taps;

use Exporter qw(import);

use Ekorn::Pipeline::Stages::Taps qw(peek count_into dump_to tee);

# A facade over Ekorn::Pipeline::Stages::Taps, exporting DBIx::Squirrel's
# own list of its functions, imported from it by name, so a name
# Ekorn::Pipeline drops fails here, as the module loads, and one it
# adds isn't exported until it's listed here.
our @EXPORT      = qw(peek count_into);          ## no critic (Modules::ProhibitAutomaticExportation)
our @EXPORT_OK   = (@EXPORT, qw(dump_to tee));
our %EXPORT_TAGS = (all => \@EXPORT_OK);

1;
__END__

=encoding utf8

=head1 NAME

DBIx::Squirrel::Stages::Taps - stages run for their side effects: peek, count_into, dump_to and tee

=head1 SYNOPSIS

    use DBIx::Squirrel::Stages::Taps;

=head1 DESCRIPTION

DBIx::Squirrel's name for L<Ekorn::Pipeline::Stages::Taps>, which
describes its stages in full. It exports C<peek> and C<count_into> by
default, and C<dump_to> and C<tee> on request, or all four with
C<:all>. They're Ekorn's functions, from a list of DBIx::Squirrel's
own, so a stage added there reaches this module only once it's listed
here. The module is here to stay, beside DBIx::Squirrel's own stages,
such as L<DBIx::Squirrel::Stages::Rows>.

C<dump_to> is for debugging. Where Text::Redact::Secrets v1.x is
installed, it writes each secret that module's rules find as
C<*REDACTED*>, in the text it writes only: the value passed on is as it
came. The rules find a long, random password, token or key, such as
the password in a DSN, but not a short or ordinary password, so a dump
can still hold secrets. Without the module, or while
C<local $Ekorn::Pipeline::Stages::Taps::DumpSecrets = 1> is set, it
writes each value in full; with the module there but broken, it
croaks rather than write a dump. It doesn't escape control characters
in strings, so a value from outside can send escape sequences to a
terminal.

C<tee(@stages)> runs each value through a branch of stages, one run of
its own beside the main run, and passes the value on unchanged. The
branch shares the main run's context, so C<pluck> and C<as_hash> work
in it on a statement's rows. A stop in the branch ends only the
branch; a death in it kills the run. It costs a good deal more than
C<peek>, so it's for side jobs and debugging.

=head1 SEE ALSO

L<Ekorn::Pipeline::Stages::Taps>, L<DBIx::Squirrel>

=head1 AUTHOR

Iain Campbell E<lt>cpanic@cpan.orgE<gt>

=head1 LICENSE

Copyright (c) 2024-2026 by Iain Campbell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
