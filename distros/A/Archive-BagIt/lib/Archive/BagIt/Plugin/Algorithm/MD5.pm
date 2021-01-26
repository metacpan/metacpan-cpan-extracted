#ABSTRACT: The MD5 algorithm plugin (default for v0.97)
package Archive::BagIt::Plugin::Algorithm::MD5;
use strict;
use warnings;
use Carp;
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
    my $digest = Digest::MD5->new();
    return $digest;
}

sub get_hash_string {
    my ($self, $fh) = @_;
    my $blksize = $self->get_optimal_bufsize($fh);
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

Archive::BagIt::Plugin::Algorithm::MD5 - The MD5 algorithm plugin (default for v0.97)

=head1 VERSION

version 0.072

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

This software is copyright (c) 2021 by Rob Schmidt and William Wueppelmann and Andreas Romeyke.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
