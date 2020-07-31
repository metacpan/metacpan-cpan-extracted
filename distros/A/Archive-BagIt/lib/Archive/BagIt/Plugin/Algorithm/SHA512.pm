#ABSTRACT: The default SHA algorithms plugin (default for v1.0)
package Archive::BagIt::Plugin::Algorithm::SHA512;
use strict;
use warnings;
use Carp;
use Moo;
use namespace::autoclean;
with 'Archive::BagIt::Role::Algorithm';

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
    my $digest = Digest::SHA->new("512");
    return $digest;
}

sub get_hash_string {
    my ($self, $fh) = @_;
    my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
        $atime,$mtime,$ctime,$blksize,$blocks)
        = stat $fh;
    if ((!defined $blksize) || (length($blksize) < 1) || ($blksize <1)) {
        $blksize = 8192;
    }
    my $buffer;
    while (read($fh, $buffer, $blksize)) {
        $self->_digest->add($buffer);
    }
    return $self->_digest->hexdigest;
}

sub verify_file {
    my ($self, $filename) = @_;
    open(my $fh, '<:raw', $filename) || croak ("Can't open '$filename', $!");
    binmode($fh);
    my $digest = $self->get_hash_string($fh);
    close $fh || croak("could not close file '$filename', $!");
    return $digest;
}
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Archive::BagIt::Plugin::Algorithm::SHA512 - The default SHA algorithms plugin (default for v1.0)

=head1 VERSION

version 0.063

=head1 NAME

Archive::BagIt::Plugin::Algorithm::SHA512 - The default SHA algorithms plugin (default for v1.0)

=head1 VERSION

version 0.063

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

=head1 AUTHOR

Rob Schmidt <rjeschmi@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Rob Schmidt and William Wueppelmann and Andreas Romeyke.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
