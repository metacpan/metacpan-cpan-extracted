package CAD::Drawing::IO::PgDB;
our $VERSION = '0.03';

use CAD::Drawing;
use CAD::Drawing::Defined;

use DBI;
use Storable qw(freeze);
use Digest::MD5 qw(md5);

use strict;
use Carp;

########################################################################
=pod

=head1 NAME

CAD::Drawing::IO::PgDB - PostgreSQL save / load methods

=head1 NOTICE

This module is considered pre-ALPHA and under-documented.  Its use is
strongly discouraged except under experimental conditions.  Particularly
susceptible to change will be the table structure of the database, which
currently does not yet even have any auto-create method.

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
	DBI
	DBD::Pg

=cut
########################################################################

=head1 Requisite Plug-in Functions

See CAD::Drawing::IO for a description of the plug-in architecture.

=cut
########################################################################
# the following are required to be a disc I/O plugin:
our $can_save_type = "pgdb";
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
		($type eq "pgdb") && return("pgdb");
		return();
	}
	if($filename =~ m/^dbi:/) {
		return("pgdb");
	}
	return();
} # end subroutine check_type definition
########################################################################

=head1 Back-End Input and output methods

The functions load() and save() are responsible for determining the
filetype (with forced types available via $opt->{type}.)  These then
call the appropriate load<thing> or save<thing> functions.

=cut
########################################################################

=head2 load

Loads a CAD::Drawing object from an SQL database.  $spec should be of
the form required by the database driver.

$opts->{auth} = ["username", "password"] may be required to create a
connection.

  $drw->load($spec, $opts);

