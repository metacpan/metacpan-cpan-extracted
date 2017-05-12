#!perl 

BEGIN {

    use strict;
    use warnings FATAL => 'all';
    use English '-no_match_vars';

    my %untestable = map {($_ => 1)} qw(
        Apache2::Controller::Directives
        Apache2::Controller::Test::Funk
    );

    use Test::More;
    use blib;
    my $test_libdir = File::Spec->catfile($FindBin::Bin, 'lib');
    eval "use lib '$test_libdir'";
    die $EVAL_ERROR if $EVAL_ERROR;
    use FindBin;
    use File::Find;
    use File::Spec;
    use YAML::Syck;

    my $a2c_libdir  = File::Spec->catfile($FindBin::Bin, '..', 'blib', 'lib');
    my @libs;
    my $wanted = sub {
        my $libsubpath = $File::Find::name;
        return if -d $libsubpath;
        $libsubpath =~ s{ \.pm \z }{}mxs;
        return if $libsubpath =~ m{ \. \w+ \z  }mxs; # oops, .swp and .exists
        $libsubpath =~ s{ \A .*? (Apache2/.*) \z }{$1}mxs;
        $libsubpath =~ s{ \A .*? (TestApp/.*) \z }{$1}mxs;
        (my $lib = $libsubpath) =~ s{ / }{::}mxsg;
        push @libs, $lib;
    };
    find($wanted, $a2c_libdir, $test_libdir);

    my @testable_libs = grep !exists $untestable{$_}, @libs;

    plan tests => scalar @testable_libs;

    use_ok($_) for @testable_libs;
}

diag('');
diag('Testing Apache2::Controller '.$Apache2::Controller::VERSION);
diag('Numeric version is '.$Apache2::Controller::VERSION->numify);
diag("Perl $], $^X");
