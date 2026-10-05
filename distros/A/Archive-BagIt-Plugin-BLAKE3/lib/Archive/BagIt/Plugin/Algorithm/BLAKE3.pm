package Archive::BagIt::Plugin::Algorithm::BLAKE3;
use strict;
use warnings;
use Carp qw( croak );
use Moo;
use Digest::BLAKE3;
use namespace::autoclean;
with 'Archive::BagIt::Role::Algorithm';

our $VERSION = '0.002';
# ABSTRACT: The Blake3 algorithm plugin

has '+plugin_name' => (
    is => 'ro',
    default => 'Archive::BagIt::Plugin::Algorithm::BLAKE3',
);

has '+name' => (
    is      => 'ro',
    #isa     => 'Str',
    default => 'blake3',
);


sub get_hash_string {
    my ($self, $fh) = @_;
    my $hasher = Digest::BLAKE3::->new();
    $hasher->addfile($fh);
    my $hash = $hasher->digest();
    return unpack('H*', $hash);
}
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Archive::BagIt::Plugin::Algorithm::BLAKE3 - The Blake3 algorithm plugin

=head1 VERSION

version 0.002

=head2 get_hash_string($fh)

calc digest of file
returns the digest result as hex string

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/Archive::BagIt::Plugin::BLAKE3/>.

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<http://rt.cpan.org>.

=head1 AUTHOR

Andreas Romeyke <cpan@andreas.romeyke.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Andreas Romeyke.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
