# $Id: PBib.pm 13 2004-11-27 08:58:44Z tandler $

use FindBin;
use lib "$FindBin::Bin/lib";
use PBib::Builder;

my $b = PBib::Builder->new
	(
		dist_name => 'Bundle-PBib',
		dist_version => '2.08.01',
		dist_version_from => 'lib/PBib/PBib.pm',
		module_name => 'PBib::PBib',
		license => 'perl',
		
		# PBib::Builder extensions for Inno Setup:
		app_name => 'PBib',
		#  app_version => '1.0',
		app_exe => 'bin\\PBibTk.pl', # name of the main executable
		author_url => 'http://tandlers.de/peter/',
		support_url => 'http://tandlers.de/peter/pbib',
		updates_url => 'http://tandlers.de/peter/pbib',
		
		meta_merge => {
			resources => {
				homepage => 'http://tandlers.de/peter/pbib',
				bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Bundle-PBib',
#				MailingList => 'http://lists.sourceforge.net/lists/listinfo/module-build-general',
				}
			},
		requires => {
				'perl' => '5.6.1', # I've tested with 5.8
				'Module::Build' => '0.2604',
				'Bundle::DBI' => '11.02',
				'Config::General' => '2.18',
				'Cwd' => '2.06',
				'Data::Dumper' => '2.12',
			},
		auto_features => {
			DBD_ODBC => {
				description => "Access ODBC data sources",
				requires => { 'DBD::ODBC' => '1.0', },
				},
			DBD_mysql => {
				description => "Access MySQL databases",
				requires => { 'DBD::mysql' => '2.1', },
				},
			PBibTk => {
				description => "Run PBibTk.pl, the GUI for PBib",
				requires => {
					'Tk' => '800.024',
					'Win32::OLE' => '0.16',
					'Win32::Clipboard' => '0.51',
					},
				},
			doc_MSWord => {
				description => "Process MS Word documents",
				requires => {
					'Win32::OLE' => '0.16',
					},
				},
			doc_OpenOffice => {
				description => "Process OpenOffice documents",
				requires => {
					'Archive::Zip' => '1.13',
					'XML::Parser' => '2.31',
					},
				},
			doc_XML => {
				description => "Process XML documents",
				requires => {
					'XML::Parser' => '2.31',
					},
				},
			},
		recommends => {
			},
		build_requires => {
		      'Test::More' => 0,
			},
		
		script_files => [qw(
			bin/pbib.pl
			bin/pbib-export.pl
			bin/pbib-import.pl
			bin/PBibTk.pl
			)],
		
		create_makefile_pl => 'passthrough',
		create_readme => 1,
		sign => 1,
		
		# PBib::Builder extensions
		## obsolete: I now use a new build element 'pbib'
		##   as I placed the config under lib/PBib
		#  config_srcdir => '.',
		#  config_destdir => 'lib/PBib',
		#  config_pattern => qr{^./(conf|styles)/.*\.pbib$},
		
		htmldocs => {
			'lib/PBib/Intro.pod' => 'docs/Intro.html',
			'lib/PBib/PBib.pm' => 'docs/Overview.html',
			},
	);
$b->add_build_element('pbib');
#  $b->register_config_files(); # process config_* parameters
#### obsolete, see above

# add bp files to install list
{
	my $self = $b;
	my $pm_files = $self->find_pm_files();
	my $bp_files = $self->rscan_dir('./lib/Biblio/bp', qr{.*\.pl$});
	foreach my $src (@$bp_files) {
		$src = $self->localize_file_path($src);
		$pm_files->{$src} = $src;
	}
	$self->{properties}->{pm_files} = $pm_files;
}

$b->create_build_script();
#  $b->dispatch('innosetupscript');


