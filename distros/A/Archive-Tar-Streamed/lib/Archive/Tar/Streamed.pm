
package Archive::Tar::Streamed;
use strict;

BEGIN {
	use vars qw ($VERSION @ISA);
	$VERSION     = 0.03;
}

use Archive::Tar;
use Archive::Tar::Constant;
use Carp;

sub new {
	my ($pkg,$arch) = @_;

	bless {file => $arch}, $pkg;
}

sub add {
    my $self = shift;

    my $arch = Archive::Tar->new;
    $arch->add_files(@_) or croak "add: $!";
    my $tf = $arch->write;
    syswrite $self->{file}, $tf, length($tf) - (BLOCK * 2);
}

sub next {
    my $self = shift;

    $self->{pending} ||= [];
    return shift @{$self->{pending}} if @{$self->{pending}};
    my $arch = Archive::Tar->new;
    my ($fil,@pend) = $arch->read( $self->{file}, 0, {limit => 1});
    $self->{pending} = \@pend;
    $fil;
}

sub writeeof {
    my $self = shift;

    syswrite $self->{file},TAR_END;
}

1; 
__END__
=head1 NAME

Archive::Tar::Streamed - Tar archives, non memory resident

=head1 SYNOPSIS

  use Archive::Tar::Streamed;

  my $fh;
  open $fh,'>','/home/myarch.tar' or die "Couldn't create archive";
  binmode $fh;
  my $tar = Archive::Tar::Streamed->new($fh);
  $tar->add('file1');
  $tar->add(@files);

  my $fh2l
  open $fh2,'<','prevarch.tar' or die "Couldn't open archive";
  binmode $fh;
  my $tar2 = Archive::Tar::Streamed->new($fh2);
  my $fil = $tar2->next;

=head1 DESCRIPTION

The L<Archive::Tar> module is a powerfull tool for manipulating archives from 
perl. However, most of the time, this module needs the entire archive to be
resident in memory. This renders the module per se, not to be directly usable
for very large archive (of the order of gigabytes).

Archive::Tar::Streamed provides a wrapper, which allows working with tar
archives on disk, with no need for the archive to be memory resident.

This module provides an alternative answer to the FAQ "Isn't Archive::Tar 
heavier on memory than /bin/tar?". It also aims to be portable, and available
on platforms without a native tar.

=head2 add

This is a method call to add one or more files to an archive. These are written
to disk before the method returns.

=head2 next

This method is an iterator, which returns an L<Archive::Tar::File> object
for the next file, or undef. undef indicates the end of the archive; any 
unexpected conditions result in throwing an exception.

=head1 BUGS

Please use http://rt.cpan.org to report any bugs in this module

=head1 AUTHOR

	I. Williams
	bitumen@xemaps.com

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

L<Archive::Tar>

