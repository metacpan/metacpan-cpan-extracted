# --*-Perl-*--
# $Id: ConfigFile.pm 10 2004-11-02 22:14:09Z tandler $
#

=head1 NAME

PBib::ConfigFile - Configuration file for PBib

=head1 SYNOPSIS

 use PBib::ConfigFile;
 $conf = new PBib::ConfigFile();
 # see Config::General

=head1 DESCRIPTION

extend Config::General to handle search path for included config files

=cut

package PBib::ConfigFile;
use 5.006;
use strict;
use warnings;
#use English;

# for debug:
use Data::Dumper;

BEGIN {
	use vars qw($Revision $VERSION);
	my $major = 1; q$Revision: 10 $ =~ /: (\d+)/; my ($minor) = ($1); $VERSION = "$major." . ($minor<10 ? '0' : '') . $minor;
}

# superclass
use Config::General 2.18; # previous versions have no -ConfigPath option

our @ISA;
@ISA = qw(Config::General);

# used standard modules
# use FileHandle;
#  use File::Basename;
#  use File::Spec;

=head1 METHODS

=over

=cut

1;

__END__

sub new {
	my $self = shift;
	my %conf = @_;
	if( defined($conf{-ConfigPath}) ) {
		my $path = delete($conf{-ConfigPath});
		my $file = $conf{-ConfigFile};
		$conf{-ConfigFile} = find($file, $path);
	}
	return new Config::General(%conf);
}

sub find {
	#
	# find the config file
	#
	my(file, $path) = @_;
	if (-e $file) {
		return $file;
	}
	
	#  my $params = $this->{Params};
	#  my $path = $params->{-ConfigPath};
	#  if( $path ) {
		#  ##### ToDo: search for file along search path
		#  foreach my $dir (@$path) {
			#  next unless defined $dir;
			#  my $file = "$dir/$configfile";
			#  if( -r $file ) {
				#  return $this->SUPER::_open($file);
			#  }
		#  }
	#  }
	
	return $file;
}


1;

=back

=head1 AUTHOR

Peter Tandler I<pbib@tandlers.de>

=head1 SEE ALSO

Module L<PBib::PBib>

=head1 HISTORY

$Log: ConfigFile.pm,v $
Revision 1.4  2003/06/16 09:11:50  tandler
cosmetic change

Revision 1.3  2003/06/13 15:25:17  tandler
the module Config::General is use in version >= 2.18

Revision 1.2  2003/04/16 15:05:15  tandler
all code removed ....
I instead patched Config::General

Revision 1.1  2003/04/14 09:46:12  ptandler
new module ConfigFile that encapsulates Config::General


=cut
