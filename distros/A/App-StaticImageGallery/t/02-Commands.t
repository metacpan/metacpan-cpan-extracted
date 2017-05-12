
use Test::More;
use App::StaticImageGallery;

my @tests = (
    {
        argv            => [qw(-vv --no-recursive build)],
        command         => 'build',
        work_dir        => '.',
        get_verbose     => 2,
        get_recursive   => 0,
    },
    {
        argv            => [qw(-vv clean)],
        command         => 'clean',
        work_dir        => '.',
        get_verbose     => 2,
        get_recursive   => 1,
    }
);

plan tests => ( ( scalar @tests ) * 5 );

foreach my $test ( @tests ){
    @ARGV = @{ $test->{argv} };
    my $app = App::StaticImageGallery->new_with_options();
    isa_ok($app, 'App::StaticImageGallery');

    foreach my $opt ('get_verbose','get_recursive'){
        is(
            $app->opt->$opt,
            $test->{$opt},
            "Check $opt...",
        );
    }

    is($app->cmd_name,$test->{command},"Check command name");
    is($app->{_work_dir},$test->{work_dir},"Check work_dir");

}

