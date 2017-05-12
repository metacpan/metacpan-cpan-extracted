#!/usr/bin/perl -w

# $Id: Build.PL,v 1.19 2008/05/01 22:35:40 pauldoom Exp $

use strict;
use warnings;
use Module::Build;

# Decide right now if we are shooting for a mod_perl 1.x
# or mod_perl 2.x install.  Defaults to mod_perl 2.x.
# This is to have a proper set of requirements in place
# so CPAN and others will behave.
my @extrareq = ();
if (eval{require mod_perl2;}) {
    push(@extrareq, 'mod_perl2', 1.9922, 'Apache2::Request', 0);
    print STDERR "mod_perl 2 detected: Setting requirements accordingly\n";
} elsif (eval{require mod_perl;}) {
    push(@extrareq, 'mod_perl', 1.07, 'Apache::Request', 0);
    print STDERR "mod_perl 1 detected: Setting requirements accordingly\n";
} else {
    # Nothing found yet.  Let's go with MP2
    push(@extrareq, 'mod_perl2', 1.9922, 'Apache2::Request', 0);
    print STDERR "mod_perl not detected: Setting requirements for mod_perl 2.x\n";
}

# Try to find a supported cipher module now.  If none
# are present, Crypt::Rijndael is set as a requirement.
# No requirement set otherwise.  (Recommendation will still appear)
my @blockciphers = ('Crypt::Rijndael', 'Crypt::OpenSSL::AES', 'Crypt::Twofish',  'Crypt::Blowfish');
my $bc;
while ($bc = shift @blockciphers) {
    if (eval{requires $bc;}) {
	print STDERR "$bc detected: Crypt::CBC block cipher needs met\n";
	last;
    }
}

if (scalar @blockciphers) {
    push(@extrareq, 'Crypt::Rijndael', 0);
    print STDERR "No suitable block ciphers detected. Setting requirement for Crypt::Rijndael\n";
}

 # Add extra processing to install example files
my $class = Module::Build->subclass(code => <<'EOF');
sub process_misc_files {
    my $self = shift;
    
    # Copy the following trees into ./blib/
    my @dirs = ( "examples");
    my @found = ();
    
    # Define a find matcher
    my $mat = sub {-f $_ && ! /^(Root|Repository|Entries|Tag|.cvsignore)\z/s &&
		       push(@found, $File::Find::name);};

    # Run a find under each $dir for normal, non-CVS files
    foreach $dir (@dirs) { File::Find::find({wanted => $mat}, $dir); }

    # Copy into ./bdir
    foreach (@found) {
	$self->copy_if_modified(from => $_, to => "blib/" . $_);
    }
}
EOF

my $builder = $class->new(
			  module_name         => 'Apache::AppSamurai',
			  license             => 'perl',
			  dist_author         => 'Paul M. Hirsch <paul@voltagenoir.org>',
			  dist_version_from   => 'lib/Apache/AppSamurai.pm',
			  dist_abstract       => 'Web application/reverse proxy authenticating front end',
			  requires => {
			      'Test::More'   => 0,
			      'CGI::Cookie'  => 0,
			      'URI'          => 0,
			      'Time::HiRes'  => 0,
			      'MIME::Base64' => 0,
			      'Carp'         => 0,
			      'Apache::Session' => 0,
			      'Digest::SHA'  => 0,
			      'Storable'     => 0,
			      'Crypt::CBC' => 2.17,
			      @extrareq
			  },
			  add_to_cleanup      => [ 'Apache-AppSamurai-*' ],
			  recommends => {
			      'Crypt::OpenSSL::AES' => 0, # Needs one
			      'Crypt::Twofish'      => 0, # good block cipher
			      'Crypt::Blowfish'     => 0, # for Crypt::CBC to
			      'Crypt::Rijndael'     => 0, # use.
			      'Apache::Test'        => 0, # Full tests
			      'LWP::UserAgent'      => 0, # AuthBasic.pm
			      'HTTP::Request'       => 0, # AuthBasic.pm
			      'Authen::Radius'      => 0, # AuthRadius.pm
			      'Authen::Simple'      => 0, # AuthSimple.pm
			  },
			  auto_features => {
			      Apache_Test_support =>
			      {
				  description => "Perform full Apache::Test testing",
				  requires => { 'Apache::Test' => 0},
			      },
			      YAML_support =>
			      {
				  description => "Use YAML.pm to write META.yml files",
				  requires => { YAML => ' >= 0.35, != 0.49_01 ' },
			      },
			      manpage_support =>
			      {
				  description => "Create Unix man pages",
				  requires => { 'Pod::Man' => 0 },
			      },
			      HTML_support =>
			      {
				  description => "Create HTML documentation",
				  requires => { 'Pod::Html' => 0 },
			      },
			  },
			  add_to_cleanup => ['t/session/sessions/*', 't/session/slock/*'],
			  meta_merge => {
			      resources =>
			      {
				  homepage => 'http://appsamurai.sourceforge.net',
				  bugtracker => 'http://rt.cpan.org/Public/Dist/Display.html?Name=Apache-AppSamurai',
				  MailingList => 'mailto:appsamurai-misc@lists.sourceforge.net',
				  #repository => 'http://svn.perl.org/modules/Apache-AppSamurai/'
			      }
			  },
                          # Build MakeMaker Makefile.PL (limited functionality)
			  create_makefile_pl => 'passthrough',
			  );


# Enable and setup optional Apache::Test tests
if ($builder->feature("Apache_Test_support")) {
    # Add t/*.at tests
    $builder->test_files("t/*.t", "t/*.at");
    print STDERR "NOTICE: Apache::Test tests not fully implemented (this is a place holder)\n";
} else {
    # Danger Will Wheaton....
    #print STDERR "WARNING: Apache::Test not found - Skipping live tests\n";
}
    

# Build examples: Note - YOU MUST DEFINE THE misc INSTALLATION PATH
# FOR Build install TO INSTALL.  (See README) 
$builder->add_build_element('misc');

$builder->create_build_script();
