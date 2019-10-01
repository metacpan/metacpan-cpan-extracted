# App::GitFind::Searcher::Git - Search for files in a Git index
package App::GitFind::Searcher::Git;

use 5.010;
use strict;
use warnings;
use App::GitFind::Base;

our $VERSION = '0.000002';

use parent 'App::GitFind::Searcher';
use Class::Tiny qw(repo searchbase),
{
    scan_submodules => sub { true },
};

use App::GitFind::Entry::GitIndex;
use Git::Raw;
use Git::Raw::Submodule;

# Docs {{{1

=head1 NAME

App::GitFind::Searcher::Git - Search for files on disk

=head1 SYNOPSIS

This is an L<App::GitFind::Searcher> that looks through a file system.

=cut

# }}}1

=head1 FUNCTIONS

=head2 run

Conducts a search.

=cut

sub run {
    my ($self, $callback) = @_;
    return $self->_run($callback, $self->repo);
} #run()

# Implementation of run().  Call as $self->_run($callback, $repo).
sub _run {
    my ($self, $callback, $repo) = @_;
    my $index = $repo->index;

    my %submodules;     # map submodule paths to Git::Raw::Submodule instances

    if($self->scan_submodules) {
        # Does $repo have submodules? (EXPERIMENTAL)
        my @submodule_names;
        Git::Raw::Submodule->foreach($repo, sub {
                push @submodule_names, $_[0];
                return 0;   # Tell foreach() to keep going
        });
        vlog { "Submodules:", join ', ', @submodule_names } if @submodule_names;

        # Open the submodules
        for(@submodule_names) {
            my $sm = Git::Raw::Submodule->lookup($repo, $_);
            unless($sm) {
                vwarn { "Could not access submodule $_" };  # TODO die?
                return undef;
            }
            $submodules{$_} = $sm;
        }
    }

    for my $idxe ($index->entries) {
        my $entry = App::GitFind::Entry::GitIndex->new(-obj=>$idxe,
            -repo=>$repo, -searchbase=>$self->searchbase);
        $callback->($entry);
        # TODO prune and other control

        if(my $sm = $submodules{$idxe->path}) {
            vlog { "Entering submodule", $sm->name } 2;
            my $smrepo = $sm->open;
            die "Could not open repo for submodule @{[$smrepo->name]}: $@" if $@;
            $self->_run($callback, $smrepo);
            vlog { "Exiting submodule", $sm->name } 2;

            # Make sure everything is closed
            undef $smrepo;
            undef $sm;
            undef $submodules{$idxe->path};
        }

        undef $entry;
    }
} #_run()

=head2 BUILD

=cut

sub BUILD {
    my ($self, $hrArgs) = @_;
    unless($self->searchbase && $self->repo &&
        $self->repo->DOES('Git::Raw::Repository')) {
        require Carp;
        Carp::croak 'Need a -searchbase' unless $self->searchbase;
        Carp::croak 'Need a -repo' unless $self->repo;
        Carp::croak 'Repo must be a Git::Raw::Repository'
            unless $self->repo->DOES('Git::Raw::Repository');
    }
} #BUILD()

1;
__END__
# vi: set fdm=marker: #
