# $Id: Parser.pm,v 1.20 2003/10/05 09:34:40 clajac Exp $

package CPANXR::Parser;
use IO::File;
use Carp qw(carp croak);
use strict;

require Exporter;
our @ISA = qw(Exporter);

our @EXPORT = qw(
		 CONN_INCLUDE
		 CONN_FUNCTION
		 CONN_METHOD
		 CONN_DECL
                 CONN_MACRO
                 CONN_PACKAGE
                 CONN_ISA
                 CONN_REF
                 CONN_LINK
                 CONN_FILE
		);

our @EXPORT_OK = @EXPORT;
our %EXPORT_TAGS = (
		    'constants' => [@EXPORT_OK],
		   );

use constant NO_FILE => 0;
use constant XS_FILE => 1;
use constant PM_FILE => 2;

use constant CONN_INCLUDE => 0;
use constant CONN_FUNCTION => 1;
use constant CONN_METHOD => 2;
use constant CONN_DECL => 3;
use constant CONN_MACRO => 4;
use constant CONN_PACKAGE => 5;
use constant CONN_ISA => 6;
use constant CONN_REF => 7;
use constant CONN_LINK => 8;
use constant CONN_FILE => 9;

sub understands {
  my ($pkg, $path) = @_;

  if ($path =~ /\.xs$/) {
    return XS_FILE;
  } elsif ($path =~ /\.pm$/) {
    return PM_FILE;
  }

  return NO_FILE;
}

sub parse {
  my ($pkg, $file, %args) = @_;

  if ($file =~ /\.pm$/) {
    require CPANXR::Parser::Perl;
    return CPANXR::Parser::Perl->new($file, %args)->parse;
  } elsif ($file =~ /\.xs$/) {
    require CPANXR::Parser::XS;
    return CPANXR::Parser::XS->new($file, %args)->parse;
  }

  return 0;
}

sub slurp_file {
  my ($self, $file) = @_;

  $file = $self->{file} unless(defined $file);
  my $io = IO::File->new($file, "r");
  croak("Can't open $file") unless(defined $io);

  my @source = <$io>;
  $io->close();

  return @source;
}

sub connect {
  my ($self, $sym_id, $token, $offset, $package_id, $caller_id, $caller_sub_id, $type) = @_;
  CPANXR::Database->insert_connection($sym_id, $self->{file_id}, $token->{_cpanxr}->[0], $token->{_cpanxr}->[1] + $offset, $package_id, $caller_id, $caller_sub_id, $type);
}

1;
