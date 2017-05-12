package App::YG::Nginx::Main;
use strict;
use warnings;

# $remote_addr - $remote_user [$time_local] "$request" $status $body_bytes_sent "$http_referer" "$http_user_agent" "$http_x_forwarded_for"
our $regexp = qr/^
  ([^\ ]+)\ +([^\ ]+)\ +([^\ ]+)\ +
  \[([^\]]+)\]\ +
  "(.*)"\ +(\d+)\ +([^\ ]+)\ +
  "(.*)"\ +"(.*)"\ +"(.*)"
$/x;

sub parse {
    my $line = shift;

    $line =~ m!$regexp! or warn "failed to parse line: '$line'\n";

    return [
        $1 || '', $2 || '', $3 || '',
        $4 || '',
        $5 || '', $6 || '', $7 || '',
        $8 || '', $9 || '', $10 || '',
    ];
}

sub labels {
    return [qw/
        Remote_Addr
        -
        Remote_User
        Time_Local
        Request
        Status
        Body_Bytes_Sent
        HTTP_Referer
        User_Agent
        HTTP_x_Forwarded_For
    /];
}

1;

__END__

=head1 NAME

App::YG::Nginx::Main - Nginx main log parser


=head1 SYNOPSIS

    use App::YG::Nginx::Main;
    App::YG::Nginx::Main::parse($log);


=head1 METHOD

=over

=item parse($log_line)

=item labels

=back


=head1 AUTHOR

Dai Okabayashi E<lt>bayashi@cpan.orgE<gt>


=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
