use 5.008;
use strict;
use warnings;

package Authen::SCRAM;
# ABSTRACT: Salted Challenge Response Authentication Mechanism (RFC 5802)

our $VERSION = '0.011';

1;


# vim: ts=4 sts=4 sw=4 et:

__END__

=pod

=encoding UTF-8

=head1 NAME

Authen::SCRAM - Salted Challenge Response Authentication Mechanism (RFC 5802)

=head1 VERSION

version 0.011

=head1 SYNOPSIS

    use Authen::SCRAM::Client;
    use Authen::SCRAM::Server;
    use Try::Tiny;

    ### CLIENT SIDE ###

    $client = Authen::SCRAM::Client->new(
        username => 'johndoe',
        password => 'trustno1',
    );

    try {
        $client_first = $client->first_msg();

        # send to server and get server-first-message

        $client_final = $client->final_msg( $server_first );

        # send to server and get server-final-message

        $client->validate( $server_final );
    }
    catch {
        die "Authentication failed!"
    };

    ### SERVER SIDE ###

    $server = Authen::SCRAM::Server->new(
        credential_cb => \&get_credentials,
    );

    $username = try {
        # get client-first-message

        $server_first = $server->first_msg( $client_first );

        # send to client and get client-final-message

        $server_final = $server->final_msg( $client_final );

        # send to client

        return $server->authorization_id; # returns valid username
    }
    catch {
        die "Authentication failed!"
    };

=head1 DESCRIPTION

The modules in this distribution implement the Salted Challenge Response
Authentication Mechanism (SCRAM) from RFC 5802.

See L<Authen::SCRAM::Client> and L<Authen::SCRAM::Server> for usage details.

=head1 NAME

Authen::SCRAM - Salted Challenge Response Authentication Mechanism (RFC 5802)

=head1 VERSION

version 0.011

=for Pod::Coverage BUILD

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/dagolden/Authen-SCRAM/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/dagolden/Authen-SCRAM>

  git clone https://github.com/dagolden/Authen-SCRAM.git

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 CONTRIBUTOR

=for stopwords David Golden

David Golden <xdg@xdg.me>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/dagolden/Authen-SCRAM/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/dagolden/Authen-SCRAM>

  git clone https://github.com/dagolden/Authen-SCRAM.git

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 CONTRIBUTOR

=for stopwords David Golden

David Golden <xdg@xdg.me>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
