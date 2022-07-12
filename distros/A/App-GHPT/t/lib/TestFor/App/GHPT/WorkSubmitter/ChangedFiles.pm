package TestFor::App::GHPT::WorkSubmitter::ChangedFiles;

use App::GHPT::Wrapper::OurTest::Class::Moose;
use App::GHPT::WorkSubmitter::ChangedFilesFactory ();

########################################################################

has branch_name => (
    is      => 'ro',
    default => sub { return 'test-' . time . '-' . $$; },
);

sub test_startup ( $self, @ ) {
    unless ( $ENV{RUN_CRAZY_GIT_TESTS} ) {
        $self->test_skip(q{The RUN_CRAZY_GIT_TESTS env var is not set});
        return;
    }

    system( 'git', 'checkout', '-b', $self->branch_name );

    _delete( 't/test-data/todelete1', 1 );
    _delete( 't/test-data/todelete2', 1 );
    _commit('delete files');
    _create( 't/test-data/tocreate1', 'example1', 1 );
    _create( 't/test-data/tocreate2', 'example2', 1 );
    _commit('add files');
    _append( 't/test-data/tomodify1', 'extra text', 1 );
    _append( 't/test-data/tomodify2', 'extra text', 1 );
    _commit('modify files');

    # some modifications that are not committed.  These should not
    # be visible to the diff
    _create( 't/test-data/not-committed-tocreate', 'create' );
    _append( 't/test-data/not-committed-tomodify', 'modify' );
    _delete( 't/test-data/not-committed-todelete', 'delete' );
}

sub _create ( $filename, $text, $git_add = 0 ) {
    _write( $filename, '>', $text );
    system( 'git', 'add', $filename ) if $git_add;
}

sub _append ( $filename, $text, $git_add = 0 ) {
    _write( $filename, '>>', $text );
    system( 'git', 'add', $filename ) if $git_add;
}

sub _delete ( $filename, $git_add = 0 ) {
    unlink($filename);
    system( 'git', 'add', $filename ) if $git_add;
}

sub _write ( $filename, $mode, $text ) {
    ## no critic (InputOutput::RequireBriefOpen)
    my $fh;
    open $fh, $mode, $filename;
    print $fh $text;
    close $fh;
}

sub _commit ($message) {
    system( 'git', 'commit', '-m', $message );
}

sub test_shutdown ( $self, @ ) {

    # git reset everything back the way it was, but
    # manually fix everything so we don't mess up anything else in
    # the working tree / staging area
    system( 'git', 'reset',    'main', 't/test-data/not-committed-todelete' );
    system( 'git', 'checkout', 't/test-data/not-committed-tomodify' );
    system( 'git', 'checkout', 't/test-data/not-committed-todelete' );
    unlink('t/test-data/not-committed-tocreate');
    system( 'git', 'checkout', 'main' );
    system( 'git', 'branch', '-D', $self->branch_name );
}

########################################################################

sub test_factory ( $self, @ ) {
    my $factory = App::GHPT::WorkSubmitter::ChangedFilesFactory->new(
        merge_to_branch_name => 'main',
    );
    my $changed_files = $factory->changed_files;

    isa_ok(
        $changed_files,
        'App::GHPT::WorkSubmitter::ChangedFiles',
    );

    my %expected = (
        'added_files' => [
            't/test-data/tocreate1',
            't/test-data/tocreate2',
        ],
        'deleted_files' => [
            't/test-data/todelete1',
            't/test-data/todelete2',
        ],
        'changed_files' => [
            't/test-data/tocreate1',
            't/test-data/tocreate2',
            't/test-data/tomodify1',
            't/test-data/tomodify2',
        ],
        'modified_files' => [
            't/test-data/tomodify1',
            't/test-data/tomodify2',
        ],
    );

    for my $key ( keys %expected ) {
        is_deeply [ sort $changed_files->$key->@* ], $expected{$key}, $key;
    }

    ok( $changed_files->changed_files_match(qr/tocreate/), 'matching' );
    ok( !$changed_files->changed_files_match(qr/fish/),    'not matching' );

    # this file has been changed but not committed, so it shouldn't match.
    ok(
        !$changed_files->changed_files_match(qr/committed/),
        'not committed not match'
    );
}

__PACKAGE__->meta->make_immutable;
1;
