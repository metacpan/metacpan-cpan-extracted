package App::Nopaste::Service::dpaste;

use strict;
use warnings;

use JSON ();

our $VERSION = '0.03';

our $SYNTAX_CHOICES_URL = 'http://dpaste.com/api/v2/syntax-choices/';

use base 'App::Nopaste::Service';

sub uri { 'http://dpaste.com/' }

sub fill_form {
    my ($self, $mech, %args) = @_;

    my $syntax_map = $self->get_syntax_map($mech);

    my $syntax = $syntax_map->{$args{lang}}
      ? $syntax_map->{$args{lang}}
      : $syntax_map->{text};

    $mech->submit_form(
        form_name => 'pasteform',
        fields    => {
            content     => $args{text},
            syntax      => $syntax,
            expiry_days => 1,
            ( $args{nick}
                ? (poster => $args{nick})
                : ()
            ),
            ( $args{desc}
                ? (title => $args{desc})
                : ()
            ),
        },
    );
}

sub get_syntax_map {
    my ($self, $mech) = @_;

    my $res = $mech->get($SYNTAX_CHOICES_URL);

    die "Unable to fetch $SYNTAX_CHOICES_URL: @{[$res->status_line()]}"
        unless $res->is_success();

    $mech->back();

    return JSON->new->decode($res->content());
}

sub return {
    my ($self, $mech) = @_;

    my $link = $mech->uri();

    return (1, $link);
}

1 && q[Electric Wizard - Return Trip];

__END__
=pod

=encoding UTF-8

=head1 NAME

App::Nopaste::Service::dpaste - L<App::Nopaste> interface to L<http://dpaste.com>

=head1 SYNOPSIS

    nopaste -s dpaste -l haskell foo_file.hs

=head1 DESCRIPTION

This is an L<App::Nopaste> back-end for L<http://dpaste.com> pastebin.
All pastes will be expired in 1 day.

=head1 SEE ALSO

L<http://dpaste.com/api/v2/syntax-choices/> - available syntax mappings

L<App::Nopaste::Command> - command-line utility for L<App::Nopaste>

=head1 AUTHOR

Sergey Romanov, C<sromanov@cpan.org>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013-2014 by Sergey Romanov.

This library is free software; you can redistribute it and/or modify
it under the terms of the Artistic License version 2.0.

=cut