=cut
sub load {
	my $self = shift;
	my ($spec, $options) = @_;
	my %opts = parse_options($spec, $options);
	my $dbh = $opts{handle};
	$dbh || (
		$dbh = DBI->connect(
			$opts{spec}, $opts{username}, $opts{password},
			) or croak("connection failed\n")
		);
	my %have = map( {$_ => 1} $dbh->tables);
	$have{drawing} or croak("$spec has no drawing table");
	$have{layer} or croak("$spec has no layer table");
	my $drawing = $opts{drawing};
#    my $col = $dbh->selectcol_arrayref(
#                    "select layer_name from layer where dwg_name=?", 
#                                        {}, $drawing) or 
#                    croak "get layers failed";
#    my @layers = @$col;
	# faster replacement method
	my $got = $dbh->selectall_arrayref(
					"select layer_name, layer_id FROM layer " .
					"WHERE dwg_name = ?", {}, $drawing) or
					croak "get layers failed";
	my %layer_id = map({$_->[0] => $_->[1]} @$got);
	my @layers = keys(%layer_id);
	@layers or croak "no layers for $drawing";
#    print "gots: @$got\n";exit;

					
	# print "got layers:\n\t", join("\n\t", @layers), "\n";
	my($s, $n) = check_select(\%opts);
	my %want = map({$_ => 1} keys(%call_syntax));
	if($s->{t}) {
		%want = %{$s->{t}};
	}
	if($n->{t}) {
		foreach my $type (keys(%{$n->{t}})) {
			$want{$type} = 0;
		}
	}
	my $ftchdbg = 0; # for fetch debugs
	my $stat = $opts{show_stat};
	if($have{polyline} and $want{plines}) {
		# new method:
		my $plines = $dbh->selectall_arrayref(
			"SELECT " . join(", ", 
				map({"l." . $_}
					qw(
						layer_name
						)
					),
				map({"p." . $_} 
					qw(
						line_id
						line_value
						sclosed
						color
						linetype
						)
					),
				) . " " . # end join
			"FROM layer l, polyline p " .
			"WHERE p.layer_id = l.layer_id " .
			"AND l.dwg_name = ?", 
			{},
			$drawing
			);
		foreach my $pl (@{$plines}) {
			my ($l, $id, $lv, $cl, $co, $lt) = @$pl;
			$s->{l} && ($s->{l}{$l} || next);
			$n->{l} && ($n->{l}{$l} && next);
			$s->{c} && ($s->{c}{$co} || next);
			$n->{c} && ($n->{c}{$co} && next);
			$stat && print "pline: $l\n";
			my %plopts = (
					"closed"   => $cl,
					"color"    => $co,
					"layer"    => $l,
					"linetype" => $lt,
					"id"       => $id,
					);
			my @pts = map({[split(/\s*,\s*/, $_)]
						} split(/\s*:\s*/, $lv)
						);
			my $addr = $self->addpolygon(\@pts, \%plopts);

		} # end foreach $pl
	} # end if polyline
	if(($have{inst_point} and $have{data_point}) and $want{points} ) {
		my $points = $dbh->selectall_arrayref(
			"SELECT " . join(", ",
				map({"l." . $_}
					qw(
						layer_name
						)
					),
				"i.match_id", 
				map({"d." . $_ . "_value"} qw(x y z)),
				map({"i." . $_} 
					qw(
						color
						linetype
						)
					),
				) . " " . # end join
			"FROM layer l, inst_point i, data_point d " .
			"WHERE i.layer_id = l.layer_id ".
			"AND l.dwg_name = ?".
			"AND i.point_id = d.point_id",
			{},
			$drawing
			);
		foreach my $po (@{$points}) {
			($stat > 1) && print "point\n";
			my ($l, $id, $x, $y, $z, $co, $lt) = @$po;
			$s->{l} && ($s->{l}{$l} || next);
			$n->{l} && ($n->{l}{$l} && next);
			$s->{c} && ($s->{c}{$co} || next);
			$n->{c} && ($n->{c}{$co} && next);
			my %poopts = (
					"color"    => $co,
					"layer"    => $l,
					"linetype" => $lt,
					"id"       => $id,
					);
			my $addr = $self->addpoint([$x,$y,$z], {%poopts});
		} # end foreach $po
	} # end if have points and such


	unless($opts{handle}) {
		$dbh->disconnect();
	}

	return();
########################################################################	
# end used code
		
	my %sth;
	foreach my $layer (@layers) {
		$s->{l} && ($s->{l}{$layer} || next);
		$n->{l} && ($n->{l}{$layer} && next);
		$stat && print "$layer\n";
		if($have{arcs} and $want{arcs}) {
			# load them
			$sth{arcs} || ($sth{arcs} = 
				$dbh->prepare(
					"SELECT " . join(", ",
									"arc_id",
									"x_value",
									"y_value",
									"z_value",
									"radius",
									"stang",
									"endang",
									"color",
									"linetype",
									) . " " .
					"FROM arcs " .
					"WHERE layer_id = ?")
					);
			$ftchdbg && print "layer_id is $layer_id{$layer}\n";
			my $success = $sth{arcs}->execute($layer_id{$layer});
			my $arcs = $sth{arcs}->fetchall_arrayref;
			foreach my $ar (@$arcs) {
				my ($id, $x, $y, $z, $r, $sa, $ea, $co, $lt) = @$ar;
				$s->{c} && ($s->{c}{$co} || next);
				$n->{c} && ($n->{c}{$co} && next);
				$ftchdbg && print "fetching arc $id\n";
				($stat > 1) && print "arc\n";
				my %aropts = (
						"color"    => $co,
						"layer"    => $layer,
						"linetype" => $lt,
						"id"       => $id,
						);
				my @angs = ($sa, $ea);
				my $addr = $self->addarc([$x,$y,$z], $r, \@angs, {%aropts});
				} # end foreach $ar
			}
		if($have{circles} and $want{circles}) {
			# load these
			$sth{circles} || ($sth{circles} =
				$dbh->prepare(
					"SELECT " . join(", ",
									"circle_id",
									"x_value",
									"y_value",
									"z_value",
									"radius",
									"color",
									"linetype",
									) . " " .
					"FROM circles " .
					"WHERE layer_id = ?")
					);
			$ftchdbg && print "layer_id is $layer_id{$layer}\n";
			my $success = $sth{circles}->execute($layer_id{$layer});
			my $circles = $sth{circles}->fetchall_arrayref;
			foreach my $ci (@$circles) {
				my($id, $x,$y,$z,$r,$co,$lt) = @$ci;
				$s->{c} && ($s->{c}{$co} || next);
				$n->{c} && ($n->{c}{$co} && next);
				$ftchdbg && print "fetching circle $id\n";
				($stat > 1) && print "circle\n";
				my %ciopts = (
						"color"    => $co,
						"layer"    => $layer,
						"linetype" => $lt,
						"id"       => $id,
						);
				my $addr = $self->addcircle([$x,$y,$z], $r, {%ciopts});
				} # end foreach $ci
			} # end if $have{circles}
		if($have{lines} and $want{lines}) {
			# load these
			$sth{lines} || ($sth{lines} =
				$dbh->prepare(
					"SELECT " . join(", ",
									"line_id",
									"x1_value",
									"y1_value",
									"z1_value",
									"x2_value",
									"y2_value",
									"z2_value",
									"color",
									"linetype",
									) . " " .
					"FROM lines " .
					"WHERE layer_id = ?")
					);
			$ftchdbg && print "layer_id is $layer_id{$layer}\n";
			my $success = $sth{lines}->execute($layer_id{$layer});
			my $lines = $sth{lines}->fetchall_arrayref;
			foreach my $li (@$lines) {
				my($id, $x1,$y1,$z1, $x2,$y2,$z2, $co, $lt) = @$li;
				$s->{c} && ($s->{c}{$co} || next);
				$n->{c} && ($n->{c}{$co} && next);
				$ftchdbg && print "fetching line $id\n";
				($stat > 1) && print "line\n";
				my %liopts = (
						"color"    => $co,
						"layer"    => $layer,
						"linetype" => $lt,
						"id"       => $id,
						);
				my @pts = (
						[$x1, $y1, $z1],
						[$x2, $y2, $z2]
						);
				my $addr = $self->addline(\@pts, {%liopts});
				} # end foreach $li
			} # end if $have{lines}
		if($have{points} and $want{points}) {
			# load these
				# FIXME: don't have any of these yet
			}
		if($have{polyline} and $want{plines}) {
			# load these
			# maybe this is much faster:
			$sth{plines} || ($sth{plines} = 
				$dbh->prepare(
					"SELECT " . join(", ",   
								"line_id", 
								"line_value", 
								"sclosed", 
								"color", 
								"linetype"
								) . " " .
					"FROM polyline " . 
					"WHERE layer_id = ? " )
					);
			$ftchdbg && print "layer_id is $layer_id{$layer}\n";
			my $success = $sth{plines}->execute($layer_id{$layer});
			my $plines = $sth{plines}->fetchall_arrayref;
			# print "fetching polylines for $layer from $drawing\n";
			# print "got polylines:\n\t", 
			# 	join("\n\n\t", map({join(" ", @{$_})} @{$plines})), "\n";
			foreach my $pl (@{$plines}) {
				my ($id, $lv, $cl, $co, $lt) = @{$pl};
				$s->{c} && ($s->{c}{$co} || next);
				$n->{c} && ($n->{c}{$co} && next);
				$ftchdbg && print "fetching polyline $id\n";
				($stat > 1) && print "polyline\n";
#                print "closed: $cl\n";
				my %plopts = (
						"closed"   => $cl,
						"color"    => $co,
						"layer"    => $layer,
						"linetype" => $lt,
						"id"       => $id,
						);
				($stat == 4) && print "string:  $lv\n";
				my @pts = map({[split(/\s*,\s*/, $_)]
							} split(/\s*:\s*/, $lv)
							);
				($stat > 2 ) && 
					print "pts:\n\t", 
						join("\n\t", 
							map({join(",", 
								map({sprintf("%0.2f", $_)} @$_))} @pts
								) 
							), "\n";
				#print "got points:\n\t", 
				#	join("\n\t", map({join(",", @{$_})} @pts)), "\n";
				my $addr = $self->addpolygon(\@pts, {%plopts});	
				} # end foreach $pl
			} # end if $have{polyline}
		if($have{"3Dplines"}) {
		
			# I'm not sure that we really want to implement these in the
			# same way as the others.  Are 3Dplines really any different
			# than your run-of-the-mill polylines?  If you just load 3D
			# coordinates into a polyline, it will mostly act like a 3D
			# polyline until you try to save to and from autocad format.
			# Given that we have already made the decision to move away
			# from that, let it be simple everywhere else.

		} # end if $have{3Dplines}
		if($have{texts} and $want{texts}) {
			# load these
			$sth{texts} || ($sth{texts} = 
				$dbh->prepare(
					"SELECT " . join(", ",
								"text_id",
								"x_value",
								"y_value",
								"z_value",
								"height",
								"text_string",
								"color",
								"linetype",
								) . " " .
					"FROM texts " .
					"WHERE layer_id = ? ")
					);
			$ftchdbg && print "layer_id is $layer_id{$layer}\n";
			my $success = $sth{texts}->execute($layer_id{$layer});
			my $texts = $sth{texts}->fetchall_arrayref;
			foreach my $te (@{$texts}) {
				my ($id, $x, $y, $z, $h, $str, $co, $lt) = @$te;
				$s->{c} && ($s->{c}{$co} || next);
				$n->{c} && ($n->{c}{$co} && next);
				($stat > 1) && print "text\n";
				my %teopts = (
						"height"   => $h,
						"color"    => $co,
						"layer"    => $layer,
						"linetype" => $lt,
						"id"       => $id,
						);
				my $addr = $self->addtext([$x,$y,$z], $str, {%teopts});
				} # end foreach $te
			} # end if $have{texts}
		if(($have{inst_point} and $have{data_point}) and $want{points} ) {
			# FIXME: I currently just load these as if they were
			# FIXME:  typical points
			$sth{inst_points} || ($sth{inst_points} = 
				$dbh->prepare(
					"SELECT " . join(", ",
								"i.match_id",
								"d.x_value",
								"d.y_value",
								"d.z_value",
								"i.color",
								"i.linetype",
								) . " " .
					"FROM inst_point i, data_point d " .
					"WHERE i.layer_id = ?" .
					"AND i.point_id = d.point_id")
					);
			my $success = $sth{inst_points}->execute($layer_id{$layer});
			my $points = $sth{inst_points}->fetchall_arrayref;
			foreach my $po (@{$points}) {
				($stat > 1) && print "point\n";
				my ($id, $x, $y, $z, $co, $lt) = @$po;
				$s->{c} && ($s->{c}{$co} || next);
				$n->{c} && ($n->{c}{$co} && next);
				my %poopts = (
						"color"    => $co,
						"layer"    => $layer,
						"linetype" => $lt,
						"id"       => $id,
						);
				$ftchdbg && print "pointid $id\n";
				($stat > 2) && print "point: $x, $y, $z\n";
				my $addr = $self->addpoint([$x,$y,$z], {%poopts});
				# print "point:  $x,$y,$z\n";
				} # end foreach $po
			} # end if $have{points}
		} # end foreach $layer
		
	
	unless($opts{handle}) {
		$dbh->disconnect();
	}
} # end subroutine load definition
########################################################################

