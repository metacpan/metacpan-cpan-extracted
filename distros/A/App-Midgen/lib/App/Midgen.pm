package App::Midgen;

use 5.008001;
use constant {BLANK => q{ }, NONE => q{}, TWO => 2, THREE => 3, TRUE => 1,
	FALSE => 0,};

use Moo;
with qw(
	App::Midgen::Role::Options
	App::Midgen::Role::Attributes
	App::Midgen::Role::AttributesX
	App::Midgen::Role::InDistribution
	App::Midgen::Role::TestRequires
	App::Midgen::Role::UseOk
	App::Midgen::Role::Eval
	App::Midgen::Role::FindMinVersion
	App::Midgen::Role::Output
	App::Midgen::Role::UseModule
	App::Midgen::Role::Experimental
	App::Midgen::Role::Heuristics
);

# Load time and dependencies negate execution time
# use namespace::clean -except => 'meta';
use version;
our $VERSION = '0.34';
$VERSION = eval $VERSION;    ## no critic

use English qw( -no_match_vars );    # Avoids reg-ex performance penalty
local $OUTPUT_AUTOFLUSH = 1;

use Cwd qw(getcwd);
use Data::Printer {caller_info => 1,};
use File::Find qw(find);
use File::Spec;
use Module::CoreList;
use PPI;
use Term::ANSIColor qw( :constants colored colorstrip );
use Try::Tiny;
use Tie::Static qw(static);
use version;

# stop rlib from Fing all over cwd
our $Working_Dir = getcwd();
our $Min_Version = 0;


#######
# run
#######
sub run {
	my $self = shift;

	$self->_initialise();
	try {
		$self->first_package_name();
	};


	$self->find_runtime_modules();
	$self->find_test_modules();
	$self->find_develop_modules() if $self->experimental;

	#now for some Heuristics :)
	$self->recast_to_runtimerequires($self->{RuntimeRequires},
		$self->{RuntimeRecommends});
	$self->recast_to_testrequires($self->{TestRequires}, $self->{TestSuggests});

	# Now we have switched to MetaCPAN-Api we can hunt for noisy children in tests
	if ($self->experimental) {

		$self->remove_noisy_children($self->{RuntimeRequires});
		$self->remove_twins($self->{RuntimeRequires});

		# Run a second time if we found any twins, this will sort out twins and triplets etc
		$self->remove_noisy_children($self->{RuntimeRequires})
			if $self->found_twins;

		foreach (qw( TestRequires TestSuggests DevelopRequires )) {

			p $self->{$_} if $self->debug;
			$self->remove_noisy_children($self->{$_});
			foreach my $module (keys %{$self->{$_}}) {
				if ($self->{RuntimeRequires}{$module}) {
					warn $module if $self->debug;
					try {
						delete $self->{$_}{$module};
					};
				}
			}
			p $self->{$_} if $self->debug;
		}
	}

	# display chosen output format
	$self->output_header();
	$self->output_main_body('RuntimeRequires',   $self->{RuntimeRequires});
	$self->output_main_body('RuntimeRecommends', $self->{RuntimeRecommends})
		if $self->meta2;
	$self->output_main_body('TestRequires', $self->{TestRequires});
	if ($self->meta2) {
		$self->output_main_body('TestSuggests', $self->{TestSuggests});
		$self->output_main_body('Close', {});
		$self->output_main_body('DevelopRequires', $self->{DevelopRequires});
	}
	else {

		# concatenate hashes
		try {
			%{$self->{recommends}} = (%{$self->{RuntimeRecommends}},);
		};
		try {
			%{$self->{recommends}}
				= (%{$self->{recommends}}, %{$self->{TestSuggests}},);
		};
		try {
			%{$self->{recommends}}
				= (%{$self->{recommends}}, %{$self->{DevelopRequires}},);
		};
		$self->output_main_body('recommends', $self->{recommends});
	}

	$self->output_footer();

	#now for tidy-up Heuristics :)
	$self->remove_inc_mi() if ( $self->{format} eq 'dsl' or 'mi' );

	p $self->{modules} if ($self->verbose == TWO);

	return;
}

