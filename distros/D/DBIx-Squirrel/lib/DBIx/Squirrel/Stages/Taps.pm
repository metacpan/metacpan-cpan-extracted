use v5.36;

package DBIx::Squirrel::Stages::Taps;

use Exporter qw(import);

use Ekorn::Pipeline::Stages::Taps qw(peek count_into dump_to tee);

our $VERSION = 'v4.3.0';

# A plain re-export of Ekorn::Pipeline::Stages::Taps's functions, from
# DBIx::Squirrel's own list of them, imported from it by name, so a name
# Ekorn::Pipeline drops fails here, as the module loads, and one it adds
# isn't exported until it's listed here.
our @EXPORT      = qw(peek count_into);          ## no critic (Modules::ProhibitAutomaticExportation)
our @EXPORT_OK   = (@EXPORT, qw(dump_to tee));
our %EXPORT_TAGS = (all => \@EXPORT_OK);

# True, dump_to writes each value in full, without redacting secrets.
# It's Ekorn::Pipeline's $DumpSecrets, which dump_to reads, under
# DBIx::Squirrel's name, so a caller needn't name Ekorn's package
# (roadmap 2026-0062).
#
# Why a tie, and not an alias, *DumpSecrets = \$Ekorn::...::DumpSecrets?
# Because callers set it with local, as they set Data::Dumper's, and
# local on an aliased package variable gives our name a fresh value of
# its own for the scope: Ekorn's never sees it, and dump_to goes on
# redacting. Through the tie, every read and write, local's included,
# goes to Ekorn's variable, and local puts Ekorn's value back as its
# scope ends. dump_to reads Ekorn's directly, so the tie costs nothing
# while dumping.
our $DumpSecrets;    ## no critic (Variables::ProhibitPackageVars)
tie $DumpSecrets, 'DBIx::Squirrel::Stages::Taps::DumpSecretsTie';

# The tie: each read and write goes to Ekorn::Pipeline's variable.
package              ## no critic (Modules::ProhibitMultiplePackages) its name on the next line, hidden from PAUSE
    DBIx::Squirrel::Stages::Taps::DumpSecretsTie {


    sub TIESCALAR ($class) {
        my $unused;
        return bless \$unused, $class;
    }


    sub FETCH ($self) {
        return $Ekorn::Pipeline::Stages::Taps::DumpSecrets;    ## no critic (Variables::ProhibitPackageVars) the variable it stands for
    }


    sub STORE ($self, $value) {
        $Ekorn::Pipeline::Stages::Taps::DumpSecrets = $value;    ## no critic (Variables::ProhibitPackageVars) the variable it stands for
        return;
    }
}

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
C<local $DBIx::Squirrel::Stages::Taps::DumpSecrets = 1> is set, it
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

=head1 VARIABLES

=head2 $DumpSecrets

    local $DBIx::Squirrel::Stages::Taps::DumpSecrets = 1;

True, C<dump_to> writes each value in full, without redacting secrets.
It's C<$Ekorn::Pipeline::Stages::Taps::DumpSecrets> under
DBIx::Squirrel's name, tied to it, so setting either, with C<local> or
without, sets both, and C<local> puts it back as its scope ends.

=head1 SEE ALSO

L<Ekorn::Pipeline::Stages::Taps>, L<DBIx::Squirrel>

=head1 AUTHOR

Iain Campbell E<lt>cpanic@cpan.orgE<gt>

=head1 LICENSE

Copyright (c) 2024-2026 by Iain Campbell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
