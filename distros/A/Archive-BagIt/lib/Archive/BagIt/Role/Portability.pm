package Archive::BagIt::Role::Portability;
use strict;
use warnings;
use namespace::autoclean;
use Carp;
use File::Spec;
use Moo::Role;


sub chomp_portable {
    my $self = shift;
    my $line = shift;
    $line =~ s#\x{0d}?\x{0a}?\Z##s; # replace CR|CRNL with empty
    return $line;
}

no Moo::Role;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Archive::BagIt::Role::Portability

=head1 VERSION

version 0.067

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/Archive::BagIt/>.

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<http://rt.cpan.org>.

=head1 AUTHOR

Rob Schmidt <rjeschmi@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Rob Schmidt and William Wueppelmann and Andreas Romeyke.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
