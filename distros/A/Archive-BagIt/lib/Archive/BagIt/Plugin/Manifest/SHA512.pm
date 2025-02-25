package Archive::BagIt::Plugin::Manifest::SHA512;
# ABSTRACT: The role to load the sha512 plugin (default for v1.0)
our $VERSION = '0.100'; # VERSION

use strict;
use warnings;
use Moo;
with 'Archive::BagIt::Role::Manifest';

has '+plugin_name' => (
    is => 'ro',
    default => 'Archive::BagIt::Plugin::Manifest::SHA512',
);

has 'manifest_path' => (
    is => 'ro',
);

has 'manifest_files' => (
    is => 'ro',
);

has '+algorithm' => (
    is => 'rw',
);

sub BUILD {
    my ($self) = @_;
    $self->bagit->load_plugins(("Archive::BagIt::Plugin::Algorithm::SHA512"));
    $self->algorithm($self->bagit->plugins->{"Archive::BagIt::Plugin::Algorithm::SHA512"});
    return 1;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Archive::BagIt::Plugin::Manifest::SHA512 - The role to load the sha512 plugin (default for v1.0)

=head1 VERSION

version 0.100

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
