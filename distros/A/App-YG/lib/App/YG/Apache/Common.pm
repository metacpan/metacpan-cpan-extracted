package App::YG::Apache::Common;
use strict;
use warnings;

# 127.0.0.1 - - [30/Sep/2012:12:34:56 +0900] "GET /foo HTTP/1.0" 200 123
our $regexp = qr/^
  ([^\ ]+)\ +([^\ ]+)\ +([^\ ]+)\ +
  \[([^\]]+)\]\ +
  "(.*)"\ +(\d+)\ +([^\ ]+)
$/x;

sub parse {
    my $line = shift;

    $line =~ m!$regexp! or warn "failed to parse line: '$line'\n";

    return [
        $1 || '', $2 || '', $3 || '',
        $4 || '',
        $5 || '', $6 || '', $7 || '',
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
    /];
}

1;

__END__

=head1 NAME

App::YG::Apache::Common - Apache common log parser


=head1 SYNOPSIS

    use App::YG::Apache::Common;
    App::YG::Apache::Common::parse($log);


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
