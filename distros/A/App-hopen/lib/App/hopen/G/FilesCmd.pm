# App::hopen::G::FilesCmd - Cmd that outputs a list of files.
package App::hopen::G::FilesCmd;
use Data::Hopen;
use strict; use warnings;
use Data::Hopen::Base;

our $VERSION = '0.000015'; # TRIAL

use parent 'App::hopen::G::Cmd';
use Class::Tiny {
    files => sub { [] },
};

use App::hopen::Asset;

# Docs {{{1

=head1 NAME

App::hopen::G::FilesCmd - Cmd that holds a list of files.

=head1 SYNOPSIS

    my $node = App::hopen::G::FilesCmd(files=>['foo.c'], name=>'foo node');

Used by L<App::hopen::H/files>.

=head1 ATTRIBUTES

=head2 files

The files that this Cmd outputs.  Intended to be L<App::hopen::Util::BasedPath>
instances.

=head1 FUNCTIONS

=cut

# }}}1

=head2 _run

Create L<App::hopen::Asset>s for the listed files and add them to the
generator's asset graph.
See L<App::hopen::Conventions/INTERNALS>.

=cut

sub _run {
    my ($self, %args) = getparameters('self', [qw(visitor ; *)], @_);

    my @assets = $self->make(@{$self->files});
    $args{visitor}->asset($_) foreach @assets;

    return {};
} #run()

1;
__END__
# vi: set fdm=marker: #
