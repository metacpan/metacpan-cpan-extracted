package App::Timestamper::Filter::TS;
$App::Timestamper::Filter::TS::VERSION = '0.2.0';
use strict;
use warnings;

use Time::HiRes qw/time/;

sub new
{
    return bless {}, shift;
}

sub fh_filter
{
    my ($self, $in, $out) = @_;

    while (my $l = <$in>)
    {
        $out->(sprintf('%.9f', time()) . "\t" . $l);
    }

    return;
}


1;

__END__

=pod

=head1 VERSION

version 0.2.0

=head1 METHODS

=head2 App::Timestamper::Filter::TS->new();

A constructor. Does not accept any options for now.

=head2 $obj->fh_filter($in_filehandle, $out_cb)

Reads line from $in_filehandle until eof() and for each line call $out_cb
with a string containing the timestamp when the line was read, a \t
character and the line itself.

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/App-Timestamper/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
