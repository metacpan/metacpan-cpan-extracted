use v5.36;

package DBIx::Squirrel::Tooling;

use Exporter qw(import);

# What each module exports, by default or on request, imported here, so
# Exporter can export it again: from DBIx::Squirrel's own module where
# it has one, and from Ekorn::Pipeline's only where it has none, so a
# name both export is DBIx::Squirrel's (roadmap 2026-0025, D6). Each is
# imported once, by name: gather is Factories' word too, and comes from
# DBIx::Squirrel::Gather. t/28-tooling.t checks that each tag below
# holds every name its module exports, and that each name both packages
# export is one sub.
use Ekorn::Pipeline::Sources   qw(:all);
use Ekorn::Pipeline::Sinks     qw(:all);
use Ekorn::Pipeline::JSON      qw(:all);
use Ekorn::Pipeline::Factories qw(
    pipeline stage source generator yield
    sink_one sink_many);

use DBIx::Squirrel::Stop          qw(Stop);
use DBIx::Squirrel::Gather        qw(gather);
use DBIx::Squirrel::Context       qw(iterator result_number result_original);
use DBIx::Squirrel::Stages::Flow  qw(:all);
use DBIx::Squirrel::Stages::Batch qw(:all);
use DBIx::Squirrel::Stages::Taps  qw(:all);
use DBIx::Squirrel::Stages::Rows  qw(:all);

our %EXPORT_TAGS = (
    core => [qw(Stop gather)],
    flow => [
        qw(take take_first take_last take_single take_if take_while),
        qw(drop drop_if    drop_while),
    ],
    batch   => [qw(batch      collect)],
    taps    => [qw(peek       count_into dump_to)],
    rows    => [qw(pluck      as_hash)],
    context => [qw(iterator   result_number result_original)],
    sources => [qw(from_array from_fh from_file counter)],
    sinks   => [
        qw(count_items keep keep_all keep_first keep_last keep_single),
        qw(to_fh to_file),
    ],
    json  => [qw(from_json from_jsonl to_json to_jsonl)],
    words => [
        qw(pipeline stage gather source generator yield),
        qw(sink_one sink_many),
    ],
);
$EXPORT_TAGS{stages} = [map { @{ $EXPORT_TAGS{$_} } } qw(flow batch taps rows)];

# Every name once: gather is in both :core and :words.
our @EXPORT_OK = do {
    my %seen;
    grep { !$seen{$_}++ }
        map { @{ $EXPORT_TAGS{$_} } }
        qw(core stages context sources sinks json words);
};
$EXPORT_TAGS{all} = [@EXPORT_OK];

1;

__END__

=encoding utf8

=head1 NAME

DBIx::Squirrel::Tooling - DBIx::Squirrel's stages, sinks and words, from one module

=head1 SYNOPSIS

    use DBIx::Squirrel;
    use DBIx::Squirrel::Tooling qw(:all);

    my @names = $dbh->iterate(
        'SELECT name, plays FROM track ORDER BY plays DESC',
        take_if { $_->[1] > 6000 },
        pluck('name'),
        keep_all,
    );

    use DBIx::Squirrel::Tooling qw(:stages :sinks);    # or only some
    use DBIx::Squirrel::Tooling qw(pluck keep_all);    # or by name

=head1 DESCRIPTION

What a caller uses to do work with DBIx::Squirrel is made in several
modules: stages in L<DBIx::Squirrel::Stages::Flow>, Batch, Taps and
Rows, C<Stop>, C<gather> and the run's context in modules of their
own, sinks, sources and words in Ekorn::Pipeline's, and JSON's sources,
sinks and stages in L<Ekorn::Pipeline::JSON>. This module
exports all of them, by the tags below, so there's one module to
import from, and nothing to remember about which module makes which.

Its tags are L<Ekorn::Pipeline::Tooling>'s, with DBIx::Squirrel's own
C<:rows> and C<:context> besides, so a caller moving between the two
finds the same words. Where both export a name, this module's is
DBIx::Squirrel's: today, each such name is the same sub in both, so
importing a name from both does no harm.

Each name is the very sub its own module exports, prototype and all,
so C<take_if { ... }> and C<stage { ... }> parse as they do imported
from there.

Nothing is exported by default: ask for tags, or names, or both. An
unknown tag or name is reported by Exporter, as it is for any module.

It leaves out what's for extending the package rather than using it,
such as C<is_stage>, from L<Ekorn::Pipeline>, and C<croakf>, from
L<DBIx::Squirrel::Errors>: import those from their own modules. And it
leaves out what's configured on C<use>: L<DBIx::Squirrel::Sugar>,
whose import makes functions for your databases and statements, and
L<Ekorn::Pipeline::Operators>, a pragma, which puts C<|> in force only
in the scope that uses it, by name.

=head1 TAGS

=over

=item C<:core>

C<Stop>, from L<DBIx::Squirrel::Stop>, and C<gather>, from
L<DBIx::Squirrel::Gather>.

=item C<:flow>

Everything L<DBIx::Squirrel::Stages::Flow> exports: C<take>,
C<take_first>, C<take_last>, C<take_single>, C<take_if>,
C<take_while>, C<drop>, C<drop_if> and C<drop_while>.

=item C<:batch>

Everything L<DBIx::Squirrel::Stages::Batch> exports: C<batch> and
C<collect>.

=item C<:taps>

Everything L<DBIx::Squirrel::Stages::Taps> exports: C<peek>,
C<count_into> and C<dump_to>.

=item C<:rows>

Everything L<DBIx::Squirrel::Stages::Rows> exports: C<pluck> and
C<as_hash>.

=item C<:stages>

C<:flow>, C<:batch>, C<:taps> and C<:rows>.

=item C<:context>

Everything L<DBIx::Squirrel::Context> exports: C<iterator>,
C<result_number> and C<result_original>.

=item C<:sources>

Everything L<Ekorn::Pipeline::Sources> exports: C<from_array>,
C<from_fh>, C<from_file> and C<counter>.

=item C<:sinks>

Everything L<Ekorn::Pipeline::Sinks> exports: C<count_items>, C<keep>,
C<keep_all>, C<keep_first>, C<keep_last>, C<keep_single>, C<to_fh> and
C<to_file>.

=item C<:json>

Everything L<Ekorn::Pipeline::JSON> exports: C<from_json>,
C<from_jsonl>, C<to_json> and C<to_jsonl>. L<JSON> exports a
C<from_json> and a C<to_json> of its own, by default, so a module using
both imports C<:all> from only one of them.

=item C<:words>

Everything L<Ekorn::Pipeline::Factories> exports: C<pipeline>,
C<stage>, C<gather>, C<source>, C<generator> and C<yield>, C<sink_one>
and C<sink_many>.

=item C<:all>

All of the above.

=back

A tag holds every name its module exports, by default or on request.
What a tag holds is part of the interface: a name may be added to one
in a release that only adds, but is dropped or renamed only in a major
release.

=head1 SEE ALSO

L<DBIx::Squirrel>, L<Ekorn::Pipeline::Tooling>,
L<DBIx::Squirrel::Manual::Reference>

=head1 AUTHOR

Iain Campbell E<lt>cpanic@cpan.orgE<gt>

=head1 LICENSE

Copyright (c) 2024-2026 by Iain Campbell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
