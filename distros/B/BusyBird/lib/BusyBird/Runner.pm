package BusyBird::Runner;
use v5.8.0;
use strict;
use warnings;
use Getopt::Long qw(GetOptionsFromArray :config no_ignore_case bundling);
use BusyBird::Util qw(config_directory config_file_path);
use File::Spec;
use Try::Tiny;
use Plack::Runner ();
use Exporter 5.57 qw(import);

our @EXPORT_OK = qw(run);

sub run {
    my (@argv) = @_;
    my @plack_opts = try {
        prepare_plack_opts(@argv);
    }catch {
        ();
    };
    return 1 if !@plack_opts;
    my $runner = Plack::Runner->new;
    $runner->parse_options(@plack_opts);
    $runner->run();
    return undef;
}

sub prepare_plack_opts {
    my (@argv) = @_;
    my $need_help = 0;
    my $bind_host = "127.0.0.1";
    my $bind_port = 5000;
    my $config_script;
    GetOptionsFromArray(
        \@argv,
        "h|help" => \$need_help,
        "o|host=s" => \$bind_host,
        "p|port=i" => \$bind_port
    ) or die "command-line error";
    die "need help" if $need_help;
    _ensure_config_dir_exists();
    $config_script = shift @argv;
    if(defined($config_script)) {
        _ensure_config_file_exists($config_script);
    }else {
        $config_script = config_file_path("config.psgi");
        _ensure_config_file_exists($config_script, 1);
    }
    return ("--no-default-middleware", "-a", $config_script,
            "-o", $bind_host, "-p", $bind_port, "-s", "Twiggy");
}

sub _ensure_config_dir_exists {
    my $dir = config_directory;
    if(! -d $dir) {
        if(!mkdir $dir) {
            warn "Cannot create config directory $dir: $!\n";
            die "_check_config_dir";
        }
    }
}

sub _ensure_config_file_exists {
    my ($filepath, $create_default) = @_;
    if(! -f $filepath) {
        if($create_default) {
            _create_default_config_file($filepath);
        }else  {
            my $msg = "Cannot access config file $filepath. Maybe it does not exist.";
            warn "$msg\n";
            die $msg;
        }
    }
}

sub _create_default_config_file {
    my ($config_filepath) = @_;
    require File::ShareDir;
    require File::Copy;
    my $sample = File::Spec->catfile(File::ShareDir::dist_dir("BusyBird"), "sample_config.psgi");
    File::Copy::copy($sample, $config_filepath) or do {
        warn "Error while copying $sample to $config_filepath: $!\n";
        die "_create_default_config_file";
    };
}


1;
__END__

=pod

=head1 NAME

BusyBird::Runner - BusyBird process runner

=head1 SYNOPSIS

    #!/usr/bin/perl
    use strict;
    use warnings;
    use BusyBird::Runner qw(run);
    
    run(@ARGV);

=head1 DESCRIPTION

L<BusyBird::Runner> runs L<BusyBird> process instance.
This is the direct back-end of C<busybird> command.

=head1 EXPORTABLE FUNCTIONS

The following functions are exported only by request.

=head2 $need_help = run(@argv)

Runs the L<BusyBird> process instance.

C<@argv> is the command-line arguments. See L<busybird> for detail.

Return value C<$need_help> indicates if the user might need some help.
If C<$need_help> is non-C<undef>, the caller should provide the user with some help.

=head1 AUTHOR

Toshio Ito C<< <toshioito [at] cpan.org> >>

=cut

