package App::Web::VPKBuilder;

use 5.014000;
use strict;
use warnings;
use parent qw/Plack::Component/;
use re '/s';
our $VERSION = '0.001';

use File::Find qw/find/;
use File::Path qw/remove_tree/;
use File::Spec::Functions qw/abs2rel catfile rel2abs/;
use File::Temp qw/tempdir/;
use IO::Compress::Zip qw/zip ZIP_CM_LZMA/;
use sigtrap qw/die normal-signals/;

use Data::Diver qw/DiveRef/;
use File::Slurp qw/write_file/;
use HTML::Element;
use HTML::TreeBuilder;
use Hash::Merge qw/merge/;
use List::MoreUtils qw/uniq/;
use Plack::Request;
use Sort::ByExample qw/sbe/;
use YAML qw/LoadFile/;

sub new {
	my $self = shift->SUPER::new(@_);
	$self->{cfg} = {};
	for (sort <cfg/*>) {
		my $cfg = LoadFile $_;
		$self->{cfg} = merge $self->{cfg}, $cfg
	}
	$self->{cfg}{vpk_extension} //= 'vpk';
	$self->{cfg}{sort} = sbe $self->{cfg}{sort_order}, { fallback => sub { shift cmp shift } };
	$self
}

sub addpkg {
	my ($pkg, $dir) = @_;
	return unless $pkg =~ /^[a-zA-Z0-9_-]+$/aa;
	my @dirs = ($dir);
	find {
		postprocess => sub { pop @dirs },
		wanted => sub {
			my $dest = catfile @dirs, $_;
			mkdir $dest if -d;
			push @dirs, $_ if -d;
			link $_, $dest if -f;
	}}, catfile 'pkg', $pkg;
}

sub makepkg {
	my ($self, @pkgs) = @_;
	mkdir $self->{cfg}{dir};
	my $dir = rel2abs tempdir 'workXXXX', DIR => $self->{cfg}{dir};
	my $dest = catfile $dir, 'pkg';
	mkdir $dest;
	@pkgs = grep { exists $self->{cfg}{pkgs}{$_} } @pkgs;
	push @pkgs, split /,/, ($self->{cfg}{pkgs}{$_}{deps} // '') for @pkgs;
	@pkgs = uniq @pkgs;
	addpkg $_, $dest for @pkgs;
	write_file catfile ($dir, 'readme.txt'), $self->{cfg}{readme};
	my @zip_files = catfile $dir, 'readme.txt';
	if ($self->{cfg}{vpk}) {
		system $self->{cfg}{vpk} => $dest;
		push @zip_files, catfile $dir, "pkg.$self->{cfg}{vpk_extension}"
	} else {
		find sub { push @zip_files, $File::Find::name if -f }, $dest;
	}
	zip \@zip_files, catfile($dir, 'pkg.zip'), FilterName => sub { $_ = abs2rel $_, $dir }, -Level => 1;
	open my $fh, '<', catfile $dir, 'pkg.zip' or return [500, ['Content-Type' => 'text/plain;charset=utf-8'], ['Error opening pkg.zip']]; ## no critic (RequireBriefOpen)
	remove_tree $dir;
	[200, ['Content-Type' => 'application/zip', 'Content-Disposition' => 'attachment; filename=pkg.zip'], $fh]
}

sub makelist {
	my ($self, $elem, $tree, $lvl, $key) = @_;
	my $name = HTML::Element->new('span', class => 'name');
	$name->push_content($key);
	$elem->push_content($name) if defined $key;
	if (ref $tree eq 'ARRAY') {
		my $sel = HTML::Element->new('select', name => 'pkg');
		my $opt = HTML::Element->new('option', value => '');
		$opt->push_content('None');
		$sel->push_content($opt);
		for my $pkg (sort { $a->{name} cmp $b->{name} } @$tree) {
			my $option = HTML::Element->new('option', value => $pkg->{pkg}, $pkg->{default} ? (selected => 'selected') : ());
			$option->push_content($pkg->{name});
			$sel->push_content($option);
		}
		$elem->push_content($sel);
	} else {
		my $ul = HTML::Element->new('ul');
		for my $key ($self->{cfg}{sort}->(keys %$tree)) {
			my $li = HTML::Element->new('li', class => "level$lvl");
			$self->makelist($li, $tree->{$key}, $lvl + 1, $key);
			$ul->push_content($li);
		}
		$elem->push_content($ul);
	}
}

sub makeindex {
	my ($self) = @_;
	my ($pkgs, $tree) = ($self->{cfg}{pkgs}, {});
	for (keys %$pkgs) {
		my $ref = DiveRef ($tree, split /,/, $pkgs->{$_}{path});
		$$ref = [] unless ref $$ref eq 'ARRAY';
		push @{$$ref}, {pkg => $_, name => $pkgs->{$_}{name}, default => $pkgs->{$_}{default}};
	}
	my $html = HTML::TreeBuilder->new_from_file('index.html');
	$self->makelist(scalar $html->look_down(id => 'list'), $tree, 1);
	my $ret = $html->as_HTML('', ' ');
	utf8::encode($ret);
	[200, ['Content-Type' => 'text/html;charset=utf-8'], [$ret]]
}

sub call{
	my ($self, $env) = @_;
	my $req = Plack::Request->new($env);
	return $self->makepkg($req->param('pkg')) if $req->path eq '/makepkg';
	$self->makeindex;
}

1;
__END__

=encoding utf-8

=head1 NAME

App::Web::VPKBuilder - Mix & match Source engine game mods

=head1 SYNOPSIS

  use Plack::Builder;
  use App::Web::VPKBuilder;
  builder {
    enable ...;
    enable ...;
    App::Web::VPKBuilder->new->to_app
  }

=head1 DESCRIPTION

App::Web::VPKBuilder is a simple web service for building Source engine game VPK packages. It presents a list of mods sorted into (sub)categories. The user can choose a mod from each category and will get a VPK containing all of the selected packages.

=head1 CONFIGURATION

APP::Web::VPKBuilder is configured via YAML files in the F<cfg> directory. The recommended layout is to have an F<options.yml> file with the global options, and one file for each source mod (original mod that may be split into more mods).

=head2 Global options

=over

=item readme

A string representing the contents of the readme.txt file included with the package.

=item sort_order

An array of strings representing the sort order of (sub)categories. (sub)categories appear in this order. (sub)categories that are not listed appear in alphabetical order after those listed.

=item dir

A string representing the directory in which the packages are built. Must be on the same filesystem as the package directory (F<pkg/>). Is created if it does not exist (but its parents must exist).

=item vpk

A string representing the program that makes a package out of a folder. Must behave like the vpk program included with Source engine games: that is, when called like C<vpk path/to/folder> it should create a file F<path/to/folder.ext>, where C<ext> is given by the next option. If not provided, the folder is included as-is.

=item vpk_extension

The extension of a package. Only useful with the C<vpk> option. Defaults to C<vpk>

=back

Example:

  ---
  readme: "Place the .vpk file in your custom directory (<steam root>/SteamApps/common/Team Fortress 2/tf/custom/)"
  sort_order: [Scout, Soldier, Pyro, Demoman, Heavy, Engineer, Medic, Sniper, Spy, Sounds, Model]
  dir: work
  vpk: ./vpk
  vpk_extension: vpk

=head2 Mods

Each source mod is composed of one or more directories (mods) in the F<pkg/> directory and a config file. Each config file should contain a hash named C<pkgs>. For each directory the hash should contain an entry with the directory name as key. Mod directory names may only contain the characters C<a-zA-Z0-9_->.

Mod options:

=over

=item name

A string representing the (human readable) name of the mod.

=item path

A comma-delimited string of the form C<category,subcategory,subcategory,...,item>. There can be any number of subcategories, but the default stylesheet is made for two-element paths (C<category,item>).

If multiple mods have the same path, the user will be allowed to choose at most one of them.

=item default

A boolean which, if true, marks this mod as the default mod for its path.

=item deps

A comma-delimited string representing a list of mods that must be included in the final package if this mod is included. The pkgs hash need not contain an entry for the dependencies.

For example, if two mods share a large part of their contents, then the shared part could be split into a third mod, and both of the original mods should depend on it. This third mod should not be included in the hash, as it shouldn't need to be manually selected by the user.

=back

Example:

  ---
  pkgs:
    mymod-basher:
      name: MyMod
      path: "Scout,Boston Basher"
      default: true
      deps: mymod-base
    mymod-sandman:
      name: MyMod
      path: "Scout,Sandman"
      default: true
      deps: mymod-base


=head1 TODO

For 1.000:
* Tests
* More/Clearer documentation
* Nicer user interface

=head1 AUTHOR

Marius Gavrilescu, E<lt>marius@ieval.roE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014-2015 by Marius Gavrilescu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
