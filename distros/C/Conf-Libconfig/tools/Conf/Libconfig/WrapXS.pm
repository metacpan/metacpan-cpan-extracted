package Conf::Libconfig::WrapXS;
use strict;
use warnings;

use Cwd;
our @ISA    = qw( ExtUtils::XSBuilder::WrapXS );
use base qw/ExtUtils::XSBuilder::WrapXS/;

my $cwd = cwd;
$cwd =~ m{^(.+/Conf-Libconfig).*$} or die "Can't find base directory";
my $basedir = $1;
my $srcdir = "$basedir/src";
my $xsdir = "$basedir/xsbuilder/tables";
my $mapdir = "$basedir/xsbuilder/maps";
my @dirs = ("$basedir/src");
unless (-d $mapdir)
{
    mkdir ($mapdir, 0755);
    chmod (0755, $mapdir);
}

sub new_parsesource  { [ Conf::Libconfig::ParseSource->new ] }

sub my_xs_prefix  { 'config_xs_' }

sub h_filename_prefix  { 'libconfig_xs_' }

sub xs_include_dir { $xsdir }

sub xs_includes
{
    my $self = shift ;
    return $self->SUPER::xs_includes;
}

1;
