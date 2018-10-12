use strict;
use warnings;
use lib '.';

use t::helper;
use Test::More 0.98;

use App::CpanfileSlipstop::Resolver;
use App::CpanfileSlipstop::Writer;

sub run_slipstop {
    my ($name, $stopper) = @_;

    my $resolver = App::CpanfileSlipstop::Resolver->new(
        cpanfile => test_cpanfile($name),
        snapshot => test_snapshot($name),
    );
    $resolver->read_cpanfile_requirements;
    $resolver->merge_snapshot_versions(+{
        minimum => 'add_minimum',
        maximum => 'add_maximum',
        exact   => 'exact_version',
    }->{$stopper});

    no warnings 'redefine';
    my $last_document;
    local *App::CpanfileSlipstop::Writer::writedown_cpanfile = sub {
        my ($self, $doc) = @_;
        $last_document = $doc;
    };

    my $writer = App::CpanfileSlipstop::Writer->new(
        cpanfile_path => test_file($name . '.cpanfile')->stringify,
    );
    $writer->set_versions(
        sub { $resolver->get_version_range($_[0]) },
        sub {},
    );

    is $last_document->serialize,
        test_file(join('.', $name, 'cpanfile', $stopper))->slurp;
}

subtest simple => sub {
    run_slipstop('simple', 'minimum');
    run_slipstop('simple', 'exact');
    run_slipstop('simple', 'maximum');
};

subtest indent => sub {
    run_slipstop('indent', 'minimum');
    run_slipstop('indent', 'exact');
};

subtest literals => sub {
    run_slipstop('literals', 'minimum');
    run_slipstop('literals', 'exact');
};

subtest phases => sub {
    run_slipstop('phases', 'minimum');
};

subtest types => sub {
    run_slipstop('types', 'exact');
};

subtest versioned => sub {
    run_slipstop('versioned', 'minimum');
    run_slipstop('versioned', 'exact');
    run_slipstop('versioned', 'maximum');
};

done_testing;
