use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;
use FindBin qw($Bin);

use DBIx::Squirrel;
use DBIx::Squirrel::Errors;
use DBIx::Squirrel::Context;
use DBIx::Squirrel::Gather ();
use DBIx::Squirrel::Iterator;
use DBIx::Squirrel::Result;
use DBIx::Squirrel::Results;
use Ekorn::Pipeline qw();
use DBIx::Squirrel::Placeholders;
use DBIx::Squirrel::Stages::Batch ();
use DBIx::Squirrel::Stages::Flow  ();
use DBIx::Squirrel::Stages::Rows  ();
use DBIx::Squirrel::Stages::Taps  ();
use DBIx::Squirrel::Stop          ();
use DBIx::Squirrel::Sugar         ();
use DBIx::Squirrel::Util;

# Imported functions are cleaned out of each package, so they can't be
# called as methods. Each is looked for in the package's own symbol
# table, not with can, which would find one a parent class defines: DBI
# 1.643, as Debian and Ubuntu ship it, imports Carp's croak (1.656
# doesn't), which DBIx::Squirrel, a subclass of the DBI, would then seem
# to have.
my %imported = (
    'DBIx::Squirrel'     => [qw(canonical croak is_hashref split_attrs)],
    'DBIx::Squirrel::db' => [
        qw(
            all          at_caller     canonical      croak       croakf
            expand_lists failed        in_method      is_arrayref is_coderef
            is_hashref   is_ref        iterator_going key_of
            max          shift_attrs   split_attrs    split_stages
            study_sql    unwrap_values values_for     values_taken
        ),
    ],
    'DBIx::Squirrel::Context'  => [qw(is_plain_hashref)],
    'DBIx::Squirrel::Errors'   => [qw(croak  is_ref)],
    'DBIx::Squirrel::Gather'   => [qw(croakf is_coderef)],
    'DBIx::Squirrel::Iterator' => [
        qw(
            at_caller      croakf       is_coderef is_plain_arrayref
            iterator_going split_stages weaken
        ),
    ],
    'DBIx::Squirrel::Placeholders' =>
        [qw(any croakf is_arrayref is_hashref is_plain_ref max uniq)],
    'DBIx::Squirrel::Result' =>
        [qw(croakf install_sub is_name sha1_hex set_subname)],
    'DBIx::Squirrel::Results'       => [qw(at_caller croakf)],
    'DBIx::Squirrel::Stages::Batch' => [qw(croakf    gather is_coderef)],
    'DBIx::Squirrel::Stages::Flow'  => [qw(croakf    gather is_coderef)],
    'DBIx::Squirrel::Stages::Rows'  =>
        [qw(croakf gather is_plain_arrayref is_plain_hashref)],
    'DBIx::Squirrel::Stages::Taps' =>
        [qw(croakf gather is_coderef is_plain_scalarref openhandle)],
    'DBIx::Squirrel::Stop'  => [qw(croak)],
    'DBIx::Squirrel::Sugar' => [
        qw(
            at_caller  croakf  install_sub is_arrayref is_coderef
            is_hashref is_name is_ref      shift_attrs split_stages
        ),
    ],
    'DBIx::Squirrel::st' => [
        qw(
            at_caller croakf       is_arrayref   is_numbered key_of
            pairs     place_values unwrap_values values_for  values_taken
        ),
    ],
    'DBIx::Squirrel::Util' => [
        qw(croakf is_arrayref is_coderef is_hashref is_ref set_subname subname),
    ],
);

# True if a package defines a sub of its own of that name.
sub defines ($package, $name) {
    no strict 'refs';    ## no critic (TestingAndDebugging::ProhibitNoStrict)
    return defined &{ "${package}::$name" };
}

for my $pkg (sort keys %imported) {
    subtest $pkg => sub {
        ok !defines($pkg, $_), "no $_" for @{ $imported{$pkg} };
    };
}

