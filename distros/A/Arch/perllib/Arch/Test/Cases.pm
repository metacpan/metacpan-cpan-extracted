# Arch Perl library, Copyright (C) 2005 Enno Cramer
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

package Arch::Test::Cases;

use Arch::Test::Framework;
use Arch::Test::Tree;

sub generate_empty_tree ($$;$) {
	my $fw = shift;

	return $fw->make_tree(@_);
}

sub generate_trivial_tree ($$;$) {
	my $tree = &generate_empty_tree(@_);

	foreach my $f (qw(README INSTALL COPYING)) {
		$tree->add_file('.', $f);
	}

	return $tree;
}

sub generate_simple_tree ($$;$) {
	my $tree = &generate_trivial_tree(@_);

	my $inc = $tree->add_dir('.', 'include');
	my $src = $tree->add_dir('.', 'src');
	my $bld = $tree->add_dir('.', 'build');

	foreach my $f (qw(io.h logic.h)) {
		$tree->add_file($inc, $f);
	}

	foreach my $f (qw(io.c logic.c main.c)) {
		$tree->add_file($src, $f);
	}

	$tree->add_file('.', 'Makefile');

	return $tree;
}

sub generate_complex_tree ($$;$) {
	my $tree = &generate_trivial_tree(@_);

	my $version = join('--', reverse split(/\//, $_[1]));

	my $inc = $tree->add_dir('.', 'include');
	my $src = $tree->add_dir('.', 'src');
	my $dat = $tree->add_dir('.', 'data');

	# text source files
	foreach my $d (qw(base util io mem)) {
		my $inc_sub = $tree->add_dir($inc, $d);
		my $src_sub = $tree->add_dir($src, $d);

		for (1..10) {
			$tree->add_file($inc_sub);
			$tree->add_file($src_sub);
		}
	}

	# binary files
	for (1..3) {
		$tree->add_file($dat, undef, pack('CCCC', 1, 2, 3, 4));
	}

	# symlink
	$tree->add_link('.', 'LICENSE', 'COPYING');
	
	# clutter
	$tree->add_dir('.', ',,undo-1');
	$tree->add_file('.', "++log.$version~");
	$tree->add_file('.', '+notes');
	$tree->add_file('.', 'README~');
	
	return $tree;
}
	

1;

__END__

=head1 NAME

Arch::Test::Cases - A test framework for Arch-Perl

=head1 SYNOPSIS 

    use Arch::Test::Framework;

    my $fw = Arch::Test::Framework->new;
    my $ver = $fw->make_version;

    my $tree = Arch::Test::Cases::generate_complex_tree($fw, $ver);

=head1 DESCRIPTION

Arch::Test::Tree provides methods to quickly build and modify Arch
project trees within the Arch::Test framework.

=head1 METHODS

B<generate_empty_tree>,
B<generate_trivial_tree>,
B<generate_simple_tree>,
B<generate_complex_tree>.

=over 4

=item B<generate_empty_tree> I<framework> I<version> [I<name>]

Create a new project tree for I<version>. Equivalent to

  $framework->make_tree($version, $name);

=item B<generate_tivial_tree> I<framework> I<version> [I<name>]

Create a new project tree for I<version> with basic files.

=item B<generate_simple_tree> I<framework> I<version> [I<name>]

Create a new project tree for I<version> with basic and source files.

=item B<generate_complex_tree> I<framework> I<version> [I<name>]

Create a new project tree for I<version> with basic and source files
and a bit of clutter.

=back

=head1 AUTHORS

Mikhael Goikhman (migo@homemail.com--Perl-GPL/arch-perl--devel).

Enno Cramer (uebergeek@web.de--2003/arch-perl--devel).

=cut
