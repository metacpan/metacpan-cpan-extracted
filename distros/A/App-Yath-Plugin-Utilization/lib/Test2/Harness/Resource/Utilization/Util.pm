package Test2::Harness::Resource::Utilization::Util;
use strict;
use warnings;

our $VERSION = '0.000001';

use Carp qw/croak/;

use Importer Importer => 'import';

our @EXPORT_OK = qw/read_file_lines maybe_read_file_lines/;

sub read_file_lines {
    my ($file) = @_;

    open my $fh, '<', $file
        or croak "Could not open file '$file' (<): $!";

    unless (wantarray) {
        my $line = <$fh>;
        close $fh;
        chomp $line if defined $line;
        return $line;
    }

    my @lines;
    while (defined(my $line = <$fh>)) {
        chomp $line;
        push @lines => $line;
    }
    close $fh;

    return @lines;
}

sub maybe_read_file_lines {
    my ($file) = @_;
    return wantarray ? () : undef unless -f $file;
    return read_file_lines($file);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test2::Harness::Resource::Utilization::Util - Internal helpers for utilization resources.

=head1 EXPORTS

=over 4

=item @lines = read_file_lines($file)

=item $first = read_file_lines($file)

Read C<$file> line by line. Newlines stripped. In scalar context returns
only the first line and closes the filehandle immediately. Croaks if
the file cannot be opened.

=item @lines = maybe_read_file_lines($file)

=item $first = maybe_read_file_lines($file)

As L</read_file_lines> but returns C<()> (or C<undef> in scalar context)
when the file does not exist, instead of croaking.

=back

=head1 SOURCE

L<https://github.com/Test-More/App-Yath-Plugin-Utilization>

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<http://dev.perl.org/licenses/>

=cut
