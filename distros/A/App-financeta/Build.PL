use strict;
use warnings;
use 5.10.0;
use Module::Build;
### do not install these packages on Windows
my %non_windows = ();
$non_windows{'POE::Loop::Prima'} = '1.03' if $^O !~ /win32/i;

my $build = Module::Build->new(
    module_name => 'App::financeta',
    license => 'gpl',
    dist_author => 'Vikas N. Kumar <vikas@cpan.org>',
    dist_abstract => 'App::financeta is a Technical Analysis GUI',
    dist_version_from => 'lib/App/financeta.pm',
    create_readme => 0,
    configure_requires => {
        'Module::Build' => 0,
        'File::ShareDir' => '1.118',
    },
    build_requires => {
        'Module::Build' => 0,
        'File::ShareDir' => '1.118',
        'Test::More' => 0,
    },
    requires => {
        perl => '5.10.0',
        'Carp' => 0,
        'POSIX' => 0,
        'Cwd' => 0,
        'Pod::Usage' => '2.03',
        'Data::Dumper' => '2.183',
        'File::Spec' => '3.78',
        'File::ShareDir' => '1.118',
        'File::HomeDir' => '1.006',
        'File::Path' => '2.18',
        'Path::Tiny' => '0.144',
        'Capture::Tiny' => '0.48',
        'Try::Tiny' => '0.31',
        'PDL'  => '2.081',
        'DateTime' => '1.59',
        'DateTime::Format::Strptime' => '1.79',
        'Finance::QuoteHist' => '1.32',
        'PDL::Finance::TA' => '0.010',
        'Prima' => '1.67001',
        'PDL::Graphics::Gnuplot' => '2.021',
        'Scalar::Util' => '1.63',
        'Getopt::Long' => '2.54',
        'Browser::Open' => '0.04',
        'YAML::Any' => '1.30',
        'Pegex' => '0.75',
        'Perl::Tidy' => 0,
        'Log::Any' => '1.713',
        %non_windows,
    },
    dynamic_config => 1,
    add_to_cleanup => [ qw/*.bak _Inline/ ],
    meta_merge => {
        resources => {
            repository => "https://github.com/vikasnkumar/financeta",
            bugtracker => "https://github.com/vikasnkumar/financeta/issues",
        },
        keywords => [qw/ finance technical-analysis technical analysis/],
        no_index => {
            directory => [qw/ t share /],
        },
    },
    share_dir => 'share',
    installdirs => ($^O =~ /Darwin/i) ? 'core' : 'site',
);

$build->create_build_script;
$build->dispatch('distmeta');
$build->dispatch('manifest');

__END__
#### COPYRIGHT: 2013. Vikas N Kumar. All Rights Reserved
#### AUTHOR: Vikas N Kumar <vikas@cpan.org>
#### DATE: 18th Dec 2013
#### LICENSE: Refer LICENSE file.
