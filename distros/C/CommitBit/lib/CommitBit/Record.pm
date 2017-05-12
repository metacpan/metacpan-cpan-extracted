package CommitBit::Record;
use base 'Jifty::Record';
use strict;
use warnings;


sub after_create {
    my $self = shift;
    $self->update_all_repositories;
    return 1;
}

sub _set {
    my $self = shift;
    my @ret = $self->SUPER::_set(@_);

    $self->update_all_repositories;

    return @ret;
}


sub update_all_repositories {
    my $self = shift;

    my $repositories = CommitBit::Model::RepositoryCollection->new;
    $repositories->unlimit;

    while (my $repository = $repositories->next) {
        $repository->write_password_files;
        $repository->write_authz_file();
    }
}


1;

