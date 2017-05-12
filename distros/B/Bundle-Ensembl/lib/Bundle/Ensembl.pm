package Bundle::Ensembl;

use 5.008008;
use strict;
use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Bundle::Ensembl ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.03';


# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Bundle::Ensembl - Bundle for installing Ensembl Perl Modules 
(Built from dependencies of ENSEMBL_45 VERSION)

=head1 SYNOPSIS

C<perl -MCPAN -e 'install Bundle::Ensembl'>

This is almost in a test, But works fine, Just to make things easier email: gene@gpse.org.

=head1 CONTENTS

CGI

CGI::Ajax

CGI::Application

CGI::ArgChecker

CGI::Authent

CGI::Base

CGI::BasePlus

CGI::CList

CGI::Cache

CGI::Carp::DebugScreen

CGI::ContactForm

CGI::DBTables

CGI::Debug

CGI::Deurl

CGI::Echo

CGI::Enurl

CGI::Ex

CGI::Explorer

CGI::FormBuilder

CGI::FormFactory

CGI::FormMagick

CGI::FormManager

CGI::Formalware

CGI::Getopt

CGI::Imagemap

CGI::Lite

CGI::LogCarp

CGI::MiniSvr

CGI::Minimal

CGI::MultiValuedHash

CGI::MxScreen

CGI::NoPoison

CGI::Out

CGI::Panel

CGI::PathInfo

CGI::Persistent

CGI::Portable

CGI::Query

CGI::QuickForm

CGI::Request

CGI::Response

CGI::SSI

CGI::SSI_Parser

CGI::Screen

CGI::SecureState

CGI::Session

CGI::Session::DB2

CGI::Session::Encrypted

CGI::SimpleCache

CGI::SpeedyCGI

CGI::State

CGI::Test

CGI::URI2param

CGI::Untaint::Filenames

CGI::UploadEasy

CGI::Validate

CGI::WML

CGI::WebApp

CGI::XML

CGI::XMLForm

CGI_Lite

Class::DBI

Class::DBI::DB2

Class::DBI::Loader::DB2

Class::DBI::Oracle

Class::DBI::Plugin::CountSearch

Class::DBI::Plugin::DeepAbstractSearch

Class::DBI::Plugin::DeepAbstractSearchPager

Class::DBI::Plugin::Pager

Class::DBI::Storable

Class::DBI::Template

Class::DBI::Test::TempDB

Class::DBI::mysql

Class::Data::Reloadable

Class::DataStore

Class::Date

Bundle::DBI

DBD::mSQL

DBD::mysql

DBD::mysqlPP

DB_File::DB_Database

DB_File::Lock

Compress::Zlib

Compress::Raw::Zlib

DBD::mysql

GD

GD::Simple

GD::Polyline

GD::Image

GD::Polygon

GD::SVG

GD::Convert

GD

GD::Barcode

GD::Barcode::Code93

GD::Gauge

GD::Graph

GD::Graph3d

GD::Image::AnimatedGif

GD::Image::CopyIFS

GD::Image::Orientation

GD::Image::Thumbnail

GD::SecurityImage

GD::Text

GDS2

GIFgraph

GISI

GISI::MIFMID

Template::Plugin::GD

Bundle::ParallelUA

Data::UUID

Digest::MD5

Storable

LWP

LWP

LWP::Conn

LWP::MediaTypes

LWP::Parallel

LWP::Protocol

LWP::Protocol::http::SocketUnix

LWP::RobotUA

LWP::Simple

LWP::UA

LWP::UserAgent

LWPx::ParanoidAgent

SOAP::Lite

XML::Parser

XML::Simple

Parse::RecDescent

PDF::API2

Spreadsheet::WriteExcel

OLE::Storage_Lite

Time::HiRes

HTML::Template

File::Temp

Mail::Mailer

Math::Bezier

IO::String

Image::Size

Cwd   	 

File::Spec 	

File::Spec::Cygwin 	

File::Spec::Epoc 	

File::Spec::Functions 	

File::Spec::Unix 	

Perl::Version

version

DB_File

CGI::Ajax

CGI::Session

Class::Accessor

Class::Data::Inheritable

Class::Std::Utils

Class::Std

Devel::StackTrace

Bio::Das::Lite

Exception::Class

=head1 DESCRIPTION

A Bundle of Modules related to Ensembl Genome Browser Installation (Ensembl V45). 
If there are any modules that needs to be installed please email me at 
gene@gpse.org


=head1 SEE ALSO

Please see the README file and Run the ens_modtest.pl

=head1 AUTHOR

Ahamarshan.J.N @www.gpse.org @www.mellorlab.org

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007-2009 by Ahamarshan.J.N @www.gpse.org @www.mellorlab.org

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
