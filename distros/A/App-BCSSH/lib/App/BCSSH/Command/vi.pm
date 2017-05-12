package App::BCSSH::Command::vi;
use Moo;
use App::BCSSH::Options;
with Options;
with 'App::BCSSH::Client';

use File::Spec;

has 'wait' => (is => 'ro', coerce => sub { $_[0] ? 1 : 0 }, arg_spec => 'f');

sub run {
    my $self = shift;
    my @files = @{ $self->args };
    @files or die "At least one file must be specified!\n";
    for my $file (@files) {
        $file = File::Spec->rel2abs($file);
    }
    $self->command({ wait => $self->wait, files => \@files });
}

1;
__END__

=head1 NAME

App::BCSSH::Command::vi - Edit file on user's local machine

=head1 SYNOPSIS

    bcssh vi -- file.txt

=cut
