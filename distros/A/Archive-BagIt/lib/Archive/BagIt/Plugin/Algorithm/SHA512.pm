package Archive::BagIt::Plugin::Algorithm::SHA512;
use strict;
use warnings;
use Carp qw( croak );
use Moo;
use namespace::autoclean;
with 'Archive::BagIt::Role::Algorithm';
with 'Archive::BagIt::Role::OpenSSL';
our $VERSION = '0.085'; # VERSION
# ABSTRACT: The default SHA algorithms plugin (default for v1.0)

has '+plugin_name' => (
    is => 'ro',
    default => 'Archive::BagIt::Plugin::Algorithm::SHA512',
);

has '+name' => (
    is      => 'ro',
    #isa     => 'Str',
    default => 'sha512',
);

has '_digest' => (
    is => 'ro',
    lazy => 1,
    builder => '_build_digest_sha',
    init_arg => undef,
);

sub _build_digest_sha {
    my ($self) = @_;
    return $self->_init_digest();
}


__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Archive::BagIt::Plugin::Algorithm::SHA512 - The default SHA algorithms plugin (default for v1.0)

=head1 VERSION

version 0.085

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

This software is copyright (c) 2021 by Rob Schmidt <rjeschmi@gmail.com>, William Wueppelmann and Andreas Romeyke.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
