use Module::Build;


 
my $class = Module::Build->subclass(
				    class => "Module::Build::Custom",
code => <<'SUBCLASS' );

sub ACTION_install {
    my $self = shift;
    $self->SUPER::ACTION_install;
}

sub ACTION_fakeinstall {
    my $self = shift;
    $self->SUPER::ACTION_fakeinstall;
}

sub ACTION_build {
    my $self = shift;

    require Config::General;

    my $rcfile = $self->base_dir() . "/etc/alvis-nlpplatform/nlpplatform.rc";

    warn "Setting the default location of nlpplatform.rc in lib/Alvis/NLPPlatform.pm\n";
    my $mainpmfile = $self->base_dir() . "/lib/Alvis/NLPPlatform.pm";
    require File::Copy;

    my $n = FileHandle->new($mainpmfile,"r");

    chmod(0644, $mainpmfile);
    if (!( -f "$mainpmfile.orig") ) {
	File::Copy::copy($mainpmfile, "$mainpmfile.orig");
    }
    my $line;
    open MAINPMFILE, "$mainpmfile.orig" or die "No such file ($mainpmfile.orig)\n";
    open MAINPMFILEDEST, ">$mainpmfile" or die "Can not open file $mainpmfile\n";
    while($line = <MAINPMFILE>) {
	if ($line =~ /^(\s\$rcfile\s=\s\")\/etc\/alvis\-nlpplatform\/nlpplatform.rc(\".*\n)/) {
	    $line = $1 . $self->install_destination("etc") . "/alvis-nlpplatform/nlpplatform.rc" . $2;
	}
	print MAINPMFILEDEST $line;
    }
    close MAINPMFILE;
    close MAINPMFILEDEST;
    warn "Done\n";


    my $originalrcfile = $self->base_dir() . "/etc/alvis-nlpplatform/nlpplatform.rc";
    warn "Setting the default location of Default.xsl and SupplMagicFile in /etc/alvis-nlpplatform/nlpplatform.rc\n";
    require File::Copy;

    $n = FileHandle->new($originalrcfile,"r");

    chmod(0644, $originalrcfile);
    if (!( -f "$originalrcfile.orig") ) {
	File::Copy::copy($originalrcfile, "$originalrcfile.orig");
    }
    open ORIGINALRCFILE, "$originalrcfile.orig" or die "No such file ($originalrcfile.orig)\n";
    open ORIGINALRCFILEDEST, ">$originalrcfile" or die "Can not open file $originalrcfile\n";
    while($line = <ORIGINALRCFILE>) {
	if ($line =~ /^(\s*default *= *\"?xsltproc +)\/etc(\/alvis\-nlpplatform\/xsl\/Default\.xsl\"?.*\n)/) {
	    $line = $1 . $self->install_destination("etc") . $2;
	} else {
	    if ($line =~ /^(\s*SupplMagicFile *= *\"?)\/etc(\/alvis\-nlpplatform\/mime\/magic\.TeX\"?.*\n)/) {
		$line = $1 . $self->install_destination("etc") . $2;
	    }
	}
	print ORIGINALRCFILEDEST $line;
    }
    close ORIGINALRCFILE;
    close ORIGINALRCFILEDEST;
    warn "Done\n";


    $self->SUPER::ACTION_build;
}

sub ACTION_clean {
    my $self = shift;
    $self->SUPER::ACTION_clean;

    require File::Copy;

    my $mainpmfile = $self->base_dir() . "/lib/Alvis/NLPPlatform.pm";
    File::Copy::move("$mainpmfile.orig", $mainpmfile);

    my $originalrcfile = $self->base_dir() . "/etc/alvis-nlpplatform/nlpplatform.rc";
    File::Copy::move("$originalrcfile.orig", $originalrcfile);
}

SUBCLASS

my $build = $class->new
    (
     module_name => 'Alvis::NLPPlatform',
     dist_version_from => 'lib/Alvis/NLPPlatform.pm',
     license => 'gpl',
     requires => {'perl' => '5.005',
		  Time::HiRes => 0,
		  IO => 0,
		  XML::Parser::PerlSAX => 0,
		  Data::Dumper => 0,
		  Alvis::TermTagger => 0.3,
		  Alvis::Pipeline => 0,
		  Alvis::Convert => 0,
		  XML::LibXML => 0,
		  IO::File => 0,
		  IO::Socket::INET => 0,
		  Getopt::Long => 0,
		  Pod::Usage => 0,
		  Config::General => 2.30,
		  Sys::Hostname => 0,
		  Fcntl => 0,
		  utf8 => 0,
		  File::Touch => 0,
		  File::Basename => 0,
		  Encode => 0,
		  Fcntl => 0,
		  File::Path => 0,
		  File::MMagic => 0,
		  File::Basename => 0,
		  Lingua::Identify => 0,
		  XML::Parser => 0,
		  Parse::Yapp => 0,
		  Test::More => 0,
	      },
    build_requires => {
        "Module::Build"     => 0.28,
    },
     etc_files => {
	 'etc/alvis-nlpplatform/nlpplatform-test.rc' => 'etc/alvis-nlpplatform/nlpplatform-test.rc',
	     'etc/alvis-nlpplatform/nlpplatform.rc' => 'etc/alvis-nlpplatform/nlpplatform.rc',
	     'etc/alvis-nlpplatform/xsd/enriched-document.xsd' => 'etc/alvis-nlpplatform/xsd/enriched-document.xsd',
	     'etc/alvis-nlpplatform/dtd/enriched-document.dtd' => 'etc/alvis-nlpplatform/dtd/enriched-document.dtd',
	     'etc/alvis-nlpplatform/xsl/Default.xsl' => 'etc/alvis-nlpplatform/xsl/Default.xsl',
	     'etc/alvis-nlpplatform/mime/magic.TeX' => 'etc/alvis-nlpplatform/mime/magic.TeX',
	 },
     );


$build->install_base_relpaths( etc => 'etc' );
$build->prefix_relpaths('site', etc => 'etc' );
$build->prefix_relpaths('core', etc => 'etc' );
$build->prefix_relpaths('vendor', etc => 'etc' );
$build->add_build_element('etc');


foreach my $type (keys(%{$build->install_sets})) {
    $build->install_sets->{$type}->{'etc'} = '/etc';
}

$build->install_sets->{'site'}->{'etc'} = '/usr/local/etc';

# same thing with prefix
if (((defined $build->install_base()) && ($build->install_base() eq "/usr")) ||
    ((defined $build->prefix()) && ($build->prefix() eq "/usr")))
 {
	$build->install_path->{'etc'} = '/etc';
}

$build->create_build_script;

