package App::RepoSync::Command::Export;
use 5.10.0;
use warnings;
use strict;
use base qw( CLI::Framework::Command );
use Cwd;
use YAML;
use App::RepoSync::Export;

sub run {
    my ($self,$opts,@args) = @_;

    my ($export_file,@dirs) = @args;

    my $cwd = getcwd();

    $export_file ||= 'repos.yml';
    @dirs = getcwd() unless @dirs;

    my @data = ();
    for( @dirs ) {
        say "scanning $_";
        chdir $cwd;
        my @repos = App::RepoSync::Export->run( $_ );
        push @data, @repos;
    }

    chdir $cwd;

    say "writing $export_file...";
    YAML::DumpFile( $export_file , {
        version => 0.1,
        repos => \@data,
    });

    say "done. @{[ scalar @data ]} repositories exported.";
}



1;
