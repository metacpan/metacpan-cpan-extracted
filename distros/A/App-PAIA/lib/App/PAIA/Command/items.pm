package App::PAIA::Command::items;
use strict;
use v5.10;
use parent 'App::PAIA::Command';

our $VERSION = '0.30';

use App::PAIA::JSON;

sub _execute {
    my ($self, $opt, $args) = @_;

    $self->core_request('GET', 'items');
}

1;
__END__

=head1 NAME

App::PAIA::Command::items - list loans, reservations and other items related to a patron

=cut
