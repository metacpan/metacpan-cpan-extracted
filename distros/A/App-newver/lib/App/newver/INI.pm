package App::newver::INI;
use 5.016;
use strict;
use warnings;
our $VERSION = '0.02';

use Exporter qw(import);
our @EXPORT_OK = qw(read_ini);

sub read_ini {

    my ($file) = @_;

    my $hash = {};

    open my $fh, '<', $file or die "Failed to open $file for reading: $!\n";

    my $sect = undef;
    my $ln = 0;
    while (my $l = readline $fh) {
        $ln++;
        $l =~ s/^\s+|\s+$//g;
        if ($l =~ /^#/ or $l eq '') {
            next;
        }
        if ($l =~ /^\[\s*(.+)\s*\]$/) {
            $sect = $1;
        } elsif ($l =~ /^(\w+)\s*=\s*(.+)$/) {
            if (not defined $sect) {
                close $fh;
                die "$file line $ln: key-value pair not under a section\n";
            }
            $hash->{ $sect }{ $1 } = $2;
        } else {
            close $fh;
            die "$file line $ln: invalid line\n";
        }
    }

    close $fh;

    return $hash;

}

1;

=head1 NAME

App::newver::INI - newver INI file parser

=head1 SYNOPSIS

  use App::newver::INI qw(read_ini);

  my $hash = read_ini($path_to_ini);

=head1 DESCRIPTION

B<App::newver::INI> is an INI parser module for L<newver>. This is a private
module, for user documentation please consult the L<newver> manual.

L<newver> uses the following dialect of INI:

=over 2

=item Key-value pairs are separated by equals (=) signs.

=item Sections are lines enclosed in brackets.

=item Key-value pairs must be under a section (no default section)

=item Comments start with a hash (#) sign.

=item Whitespace is trimmed.

=item Leading and trailing whitespace is trimmed.

=back

=head1 SUBROUTINES

Subroutines are not exported by default.

=head2 $hash = read_ini($ini_file)

Reads the INI file C<$ini_file> and returns a hash of hashes representing the
file.

For example, the following INI file:

  [Cat]
  Meows = Yes
  Tail = Yes

  [Dog]
  Meows = No
  Tail = Yes

would yield the following hash structure:

  {
    'Cat' => {
      Meows => 'Yes',
      Tail => 'Yes',
    },
    'Dog' => {
      Meows => 'No',
      Tail => 'Yes',
    },
  }

=head1 AUTHOR

Written by L<Samuel Young|samyoung12788@gmail.com>

This project's source can be found on its
L<Codeberg page|https://codeberg.org/1-1sam/newver.git>. Comments and pull
requests are welcome.

=head1 COPYRIGHT

Copyright (C) 2025 Samuel Young.

This program is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0.

=head1 SEE ALSO

L<newver>

=cut
