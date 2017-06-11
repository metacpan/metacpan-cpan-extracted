package DDG::Meta::ShareDir;
our $AUTHORITY = 'cpan:DDG';
# ABSTRACT: Installing functions for easy access to the module sharedir
$DDG::Meta::ShareDir::VERSION = '1017';
use strict;
use warnings;
use Carp qw( croak );
use Module::Data;
use Path::Class;
use Package::Stash;
use File::ShareDir ':ALL';

require Moo::Role;


my %applied;

sub apply_keywords {
	my ( $class, $target ) = @_;

	return if exists $applied{$target};
	$applied{$target} = undef;

	my @parts = split('::',$target);
	shift @parts;
	unshift @parts, 'share';
	my $share_path = join('/',map { s/([a-z])([A-Z])/$1_$2/g; lc; } @parts);

	my $moddata = Module::Data->new($target);
	my $basedir = $moddata->root->parent;

	my $share;

	if ( get_lib($basedir) and get_share($basedir) ) {
		my $dir = dir($basedir,$share_path);
		$share = $dir if -d $dir;
	} else {
		eval {
			my $dir = module_dir($target);
			$share = dir($dir) if -d $dir;
		}
	}

	if ($share) {
		my $stash = Package::Stash->new($target);


		$stash->add_symbol('&share', sub {
			@_ ? -d dir($share,@_)
				? $share->subdir(@_)
				: $share->file(@_)
			: $share
		});


		$stash->add_symbol('&module_share_dir', sub { $share_path });

		#
		# apply role
		#

		Moo::Role->apply_role_to_package($target,'DDG::HasShareDir');
	}

}

# Temporarily add support for both `subdir` and `child` methods
# to ensure backwards compatibilty while we upgrade Module::Data
# throughout our stack
# More info: https://github.com/duckduckgo/duckduckgo/pull/244 
sub get_lib {
	my $basedir = shift;
	return -e $basedir->subdir('lib') if $basedir->can('subdir');
	return -e $basedir->child('lib');
}

sub get_share {
	my $basedir = shift;
	return -e $basedir->subdir('share') if $basedir->can('subdir');
	return -e $basedir->child('share');
}
1;

__END__

=pod

=head1 NAME

DDG::Meta::ShareDir - Installing functions for easy access to the module sharedir

=head1 VERSION

version 1017

=head1 DESCRIPTION

This package installs the function required for using a sharedir and also
provides the function L<share> for easy access to it.

B<Warning>: This function only installs its function when there is a sharedir
at the proper directory inside the repository, else it will fail. You cant
define that directory for yourself, the complete concept requires staying to
the convention, see L</module_share_dir>.

=head1 EXPORTS FUNCTIONS

=head2 share

This function gives direct access to sharedir content. For example with

  my $file = share('somefile.txt');

you will get a L<Path::Class::File> object of this specific file inside
your sharedir. It works in development and inside the live system after
installation of the module.

=head2 module_share_dir

This function gets installed as part of the requirements a sharedir must
provide. It gives back the path inside the repository where the sharedir
of this module is placed. B<DDG::Spice::TestTest> gets to
B<share/spice/test_test>.

=head1 METHODS

=head2 apply_keywords

Uses a given classname to install the described keywords.

It also adds the role L<DDG::HasShareDir> to the target classname if the
class has a sharedir.

=head1 AUTHOR

DuckDuckGo <open@duckduckgo.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by DuckDuckGo, Inc. L<https://duckduckgo.com/>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
