package App::YG::Apache::Error;
use strict;
use warnings;

# [Sat Oct 06 17:34:17 2012] [notice] suEXEC mechanism enabled (wrapper: /usr/sbin/suexec)
# [Sat Oct 06 17:36:10 2012] [error] [client 123.220.65.13] File does not exist: /var/www/html/favicon.ico
our $regexp = qr/^
  \[([^\]]+)\]\ +\[([^\]]+)\]\ +
  (?:\[client\ ([^\]]+)\]\ +)?
  (.+)
$/x;

sub parse {
    my $line = shift;

    $line =~ m!$regexp! or warn "failed to parse line: '$line'\n";

    return [
        $1 || '', $2 ||'',
        $3 || '',
        $4 || '',
    ];
}

sub labels {
    return [qw/
        Date
        Log_Level
        Client
        Message
    /];
}

1;

__END__

=head1 NAME

App::YG::Apache::Error - Apache error log parser


=head1 SYNOPSIS

    use App::YG::Apache::Error;
    App::YG::Apache::Error::parse($log);


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
