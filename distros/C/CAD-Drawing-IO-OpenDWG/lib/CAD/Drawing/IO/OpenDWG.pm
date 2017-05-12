package CAD::Drawing::IO::OpenDWG;
our $VERSION = '0.22';

#use CAD::Drawing; # circular requirements?
use CAD::Drawing::Defined;
use CAD::Drawing::IO::DWGI;

use strict;
use Carp;

########################################################################
our %filetype = (
				"dwg" 	=> $DWG::AD_DWG,
				"dxf" 	=> $DWG::AD_DXF,
				"bdxf" 	=> $DWG::AD_BDXF
				);

our %fileversion = (
				"2000"	=> $DWG::AD_ACAD2000,
				"14"		=> $DWG::AD_ACAD14,
				);
########################################################################
=pod

=head1 NAME

CAD::Drawing::IO::OpenDWG - Accessor methods for OpenDWG toolkit wrapper

=head1 AUTHOR

Eric L. Wilhelm <ewilhelm at cpan dot org>

http://scratchcomputing.com

=head1 COPYRIGHT

This module is copyright (C) 2004-2006 by Eric L. Wilhelm.  Portions
copyright (C) 2003 by Eric L. Wilhelm and A. Zahner Co.

=head1 LICENSE

This module is distributed under the same terms as Perl.  See the Perl
source package for details.

