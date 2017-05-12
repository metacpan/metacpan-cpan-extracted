package App::Critique::Tester;

use strict;
use warnings;

use Path::Tiny ();
use IPC::Run   ();

use Git::Wrapper;

my ($PSUEDO_HOME, %TEMP_WORK_TREES);

BEGIN {
    $PSUEDO_HOME = Path::Tiny::tempdir( CLEANUP => 1 )
}

sub init_test_repo {

    # if we don't have git, why both testing
    Test::More::BAIL_OUT('Unable to find a `git` binary, not in path')
        unless Git::Wrapper->has_git_in_path;

    # grab the test files for the repo
    my $work_tree = Path::Tiny::tempdir( CLEANUP => 1 );
    _copy_full_tree(
        from => Path::Tiny->cwd->child('devel/git/test_repo'),
        to   => $work_tree,
    );

    # and then create, add and commit
    my $test_repo = Git::Wrapper->new( $work_tree );
    $test_repo->init;

    if ( my $err = $test_repo->ERR ) {
        # if we get an error from running
        # init, we likely have a bad setup
        # so bail again ...
        Test::More::BAIL_OUT('Unable to find a usable `git` binary, because: ' . join "\n" => @$err)
            unless 0 == scalar @$err;
    }

    $test_repo->add( '*' );
    $test_repo->commit({ message => 'initial commit' });

    $TEMP_WORK_TREES{ $test_repo } = $work_tree;

    return $test_repo;
}

sub run {
    my ($cmd, @args) = @_;

    my ($in, $out, $err);
    my @not_used_but_needed = IPC::Run::run(
        [ $^X, "$FindBin::Bin/../bin/critique", $cmd, @args ],
        \$in, \$out, \$err,
        init => sub {
            $ENV{CRITIQUE_HOME} = $PSUEDO_HOME->stringify;
        }
    ) or die "critique: $err";

    return ($out, $err);
}

sub test {
    my ($cmd_and_args, $good, $bad) = @_;

    my ($out, $err) = App::Critique::Tester::run( @$cmd_and_args );

    my $all = $out . $err;

    Test::More::like(   $all, $_, '... matched '.$_.' correctly'      ) foreach @$good;
    Test::More::unlike( $all, $_, '... failed match '.$_.' correctly' ) foreach @$bad;

    return ($out, $err);
}

sub teardown_test_repo {
    my $test_repo = $_[0];
    my $work_tree = delete $TEMP_WORK_TREES{ $test_repo };
    undef $work_tree;
}

END {
    undef $PSUEDO_HOME;
    foreach my $k ( keys %TEMP_WORK_TREES ) {
        my $work_tree = delete $TEMP_WORK_TREES{ $k };
        undef $work_tree;
    }
}

# ...

sub _copy_full_tree {
    my %args = @_;

    my $from = $args{from};
    my $to   = $args{to};

    foreach my $from_child ( $from->children( qr/^[^.]/ ) ) {
        my $to_child = $to->child( $from_child->basename );

        if ( -f $from_child ) {
            $from_child->copy( $to_child );
        }
        elsif ( -d $from_child ) {
            $to_child->mkpath unless -e $to_child;
            _copy_full_tree(
                from => $from_child,
                to   => $to_child,
            );
        }
    }
}

1;

__END__
