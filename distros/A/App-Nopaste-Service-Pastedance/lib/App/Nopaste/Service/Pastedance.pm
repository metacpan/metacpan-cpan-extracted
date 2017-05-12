package App::Nopaste::Service::Pastedance;

use warnings;
use strict;
use Encode;

our $VERSION = '0.04';

use base q[App::Nopaste::Service];

sub uri { $ENV{PASTEDANCE_URL} || 'http://paste.perldancer.org/' }

sub fill_form {
    my ($self, $mech) = (shift, shift);
    my %args = @_;

    my $content = {
        code    => decode('UTF-8', $args{text}),
        subject => decode('UTF-8', $args{desc}),
        # Pastedance itself defaults to txt if <lang> is not known
        lang    => $args{lang},
    };

    my $form = $mech->form_number(1) || return;

    # do not follow redirect please
    @{$mech->requests_redirectable} = ();

    my $paste = HTML::Form::Input->new(
        type  => 'text',
        value => 'Send',
        name  => 'paste'
    )->add_to_form($form);

    return $mech->submit_form( form_number => 1, fields => $content );
}

sub return {
    my $self = shift;
    my $mech = shift;
    my $response = $mech->response;
    if($response->is_redirect) {
      return (1,$response->header("Location"));
    } else {
      return (0, "Cannot find URL");
    }
}

1;
__END__

=head1 NAME

App::Nopaste::Service::Pastedance - paste to any Pastedance instance

=head1 SYNOPSIS

 cat << "EOS" > ~/bin/pd
 #!/usr/bin/env perl
 
 export PASTEDANCE_URL= # if unset it defaults to http://pb.rbfh.de/
 exec nopaste -s Pastedance "$@"
 EOS

=cut
