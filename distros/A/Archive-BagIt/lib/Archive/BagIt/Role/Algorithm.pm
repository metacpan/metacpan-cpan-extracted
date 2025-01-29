package Archive::BagIt::Role::Algorithm;
use strict;
use warnings;
use Moo::Role;
use Carp qw(croak);
with 'Archive::BagIt::Role::Plugin';
# ABSTRACT: A role that defines the interface to a hashing algorithm
our $VERSION = '0.096'; # VERSION

has 'name' => (
    is => 'ro',
);


sub get_optimal_bufsize {
    my ($self, $fh) = @_;
    my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
        $atime,$mtime,$ctime,$blksize,$blocks)
        = stat $fh;
    # Windows systems return "" for $blksize
    if ((defined $blksize ) && ($blksize ne "") && ($blksize >= 512)) {
        return $blksize;
    }
    return 8192;
}

sub register_plugin {
    my ($class, $bagit) =@_;
    my $self = $class->new({bagit=>$bagit});
    my $plugin_name = $self->plugin_name;
    $self->bagit->plugins( { $plugin_name => $self });
    $self->bagit->algos( {$self->name => $self });
    return 1;
}
no Moo;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Archive::BagIt::Role::Algorithm - A role that defines the interface to a hashing algorithm

=head1 VERSION

version 0.096

=head2 get_optimal_bufsize($fh)

uses L<stat> to determine optimal filesize, defaults to 8192

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
