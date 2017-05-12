use strict;
use warnings;
package App::Nopaste::Service::Perlbot;
# ABSTRACT: Service provider for perlbot.pl - https://perlbot.pl/

our $VERSION = '0.002';

use parent 'App::Nopaste::Service';
use JSON qw/decode_json/;

sub run {
    my ($self, %arg) = @_;
    my $ua = LWP::UserAgent->new;

    my $res = $ua->post("https://perlbot.pl/api/v1/paste", {
        paste => $arg{text},
        description => $arg{desc},
        username => $arg{nick},
        chan => $arg{chan},
        language => $arg{lang}
    });

    if ($res->is_success()) {
        my $content = $res->decoded_content;
        my $data = decode_json $content;

        return (1, $data->{url});
    } else {
        return (0, "Paste failed");
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Nopaste::Service::Perlbot - Service provider for perlbot.pl - https://perlbot.pl/

=head1 VERSION

version 0.001

=head1 AUTHOR

Ryan Voots L<simcop@cpan.org|mailto:simcop@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

