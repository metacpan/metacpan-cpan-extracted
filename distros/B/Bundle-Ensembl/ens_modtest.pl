#!/usr/bin/perl -w
# Copyright © 2007 Ahamarshan.jn <gene@gpse.org>
# To test the module installation,dependencies and missing modules for the Ensembl Genome Browser
print "\n";
print "If you see any error messages \n"; 
print "then please re-install the module Bundle::Ensembl \n";
print "or the missing dependencies \n";
print "\n";
use CGI;
use Compress::Zlib;
use Compress::Raw::Zlib;
use DBD::mysql;
use GD;
use GD::Simple;
use Template::Plugin::GD;
use Bundle::ParallelUA;
use Bio::Das::Lite;
use Data::UUID;
use Digest::MD5;
use Storable;
use LWP;
use SOAP::Lite;
use XML::Parser;
use XML::Simple;
use Parse::RecDescent;
use PDF::API2;
use Spreadsheet::WriteExcel;
use OLE::Storage_Lite;
use Time::HiRes;
use HTML::Template;
use File::Temp;
use Mail::Mailer;
use Math::Bezier;
use IO::String;
use Image::Size;
use Cwd;   	 
use File::Spec; 	
use File::Spec::Cygwin;
use File::Spec::Epoc; 	
use File::Spec::Functions;	
use File::Spec::Unix; 	
use Perl::Version;
use version;
use DB_File;
use CGI::Ajax;
use CGI::Session;
use Class::Accessor;
use Class::Data::Inheritable;
use Class::Std::Utils;
use Class::Std;
use Devel::StackTrace;
use Exception::Class;

print "\n";
print "\n";
print "No-errors detected: Your installation looks Okay \n";
print "\n";

