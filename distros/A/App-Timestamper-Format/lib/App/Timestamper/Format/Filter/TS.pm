package App::Timestamper::Format::Filter::TS;
$App::Timestamper::Format::Filter::TS::VERSION = '0.0.2';
use strict;
use warnings;

use POSIX qw/ strftime /;

use App::Timestamper::Filter::TS;

sub new
{
    return bless {}, shift;
}

sub fh_filter
{
    my ($self, $in, $out) = @_;

    my $FMT = $ENV{'TIMESTAMPER_FORMAT'} // '%Y-%m-%d-%H:%M:%S';

    my $filt = App::Timestamper::Filter::TS->new;
    $filt->fh_filter($in,
        sub {
            my ($l) = @_;
            return $out->(
                $l =~ s#\A([0-9\.]+)(\t)#strftime($FMT,localtime($1)).$2#er
            );
        }
    );

    return;
}


1;

__END__

=pod

=head1 VERSION

version 0.0.2

=head1 METHODS

=head2 App::Timestamper::Format::Filter::TS->new();

A constructor. Does not accept any options for now.

=head2 $obj->fh_filter($in_filehandle, $out_cb)

Reads line from $in_filehandle until eof() and for each line call $out_cb
with a string containing the timestamp when the line was read, a \t
character and the line itself.

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/app-timestamper-format/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
