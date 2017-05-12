package Data::Format::Pretty::Perl;

use 5.010001;
use strict;
use warnings;

use Data::Dump qw();
use Data::Dump::Color qw();

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(format_pretty);

our $VERSION = '0.05'; # VERSION

sub content_type { "text/x-perl" }

sub format_pretty {
    my ($data, $opts) = @_;
    $opts //= {};

    my $interactive = (-t STDOUT);
    my $color  = $opts->{color} // $ENV{COLOR} // $interactive;
    my $linum  = $opts->{linum} // $ENV{LINUM} // 0;

    my $dump;
    if ($color) {
        $dump = Data::Dump::Color::dump($data) . "\n";
    } else {
        $dump = Data::Dump::dump($data) . "\n";
    }
    if ($linum) {
        my $lines = 0;
        $lines++ while $dump =~ /^/mog;
        my $fmt;
        my $i = 0;
        if ($color) {
            $fmt = "%".length($lines)."d";
            $dump =~ s/^/
                "\e[7m" . sprintf($fmt, ++$i) . "\e[0m"
                    /egm;
        } else {
            $fmt = "%".length($lines)."d|";
            $dump =~ s/^/
                sprintf($fmt, ++$i)
                    /egm;
        }
    }
    $dump;
}

1;
# ABSTRACT: Pretty-print data structure as Perl code

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Format::Pretty::Perl - Pretty-print data structure as Perl code

=head1 VERSION

version 0.05

=head1 SYNOPSIS

 use Data::Format::Pretty::Perl qw(format_pretty);
 print format_pretty($data);

Some example output:

=over

=item * format_pretty({a=>1, b=>2})

 { a => 1, b => 2 }

=back

=head1 DESCRIPTION

This module uses L<Data::Dump> or L<Data::Dump::Color> to format data as Perl
code.

=head1 FUNCTIONS

=head2 format_pretty($data, \%opts)

Return formatted data structure as Perl code. Options:

=over 4

=item * color => BOOL

Whether to enable coloring. The default is the enable only when running
interactively. Currently also enable line numbering.

=item * linum => BOOL (default: 0)

Whether to add line numbers.

=back

=head2 content_type()

=head1 ENVIRONMENT

=head2 COLOR => BOOL

Set C<color> option (if unset).

=head2 LINUM => BOOL

Set C<linum> option (if unset).

=head1 FAQ

=head1 SEE ALSO

L<Data::Format::Pretty>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Format-Pretty-Perl>.

=head1 SOURCE

Source repository is at L<https://github.com/sharyanto/perl-Data-Format-Pretty-Perl>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Format-Pretty-Perl>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
