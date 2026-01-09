package EasyDNS::DDNS::State;

use strict;
use warnings;

use File::Basename ();
use File::Path qw(make_path);
use File::Temp qw(tempfile);

use EasyDNS::DDNS::Util ();

sub new {
    my ($class, %args) = @_;

    my $path = $args{path} // '';
    my $self = bless {
        path    => $path,
        verbose => $args{verbose} // 0,
    }, $class;

    return $self;
}

sub getPath {
    my ($self) = @_;
    return $self->{path} // '';
}

sub getLastIp {
    my ($self) = @_;
    my $path = $self->{path};

    return '' if !$path;
    return '' if !-f $path;

    open my $fh, '<', $path or return '';
    my $line = <$fh>;
    close $fh;

    $line = EasyDNS::DDNS::Util::trim($line);
    return $line;
}

sub setLastIp {
    my ($self, $ip) = @_;
    my $path = $self->{path};

    die "State path not set\n" if !$path;

    $ip = EasyDNS::DDNS::Util::trim($ip);
    die "Refusing to store empty IP\n" if $ip eq '';

    my $dir = File::Basename::dirname($path);
    if (!-d $dir) {
        make_path($dir) or die "Failed to create state dir '$dir': $!\n";
    }

    # Atomic write: write to temp file in same directory, then rename.
    my ($fh, $tmp) = tempfile('last_ip.XXXXXX', DIR => $dir, UNLINK => 0);
    print {$fh} $ip, "\n" or die "Failed writing temp state file: $!\n";
    close $fh or die "Failed closing temp state file: $!\n";

    rename($tmp, $path) or die "Failed renaming '$tmp' -> '$path': $!\n";

    return 1;
}

1;

__END__

=pod

=head1 NAME

EasyDNS::DDNS::State - Persistent state (e.g., last-known public IP)

=head1 DESCRIPTION

Stores and retrieves the last-known IP so the updater can avoid calling
the EasyDNS API when nothing changed. Uses atomic writes via rename(2).

=cut