=head2 save

  $drw->save($spec, $opts);

=cut
sub save {
	my $self = shift;
	my ($spec, $options) = @_;
	my %opts = parse_options($spec, $options);
	my $drawing = $opts{drawing};
	my %dbopts;
	$opts{dbopts} && (%dbopts = %{$opts{dbopts}});
	defined($dbopts{AutoCommit}) || ($dbopts{AutoCommit} = 0);
	my $dbh = DBI->connect(
		$opts{spec}, $opts{username}, $opts{password},
		\%dbopts
		) or croak("connection failed\n");
	# FIXME: # we could make the required tables (add this later?)
	my %have = map( {$_ => 1} $dbh->tables);
	$have{drawing} or croak("$spec has no drawing table");
	$have{layer} or croak("$spec has no layer table");

	# FIXME: we need to support selective saves here? 

	# FIXME: 
	# should also have a way to kill deleted items (would have to get
	# everything from this database for this drawing, then remove it
	# (which frees us to always INSERT (but prevents building-up a
	# drawing from separate processes)
	
	# FIXME: should have more info to select drawing name
	my ($had) = $dbh->selectrow_array(
		"SELECT dwg_name from drawing where dwg_name = ?",
		{},
		$drawing
		);
	print "table had: $had\n";
	if($had) {
		# FIXME: this is currently pointless
		my $did = $dbh->do(
			"UPDATE drawing set dwg_name = ? " .
				"WHERE dwg_name = ?", 
			{
			AutoCommit => 1,
			},
			$drawing, $drawing
			);
	}
	else {
#        print "insert forced\n";
		$dbh->do(
			"INSERT into drawing(dwg_name) VALUES(?)",
			{},
			$drawing
			) or croak("cannot make drawing", $dbh->errstr);
	}
	

	# Seems like a better plan to simply use REPLACE, but also offer an
	# option to delete all existing items first (rather than doing all
	# of the queries and then a few deletes

	# This would be fine and dandy except that REPLACE is a proprietary
	# extension implemented only by mysql

	my @layers = $self->getLayerList();
#    print "layers: @layers\n";
	my $to_save = $self->select_addr($options);
#    print "not a list: @$to_save\n";
	my %se_h; # SELECT handles
	my %up_h; # UPDATE handles
	my %in_h; # INSERT handles
	$se_h{layers} =	$dbh->prepare(
					"SELECT layer_id " .
					"FROM layer " .
					"WHERE layer_name = ? " .
					"AND dwg_name = ? " 
				);
	$in_h{layers} = $dbh->prepare(
					"INSERT into layer(layer_name, dwg_name) " .
					"VALUES(?, ?)"
				);
	my %tntr = (
		"arcs" => "arcs",
		"circles" => "circles",
		"lines" => "lines",
		"plines" => "polyline", # FIXME: rename that table!
		"points" => "points",
		"texts" => "texts",
		"images" => "images",
		);

	my %del_h;
	foreach my $type (keys(%tntr)) {
		$have{$tntr{$type}} || next; # no table for that
		$del_h{$type} = $dbh->prepare(
			"DELETE from " . $tntr{$type} . " " .
			"WHERE layer_id = ?"
			);
	}
	# make it the default behaviour to cleanup first
	defined($opts{clear_layers}) || ($opts{clear_layers} = 1);

	# now we either have to have loaded the entire thing or provide
	# some selective kill methods (ack) because source id will not
	# match dest id!
					
	foreach my $layer (@layers) {
#        print "working on layer $layer\n";
		$se_h{layers}->execute($layer, $drawing)
			or croak("cannot lookup $layer in $drawing\n");
		my ($layer_id) = $se_h{layers}->fetchrow_array();
		if(defined($layer_id)) {
#            print "layer id: $layer_id\n";
			if($opts{clear_layers}) {
#                print "clearing layer $layer\n";
				foreach my $type (keys(%del_h)) {
#                    print "clearing type $type\n";
					$del_h{$type}->execute($layer_id);
#                    print "affecting ", $del_h{$type}->rows, " rows\n";
					$del_h{$type}->finish();
				}
			}
		}
		else {
#            print "should be making new layer\n";
			$in_h{layers}->execute($layer, $drawing);
			# nothing beats maintaining knowledge in 5 places!
			# FIXME:  SQL is primitive?
			my ($this) = $se_h{layers}->execute($layer, $drawing)
				or croak("cannot lookup $layer in $drawing\n");
#            print "this came back as $this\n";
			($layer_id) = $se_h{layers}->fetchrow_array();
#            print "new layer_id: $layer_id\n";
		}
		# FIXME: would set layer properties here
		my %these = sort_addr($layer, $to_save);
		# FIXME: current assumption is that the tables exist!
		foreach my $point (@{$these{points}}) {
#            print "have a point\n";
			my $obj = $self->getobj($point);
			# FIXME: this crap has GOT to go elsewhere
			$se_h{points} || ( 
				$se_h{points} = 
					$dbh->prepare(
						"SELECT point_id " .
						"FROM points " .
						"WHERE point_id = ? ". 
						"AND layer_id = ? "
						)
					);
			$in_h{points} || (
				$in_h{points} = 
					$dbh->prepare(
						"INSERT into points(" .
							join(", ", 
								"x_value",
								"y_value",
								"z_value",
								"color",
								"linetype",
								"layer_id",
								) . 
							") " .
						"VALUES(?,?,?, ?,?, ?)"
						)
					);
			$up_h{points} || (
				$up_h{points} =
					$dbh->prepare(
						"UPDATE points set " .
							join(", ", 
								map({"$_ = ?"}
									"x_value",
									"y_value",
									"z_value",
									"color",
									"linetype",
									)
								) . 
						"WHERE layer_id = ? " .
						"AND point_id = ?"
						)
					);
			my $id = $point->{id};
			$se_h{points}->execute($id, $layer_id);
			my ($have_id) = $se_h{points}->fetchrow_array;
			# FIXME: this will eventually have to change to a name!
			if(defined($have_id)) {
#                print "replacing $id\n";
				# over-write it
				$up_h{points}->execute(
					$obj->{pt}[0], $obj->{pt}[1], $obj->{pt}[2],
					$obj->{color}, $obj->{linetype},
					$layer_id, $id
					);
			}
			else {
#                print "new for $id\n";
				# make a new one
				$in_h{points}->execute( 
					$obj->{pt}[0], $obj->{pt}[1], $obj->{pt}[2],
					$obj->{color}, $obj->{linetype},
					$layer_id
					);
			}
		} # end foreach $point
		foreach my $line (@{$these{lines}}) {
		} # end foreach $line
		foreach my $pline (@{$these{plines}}) {
			my $obj = $self->getobj($pline);
			if($opts{update_by} eq "color") {
				$se_h{plines} || (
					$se_h{plines} = 
						$dbh->prepare(
							"SELECT line_id " .
							"FROM polyline " .
							"WHERE color = ? " .
							"AND layer_id = ? "
							)
						);

			}
			else {
				$se_h{plines} || (
					$se_h{plines} = 
						$dbh->prepare(
							"SELECT line_id " .
							"FROM polyline " .
							"WHERE line_id = ? " .
							"AND layer_id = ? "
							)
						);
			}
			$in_h{plines} || (
				$in_h{plines} = 
					$dbh->prepare(
						"INSERT into polyline(" .
							join(", ",
								"line_value", "sclosed",
								"color", "linetype",
								"layer_id"
								) .
							") " .
						"VALUES(?, ?, ?,?, ?)"
						)
					);
			$up_h{plines} || (
				$up_h{plines} = 
					$dbh->prepare(
						"UPDATE polyline set " .
							join(", ", 
								map({"$_ = ?"}
									"line_value", "sclosed",
									"color", "linetype",
									"layer_id"
									) 
								) .
						"WHERE layer_id = ? " .
						"AND line_id = ? "
						)
					);
			my $pstring = join(":", map({join(",", @$_)} @{$obj->{pts}}));
#            print "closed: $obj->{closed}\n";
			my @tr = ("f", "t");
			# gives the option to update according to any property
			my $update_by = $opts{update_by};
			$update_by || ($update_by = "id");
			my $update_key = $pline->{$update_by};
			$se_h{plines}->execute($update_key, $layer_id);
			my ($have_id) = $se_h{plines}->fetchrow_array;
			if(defined($have_id)) {
				my $id = $have_id;
				$up_h{plines}->execute( 
					$pstring, $tr[$obj->{closed}],
					$obj->{color}, $obj->{linetype},
					$layer_id, $id
					);
			}
			else {
				$in_h{plines}->execute(
					$pstring, $tr[$obj->{closed}],
					$obj->{color}, $obj->{linetype},
					$layer_id
					);
			}
		} # end foreach $pline
		foreach my $circ (@{$these{circs}}) {
		} # end foreach $circ
		foreach my $arc (@{$these{arcs}}) {
		} # end foreach $arc
		foreach my $text (@{$these{texts}}) {
		} # end foreach $text
	} # end foreach $layer
	$se_h{layers}->finish();
	$in_h{layers}->finish();
	foreach my $type (keys(%call_syntax)) {
		$se_h{$type} && $se_h{$type}->finish();
		$in_h{$type} && $in_h{$type}->finish();
		$up_h{$type} && $up_h{$type}->finish();
	}
	unless($dbopts{AutoCommit}) {
		$dbh->commit or 
			croak("commit failed:\n", $dbh->errstr);
	}
	$dbh->disconnect();
} # end subroutine save definition
########################################################################