You may use this software under one of the following licenses:

  (1) GNU General Public License
    (found at http://www.gnu.org/copyleft/gpl.html)
  (2) Artistic License
    (found at http://www.perl.com/pub/language/misc/Artistic.html)

=head1 NO WARRANTY

This software is distributed with ABSOLUTELY NO WARRANTY.  The author,
his former employer, and any other contributors will in no way be held
liable for any loss or damages resulting from its use.

=head1 Modifications

The source code of this module is made freely available and
distributable under the GPL or Artistic License.  Modifications to and
use of this software must adhere to one of these licenses.  Changes to
the code should be noted as such and this notification (as well as the
above copyright information) must remain intact on all copies of the
code.

Additionally, while the author is actively developing this code,
notification of any intended changes or extensions would be most helpful
in avoiding repeated work for all parties involved.  Please contact the
author with any such development plans.

=head1 SEE ALSO

  CAD::Drawing
  CAD::Drawing::IO
  CAD::Drawing::IO::DWGI

=cut
########################################################################

# the following are required to be a disc I/O plugin:
our $can_save_type = "dwg";
our $can_load_type = $can_save_type;
our $is_inherited = 1;

=head1 Requisite Plug-in Functions

See CAD::Drawing::IO for a description of the plug-in architecture.

=head2 check_type

  $type_over_ride = check_type($filename, $type);

=cut
sub check_type {
	my ($filename, $type) = @_;
	my ($t, $v) = dwgtype($type);
	(defined($t) && defined($v)) && return($type);
	# print "passed that\n";
	my $extension;
	if($filename =~ m/.*\.(\w+)$/) {
		$extension = $1;
	}
	if(defined($type)) {
		$extension = $type;
	}
	else {
		$extension ||= $type;
	}
	$extension = lc($extension);
	my %change = (
		dwg => "dwg2000",
		dxf => "dxf2000",
		);
	$change{$extension} && (return($change{$extension}));
} # end subroutine check_type definition
########################################################################

=head1 Back-End Methods

These are called directly from CAD::Drawing::IO

=head2 load

  $drw->load($filename, \%options);

=cut
sub load {
	my $self = shift;
	my($filename, $opt) = @_;
	(-e $filename) || croak("$filename does not exist\n");
	my %opts = %$opt;
	####################################################################
	$opts{verbose} && (my $verbose_load = 1);
	my $dwg = CAD::Drawing::IO::DWGI->new();
	$dwg->loadfile($filename);
	$dwg->getentinit(); # starts up the objecthandles
	my($s, $n) = check_select($opt);
	my $count = 0;
	while(my($layer, $color, $type) = $dwg->getent()) {
		$s->{l} && ($s->{l}{$layer} || next);
		$n->{l} && ($n->{l}{$layer} && next);
		# FIXME: color is only 0-256 in the world of autodesk, should
		#        quit using it here
		$s->{c} && ($s->{c}{$color} || next);
		$n->{c} && ($n->{c}{$color} && next);
		$type = $dwg->entype($type);
		$s->{t} && ($s->{t}{$type} || next);
		$n->{t} && ($n->{t}{$type} && next);
# FIXME: What if we want to load everything into one layer?
# FIXME: 		must support that here. 
		my %pass = (
			"layer" => $layer,
			"color" => $color,
			);
		# here we will support reading the extrusion direction:
		if(my $extrusion = $dwg->get_extrusion()) {
			$pass{extrusion} = $extrusion;
			# print "yippee! extrusion: ", join(",", @$extrusion), "\n";
			# see CAD::Drawing::Calculate for coordinate system handling
		}
		# beginning of the if`ing
		my $addr;
		if($type eq "lines") {
			my $ld = $dwg->getLine();
			$addr = $self->addline($ld->{pts}, \%pass);
		}
		elsif($type eq "plines") {
			my $pl = $dwg->getLWPline();
			# FIXME: someone should check the elevation eh?
			$pass{closed} = $pl->{closed};
			# print "closed set to $pl->{closed}\n";
			$addr = $self->addpolygon($pl->{pts}, \%pass);
		}
		elsif($type eq "texts") {
			my $tx = $dwg->getText();
			$pass{height} = $tx->{height};
			$tx->{angle} and ($pass{angle} = $tx->{angle});
			$addr = $self->addtext($tx->{pt}, $tx->{string}, \%pass);
		}
		elsif($type eq "points") {
			my $pt = $dwg->getPoint();
			$addr = $self->addpoint($pt->{pt}, \%pass);
		}
		elsif($type eq "circles") {
			my $ci = $dwg->getCircle();
			$addr = $self->addcircle($ci->{pt}, $ci->{rad}, \%pass);
		}
		elsif($type eq "arcs") {
			my $ar = $dwg->getArc();
			$addr=$self->addarc($ar->{pt},$ar->{rad},$ar->{angs},\%pass);
		}
		elsif($type eq "images"){
			my $im = $dwg->getImage();
			$pass{size} = [@{$im->{size}}];
			$pass{vector} = [ [@{$im->{uvec}}], [@{$im->{vvec}}] ];
			$pass{fullpath} = $im->{fullpath};
			$pass{clipping} = $im->{clipping};
			$addr = $self->addimage($im->{pt}, \%pass);
		}
		else {
		# 	warn "unknown type $type\n";
		}

		if($pass{extrusion}) {
			# if we made an entity in ocs, I think we should be nice
			# here and put it in the wcs (but I might be insane.)
			$self->to_wcs($addr);
		}
		$count++;
		# FIXME: are we pushing the $addr to a list?

	} # end while getent()
	# XXX need to return all of the loaded addrs?
	# sure, but at least return true for now!
	return($count);
} # end subroutine load definition
########################################################################

=head2 save

This needs some work still.

  $drw->save($filename, \%options);

=cut
sub save {
	my $self = shift;
	my($filename, $opts) = @_;
	##print "saving to $filename\n";
	my $type = $opts->{type};
	my($filetype, $version) = dwgtype($type);
	unless(defined($filetype) && defined($version)) { 
		# print "trying type again\n";
		$type = check_type($filename, $type);
		$type or croak("couldn't get DWG type and version for $type\n");
		($filetype, $version) = dwgtype($type);
		# print "using type $filetype and version $version\n";
	}
	
	my $dwg = CAD::Drawing::IO::DWGI->new();
	$dwg->newfile($version);
	$dwg->getentinit();
	$opts->{verbose} && print "starting dwg save\n";
	# $kok was an attempt at a speed hack which would help free the
	# memory as it was being saved when working with large drawings.
	# This is probably no longer needed.
	my $kok = $opts->{killok};
	
	# Note that $dwg->writeLayer sets that layer as the current one
	# until it gets called again.  Therefore, we must write everything
	# on "0" first and then write everything that is not "0".
	# Otherwise, we would have to explicitely do a setLayer() (maybe
	# that would work, but I haven't really tested it, don't care to,
	# and it seems wasteful.)

	# FIXME: not supporting selective saves yet!

	# NOTE: this would be the most effective way to selective-save:
	my $items = $self->select_addr({all => 1});

	# FIXME: how much time are we losing to this loopiness?
	foreach my $item (@$items) {
		$self->to_ocs($item);
	}
	
	foreach my $layer ("0", grep({$_ ne "0"} keys(%{$self->{g}}))) {
		# FIXME: allow an option to flatten layers?
		# FIXME: this would do colors by layer:
		my %opts = ("name" =>$layer);
		($layer eq "0") || $dwg->writeLayer(\%opts);
#        print "writing to $layer\n";
		foreach my $ent (keys(%{$self->{g}{$layer}}) ) {
			if($ent eq "lines") {
				foreach my $id (keys(%{$self->{g}{$layer}{$ent}})) {
#                    print "writing line\n";
					my %addr = (
						"layer" => $layer,
						"type"  => $ent,
						"id"    => $id,
						);
					my $obj = $self->getobj(\%addr);
					$dwg->writeLine($obj);
					$kok && $self->remove(\%addr);
					}
				}
			elsif($ent eq "plines") {
				foreach my $id (keys(%{$self->{g}{$layer}{$ent}})) {
					# FIXME: probably should not build our own addresses:
					my %addr = (
						"layer" => $layer,
						"type"  => $ent,
						"id"    => $id,
						);
					my $obj = $self->getobj(\%addr);
					unless(defined($obj->{elevation})) {
						my $elev_avg;
						foreach my $point (@{$obj->{pts}}) {
							$point->[2] || last;
							# average the z-coordinates?
							$elev_avg += $point->[2];
							#print "z-value: $point->[2]\n";
						}
						$elev_avg /= scalar(@{$obj->{pts}});
						# print "elevation result $elev_avg\n";
						# FIXME: configurable?
						if(sprintf("%0.6f", $elev_avg)) {
							$obj->{elevation} = $elev_avg;
						}
					}
					$dwg->writeLWPline($obj);
					$kok && $self->remove(\%addr);
					}
				}
			elsif($ent eq "texts") {
				foreach my $id (keys(%{$self->{g}{$layer}{$ent}})) {
					my %addr = (
						"layer" => $layer,
						"type"  => $ent,
						"id"    => $id,
						);
					my $obj = $self->getobj(\%addr);
					$dwg->writeText($obj);
					# print "text string: $obj->{string}\n";
					$kok && $self->remove(\%addr);
					}
				}
			elsif($ent eq "points") {
				foreach my $id (keys(%{$self->{g}{$layer}{$ent}})) {
					my %addr = (
						"layer" => $layer,
						"type"  => $ent,
						"id"    => $id,
						);
					my $obj = $self->getobj(\%addr);
					# print "point to toolkit:  @{$obj->{pt}}\n";
					$dwg->writePoint($obj);
					$kok && $self->remove(\%addr);
					}
				}
			elsif($ent eq "circles") {
				foreach my $id (keys(%{$self->{g}{$layer}{$ent}})) {
					my %addr = (
						"layer" => $layer,
						"type"  => $ent,
						"id"    => $id,
						);
					# FIXME: I sure do not like this:
					$self->to_ocs(\%addr);
					my $obj = $self->getobj(\%addr);
					$dwg->writeCircle($obj);
					$self->to_wcs(\%addr);
					$kok && $self->remove(\%addr);
					}
				}
			elsif($ent eq "arcs") {
				foreach my $id (keys(%{$self->{g}{$layer}{$ent}})) {
					my %addr = (
						"layer" => $layer,
						"type"  => $ent,
						"id"    => $id,
						);
					my $obj = $self->getobj(\%addr);
					$dwg->writeArc($obj);
					$kok && $self->remove(\%addr);
					}
				}
			} # end foreach $ent
		} # end foreach $layer
	
	# FIXME: how much time are we losing to this loopiness?
	unless($kok) {
		foreach my $item (@$items) {
			$self->to_wcs($item);
		}
	}
	## print "saving to $filename\n";
	my $res = $dwg->savefile($filename, $filetype);
	$opts->{verbose} && print "finished save\n";
	return($res);
} # end subroutine save definition
########################################################################

=head1 Internal Methods

The back-end methods should definitely not be called directly, and these
should not even be called from the backend code.

=cut
########################################################################

=head2 dwgtype

Returns the toolkit constants corresponding to some human-readable
version and type names.

  ($type, $version) = dwgtype($type);

=cut
sub dwgtype {
	my($type) = @_;
	my %filetype = (
				"dwg" 	=> 0, # AD_DWG
				"dxf" 	=> 1, # AD_DXF
				"bdxf" 	=> 2, # AD_BDXF
				);
	my %fileversion = (
				"2000"	=> 7, #AD_ACAD2000
				"14"		=> 6, #AD_ACAD14
				"13"		=> 5, 
				"11"		=> 4,
				"10"		=> 3,
				"9" 		=> 2,
				"26"		=> 1,
				"25"		=> 0
				);
	if($type =~ m/^((?:dwg)|(?:b?dxf))(\d+)$/) {
		my $typespec = $1;
		my $version = $2;
		unless(defined($filetype{$typespec})) {
			carp("no type for $typespec\n");
			}
		unless(defined($fileversion{$version})) {
			carp("no version for $version\n");
			}
		return($filetype{$typespec}, $fileversion{$version});
		}
	return();
} # end subroutine dwgtype definition
########################################################################
