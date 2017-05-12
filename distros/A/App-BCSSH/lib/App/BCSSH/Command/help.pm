package App::BCSSH::Command::help;
use strictures 1;

use Module::Reader qw(:all);
use File::Temp ();
use File::Spec;
use Pod::Perldoc;
use Pod::Perldoc::ToMan;
use App::BCSSH::Util qw(command_to_package package_to_command);
use App::BCSSH::Command::commands;

sub new { bless { command => $_[1] }, $_[0] }

sub run {
    my $self = shift;
    my $command = $self->{command};
    if ($command) {
        $self->help_for_package(command_to_package($command));
    }
    else {
        $self->help_for_package('App::BCSSH');
    }
}

sub help_for_package {
    my $self = shift;
    my $package = shift;
    my $pod = module_content($package, { found => \%INC });
    my $command = package_to_command($package);

    # perldoc will try to drop privs anyway, so do it ourselves so the
    # temp file has the correct owner
    Pod::Perldoc->new->drop_privs_maybe;

    my $pod_name = $command ? "bcssh-$command" : $package;
    my $pod_file = $pod_name;
    $pod_file =~ s/::/-/g;
    my $section = $command ? 1 : 3;
    my $tmpdir = File::Temp->newdir( TMPDIR => 1 );
    my $out_file = File::Spec->catfile($tmpdir, $pod_file);
    open my $out, '>', $out_file;
    print {$out} $pod;
    close $out;
    {
        no warnings qw(redefine once);
        # fix width handling
        *Pod::Perldoc::ToMan::is_linux = sub () { 1 };
        # silence groff warning
        *Pod::Perldoc::ToMan::warn = sub {};
        # fix option passing
        *Pod::Perldoc::ToMan::_get_podman_switches = sub {
            my $self = shift;
            return map {; $_ => $self->{$_} } grep !m/^_/s, keys %$self;
        };
    }
    @ARGV = (
        -o => 'Man',
        -w => "name:$pod_name",
        -w => "section:$section",
        -w => 'center:',
        '-F' => $out_file,
    );
    exit Pod::Perldoc->run;
}

1;

__END__

=head1 NAME

App::BCSSH::Command::help - Show documentation for bcssh commands

=head1 SYNOPSIS

    bcssh help ssh

=cut