subtest 'what the packages need is kept' => sub {
    ok +DBIx::Squirrel::Gather->can('import'),       'Gather can export';
    ok +DBIx::Squirrel::Gather->can('gather'),       'and keeps gather';
    ok +DBIx::Squirrel::Placeholders->can('import'), 'Placeholders can export';
    my @stages = map { "DBIx::Squirrel::Stages::$_" } qw(Batch Flow Rows Taps);
    ok $_->can('import'),                       "$_ can export" for @stages;
    ok +DBIx::Squirrel::Stop->can('import'),    'Stop can export';
    ok +DBIx::Squirrel::Sugar->can('import'),   'Sugar can export';
    ok +DBIx::Squirrel::Sugar->can('database'), 'and keeps database';
    ok +DBIx::Squirrel::Util->can('import'),    'Util can export';

    is '' . dies { DBIx::Squirrel::Stop::Stop() },
        "Stop used outside a pipeline\n",
        'a stop explains itself as a string';
};

subtest 'both handle classes inherit pipe and tap' => sub {
    for my $class (qw(DBIx::Squirrel::db DBIx::Squirrel::st)) {
        isa_ok $class, ['Ekorn::Pipeline::Pipes'], $class;
        ref_is $class->can($_), Ekorn::Pipeline::Pipes->can($_), "$class can $_"
            for qw(pipe tap);
    }
};

# A package's export lists: its @EXPORT, @EXPORT_OK and %EXPORT_TAGS.
sub exports_of ($package) {
    no strict 'refs';    ## no critic (TestingAndDebugging::ProhibitNoStrict)
    return (
        [@{ "${package}::EXPORT" }],
        [@{ "${package}::EXPORT_OK" }],
        {%{ "${package}::EXPORT_TAGS" }},
    );
}

# The pipeline is Ekorn::Pipeline's, behind a facade of DBIx::Squirrel's
# names: each exports Ekorn's functions from a list of its own, which
# stays as documented, and names only functions Ekorn still exports,
# but for those DBIx::Squirrel adds of its own, such as is_stop (roadmap
# 2026-0060).
subtest 'the facades follow Ekorn::Pipeline' => sub {
    # DBIx::Squirrel's own lists, as its POD documents them: @EXPORT, and
    # the rest of @EXPORT_OK, all of which an :all tag holds.
    my %exports = (
        'Gather'        => [[qw(gather)]],
        'Stop'          => [[qw(Stop)],          [qw(is_stop)]],
        'Stages::Batch' => [[qw(batch collect)], []],
        'Stages::Flow'  => [
            [qw(take drop)],
            [
                qw(take_first take_last take_single take_while drop_while take_if drop_if)
            ],
        ],
        'Stages::Taps' => [[qw(peek count_into)], [qw(dump_to tee)]],
    );

    # The functions a facade has of its own, not Ekorn's.
    my %own = ('Stop' => {is_stop => 1});
    for my $name (sort keys %exports) {
        my($ours,    $theirs) = ("DBIx::Squirrel::$name", "Ekorn::Pipeline::$name");
        my($default, $more)   = @{ $exports{$name} };
        my($export, $ok, $tags) = exports_of($ours);
        is $export, $default, "$ours\'s \@EXPORT";
        if (defined $more) {
            is $ok, [@$default, @$more], "$ours\'s \@EXPORT_OK";
            is $tags, {all => [@$default, @$more]}, "$ours\'s %EXPORT_TAGS";
        }
        else {
            is $ok, [], "$ours has no \@EXPORT_OK";
            is $tags, {}, "$ours has no %EXPORT_TAGS";
        }
        my($their_export, $their_ok) = exports_of($theirs);
        my %theirs = map { $_ => 1 } @$their_export, @$their_ok;
        for my $function (@$default, @{ $more // [] }) {
            if ($own{$name}{$function}) {
                ok !$theirs->can($function)
                    || $ours->can($function) != $theirs->can($function),
                    "$ours\'s $function is its own";
                next;
            }
            ok $theirs{$function}, "$theirs exports $function";
            ref_is $ours->can($function), $theirs->can($function),
                "$ours\'s $function is $theirs\'s";
        }
    }
    # The distribution doesn't ship them. A copy that version 2 installed
    # stays where it was, as installing never removes a file, so this
    # looks in the distribution, not @INC, where requiring one succeeds.
    for my $gone (qw(Pipeline Pipes)) {
        my @shipped
            = grep { -e "$Bin/../$_/DBIx/Squirrel/$gone.pm" } qw(lib blib/lib);
        is \@shipped, [], "DBIx::Squirrel::$gone is no longer shipped";
    }
    ok !DBIx::Squirrel::Stop->isa('Ekorn::Pipeline::Stop'),
        'and Stop is no subclass of Ekorn\'s';
};

done_testing;
