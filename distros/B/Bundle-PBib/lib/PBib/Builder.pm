# --*-Perl-*--
# $Id: Builder.pm 25 2005-09-17 21:45:54Z tandler $
#

=head1 NAME

PBib::Builder - Extend Module::Build with support for Inno Setup installers and config files

=head1 SYNOPSIS

	use PBib::Builder;
	my $b = PBib::Builder->new(
		module_name => 'PBib::PBib',
		app_exe => 'bin\\PBibTk.pl', # name of the main executable
		);
	$b->register_config_files(); # process config_* parameters
	$b->create_build_script();
	$b->dispatch('innosetupdist');

=head1 DESCRIPTION

Module PBib::Builder extend Module::Build with support for Inno Setup installers and config files. Therefore, it is independent from the PBib system, I just placed it here ...

=cut

package PBib::Builder;
use 5.006;
use strict;
use warnings;
#use English;


# for debug:
#  use Data::Dumper;

BEGIN {
    use vars qw($Revision $VERSION);
	my $major = 1; q$Revision: 25 $ =~ /: (\d+)/; $VERSION = sprintf("$major.%03d", $1);
}

# superclass
use base qw(Module::Build);

# used modules
#use FileHandle;
#use File::Basename;

# used own modules


=head1 ACTIONS

New build actions.

=over

=cut


=item B<alldist>

Build all supported distributions (tar.gz, ppm, Inno Setup)

=cut

sub ACTION_alldist {
	my $self = shift;
	$self->depends_on('isdist');
	$self->depends_on('dist');
	$self->depends_on('ppmdist');
}

sub ACTION_dist {
	my $self = shift;
	$self->depends_on('htmldocs');
	return $self->SUPER::ACTION_dist(@_);
}

=item B<isdist> or B<innosetupdist>

Create Windows installer using Inno Setup.

=cut

sub ACTION_isdist {
	my $self = shift;
	return $self->ACTION_innosetupdist(@_);
}
sub ACTION_innosetupdist {
	my $self = shift;
	
	$self->depends_on('distdir');
	$self->depends_on('innosetupscript');
	
	my $dist_dir = $self->dist_dir;
	$self->make_innosetup();
	#  $self->delete_filetree($dist_dir);
}

=item C<innosetupscript>

Create the script for the Inno Setup Compiler from a template.

; %app_name%
; %app_version%
; %app_exe% - name of the main executable
; %author%
; %author_url%
; %support_url%
; %updates_url%
;
; %base_dir% - where the original files are located

=cut

sub ACTION_innosetupscript {
	my $self = shift;
	my $p = $self->{properties};
	
	my $template_iss = $p->{innosetup_template} || 'InnoSetupTemplate.iss';
	my $app_name = $self->app_name();
	my $app_version = $self->app_version();
	
	my $base_dir = File::Spec->catdir(
		$self->base_dir(), 
		$self->dist_dir());
	### transform base_dir to OS style??
	
	my $author = $self->dist_author();
	if( ref $author eq 'ARRAY' ) {
		$author = join(', ', @$author);
	}
	my $author_url = $p->{author_url};
	my $support_url = $p->{support_url};
	my $updates_url = $p->{updates_url};
	
	my %fields = (
		'%app_name%' => $app_name,
		'%app_version%' => $app_version,
		'%app_exe%' => $p->{app_exe},
		'%author%' => $author,
		'%author_url%' => $author_url,
		'%support_url%' => $support_url,
		'%updates_url%' => $updates_url,
		'%base_dir%' => $base_dir,
		);
	my $pattern = join('|', keys %fields);
	
	my $script = "$app_name-$app_version.iss";
	$p->{innosetup_script} = $script;
	$self->add_to_cleanup($script);
	print "Create Inno Setup script $script\n";
	
	open IN, "<", $template_iss or
		die "Cannot read Inno Setup template from $template_iss.\n";
	open OUT, ">", $script or
		die "Cannot write to Inno Setup file $script.\n";
	while(<IN>) {
		s/($pattern)/ $fields{$1} /ge;
		print OUT $_;
	}
	close IN;
	close OUT;
}

=item B<htmldocs>

