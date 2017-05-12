#!/usr/bin/perl -w

=head1 NAME

cas-starter.pl - creates a skeleton CGI::Application::Structured project.

=cut

=head1 ABSTRACT

Creates CGI::Application::Structured based applications.


=head1 VERSION

Version 0.003

=cut

our $VERSION = '0.003';

use warnings;
use strict;

# Provide a sane defailt
use File::Basename;
use File::Spec;
use FindBin qw/$Bin/;

use lib "$Bin/../lib";

 @ARGV = grep { defined } @ARGV;

 unless ($ENV{MODULE_TEMPLATE_DIR}) {
     $ENV{MODULE_TEMPLATE_DIR} = 
	 File::Spec->catdir(  
	     dirname($INC{'CGI/Application/Structured/Tools/Starter.pm'}), 
	     'templates' );
 }


use Module::Starter qw(
        Module::Starter::Simple
        Module::Starter::Plugin::Template
        CGI::Application::Structured::Tools::Starter
);
use Module::Starter::App;
Module::Starter::App->run;

=head1 SYNOPSIS


    ~/tmp$ cas-starter.pl --module=MyApp1 \
                                                --author=gordon \
                                                --email="vanamburg@cpan.org" \
                                                --verbose
    Created MyApp1
    Created MyApp1/lib
    Created MyApp1/lib/MyApp1.pm                      # YOUR *CONTROLLER BASE CLASS* !
    Created MyApp1/t
    Created MyApp1/t/pod-coverage.t
    Created MyApp1/t/pod.t
    Created MyApp1/t/01-load.t
    Created MyApp1/t/test-app.t
    Created MyApp1/t/perl-critic.t
    Created MyApp1/t/boilerplate.t
    Created MyApp1/t/00-signature.t
    Created MyApp1/t/www
    Created MyApp1/t/www/PUT.STATIC.CONTENT.HERE
    Created MyApp1/templates/MyApp1/C/Home
    Created MyApp1/templates/MyApp1/C/Home/index.tmpl # DEFAULT HOME PAGE TEMPLATE
    Created MyApp1/Makefile.PL
    Created MyApp1/Changes
    Created MyApp1/README
    Created MyApp1/MANIFEST.SKIP
    Created MyApp1/t/perlcriticrc
    Created MyApp1/lib/MyApp1/C                       # YOUR CONTROLLERS GO HERE 
    Created MyApp1/lib/MyApp1/C/Home.pm               # YOUR *DEFAULT CONTROLLER SUBCLASS*
    Created MyApp1/lib/MyApp1/Dispatch.pm             # YOUR CUSTOM DISPATCHER
    Created MyApp1/config
    Created MyApp1/config/config-dev.pl               # YOU CONFIG -- MUST BE EDITED BY YOU!
    Created MyApp1/script
    Created MyApp1/script/create_dbic_schema.pl       # IMPORTANT HELPER SCRIPT
    Created MyApp1/script/create_controller.pl        # ANOTHER IMPORTANT HELPER SCRIPT.
    Created MyApp1/server.pl                          # SERVER USES YOUR CUSTOM DISPATCH.PM
    Created MyApp1/MANIFEST
    Created starter directories and files



Options:

    --module=module  Module name 
    --dir=dirname    Directory name to create new module in (optional)

    --builder=module Build with 'ExtUtils::MakeMaker' or 'Module::Build'
    --eumm           Same as --builder=ExtUtils::MakeMaker
    --mb             Same as --builder=Module::Build
    --mi             Same as --builder=Module::Install

    --author=name    Author's name (required)
    --email=email    Author's email (required)
    --license=type   License under which the module will be distributed
                     (default is the same license as perl)

    --verbose        Print progress messages while working
    --force          Delete pre-existing files if needed

    --help           Show this message

=head1 DESCRIPTION

Sets up a working skeleton for an CGI::Application::Structured-based project, packaged as a CPAN module. The script also generates:
 
     - a base controller class
     - an organized directory structure to contain your modules
     - a default Home module (subclass of base controller)
     - a default runmode for Home ('index') with a corresponding template
     - a default configuration for Template Toolkit
     - basic automated tests 
     - a helper script to generate controller subclasses and TT templates
     - a helper script to generate DBIx::Class schema and resultset classes for your database.


By default the skeleton files can be found in the C<templates>
directory where CGI::Application::Structured::Tools::Starter is stored. 

Multiple --builder options may be supplied to produce the files for multiple
builders.

=head TUTORIAL

See L<CGI::Application::Structured> for a brief tutorial on using the helper scripts.

=cut

