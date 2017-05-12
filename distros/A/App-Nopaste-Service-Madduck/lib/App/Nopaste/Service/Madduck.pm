use strict;
use warnings;
package App::Nopaste::Service::Madduck;
BEGIN {
  $App::Nopaste::Service::Madduck::VERSION = '0.01';
}

# ABSTRACT: Paste to the madduck.co.uk pastebin

use base 'App::Nopaste::Service';

sub uri { 'http://p.madduck.co.uk/pastes/add' }

sub fill_form {
    my $self = shift;
    my $mech = shift;
    my %args = @_;

    $mech->form_number(0);

    $mech->submit_form(
        fields => {
            'paste_contents'    => $args{text},
            'name' => ucfirst $args{nick},
        },
    );
}

sub return {
    my $self = shift;
    my $mech = shift;

    my $url = $mech->uri;
    return (0, "Could not construct paste link.") if !$url;
    return (1, $url);
}

=head1 NAME

App::Nopaste::Service::Madduck - http://p.madduck.co.uk/

=head1 VERSION

version 0.01

=cut

1;