#######
# initialise
#######
sub _initialise {
	my $self = shift;

	# let's give Output a copy, to stop it being F'up as well, suspect Tiny::Path as-well rlib
	warn 'working in dir: ' . $Working_Dir if $self->debug;

	return;
}

#######
# first_package_name
#######
sub first_package_name {
	my $self = shift;

	try {
		find(
			sub { _find_package_names($self); },
			File::Spec->catfile($Working_Dir, 'lib')
		);
	};

	p $self->package_names if $self->debug;

	# We will assume the first package found is our Package Name, pot lock :)
	# due to Milla not being a dist we go and get dist-name

	try {
		my $is_package_name = $self->package_names->[0];
		$is_package_name =~ s{::}{-}g;

		# MetaCPAN::Client expects hyphens in distribution search
		my $mcpan_dist_info = $self->mcpan->distribution($is_package_name);
		my $distribution_name = $mcpan_dist_info->name();

		$distribution_name =~ s{-}{::}g;
		$self->_set_distribution_name($distribution_name);
	}
	catch {
		$self->_set_distribution_name($self->package_names->[0]);
	};

	# I still want to see package name even though infile sets verbose = 0
	print 'Package: ' . $self->distribution_name . "\n"
		if $self->verbose
		or $self->format eq 'infile';

	return;
}
#######
# find_package_name
#######
sub _find_package_names {
	my $self     = shift;
	my $filename = $_;
	static \my $files_checked;
	if (defined $files_checked) {
		return if $files_checked >= THREE;
	}

	# Only check in pm files
	return if $filename !~ /[.]pm$/sxm;

	# Load a Document from a file
	$self->_set_ppi_document(PPI::Document->new($filename));

	# Extract package names
	push @{$self->package_names},
		$self->ppi_document->find_first('PPI::Statement::Package')->namespace;
	$files_checked++;

	return;
}


