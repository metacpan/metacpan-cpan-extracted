use strict;
use warnings;
use Module::Build;
my %requires=(
	      'perl' => '5.6.1',
	      'Object::InsideOut' => 0,
	      'CGI'=>0,
	      'File::Temp'=>0,
	      'File::Spec'=>0,
	      'Util::Properties'=>'0.14',
	     );
my %recommends=(
		'File::Glob'=>0,
		'File::Basename'=>0,
		'CGI::Carp'=>0,
	       );

my @scripts;
open (FD, "<MANIFEST") or die "cannot open MANIFEST: $!";
while(<FD>){
  chomp;
  push @scripts, $_ if /^(scripts)\//;
}
close FD;
my %cgi_scripts;
open (FD, "<MANIFEST") or die "cannot open MANIFEST: $!";
while(<FD>){
  chomp;
  $cgi_scripts{$_}=$_ if /^(cgi)\//;
}
close FD;

my $builder = Module::Build->new(
    module_name         => 'CGI::FileUpload',
    license             => 'perl',
    dist_author         => 'Alexandre Masselot <alexandre.masselot@genebio.com>',
    dist_version_from   => 'lib/CGI/FileUpload.pm',
    requires => \%requires,
    recommends => \%recommends,
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'CGI-FileUpload-*' ],
    create_makefile_pl => 'traditional',

    script_files=>\@scripts,
    cgi_files=>\%cgi_scripts,
    install_path => { cgi =>"blib/cgi/" },
);

$builder->add_build_element('cgi') || die "cannot add build element [cgi]";
$builder->prereq_failures() && $builder->prereq_failures()->{requires}  && die "conflicts (missing requirem\ents?)";
$builder->create_build_script();
