#ABSTRACT: The role to load md5 plugin (default for v0.97)
package Archive::BagIt::Plugin::Manifest::MD5;
use strict;
use warnings;
use Digest::MD5;
use Moo;
with 'Archive::BagIt::Role::Manifest';

has '+plugin_name' => (
    is => 'ro',
    default => 'Archive::BagIt::Plugin::Manifest::MD5',
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
    $self->bagit->load_plugins(("Archive::BagIt::Plugin::Algorithm::MD5"));
    $self->algorithm($self->bagit->plugins->{"Archive::BagIt::Plugin::Algorithm::MD5"});
    return 1;
}

sub verify_file {
    my ($self, $fh) = @_;
    return;
}

sub verify {
    my ($self) =@_;
    return;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Archive::BagIt::Plugin::Manifest::MD5 - The role to load md5 plugin (default for v0.97)

=head1 VERSION

version 0.069

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
