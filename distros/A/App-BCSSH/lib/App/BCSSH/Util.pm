package App::BCSSH::Util;
use strictures 1;

use Module::Runtime qw(require_module);

use base 'Exporter';
our @EXPORT_OK = qw(find_mods command_to_package package_to_command rc_dir);

sub find_mods {
    my ($ns, $load) = @_;
    require Module::Find;
    my @mods = Module::Find::findallmod($ns);
    if (defined &_fatpacker::modules) {
        push @mods, grep { /^$ns\::/ } _fatpacker::modules();
    }
    push @mods, grep { /^$ns\::/ } map { my $m = $_; $m =~ s{/}{::}g; $m =~ s/\.pm$//; $m } keys %INC;
    if ($load) {
        for my $mod (@mods) { require_module($mod) }
    }
    my %mods;
    @mods{@mods} = ();
    return sort keys %mods;
}

sub command_to_package {
    my $command = shift;
    $command =~ s/-/::/g;
    return "App::BCSSH::Command::$command";
}

sub package_to_command {
    my $package = shift;
    $package =~ s/^App::BCSSH::Command:://;
    $package =~ s/::/-/g;
    return $package;
}

sub rc_dir {
    my $config_base = $ENV{XDG_CONFIG_HOME} || "$ENV{HOME}/.config";
    return "$config_base/bcssh";
}

1;
__END__

=head1 NAME

App::BCSSH::Util - Utility functions for App::BCSSH

=head1 SYNOPSIS

    use App::BCSSH::Util qw(find_mods command_to_package package_to_command rc_dir);

=cut
