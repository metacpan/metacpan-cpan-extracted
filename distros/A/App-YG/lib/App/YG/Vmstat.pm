package App::YG::Vmstat;
use strict;
use warnings;

our $regexp = qr/
  [^\d]+?(\d+)[^\d]+(\d+)[^\d]+(\d+)[^\d]+(\d+)[^\d]+(\d+)[^\d]+(\d+)[^\d]+(\d+)[^\d]+(\d+)[^\d]+(\d+)[^\d]+(\d+)[^\d]+(\d+)[^\d]+(\d+)[^\d]+(\d+)[^\d]+(\d+)[^\d]+(\d+)[^\d]+(\d+)[^\d]+(\d+)
/x;

sub parse {
    my $line = shift;

    if ($line =~ m!(proc|swpd)!) {
        return [];
    }

    my @matched = ($line =~ m!$regexp!);
    unless (scalar @matched) {
        warn "failed to parse line: '$line'\n";
    }

    return \@matched;
}

sub labels {
    return [qw/
        r
        b
        swpd
        free
        buff
        cache
        si
        so
        bi
        bo
        in
        cs
        us
        sy
        id
        wa
        st
    /];
}

1;

__END__

=head1 NAME

App::YG::Vmstat - vmstat log parser


=head1 SYNOPSIS

    use App::YG::Vmstat;
    App::YG::Vmstat::parse($log);


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