=head2 cleardb

Deletes the drawing and all of its entities from the database.

  $drw->cleardb();

=cut
sub cleardb {
	my $self = shift;
	my ($spec, $options) = @_;
	my %opts = parse_options($spec, $options);
	my $drawing = $opts{drawing};
	my %dbopts;
	$opts{dbopts} && (%dbopts = %{$opts{dbopts}});
	defined($dbopts{AutoCommit}) || ($dbopts{AutoCommit} = 0);
	my $dbh = DBI->connect(
		$opts{spec}, $opts{username}, $opts{password},
		\%dbopts
		) or croak("connection failed\n");
	my %have = map( {$_ => 1} $dbh->tables);
	$have{drawing} or croak("$spec has no drawing table");
	$have{layer} or croak("$spec has no layer table");
	my ($had) = $dbh->selectrow_array(
		"SELECT dwg_name from drawing where dwg_name = ?",
		{},
		$drawing
		);
	defined($had) or croak("$spec / $drawing does not exists\n");
	my $col = $dbh->selectcol_arrayref(
					"select layer_name from layer where dwg_name=?", 
										{}, $drawing) or 
					croak "get layers failed";
	my @layers = @$col;
	my %tntr = (
		"arcs" => "arcs",
		"circles" => "circles",
		"lines" => "lines",
		"plines" => "polyline", # FIXME: rename that table!
		"points" => "points",
		"texts" => "texts",
		"images" => "images",
		);
	my %se_h;
	$se_h{layers} =	$dbh->prepare(
					"SELECT layer_id " .
					"FROM layer " .
					"WHERE layer_name = ? " .
					"AND dwg_name = ? " 
				);


	my %del_h;
	foreach my $type (keys(%tntr)) {
		$have{$tntr{$type}} || next;
		$del_h{$type} = $dbh->prepare(
			"DELETE from " . $tntr{$type} . " " .
			"WHERE layer_id = ?"
			);
	}
	$del_h{layer} = $dbh->prepare(
		"DELETE from layer where layer_id = ?"
		);

	foreach my $layer (@layers) {
		$se_h{layers}->execute($layer, $drawing)
			or croak("cannot lookup $layer in $drawing\n");
		my ($layer_id) = $se_h{layers}->fetchrow_array();
		foreach my $type (keys(%del_h)) {
			$del_h{$type}->execute($layer_id);
			$del_h{$type}->finish();
		}
		$del_h{layer}->execute($layer_id);
	}
	$se_h{layers}->finish();

	$dbh->do(
		"DELETE from drawing WHERE dwg_name = ?",
		{
			AutoCommit => 1,
		},
		$drawing
		);
	unless($dbopts{AutoCommit}) {
		$dbh->commit or 
			croak("commit failed:\n", $dbh->errstr);
	}
	$dbh->disconnect();
		


} # end subroutine cleardb definition
########################################################################