=cut

sub ACTION_htmldocs {
	my $self = shift;
	my $p = $self->{properties};
	my $pods = $p->{htmldocs} || {};
	
	foreach my $pod (keys %$pods){
		$self->_htmlify_pod_docs(
			infile => $pod,
			outfile => $pods->{$pod},
			backlink => '__top',
			css => ($^O =~ /Win32/) ? 'Active.css' : '',
			);
	}
}

=back

=head1 METHODS

=over

=cut

sub app_name {
	my $self = shift;
	my $p = $self->{properties};
	return $p->{app_name} if exists $p->{app_name};
	
	my $app_name = $self->dist_name();
	die "Can't determine distribution name, must supply either 'app_name', 'dist_name', or 'module_name' parameter" unless $app_name;
	
	return $p->{app_name} = $app_name;
}

sub make_innosetup {
	my ($self, $script) = @_;
	$script ||= $self->{properties}->{innosetup_script};
	my $iscc = $self->innosetup_compiler();
	
	$self->do_system($iscc, $script);
}

sub innosetup_compiler {
	my $self = shift;
	return $self->{properties}->{innosetup_compiler} || "C:\\Program Files\\Inno Setup 4\\ISCC.exe";
}


# app_version is always dist_version!
sub app_version {
	my $self = shift;
	return $self->dist_version();
}


##### htmldocs

sub _htmlify_pod_docs {
	my ($self, %args) = @_;
	require Pod::Html;
	require Module::Build::PodParser;
	
	my $infile = File::Spec::Unix->abs2rel($args{infile});
	my $outfile = File::Spec::Unix->abs2rel($args{outfile});
	
	return if $self->up_to_date($infile, $outfile);
	
	my ($name, $path) = File::Basename::fileparse($outfile, qr{\..*});
	unless (-d $path){
		File::Path::mkpath($path, 1, 0755) 
		or die "Couldn't mkdir $path: $!";  
	}
	
	my $title = $name;
	{
		my $fh = IO::File->new($infile);
		my $abstract = Module::Build::PodParser->new(fh => $fh)->get_abstract();
		$title .= " - $abstract" if $abstract;
	}
	
	my @opts = (
		  '--flush',
		  "--title=$title",
		  "--podpath=.",
		  "--infile=$infile",
		  "--outfile=$outfile",
		  "--podroot=.",
		  "--htmlroot=.",
		  eval {Pod::Html->VERSION(1.03); 1} ? ('--header', "--backlink=$args{backlink}") : (),
		 );
	push @opts, "--css=$args{css}" if $args{css};
	
	$self->add_to_cleanup($outfile);
	print "Creating $outfile\n";
	print "pod2html @opts\n" if $self->verbose;
	Pod::Html::pod2html(@opts);	# or warn "pod2html @opts failed: $!";
}


##### support for config files #####

sub register_config_files {
	my $self = shift;
	my $pm_files = $self->find_pm_files();
	my $config_files = $self->find_config_files();
	#  print Dumper $config_files;
	while( my ($src, $dest) = each %$config_files ) {
		$pm_files->{$src} = $dest;
	}
	$self->{properties}->{pm_files} = $pm_files;
}

sub find_config_files  {
	# collect all files in the config_dirs.
	my $self = shift;
	my $src_dir = $self->{properties}->{config_srcdir};
	my $pattern = $self->{properties}->{config_pattern};
	my $config_files = $self->rscan_dir($src_dir, $pattern);
	
	# move all config files to lib/PBib
	my $dest_dir = $self->{properties}->{config_destdir};
	return { map {$_, ( $dest_dir ? "$dest_dir/$_" : $_ )}
		map $self->localize_file_path($_), @$config_files };
}

1;


__END__

=back

=head1 AUTHOR

Peter Tandler <pbib@tandlers.de>

=head1 COPYRIGHT AND LICENCE

Copyright (C) 2002-2004 P. Tandler

For copyright information please refer to the LICENSE file included in this distribution.

=head1 SEE ALSO

Module L<Module::Build>.

Inno Setup (http://www.jrsoftware.org/isinfo.php) is a completely free & cool installer for windows.

