package Common::Log::Parser;

# ABSTRACT: Parse the common log format lines used by Apache

use v5.14;
use warnings;

use Exporter 5.57 qw( import );

our $VERSION = 'v0.1.0';

our @EXPORT_OK = qw( split_log_line );


sub split_log_line {


    my ($line) = @_;
    my @matches = $line =~ /(?: \A | [ ]) ( - | \[ [^]]+ \] | " (?:\\.|[^"])* " | \S+ ) /agx;
    return \@matches;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Common::Log::Parser - Parse the common log format lines used by Apache

=head1 VERSION

version v0.1.0

=head1 SYNOPSIS

  use Common::Log::Parser qw( split_log_line );

  my $columns = split_log_line($line);

=head1 DESCRIPTION

This module provides a simple function to parse common log format lines, such as those used by Apache.

=head1 EXPORTS

None by default.

=head2 split_log_line

  my $columns = split_log_line($line);

This function simply parses the log file and returns an array reference of the different columns.

It does not attempt to parse or unescape the contents. Surrounding brackets or quotes are not removed.

=head1 SEE ALSO

=over

=item *

L<Apache::Log::Parser>

=item *

L<Apache::ParseLog>

=item *

L<ApacheLog::Parser>

=item *

L<Regexp::Long::Common>

=back

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/perl5-Common-Log-Parser>
and may be cloned from L<git://github.com/robrwo/perl5-Common-Log-Parser.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/perl5-Common-Log-Parser/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

The initial development of this module was partially supported by Science Photo Library L<https://www.sciencephoto.com>.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
