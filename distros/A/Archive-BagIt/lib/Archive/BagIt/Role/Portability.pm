package Archive::BagIt::Role::Portability;
use strict;
use warnings;
use namespace::autoclean;
use Carp ();
use File::Spec ();
use Moo::Role;
# ABSTRACT: A role that handles filepaths for improved portability
our $VERSION = '0.098'; # VERSION


sub chomp_portable {
    my ($line) = @_;
    $line =~ s#\x{0d}?\x{0a}?\Z##s; # replace CR|CRNL with empty
    return $line;
}


sub normalize_payload_filepath {
    my ($filename) = @_;
    $filename =~ s#[\\](?![/])#/#g; # normalize Windows Backslashes, but only if they are no escape sequences
    $filename =~ s#%#%25#g; # normalize percent
    $filename =~ s#\x{0a}#%0A#g; #normalize NEWLINE
    $filename =~ s#\x{0d}#%0D#g; #normalize CARRIAGE RETURN
    $filename =~ s# #%20#g; # space
    $filename =~ s#"##g; # quotes
    return $filename;
}


sub check_if_payload_filepath_violates{
    my ($local_name) = @_;
    # HINT: there is no guarantuee *not* to escape!
    return
        ($local_name =~ m/^~/) # Unix Home
            || ($local_name =~ m#\./#) # Unix, parent dir escape
            || ($local_name =~ m#^[A-Z]:[\\/]#) # Windows Drive
            || ($local_name =~ m#^/#) # Unix absolute path
            || ($local_name =~ m#^$#) # Unix Env
            || ($local_name =~ m#^\\#) # Windows absolute path
            || ($local_name =~ m#^%[^%]*%#) # Windows ENV
            || ($local_name =~ m#^\*#) # Artifact of md5sum-Tool, where ' *' is allowed to separate checksum and file in fixity line
            || ($local_name =~ m#[<>:"?|]#) # Windows reserved chars
            || ($local_name =~ m#(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])#) # Windows reserved filenames
    ;
}

no Moo::Role;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Archive::BagIt::Role::Portability - A role that handles filepaths for improved portability

=head1 VERSION

version 0.098

=head2 chomp_portable($line)

returns chomped $line where last CR or CRLF removed

=head2 normalize_payload_filepath($filename)

returns the normalized $filename

=head2 check_if_payload_filepath_violates($local_name)

this checks if payload file path violates some OS dependent filename rules

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/Archive::BagIt/>.

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<http://rt.cpan.org>.

=head1 AUTHOR

Andreas Romeyke <cpan@andreas.romeyke.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Rob Schmidt <rjeschmi@gmail.com>, William Wueppelmann and Andreas Romeyke.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
