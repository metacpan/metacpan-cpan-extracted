package CAD::Drawing::IO::Circ;
our $VERSION = '0.03';

# use CAD::Drawing;
use CAD::Drawing::Defined;

our $circtag = ".circ_data";
#require Exporter;
#@EXPORT = qw(
#        pingcirc
#        );


use warnings;
use strict;
use Carp;
########################################################################
=pod

=head1 NAME

CAD::Drawing::IO::Circ - load and save for circle data

=head1 NOTICE

This module and the format upon which it relies should be considered
extremely experimental and should not be used in production except under
short-term and disposable conditions.

=head1 INFO

This module is intended only as a backend to CAD::Drawing::IO.  The only
method from here which you may want to call directly is pingcirc(),
which will return information stored in the ".circ_data" file.

For loading and saving, please use the front-end interface provided by
load() and save() in CAD::Drawing::IO.

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

=cut
########################################################################

=head1 Requisite Plug-in Functions

See CAD::Drawing::IO for a description of the plug-in architecture.

=cut
########################################################################
# the following are required to be a disc I/O plugin:
our $can_save_type = "circ";
our $can_load_type = $can_save_type;
our $is_inherited = 1;

=head2 check_type

Returns true if $type is "circ" or $filename is a directory containing a
".circ" file.

  $fact = check_type($filename, $type);

=cut
sub check_type {
	my ($filename, $type) = @_;
	if(defined($type)) {
		($type eq "circ") && return("circ");
		return();
	}
	elsif((-d $filename) && (-e "$filename/$circtag")) {
		return("circ");
	}
	elsif(($filename =~ s/^circ(\..*?)://) and (-d $filename)) {
		## print "suffix: $1\n";
		return("circ$1");
	}
	return();
} # end subroutine check_type definition
########################################################################

########################################################################
=head1 Methods

=cut

=head2 load

  @list = load($drw, $directory, $opts);

=cut
sub load {
	my $self = shift;
	my ($directory, $opts) = @_;
	my $info = {};
	if($opts->{type} =~ m/(\..*)$/) {
		$info->{suffix} = $1;
		$directory =~ s/^circ.*://;
		# print "loading from $directory\n";
		# FIXME: need to unify this type/opts:foo syntax!
	}
	else {
		$info = $self->pingcirc($directory) or croak("no $circtag file");
	}
	# FIXME: add $info somewhere to toplevel of $self ?
	# except that self is not owned by $info!
	my $suffix = $info->{suffix};
	my ($s, $n) = check_select($opts);
	my @addr_list;
	my @list; # files to load
	if($s->{l}) {
		@list = map({"$directory/$_$suffix"} keys(%{$s->{l}}));
	}
	else {
		@list = glob("$directory/*$suffix");
	}
	foreach my $file (@list) {
		my $layer = $file;
		$layer =~ s#^$directory/*##;
		$layer =~ s/$suffix$//;
		$n->{l} && ($n->{l}{$layer} && next);
#        print "$file -> $layer\n";
		open(CIRCLESIN, $file); 
		while(my $line = <CIRCLESIN>) {
			chomp($line);
			$line || next;
			my($ids,$cord,$r,$co,$lt) = split(/\s*:\s*/, $line);
			$s->{c} && ($s->{c}{$co} || next);
			$n->{c} && ($n->{c}{$co} && next);
#            print "adding id: $ids\n";
			my %addopts = (
					layer=>$layer,
					color=>$co, 
					linetype=>$lt,
					id=>$ids
					);
			my @pt = split(/\s*,\s*/, $cord);
			my $addr = $self->addcircle(\@pt, $r, {%addopts});
			push(@addr_list, $addr);
		} # end while reading file
		close(CIRCLESIN);
	} # end foreach $file
	return(@addr_list);
} # end subroutine load definition
########################################################################

=head2 save

  $drw->save();

=cut
sub save {
	my $self = shift;
	my ($directory, $opts) = @_;
	my %opts = %$opts;
	if(-e $directory) {
		(-d $directory) or croak("$directory is not a directory");
	}
	else {
		mkdir($directory) or croak("could not create $directory");
	}
	# does the new .circ file smash the old?
	my $suffix = $opts->{suffix};
	if(my $inf = $self->pingcirc($directory)) {
		$suffix || ($suffix = $inf->{suffix});
	}
	if($opts{type} =~ m/(\..*)$/) {
		$suffix = $1;
	}
	$suffix || die "need suffix\n";
	$opts{suffix} = $suffix;
	$self->write_circdata($directory, \%opts);
	my ($s, $n) = check_select($opts);
	foreach my $layer ($self->getLayerList()) {
		$s->{l} && ($s->{l}{$layer} || next);
		$n->{l} && ($n->{l}{$layer} && next);
		my $outfile = "$directory/$layer$suffix";
#        print "out to $outfile\n";
		open(CIRCLESOUT, ">$outfile") or 
			croak "cannot open $outfile for write\n";
		foreach my $circ ($self->getAddrByType($layer, "circles")) {
			my $obj = $self->getobj($circ);
			print CIRCLESOUT "$circ->{id}:" .
				join(",", @{$obj->{pt}}) . ":" .
				"$obj->{rad}:$obj->{color}:$obj->{linetype}\n";
			$opts->{kok} && $self->remove($circ);
		}
		close(CIRCLESOUT);
	}

} # end subroutine save definition
########################################################################

=head2 pingcirc

Returns a hash reference for colon-separated key-value pairs in the
".circ_data" file which is found inside of $directory.  If the file is
not found, returns undef. 

The key may not contain colons.  Colons in values will be preserved
as-is.

  $drw->pingcirc($directory);

=cut
sub pingcirc {
	my $self = shift;
	my ($directory) = @_;
	open(TAG, "$directory/$circtag") or return();
	my %info;
	foreach my $line (<TAG>) {
		$line =~ s/\s+$//;
		# keys may not contain colons, but values can
		# whitespace around first colon is optional
		my ($key, $val) = split(/\s*:\s*/, $line, 2);
		$info{$key} = $val;
		}
	close(TAG);
	return(\%info);
} # end subroutine pingcirc definition
########################################################################

=head2 write_circdata

  $drw->write_circdata($directory, \%options);

=cut
sub write_circdata {
	my $self = shift;
	my ($directory, $opts) = @_;
	my $circfile = "$directory/$circtag";
	# maybe load the existing one first and then over-write it?
	my $existing = $self->pingcirc($directory);
	my %info;
	$existing && (%info = %$existing);
	if($opts->{info}) {
		foreach my $key (%{$opts->{info}}) {
			$info{$key} = $opts->{info}{$key};
		}
	}
	$info{suffix} = $opts->{suffix};
	open(CDATA, ">$circfile") or croak "cannot open $circfile for write";
	foreach my $key (keys(%info)) {
		print CDATA "$key:$info{$key}\n";
	}
	close(CDATA);

} # end subroutine write_circdata definition
########################################################################


1;
