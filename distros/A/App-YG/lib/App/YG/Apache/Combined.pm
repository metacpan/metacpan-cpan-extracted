package App::YG::Apache::Combined;
use strict;
use warnings;

# 127.0.0.1 - - [30/Sep/2012:12:34:56 +0900] "GET /foo HTTP/1.0" 200 123 "http://example.com/" "Mozilla/5.0"
our $regexp = qr/^
  ([^\ ]+)\ +([^\ ]+)\ +([^\ ]+)\ +
  \[([^\]]+)\]\ +
  "(.*)"\ +(\d+)\ +([^\ ]+)\ +
  "(.*)"\ +"(.*)"
$/x;

sub parse {
    my $line = shift;

    $line =~ m!$regexp! or warn "failed to parse line: '$line'\n";

    return [
        $1 || '', $2 || '', $3 || '',
        $4 || '',
        $5 || '', $6 || '', $7 || '',
        $8 || '', $9 || '',
    ];
}

sub labels {
    return [qw/
        Host
        Ident
        Authuser
        Date
        Request
        Status
        Bytes
        Referer
        UserAgent
    /];
}

1;

__END__

=head1 NAME

App::YG::Apache::Combined - Apache combined log parser


=head1 SYNOPSIS

    use App::YG::Apache::Combined;
    App::YG::Apache::Combined::parse($log);


=head1 METHOD

=over

=item parse($log_line)

g

=item labels

g

=back


=head1 AUTHOR

Dai Okabayashi E<lt>bayashi@cpan.orgE<gt>


=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
