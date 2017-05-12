package App::BCSSH::Command::browse;
use Moo;
use App::BCSSH::Options;
with Options;
with 'App::BCSSH::Client';

use File::Spec;

sub run {
    my $self = shift;
    my @urls = @{ $self->args };
    @urls or die "At least one url must be specified!\n";
    $self->command({ urls => \@urls });
}

1;
__END__

=head1 NAME

App::BCSSH::Command::browse - Open a URL in the user's local browser

=head1 SYNOPSIS

    bcssh browse -- http://www.example.com/

=cut
