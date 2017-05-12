package Dancer::Session::Catmandu;

=head1 NAME

Dancer::Session::Catmandu - Dancer session store backed by a Catmandu::Store

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 CONFIGURATION

    session_store: MongoDB
    session_bag: sessions

=cut

use Catmandu::Sane;
use Catmandu;
use parent qw(Dancer::Session::Abstract);
use Dancer qw(:syntax config);

sub _bag {
    state $bag = do {
        my $s = config->{session_store} || Catmandu->default_store;
        my $b = config->{session_bag}   || 'session';
        Catmandu->store($s)->bag($b);
    };
}

sub init {
    $_[0]->SUPER::init;
}

sub create {
    $_[0]->new;
}

sub retrieve {
    my $data = _bag->get($_[1])
        or return bless {id => $_[1]}, $_[0];
    $data->{id} = delete $data->{_id};
    bless $data, $_[0];
}

sub flush {
    my $self = $_[0];
    my $data = {%$self};
    $data->{_id} = delete $data->{id};
    _bag->add($data);
    $self;
}

sub destroy {
    _bag->delete($_[0]->{id});
}

1;

=head1 SEE ALSO

L<Dancer::Session>, L<Catmandu>

=head1 AUTHOR

Nicolas Steenlant, C<< <nicolas.steenlant at ugent.be> >>

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
