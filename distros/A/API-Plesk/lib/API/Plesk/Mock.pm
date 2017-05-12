
package API::Plesk::Mock;

use strict;
use warnings;

use base 'API::Plesk';

sub mock_response {
    $_[0]->{mock_response} = $_[1] if @_ > 1;
    $_[0]->{mock_response};
}

sub mock_error {
    $_[0]->{mock_error} = $_[1] if @_ > 1;
    $_[0]->{mock_error};
}

sub xml_http_req { ($_[0]->{mock_response}, $_[0]->{mock_error}) }

1;

__END__

=head1 NAME

API::Plesk::Mock - Module for testing API::Plesk without sending real requests to Plesk API.

=head1 SYNOPSIS

    use API::Plesk::Mock;

    my $api = API::Plesk::Mock->new(
        username    => 'user', # required
        password    => 'pass', # required
        url         => 'https://127.0.0.1:8443/enterprise/control/agent.php', # required
        api_version => '1.6.3.1',
        debug       => 0,
        timeout     => 30,
    );
    $api->mock_response($some_response_xml);
    $api->mock_error($some_error_text);

=head1 DESCRIPTION

Module for testing API::Plesk without sending real requests to Plesk API.

=head1 METHODS

=over 3

=item mock_response($xml)

Sets response from Plesk API

=item mock_error($text)

Sets any error

=back

=head1 AUTHOR

Ivan Sokolov E<lt>ivsokolov[at]cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Ivan Sokolov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
