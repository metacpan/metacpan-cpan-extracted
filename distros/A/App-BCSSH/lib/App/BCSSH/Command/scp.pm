package App::BCSSH::Command::scp;
use Moo;
use App::BCSSH::Options;
with Options;
with 'App::BCSSH::Client';

use File::Spec;

sub run {
    my $self = shift;
    my @files = @{ $self->args };
    @files or die "At least one file must be specified!\n";
    for my $file (@files) {
        $file = File::Spec->rel2abs($file);
    }
    $self->command({ files => \@files });
    my $sock = $self->agent_socket;
    $| = 1;
    while ($sock->sysread(my $buf, 8192)) {
        print $buf;
    }
    return 1;
}

1;
__END__

=head1 NAME

App::BCSSH::Command::scp - Copy files to user's local machine

=head1 SYNOPSIS

    bcssh scp -- file.txt

=cut
