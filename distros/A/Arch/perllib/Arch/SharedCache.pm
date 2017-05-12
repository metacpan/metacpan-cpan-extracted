# Arch Perl library, Copyright (C) 2004 Mikhael Goikhman
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

use 5.005;
use strict;

package Arch::SharedCache;

use base 'Arch::SharedIndex';
use Arch::Util qw(save_file load_file);

sub new ($%) {
	my $class = shift;
	my %init = @_;

	my $dir = $init{dir} or die "No cache directory given\n";
	unless (-d $dir) {
		mkdir($dir, 0777) or die "Can't create cache directory $dir: $!\n";
	}
	-d $dir or die "No cache directory ($dir)\n";

	my $index_file = $init{index_file} || $init{file} || '.index';
	$index_file = "$dir/$index_file" unless $index_file =~ m!^\.?/!;

	my $self = $class->SUPER::new(
		# default to a more readable serialization output
		perl_data_indent => 1,
		perl_data_pair   => " => ",
		%init,
		file => $index_file,
	);
	$self->{dir} = $dir;
	$self->{generic_filenames} = $init{generic_filenames} || 0;

	return $self;
}

sub generate_unique_token ($) {
	my $self = shift;
	my $dir = $self->{dir};
	my $prefix = time() . "-";
	my $token = $prefix . "000000";
	return $token unless -e "$dir/$token";
	my $tries = 1000000;
	do {
		$token = $prefix . sprintf("%06d", rand(1000000));
	} while -e "$dir/$token" && --$tries;
	die "Failed to acquire unused file name $dir/$prefix*\n" unless $tries;
	return $token;
}

sub file_name_by_token ($$) {
	my $self = shift;
	my $token = shift;
	$token =~ s!/!%!g;
	return "$self->{dir}/$token";
}

sub delete_value ($$$) {
	my $self = shift;
	my ($key, $token) = @_;
	$token = $key if $token eq "";
	my $file_name = $self->file_name_by_token($token);
	return unless -e $file_name;
	unlink($file_name) or warn "Can't unlink $file_name: $!\n";
}

sub fetch_value ($$$) {
	my $self = shift;
	my ($key, $token) = @_;
	$token = $key if $token eq "";
	my $file_name = $self->file_name_by_token($token);
	my $value = eval { load_file($file_name); };
	warn $@ if $@;
	$self->decode_value(\$value);
	return $value;
}

sub store_value ($$$) {
	my $self = shift;
	my ($key, $token, $value) = @_;
	$token = $key
		if defined $token && $token eq "";
	$token = $key
		if !defined $token && !$self->{generic_filenames};
	$token = $self->generate_unique_token
		if !defined $token || $token eq "";
	my $file_name = $self->file_name_by_token($token);
	$self->encode_value(\$value);
	eval { save_file($file_name, \$value); };
	warn $@ if $@;
	$token = "" if $key eq $token;
	$token = undef if $@;
	return $token;
}

1;

__END__

=head1 NAME

Arch::SharedCache - a synchronized data structure (map) for IPC

=head1 SYNOPSIS

    use Arch::SharedCache;

    my $cache = Arch::SharedCache->new(
        dir => '/tmp/dir-listings',
        max_size   => 100,
        expiration => 600,  # 10 minutes
    );

    sub ls_long { scalar `ls -l $_[0]` }

    my $user_dir = '/usr/share';
    $cache->store($user_dir => ls_long($user_dir));
    $cache->fetch_store(sub { ls_long($_[0]) }, qw(/tmp /bin /usr/share));
    printf "Cached listing of $user_dir:\n%s", $cache->fetch($user_dir);
    $cache->delete($user_dir);

    # examine /tmp/dir-listings/ after running this script
    # see also synopsys of Arch::SharedIndex

=head1 DESCRIPTION

Arch::SharedCache provides an Arch::SharedIndex implementation using a
single file per value.

=head1 METHODS

The following methods are available:

B<new>.

Other methods are documented in L<Arch::SharedIndex>.

=over 4

=item B<new> I<options>

Create a new Arch::SharedCache object.  I<options> is a hash of options.

=over 4

=item B<dir>

The cache directory used to store data.  Will be created if it doesn't exist.

=item B<index_file>

Name of the index file for the cache.  Defaults to C<B<dir>/.index>.

=back

=back

=head1 BUGS

Awaiting for your reports.

=head1 AUTHORS

Mikhael Goikhman (migo@homemail.com--Perl-GPL/arch-perl--devel).

Enno Cramer (uebergeek@web.de--2003/arch-perl--devel).

=head1 SEE ALSO

For more information, see L<Arch::SharedIndex>.

=cut
