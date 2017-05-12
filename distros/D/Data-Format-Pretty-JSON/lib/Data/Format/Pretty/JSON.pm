package Data::Format::Pretty::JSON;

our $DATE = '2016-03-11'; # DATE
our $VERSION = '0.12'; # VERSION

use 5.010001;
use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(format_pretty);

sub content_type { "application/json" }

sub format_pretty {
    my ($data, $opts) = @_;
    $opts //= {};

    state $json;
    my $interactive = (-t STDOUT);
    my $pretty = $opts->{pretty} // 1;
    my $color  = $opts->{color} // $ENV{COLOR} // $interactive //
        $opts->{pretty};
    my $linum  = $opts->{linum} // $ENV{LINUM} // 0;
    if ($color) {
        require JSON::Color;
        JSON::Color::encode_json($data, {pretty=>$pretty, linum=>$linum})."\n";
    } else {
        if (!$json) {
            require JSON::MaybeXS;
            $json = JSON::MaybeXS->new->utf8->allow_nonref;
        }
        $json->pretty($pretty);
        if ($linum) {
            require String::LineNumber;
            String::LineNumber::linenum($json->encode($data));
        } else {
            $json->encode($data);
        }
    }
}

1;
# ABSTRACT: Pretty-print data structure as JSON

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Format::Pretty::JSON - Pretty-print data structure as JSON

=head1 VERSION

This document describes version 0.12 of Data::Format::Pretty::JSON (from Perl distribution Data-Format-Pretty-JSON), released on 2016-03-11.

=head1 SYNOPSIS

 use Data::Format::Pretty::JSON qw(format_pretty);
 print format_pretty($data);

=head1 DESCRIPTION

This module uses L<JSON::MaybeXS> or L<JSON::Color> to encode data as JSON.

=for Pod::Coverage ^(new)$

=head1 FUNCTIONS

=head2 format_pretty($data, \%opts)

Return formatted data structure as JSON. Options:

=over 4

=item * color => BOOL (default: from env or 1 on interactive)

Whether to enable coloring. The default is the enable only when running
interactively.

=item * pretty => BOOL (default: 1)

Whether to pretty-print JSON.

=item * linum => BOOL (default: from env or 0)

Whether to add line numbers.

=back

=head2 content_type() => STR

Return C<application/json>.

=head1 FAQ

=head1 ENVIRONMENT

=head2 COLOR => BOOL

Set C<color> option (if unset).

=head2 LINUM => BOOL

Set C<linum> option (if unset).

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Format-Pretty-JSON>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Format-Pretty-JSON>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Format-Pretty-JSON>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Data::Format::Pretty>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
