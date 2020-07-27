use strict;
use warnings;

#ABSTRACT: The default MD5 algorithm plugin

package Archive::BagIt::Plugin::Algorithm::MD5;

use Moo;
use namespace::autoclean;

with 'Archive::BagIt::Role::Algorithm';

has '+plugin_name' => (
    is => 'ro',
    default => 'Archive::BagIt::Plugin::Algorithm::MD5',
);

has '+name' => (
    is      => 'ro',
    #isa     => 'Str',
    default => 'md5',
);

has '_digest' => (
    is => 'ro',
    lazy => 1,
    builder => '_build_digest_md5',
    init_arg => undef,
);

sub _build_digest_md5 {
    my ($self) = @_;
    my $digest_md5 = new Digest::MD5;
    return $digest_md5;
}

sub get_hash_string {
    my ($self, $fh) = @_;
    my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
        $atime,$mtime,$ctime,$blksize,$blocks)
        = stat $fh;
    my $buffer;
    while (read($fh, $buffer, $blksize)) {
        $self->_digest->add($buffer);
    }
    return $self->_digest->hexdigest;

}

sub verify_file {
    my ($self, $filename) = @_;
    open(my $fh, '<', $filename) || die ("Can't open '$filename', $!");
    binmode($fh);
    my $digest = $self->get_hash_string($fh);
    close $fh || die("could not close file '$filename', $!");
    return $digest;
}
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Archive::BagIt::Plugin::Algorithm::MD5 - The default MD5 algorithm plugin

=head1 VERSION

version 0.059

=head1 NAME

Archive::BagIt::Plugin::Algorithm::MD5 - The default MD5 algorithm plugin

=head1 VERSION

version 0.059

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/Archive::BagIt/>.

=head1 SOURCE

The development version is on github at L<https://github.com/Archive-BagIt>
and may be cloned from L<git://github.com/Archive-BagIt.git>

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<http://rt.cpan.org>.

=head1 AUTHOR

Rob Schmidt <rjeschmi@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Rob Schmidt and William Wueppelmann.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 AUTHOR

Rob Schmidt <rjeschmi@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Rob Schmidt and William Wueppelmann.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
