# $Id: XS.pm,v 1.13 2003/10/06 21:15:52 clajac Exp $

package CPANXR::Parser::XS;
use CPANXR::Database;
use CPANXR::Parser;
use Carp qw(carp croak);
use strict;
use strict;

our @ISA = qw(CPANXR::Parser);

sub new {
  my ($pkg, $file, %args) = @_;
  $pkg = ref($pkg) || $pkg;

  bless {
	 file_id => $args{file_id},
	 dist_id => $args{dist_id},
	 file => $file
	}, $pkg;
}

sub parse {
  my $self = shift;

  my @source = $self->slurp_file();

  my $line_cnt = 1;
  my $current_package;
  my $current_package_id;

  my $package_prefix = "";
  for my $line (@source) {
    if ($line =~ m/^\#\s*define\s*/gc) {
      if ($line =~ m/\G(\w+)\(/gc) {
	my $sym_id = CPANXR::Database->insert_symbol($1);
	my $token = { _cpanxr => [$line_cnt, pos($line) - length($1) - 1] };
	$self->connect($sym_id, $token, 0, undef, undef, undef, CONN_MACRO);
	next;
      }
    }

    if ($line =~ m/^\#\s*include\s*/gc) {
      if ($line =~ m/\"(.*?)\"/gc) {
	my $sym_id = CPANXR::Database->insert_symbol($1);
	my $token = { _cpanxr => [$line_cnt, pos($line) - length($1) - 1] };
	$self->connect($sym_id, $token, 0, undef, undef, undef, CONN_LINK);
	next;
      }
    }

    if ($line =~ /^MODULE\s*=\s*([\w:]+)(?:\s+PACKAGE\s*=\s*([\w:]+))?(?:\s+PREFIX\s*=\s*(\S+))?\s*$/) {
      my $module = $1;
      my $package = $2;
      $package_prefix = $3 ? $3 : "";

      if ($package) {
	$line =~ m/(PACKAGE\s*=\s*)/gc;
	my $sym_id = CPANXR::Database->insert_symbol($package);
	my $token = { _cpanxr => [$line_cnt, pos($line)] };
	$current_package = $package;
	$current_package_id = $sym_id;
	$self->connect($sym_id, $token, 0, $current_package_id, $current_package_id, undef, CONN_PACKAGE);
      }
      next;
    }

    if ($line =~ /^$package_prefix([A-Za-z0-9_]+)\s*\(.*\)\s*$/) {
      my $func_name = $1;

      my $sym_id = CPANXR::Database->insert_symbol($func_name);
      my $token = { _cpanxr => [$line_cnt, length($package_prefix)] };
      $self->connect($sym_id, $token, 0, $current_package_id, $current_package_id, undef, CONN_DECL);
      next;
    }
  } continue {
    $line_cnt++;
  }
    
    return scalar @source;
}


1;
