# App::hopen::G::FilesCmd - Cmd that outputs a list of files.
package App::hopen::G::FilesCmd;
use Data::Hopen;
use Data::Hopen::Base;

our $VERSION = '0.000010';

use parent 'App::hopen::G::Cmd';
use Class::Tiny {
    files => sub { [] },
};

use App::hopen::Asset;

# Docs {{{1

=head1 NAME

Data::Hopen::G::FilesCmd - Cmd that holds a list of files.

=head1 SYNOPSIS

    my $node = Data::Hopen::G::FilesCmd(files=>['foo.c'], name=>'foo node');

Used by L<Data::Hopen::H/files>.

=head1 FUNCTIONS

=cut

# }}}1

=head2 _run

Create L<App::hopen::Asset>s for the listed files and add them to the
generator's asset graph.
See L<Data::Hopen::Conventions/INTERNALS>.

=cut

sub _run {
    my ($self, %args) = getparameters('self', [qw(phase visitor ; *)], @_);

    my @assets = $self->make(@{$self->files});
    $args{visitor}->asset($_) foreach @assets;

    return {};
} #run()

1;
__END__
# vi: set fdm=marker: #
