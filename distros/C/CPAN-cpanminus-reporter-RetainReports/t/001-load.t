# -*- perl -*-
use strict;
use warnings;
use Cwd;
use Test::More;
use File::Spec;
use File::Temp ( qw| tempdir | );

BEGIN { use_ok( 'CPAN::cpanminus::reporter::RetainReports' ); }

{
    my $reporter = CPAN::cpanminus::reporter::RetainReports->new();
    ok(defined $reporter, "Inherited constructor returned defined object");
    isa_ok($reporter, 'CPAN::cpanminus::reporter::RetainReports');
    
    note("Demonstrate that all methods inherited from App::cpanminus::reporter can be called");
    
    isa_ok($reporter, 'App::cpanminus::reporter');
    
    can_ok('CPAN::cpanminus::reporter::RetainReports', qw|
          new config verbose quiet only exclude build_dir build_logfile
          get_author get_meta_for
    | );
    
    like $reporter->build_dir, qr/\.cpanm$/, 'build_dir properly set';
    like $reporter->build_logfile, qr/build\.log$/, 'build_logfile properly set';
    
    my $ret;
    is $reporter->quiet, undef,    'quiet() is not set by default';
    ok $ret = $reporter->quiet(1), 'setting quiet() to true';
    is $reporter->quiet, 1,        'quiet() now set to true';
    is $ret, $reporter->quiet,     'quiet() was properly returned when set';
    
    is $reporter->verbose, undef,    'verbose() is not set by default';
    ok $ret = $reporter->verbose(1), 'setting verbose() to true';
    is $reporter->verbose, 1,        'verbose() now set to true';
    is $ret, $reporter->verbose,     'verbose() was properly returned when set';
    
    is $reporter->force, undef,    'force() is not set by default';
    ok $ret = $reporter->force(1), 'setting force() to true';
    is $reporter->force, 1,        'force() now set to true';
    is $ret, $reporter->force,     'force() was properly returned when set';
    
    is $reporter->exclude, undef, 'exclude() is not set by default';
    ok $ret = $reporter->exclude('Foo, Bar::Baz,Meep-Moop'), 'setting exclude()';
    is_deeply(
        [ sort keys %{ $reporter->exclude } ],
        [ qw(Bar-Baz Foo Meep-Moop) ],
        'exclude() now set to the proper dists'
    );
    is_deeply $ret, $reporter->exclude, 'exclude() was properly returned when set';
    
    is $reporter->only, undef, 'only() is not set by default';
    ok $ret = $reporter->only('Meep::Moop,Bar-Baz , Foo'), 'setting only()';
    is_deeply(
        [ sort keys %{ $reporter->only } ],
        [ qw(Bar-Baz Foo Meep-Moop) ],
        'only() now set to the proper dists'
    );
    is_deeply $ret, $reporter->only, 'only() was properly returned when set';
    
    ok my $config = $reporter->config, 'object has config()';
    isa_ok $config, 'CPAN::Testers::Common::Client::Config';
}

{
    my $reporter = CPAN::cpanminus::reporter::RetainReports->new(verbose => 1);
    ok(defined $reporter, "Inherited constructor returned defined object");
    isa_ok($reporter, 'CPAN::cpanminus::reporter::RetainReports');

    note("Demonstrate that arguments passed to constructor work as expected");
    ok($reporter->verbose, "'verbose' correctly set in object()");

    note("Demonstrate that overridden methods or other methods not found in App-cpanminus-reporter are working");
    my $tdir = tempdir( CLEANUP => 1 );
    my $rdir = $reporter->set_report_dir($tdir);
    is($rdir, $tdir, "set_report_dir() worked as expected");

    my $gdir = $reporter->get_report_dir();
    is($gdir, $rdir, "get_report_dir worked as expected");

    my ($uri, $rf);
    my $author = 'JKEENAN';
    my $first_id =  substr($author, 0, 1);
    my $second_id = substr($author, 0, 2);
    my $distro = 'Perl-Download-FTP';
    my $distro_version = '0.02';
    my $tarball = "${distro}-${distro_version}.tar.gz";
    $uri = qq|http://www.cpan.org/authors/id/$first_id/$second_id/$author/${distro}-${distro_version}.tar.gz|;
    $rf = $reporter->parse_uri($uri);
    ok($rf, "parse_uri() returned true value");
    is($reporter->distname(), $distro, "distname() returned expected value");
    is($reporter->distversion(), $distro_version, "distversion() returned expected value");
    is($reporter->distfile(), File::Spec->catfile($author, $tarball), "distfile() returned expected value");
    is($reporter->author(), $author, "author() returned expected value");
}

{
    note("Testing 'file' scheme");

    my $reporter = CPAN::cpanminus::reporter::RetainReports->new(verbose => 1);
    ok(defined $reporter, "Inherited constructor returned defined object");
    isa_ok($reporter, 'CPAN::cpanminus::reporter::RetainReports');

    my ($uri, $rf);
    my $cwd = cwd();
    my $author = 'METATEST';
    my $first_id =  substr($author, 0, 1);
    my $second_id = substr($author, 0, 2);
    my $distro = 'Phony-PASS';
    my $distro_version = '0.01';
    my $tarball = "${distro}-${distro_version}.tar.gz";
    my $tarball_for_testing = File::Spec->catfile($cwd, 't', 'data',
        $first_id, $second_id, $author, $tarball);
    ok(-f $tarball_for_testing, "Located tarball '$tarball_for_testing'");
    $uri = qq|file://$tarball_for_testing|;
    $rf = $reporter->parse_uri($uri);
    ok($rf, "parse_uri() returned true value");
    my %expect = (
        distname => $distro,
        distversion => $distro_version,
        distfile => File::Spec->catfile($author, $tarball),
        author => $author,
    );
    is($reporter->distname(), $expect{distname},
        "distname() returned expected value: $expect{distname}");
    is($reporter->distversion(), $expect{distversion},
        "distversion() returned expected value: $expect{distversion}");
    is($reporter->distfile(), $expect{distfile},
        "distfile() returned expected value: $expect{distfile}");
    ok( defined $reporter->author(),
        "author() returned defined value, as expected");
    is($reporter->author(), $expect{author},
        "author() returned expected value: $expect{author}");
}

done_testing;
