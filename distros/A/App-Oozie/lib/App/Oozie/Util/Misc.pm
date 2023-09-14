package App::Oozie::Util::Misc;
$App::Oozie::Util::Misc::VERSION = '0.006';
use 5.010;
use strict;
use warnings;
use parent qw( Exporter );

our @EXPORT_OK = qw(
    remove_newline
);

sub remove_newline { my $s = shift; $s =~ s{\n+}{ }xmsg; $s }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Oozie::Util::Misc

=head1 VERSION

version 0.006

=head1 SYNOPSIS

    use App::Oozie::Util::Misc qw( remove_newline );

=head1 DESCRIPTION

Internal module.

=head1 NAME

App::Oozie::Util::Misc - Miscellaneous utility functions

=head1 Methods

=head2 remove_newline

=head1 SEE ALSO

L<App::Oozie>.

=head1 AUTHORS

=over 4

=item *

David Morel

=item *

Burak Gursoy

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Booking.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
