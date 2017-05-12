use strict;
use lib './t';
use Test::More tests => 6;
use TestAppPrecompile;
use File::Spec::Functions qw(catdir catfile rel2abs);

# get a temp directory that we can later look into
# to find the pre-compiled templates
my $tt_dir = catdir('t', 'include1', 'TestAppIncludePath');
my $file   = rel2abs(catfile($tt_dir, 'test_mode.tmpl'));

test_success('tmpl');
test_success(qr/\.(tt|tmpl|html)$/);
test_success(sub { rel2abs($_[0]) eq $file });

test_failure('nottmpl');
test_failure(qr/\.(nottmpl)$/);
test_failure(sub { rel2abs($_[0]) eq 'blahblah' });


sub test_success {
    my $cgiapp = TestAppPrecompile->new(PARAMS => {
            TEMPLATE_PRECOMPILE_FILETEST => shift,
            TT_DIR => $tt_dir,
    });
    my $tt     = $cgiapp->tt_obj;

    # make sure we have this internally cached in our TT obj
    # This is kinda dirty since we are peeking pretty far into TT's internals
    # but it doesn't expose this stuff externally
    is(
        rel2abs($tt->{SERVICE}->{CONTEXT}->{LOAD_TEMPLATES}->[0]->{HEAD}->[1]),
        $file,
        'file is cached'
    );
}

sub test_failure {
    my $cgiapp = TestAppPrecompile->new(PARAMS => {
            TEMPLATE_PRECOMPILE_FILETEST => shift,
            TT_DIR => $tt_dir,
    });
    my $tt     = $cgiapp->tt_obj;

    # make sure we have this internally cached in our TT obj
    # This is kinda dirty since we are peeking pretty far into TT's internals
    # but it doesn't expose this stuff externally
    is(
        $tt->{SERVICE}->{CONTEXT}->{LOAD_TEMPLATES}->[0]->{HEAD}->[1],
        undef,
        'file is not cached'
    );
}