=head1 Internals

=cut
########################################################################

=head2 parse_options

Allows options to come in through the $spec or %opts.

  %options = parse_options($spec, \%opts);

=cut
sub parse_options {
	my ($spec, $options) = @_;
	my %opts;
	(ref($options) eq "HASH" ) && (%opts = %$options);
	$opts{auth} && ( 
		($opts{username}, $opts{password}) = @{$opts{auth}}
		);
	unless($opts{drawing}) {
		if($spec =~ s/drawing=(.*?)//) {
			$opts{drawing} = $1;
			$spec =~ s/;+/;/;
			$spec =~ s/;$//;
			}
		else {
			croak("no drawing found in spec or opts\n");
			}
		}
	$opts{spec} = $spec;
	return(%opts);
} # end subroutine parse_options definition
########################################################################

=head2 sort_addr

Sorts through @addr_list and returns a hash of array references for each
entity type.

  %these = sort_addr($layer, \@addr_list);

=cut
sub sort_addr {
	my ($layer, $list) = @_;
#    print "list: @$list\n";
	my @valid = grep({$_->{layer} eq $layer} @$list);
	my @ents = sort(keys(%call_syntax));
	# init the refs
	my %these = map({$_ => []} @ents);
	foreach my $addr (@valid) {
		push(@{$these{$addr->{type}}}, $addr);
	}
	return(%these);
} # end subroutine sort_addr definition
########################################################################

1;