#######
# find_runtime_modules
#######
sub find_runtime_modules {
	my $self = shift;

	my @posiable_directories_to_search
		= map { File::Spec->catfile($Working_Dir, $_) }
		qw( bin share script lib );

	my @directories_to_search = ();
	foreach my $directory (@posiable_directories_to_search) {
		if (defined -d $directory) {
			push @directories_to_search, $directory;
		}
	}
	p @directories_to_search if $self->debug;

	try {
		find(sub { _find_runtime_requirments($self); }, @directories_to_search);
	};

	return;

}
#######
# _find_runtime_requirments
#######
sub _find_runtime_requirments {
	my $self     = shift;
	my $filename = $_;

	return if $self->is_perlfile($filename) == FALSE;
 
	my $relative_dir = $File::Find::dir;
	$relative_dir =~ s/$Working_Dir//;
	$self->_set_looking_infile(File::Spec->catfile($relative_dir, $filename));
	$self->_set_ppi_document(PPI::Document->new($filename));

	# do extra test early check for use_module before hand
	$self->xtests_use_module('RuntimeRecommends');

	# ToDo add eval/try here -> prereqs { runtime { suggests or recommends {...}}}
	$self->xtests_eval('RuntimeRecommends');

	# normal pps -> RuntimeRequires
	my $prereqs = $self->scanner->scan_ppi_document($self->ppi_document);
	my @modules = $prereqs->required_modules;


	foreach my $mod_ver (@modules) {
		$self->{found_version}{$mod_ver}
			= $prereqs->requirements_for_module($mod_ver);
	}

	$self->{skip_not_mcpan_stamp} = 0;

	if (grep { $_ =~ m/^Dist::Zilla::Role::PluginBundle/ } @modules) {

		$self->{skip_not_mcpan_stamp} = 1;

		my $ppi_tqs = $self->ppi_document->find('PPI::Token::Quote::Single');
		if ($ppi_tqs) {

			foreach my $include (@{$ppi_tqs}) {

				my $module = $include->content;
				$module =~ s/^[']//;
				$module =~ s/[']$//;

				next if $module =~ m/^Dist::Zilla::Role::PluginBundle/;
				next if $module =~ m{\A[-|:|\d]};
				next if $module !~ m{\A(?:[[a-zA-Z])};
				next if $module =~ m{[.|$|\\|/|\-|\[|%|@|]};
				next if $module eq NONE;

				push @modules, 'Dist::Zilla::Plugin::' . $module;
			}
		}
	}

	if (scalar @modules > 0) {
		for (0 .. $#modules) {
			try {
				$self->_process_found_modules('RuntimeRequires', $modules[$_],
					$prereqs->requirements_for_module($modules[$_]),
					'Perl::PrereqScanner', 'RuntimeRequires',);
			};
		}
	}

	#run pmv now
	$self->min_version($self->looking_infile) if $self->format ne 'infile';

	return;
}


#######
# find_test_modules
#######
sub find_test_modules {
	my $self = shift;

	my $directory = 't';
	if (defined -d $directory) {

		find(sub { _find_test_develop_requirments($self, $directory); },
			$directory);

	}

	return;

}
#######
# find_develop_modules
#######
sub find_develop_modules {
	my $self = shift;

	my $directory = 'xt';
	if (defined -d $directory) {

		find(sub { _find_test_develop_requirments($self, $directory); },
			$directory);

	}
	return;

}


#######
# _find_test_develop_requirments
#######
sub _find_test_develop_requirments {
	my $self       = shift;
	my $directorie = shift;
	my $filename   = $_;

	##p $directorie;
	my $phase_relationship
		= ($directorie =~ m/xt$/) ? 'DevelopRequires' : 'TestSuggests';
	$self->_set_xtest(TRUE) if $directorie =~ m/xt$/;

	return if $self->is_perlfile($filename) == FALSE;

	my $relative_dir = $File::Find::dir;
	$relative_dir =~ s/$Working_Dir//;
	$self->_set_looking_infile(File::Spec->catfile($relative_dir, $filename));

	# Load a Document from a file and check use and require contents
	$self->_set_ppi_document(PPI::Document->new($filename));

	# don't scan xt/ for pmv
	$self->min_version($filename)
		if $directorie !~ m/xt$/
		or $self->format ne 'infile';


	# do extra test early check for Test::Requires before hand
	$self->xtests_test_requires($phase_relationship);

	# do extra test early check for use_ok in BEGIN blocks before hand
	$self->xtests_use_ok($phase_relationship);

	# do extra test early to identify eval before hand
	$self->xtests_eval($phase_relationship);

	# do extra test early check for use_module before hand
	$self->xtests_use_module($phase_relationship);


	# let's run p-ps for the rest
	my $prereqs = $self->scanner->scan_ppi_document($self->ppi_document);
	my @modules = $prereqs->required_modules;

	p @modules if $self->debug;

	foreach my $mod_ver (@modules) {
		$self->{found_version}{$mod_ver}
			= $prereqs->requirements_for_module($mod_ver);
	}

	if (scalar @modules > 0) {
		for (0 .. $#modules) {

			if ($self->xtest) {
				try {
					$self->_process_found_modules($phase_relationship, $modules[$_],
						$prereqs->requirements_for_module($modules[$_]),
						'Perl::PrereqScanner', $phase_relationship,)
						if $self->meta2;
				};
				try {
					$self->_process_found_modules('DevelopRequires', $modules[$_],
						$prereqs->requirements_for_module($modules[$_]),
						'Perl::PrereqScanner', 'DevelopRequires',)
						if not $self->meta2;
				};
			}
			else {
				try {
					$self->_process_found_modules('TestRequires', $modules[$_],
						$prereqs->requirements_for_module($modules[$_]),
						'Perl::PrereqScanner', 'TestRequires',);
				};
			}
		}
	}
	return;
}


#######
# composed method - _process_found_modules
#######
sub _process_found_modules {
	my $self          = shift;
	my $require_type  = shift;
	my $module        = shift;
	my $version       = shift || 0;
	my $extra_scanner = shift || 'none';
	my $pr_location   = shift || 'none';

	p $module       if $self->debug;
	p $version      if $self->debug;
	p $require_type if $self->debug;

	#deal with ''
	next if $module eq NONE;

	# let's show every thing we can find infile
	if ($self->format ne 'infile') {

		my $distribution_name = $self->distribution_name || 'm/t';

		if ($module =~ /perl/sxm) {

			# ignore perl we will get it from minperl required
			next;
		}
		elsif ($module =~ /\A\Q$distribution_name\E/sxm) {

			# don't include our own packages here
			next;
		}
		elsif ($module =~ /^t::/sxm) {

			# don't include our own test packages here
			next;
		}
		elsif ($module =~ /^inc::Module::Install/sxm) {

			# don't inc::Module::Install as it is really Module::Install
			next;
		}
		elsif ($module =~ /Mojo/sxm) {
			if ($self->experimental) {
				if ($self->_check_mojo_core($module, $require_type)) {
					if (not $self->quiet) {
						print BRIGHT_BLACK;
						print "swapping out $module for Mojolicious\n";
						print CLEAR;
					}
					next;
				}
			}
		}
		elsif ($module =~ /^Padre/sxm) {

			# mark all Padre core as just Padre only, for plugins
			$module = 'Padre';
		}
	}

	# lets keep track of how many times a module include is found
	$self->{modules}{$module}{count} += 1;
	try {
		push @{$self->{modules}{$module}{infiles}},
			[$self->looking_infile(), $version, $extra_scanner, $pr_location,];
	};

	# don't process already found modules
	p $self->{modules}{$module}{prereqs} if $self->debug;

	next if defined $self->{modules}{$module}{prereqs};
	p $module if $self->debug;

	# add skip for infile as we don't need to get v-string from metacpan-api
	$self->_store_modules($require_type, $module) if $self->format ne 'infile';

	return;
}

#######
# composed method - _store_modules
#######
sub _store_modules {
	my $self         = shift;
	my $require_type = shift;
	my $module       = shift;
	p $module if $self->debug;

	$self->_in_corelist($module)
		if not defined $self->{modules}{$module}{corelist};
	my $version = $self->get_module_version($module, $require_type);

	if ($version eq '!mcpan') {
		$self->{$require_type}{$module} = colored('!mcpan', 'magenta')
			if not $self->{skip_not_mcpan_stamp};
		$self->{modules}{$module}{prereqs} = $require_type;
		$self->{modules}{$module}{version} = '!mcpan';
	}
	elsif ($version eq 'core') {
		$self->{$require_type}{$module} = $version if $self->core;
		$self->{$require_type}{$module} = '0'      if $self->zero;
		$self->{modules}{$module}{prereqs} = $require_type;
		$self->{modules}{$module}{version} = $version if $self->core;
	}
	else {
		if ($self->{modules}{$module}{corelist}) {

			$self->{$require_type}{$module} = colored($version, 'bright_yellow')
				if ($self->dual_life || $self->core);
			$self->{modules}{$module}{prereqs} = $require_type
				if ($self->dual_life || $self->core);
			$self->{modules}{$module}{version} = $version
				if ($self->dual_life || $self->core);
			$self->{modules}{$module}{dual_life} = 1;
			$self->{modules}{$module}{prereqs} = $require_type;
			$self->{modules}{$module}{version} = $version;

		}
		else {
			$self->{$require_type}{$module} = colored($version, 'yellow');
			$self->{$require_type}{$module}
				= colored(version->parse($version)->numify, 'yellow')
				if $self->numify;

			$self->{modules}{$module}{prereqs} = $require_type;
			$self->{modules}{$module}{version} = $version;

			$self->{$require_type}{$module} = colored($version, 'bright_cyan')
				if $self->{modules}{$module}{'distribution'};
		}
	}
	p $self->{modules}{$module} if $self->debug;

	return;
}

#######
# composed method _in_corelist
#######
sub _in_corelist {
	my $self   = shift;
	my $module = shift;

	#return TRUE (1) if defined $self->{modules}{$module}{corelist};

	# hash with core modules to process regardless
	my $ignore_core = {'File::Path' => 1, 'Test::More' => 1,};

	if (!$ignore_core->{$module}) {

		if ( Module::CoreList->first_release($module) ) {
			$self->{modules}{$module}{corelist} = 1;
			return TRUE;
		}
		else {
			$self->{modules}{$module}{corelist} = 0;
			return FALSE;
		}
	}

	return FALSE;
}


#######
# _check_mojo_core
#######
sub _check_mojo_core {
	my $self         = shift;
	my $mojo_module  = shift;
	my $require_type = shift;

	my $mojo_module_ver;
	static \my $mojo_ver;

	if (not defined $mojo_ver) {
		$mojo_ver = $self->get_module_version('Mojolicious');
		p $mojo_ver if $self->debug;
	}

	$mojo_module_ver = $self->get_module_version($mojo_module);

	if ($self->verbose) {
		print BRIGHT_BLACK;

		#stdout - 'looks like we found another mojo core module';
		print "$mojo_module version $mojo_module_ver\n";
		print CLEAR;
	}

	if ($mojo_ver == $mojo_module_ver) {
		$self->{$require_type}{'Mojolicious'}
			= colored($mojo_module_ver, 'bright_blue')
			if !$self->{modules}{'Mojolicious'};
		$self->{modules}{'Mojolicious'}{prereqs} = $require_type;
		return 1;
	}
	else {
		return 0;
	}
}

#######
# get module version using metacpan_client (mc)
#######
sub get_module_version {
	my $self         = shift;
	my $module       = shift;
	my $require_type = shift || undef;
	my $cpan_version;
	my $found = 0;
	my $mcc;

	p $module if $self->debug;

	try {

		$mcc = $self->mcpan->module($module);

		$cpan_version = $mcc->version_numified();
		p $cpan_version if $self->debug;

		$found = 1;
	};
	try {
		my $dist_name = $mcc->distribution();
		$dist_name =~ s/-/::/g;

		if ($dist_name eq 'perl') {

			# mark all perl core modules with either 'core' or '0'
			$cpan_version = 'core';
			$found        = 1;
		}
		elsif ($module =~ m/^inc::/) {

			#skip saving inc::Module::Install from Role-Output
			return $cpan_version;
		}
		elsif ($dist_name ne $module) {

			# This is where we add a dist version to a knackered module
			$self->{modules}{$module}{distribution} = $dist_name;
			$self->mod_in_dist($dist_name, $module, $require_type,
				$mcc->version_numified())
				if $require_type;
			$found = 1;
		}
	}
	finally {
		# not in metacpan so mark accordingly
		$cpan_version = '!mcpan' if $found == 0;
	};

	# the following my note be needed any more due to developments in MetaCPAN 
	# scientific numbers in a version string, O what fun.
	if ($cpan_version =~ m/\d+e/) {

		# a bit of de crappy-flying
		# catch Test::Kwalitee::Extra 6e-06
		print BRIGHT_BLACK;
		print $module
			. ' Unique Release Sequence Indicator NOT! -> '
			. $cpan_version . "\n"
			if $self->verbose >= 1;
		print CLEAR;
		$cpan_version = version->parse($cpan_version)->numify;
	}

	return $cpan_version;
}

#######
# composed method
#######
sub mod_in_dist {
	my $self         = shift;
	my $dist         = shift;
	my $module       = shift;
	my $require_type = shift;
	my $version      = shift;

	$dist =~ s/-/::/g;
	if ($module =~ /$dist/) {

		print BRIGHT_BLACK;
		print "module - $module  -> in dist - $dist\n" if $self->verbose >= 1;
		print CLEAR;

		# add dist to output hash so we can get rind of cruff later
		if ($self->experimental) {

			$self->{$require_type}{$dist} = colored($version, 'bright_cyan')
				if not defined $self->{modules}{$module}{prereqs};
		}

		$self->{$require_type}{$module} = colored($version, 'bright_cyan')
			if not defined $self->{modules}{$module}{prereqs};
	}

	return;
}


no Moo;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Midgen - Check B<RuntimeRequires> & B<TestRequires> of your package for CPAN inclusion.

=head1 VERSION

This document describes App::Midgen version: 0.34

=head1 SYNOPSIS

Change to the root of your package and run

 midgen

Now with a Getopt --help or -?

 midgen -?

See L<midgen> for cmd line option info.

=head1 DESCRIPTION

This is an aid to show your packages module includes by scanning it's files,
 then display in a familiar format with the current version number
 from MetaCPAN.

This started as a way of generating the formatted contents for
 a Module::Install::DSL Makefile.PL, which has now grown to support other
 output formats, as well as the ability to show B<dual-life> and
 B<perl core> modules, see L<midgen> for option info.
This enables you to see which modules you have used, we even try and list Dist-Zilla Plugins.

All output goes to STDOUT, so you can use it as you see fit.

B<MetaCPAN Version Number Displayed>

=over 4

=item * NN.nnnnnn we got the current version number from MetaCPAN.

=item * 'core' indicates the module is a perl core module.

=item * '!mcpan' must be local, one of yours. Not in MetaCPAN, Not in core.

=back

I<Food for thought, if we update our Modules,
don't we want our users to use the current version,
so should we not by default do the same with others Modules.
Thus we always show the current version number, regardless.>

We also display some other complementary information relevant to this package
and your chosen output format.

For more info and sample output see L<wiki|https://github.com/kevindawson/App-Midgen/wiki>

=head1 METHODS

=over 4

=item * find_runtime_modules

Search for C<Prereqs RuntimeRecommends> and C<Prereqs RuntimeRequires> in
package modules C<script\>, C<bin\>, C<lib\>, C<share\> with B<UseModule>
and B<Eval> followed by B<PPS>.

=item * find_test_modules

Search for C<Prereqs TestSuggests> and C<Prereqs TestRequire> in B<t\> scripts,
with B<UseOk> and B<TestRequires> followed by B<PPS>.

=item * find_develop_modules

Search for C<Prereqs DevelopRequire> in C<xt\> using all available scanners.

=item * first_package_name

Assume first package found is your packages name

=item * get_module_version

side affect of re-factoring, helps with code readability

=item * mod_in_dist

Check if module is in a distribution and use that version number, rather than 'undef'

=item * run

=back

=head1 CONFIGURATION AND ENVIRONMENT

App::Midgen requires no configuration files or environment variables.
We do honour $ENV{ANSI_COLORS_DISABLED}

=head1 DEPENDENCIES

L<App::Midgen::Roles>, L<App::Midgen::Output>

=head1 INCOMPATIBILITIES

After some reflection, we do not scan xt/...
 as the methods by which the modules  are Included are various,
 this is best left to the module Author.

=head1 WARNINGS

As our mantra is to show the current version of a module,
 we do this by asking MetaCPAN directly so we are going to need to
 connect to L<http://api.metacpan.org/v0/>.

=head1 BUGS AND LIMITATIONS

There may be some modules on CPAN that when MetaCPAN-API asks for there
 version string, it is provided with the wrong information, as the contents
 of there Meta files are out of sync with there current version string.

Please report any bugs or feature requests to
 through the web interface at
L<https://github.com/kevindawson/App-Midgen/issues>.
 If reporting a Bug, also supply the Module info, midgen failed against.

=head1 AUTHOR

Kevin Dawson E<lt>bowtie@cpan.orgE<gt>

=head2 CONTRIBUTORS

Ahmad M. Zawawi E<lt>ahmad.zawawi@gmail.comE<gt>

Matt S. Trout E<lt>mst@shadowcat.co.ukE<gt>

Tommy Butler E<lt>ace@tommybutler.meE<gt>

Neil Bowers E<lt>neilb@cpan.orgE<gt>

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

Toby Inkster E<lt>tobyink@cpan.orgE<gt>

Karen Etheridge E<lt>ether@cpan.orgE<gt>

Oliver Gorwits E<lt>oliver@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright E<copy> 2013-2014 the App:Midgen L</AUTHOR> and L</CONTRIBUTORS>
 as listed above.


=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl 5 itself.

=head1 SEE ALSO

L<Perl::PrereqScanner>,
L<inc::Module::Install::DSL>

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
