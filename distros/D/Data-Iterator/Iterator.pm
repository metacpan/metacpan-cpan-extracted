
	package Data::Iterator;
	require 5.000;

	use strict;
	use Carp;
	use FileHandle;
	use vars qw($VERSION);

	$VERSION = 0.021;

	local $[ 	= 0;

	my %_cfg		= ('_set_'		=>  {'-Nodes'		=> 0,		# show nodes as normal items
										 '-DigLevel'	=> undef,	# dig down to this level
					   					 '-DigFiles'	=> 1,		# show file's content if value is in '-FILE:...'-format
					   					 '-DigGlobs'	=> 1,		# resolve glob references
					   					 '-DigSRefs'	=> 1,		# resolve scalar references
					   					 '-DigCode'		=> 1,		# execute coderefs, capture output
					   					 '-Files'		=> 1,		# allow for '-File:...' root objects
					   					 '-Code'		=> 1,		# allow for coderef root objects
					   					 '-SRefs'		=> 1		# resolve scalarref root objects
										},
					   '_known_refs_'=> [ {qw(ARRAY 1 CODE 1 GLOB 1 HASH 1 SCALAR 1 REF 0 FileHandle 1 VFILE 1 VCODE 0)},
					   					  {qw(ARRAY 1 CODE 1 GLOB 1 HASH 1 SCALAR 1 REF 0 FileHandle 1 VFILE 1 VCODE 0)} ],
					   '_init_'		=> sub {my $me = shift;
					   						@{$me->{'_known_refs_'}[0]}{'VFILE', 'GLOB', 'CODE', 'SCALAR'} = @{$me->{'_set_'}}{'-Files', '-Globs', '-Code', '-SRefs'};
					   						@{$me->{'_known_refs_'}[1]}{'VFILE', 'GLOB', 'CODE', 'SCALAR'} = @{$me->{'_set_'}}{'-DigFiles', '-DigGlobs', '-DigCode', '-DigSRefs'};
					   					   }
					  );
	my %br			= ('HR'	=> [('{\'', '\'}')],
					   'AR'	=> [('[', ']')],
					   'SR'	=> [('','')],
					   'GR' => [('[',']')],
					   'FH'	=> [('[',']')],
					   'SV'	=> [('','')],
					   'VF'	=> [('<','>')],
					   '0'	=> [('','')]);
	my %init =	('ARRAY'	=> sub {return $_[0], scalar @{$_[0]}, -1, 'ARRAY', @{$br{'AR'}}, $_[0];},
				 'CODE'		=> sub {my (@e, @r);
				 					eval {local $SIG{__DIE__}	= sub { chomp @_;push @e, 'FATAL: '.join ('', @_);
																		if (scalar (caller(0)) eq 'Carp') {
																			my $loc = sprintf (" at %s line %s", (caller(1))[1,2]);
																			$e[-1] =~ s/( at .*?)$/$loc/;
																		}
																	  	die};
		 								  local $SIG{__WARN__}	= sub {chomp @_;push @e, 'WARN : '.join ('', @_);
																		if (scalar (caller(0)) eq 'Carp') {
																			my $loc = sprintf (" at %s line %s", (caller(1))[1,2]);
																			$e[-1] =~ s/( at .*?)$/$loc/;
																		}
																	   };
										  @r = $_[0]->();
										 };
									unshift @r, {('_ERR_' => \@e)};
					 				return \@r, scalar @r, -1, 'ARRAY', @{$br{'AR'}}, $_[0];
								   },
				 'GLOB'		=> sub {return $_[0], undef, -1, 'GLOB', @{$br{'GR'}}, $_[0];},
				 'HASH'		=> sub {my @k = keys %{$_[0]};
				 					return $_[0], \@k, scalar @k, -1, 'HASH', @{$br{'HR'}}, $_[0];},
				 'SCALAR'	=> sub {return $_[0], 1, -1, 'SCALAR', @{$br{'SR'}}, $_[0];},
				 'VFILE'	=> sub {my ($file) = $_[0] =~ /^-FILE:(.+)/;
									my $fh = new FileHandle ("< $file");
									carp ("Iterator::init failed on opening file:\n\t'$file': $!") && return undef unless $fh;
									return $fh, undef, -1, 'FileHandle', @{$br{'FH'}}, $_[0];
									},
				 'VCODE'	=> sub {},
				 'undef'	=> sub {return \$_[0], 1, -1, 'undef', @{$br{'SV'}}, \$_[0];},
				);
	my %elem = 	('ARRAY'	=> sub {return  (++$_[0]->[2] < $_[0]->[1]				 ?
				 								($_[0]->[2], \$_[0]->[0][$_[0]->[2]]):
				 								())
				 				   },
				 'CODE'		=> sub {return undef},
				 'FileHandle'=> sub {my $fh = $_[0]->[0];
					 				 return $fh->eof ? ()
					 				 				 : ($fh->input_line_number+1, \scalar <$fh>);
					 			   },
				 'GLOB' 	=> sub {my $fh = ${$_[0]->[0]};
									return eof ($fh) ? ()
												     : do {my $l = <$fh>;($., \$l)}
								   },
				 'HASH'		=> sub {return ++$_[0]->[3] < $_[0]->[2] ?
  				 									  ($_[0]->[1][$_[0]->[3]], \$_[0]->[0]{$_[0]->[1][$_[0]->[3]]})
 				 									 : ()
				 				   },
				 'SCALAR'	=> sub {return ++$_[0]->[2] < $_[0]->[1] ? ('', $_[0]->[0]) : ()
				 				   },
# 				 'VFILE'	=> sub {return ++$_[0]->[2] < $_[0]->[1] ? '' : undef, \$_[0]->[0]
# 				 				   },
				 'undef'	=> sub {return ++$_[0]->[2] < $_[0]->[1] ? ('', $_[0]->[0]) : ()
				 				   }
				);


	sub new {
		my $class		= shift;
		my $me			= {};
		$me->{'_source'}= defined $_[0] ? shift : do{carp "Iterator::new: No valid source specified";return};
		bless $me, $class;
		$me->{'stack'}	= [];
		$me->{'level'}	= 0;

		$me->{'_cfg'}						=  { %_cfg };
		$me->{'_cfg'}{'_known_refs_'}[0]	=  { %{$_cfg{'_known_refs_'}[0]} };
		$me->{'_cfg'}{'_known_refs_'}[1]	=  { %{$_cfg{'_known_refs_'}[1]} };
		$me->{'_cfg'}{'_set_'}				=  { %{$_cfg{'_set_'}} };

 		my $item = $me->{'_source'};
		my %seen;
		while ($me->_ref_ex($item,0) eq 'SCALAR'){
			$seen{$item}	= 1;
			$item			= ${$item};
			last if (exists $seen{$item});
		};
		$me->{'root'}		= [ $me->_init ($item, 0), '' ];
		$me->{'_type'}		= ${$me->{'root'}}[-5];

		return undef unless defined $me->{'root'}[0];

 		$me->{'stack'}		= $me->{'root_context'}{'item'} = [ [@{$me->{'root'}}] ];
 		my $vp = $me->{'root'}[-2];chomp $vp;
 		$me->{'_seen'}{$vp}	= $me->{'root_context'}{'seen'}{$vp}	= 'ROOT OBJECT';#{};

		$me->{'contexts'}	= {};
		$me->{'err'}		= undef;

		return $me;
	}


	# setzt/liefert Objekt-Config: 	$obj->cfg()
	#				Modul-Config:	&Iterator::cfg()
	# rein:	- 1. (Key3, Key1=>Val1, Key2=>Val2 [, ...])
	#		- 2. nix
	# raus:	- 1. die alten Werte der übergebenen Keys
	#		- 2. %Objekt/Modul-Config
	# !! Es wird kein Validitätstest durchgeführt !!
	sub cfg {
		my ($me, $target, $key, $val, @cfg, @r);
		unless (ref $_[0] ){ 	# nicht als Methode gerufen
			$target	= \%_cfg;
		}else{					# ok, cfg des Objektes handlen
			$me		= shift;
			$target	= $me->{'_cfg'};
		}

		scalar @_	? do {shift @_ if $_[0] =~ /::/; 		# Parameter, also resp. cfg dotieren
					   return keys %{$target->{'_set_'}} if $_[0] eq '-Keys';
					   @cfg = @_}
					: return (%{$target->{'_set_'}});	# man will lesen, also % liefern

		while (@cfg) {
			$key = shift @cfg;
			push (@r, $target->{'_set_'}{$key});
			last unless @cfg;

			next if (defined $cfg[0] && exists $target->{'_set_'}{$cfg[0]});
			if ($key eq '-DigLevel') {
				$target->{'_set_'}{'-DigLevel'} = shift @cfg;
				$target->{'_set_'}{'-DigLevel'} = undef if $target->{'_set_'}{'-DigLevel'} eq '';
				next;
			}
			$target->{'_set_'}{$key} = shift (@cfg) ? 1 : 0
				if exists $target->{'_set_'}{$key};
		}
		$target->{'_init_'}->($target);
		return @r;
	}

	sub element {

		my $me 			= shift;
		$me->{'err'}	= undef;
		my ($type, $ob, $cb, $stack, $seen, $key, $vparent, $err);
		my $append		= 1;
		my $context		= $_[0];

		# Kontext (pfadabhängig) setzen...
		($stack, $seen, $context) = ($me->_get_context($context))[0..2];
		defined ($stack)	? ($stack 	? do {$me->{'stack'} = $stack;
											  $me->{'_seen'} = $seen;}
										: do {my @r = $me->_path (@_);
											  unless (defined @r) {
												  warn $me->{'err'}.=sprintf (" at %s line %s", (caller)[1,2])."\n";
								  				  return;
											  }
											  return wantarray ? @r : $r[1]}
							  )
							: do {warn $me->{'err'}.=sprintf (" at %s line %s", (caller)[1,2])."\n";
								  return};

		$me->{'level'}	= $#{$me->{'stack'}};
		my @res 		= $me->_handle_item ($stack, $seen, $me->{'contexts'}, $context);
		(@{$me}{'path','val','key','level','vref','ppath','parent'}) = @res;

		if ($me->{'err'}) {
			warn $me->{'err'} .= sprintf (" at %s line %s", (caller)[1,2])."\n";
		}
		return wantarray ? (defined ($me->{'key'}) ? (@{$me}{'path','val','key','level','vref','ppath','parent'}) : ())
						 : (defined ($me->{'key'}) || undef);
	}


	sub keys {
		my $me			= shift;
		my $path		= defined ($_[0]) ? shift : '';
		my @_keys;
		$me->{'err'}	= undef;

		my ($elem, $context) = $me->_get_item ($path);
		warn ($me->{'err'}.sprintf(" at %s line %s", (caller)[1,2])."\n") && return
			unless defined $elem;

		my $stack		= [[ $me->_init($elem), '' ]];
		my $seen		= {};
		my $contexts	= {};
		$seen->{${$stack->[0]}[-2]} = $context;

		while ( my $key = ($me->_handle_item ($stack, $seen, $contexts, $context))[0]) {
			warn $me->{'err'}.sprintf(" at %s line %s", (caller)[1,2])."\n" if $me->{'err'};
			push @_keys, $key;
		}

		return wantarray ? @_keys : scalar @_keys
	}

	sub values {
		my $me 			= shift;
		my $path		= defined ($_[0]) ? shift : '';
		my @_vals;
		$me->{'err'}	= undef;

		my ($elem, $context) = $me->_get_item ($path);
		warn ($me->{'err'}.sprintf(" at %s line %s", (caller)[1,2])."\n") && return
			unless defined $elem;

		my $stack 		= [[ $me->_init($elem, length ($path) ? 1 : 0), '' ]];
		my $seen 		= {};
		my $contexts	= {};
		$seen->{${$stack->[0]}[-2]} = $context;

		my ($key, $val) ;
		while ( ($key, $val) = ($me->_handle_item($stack, $seen, $contexts, $context))[0, 1] ) {
			warn $me->{'err'}.sprintf(" at %s line %s", (caller)[1,2])."\n" if $me->{'err'};
			push @_vals, $val;
		}
		return wantarray ? @_vals : scalar @_vals
	}


	sub reset {
		my $me		= shift;
		my $path	= shift;
		chomp ($path) if defined ($path);
		$path		=~ s/[.+?*]$// if defined ($path);

		defined $path 	? ( return exists ($me->{'contexts'}{$path}) && delete ($me->{'contexts'}{$path}) ? 1 : undef)
					  	: ($me->{'contexts'} = {});

		$me->{'stack'}	= $me->{'root_context'}{'item'} = [ [@{$me->{'root'}}] ];

		$me->{'_seen'}	= {};
 		my $vp = ${$me->{'stack'}[0]}[-2];chomp $vp;
		$me->{'_seen'}{$vp}	= $me->{'root_context'}{'seen'}{$vp}	= 'ROOT OBJECT';

		$me->{'err'}	= undef;

	}


	sub _ref_ex{
		my $me = shift;
		my ($r, $c, $t, $rt);
		my $i = defined $_[1] && $_[1] > 0 || 0;
		local $^W = undef;

		unless (ref $_[0]) {
			if ($_[0] =~ /^-FILE:.+/) {
				($rt, $r) = $me->{'_cfg'}{'_known_refs_'}[$i]{'VFILE'} ? ('VFILE', 1) : ('undef', 0);
			}else{
				($rt, $r) = ('undef', 0);
			}
		}else{
			($c, $t)	= $_[0] =~ /(.+)=(.+)\(/;
			($t)		= $_[0] =~ /(.+)\(/ unless $c;
			($rt, $r)   = $me->{'_cfg'}{'_known_refs_'}[$i]{$c}	? ($c, 1)
															: ($me->{'_cfg'}{'_known_refs_'}[$i]{$t}	? ($t, 1)
																										: ('undef', 0)
															   );
		}
		return wantarray ? ($rt, $r) : $rt;
	};


	sub _init {
		my $me = shift;
		return $init{$me->_ref_ex($_[0])}->(@_)
	}


	# erhält:	- String mit Pfad zu Unter-Datenstruktur (a.1.b[*])
	# liefert:	- item_ref (wie ein 'stack'-Element), die auf die
	#			  per $_[0]=Pfad angegebene Unter-Datenstruktur verweist
	#			- $seen-Hash
	#			- um das \*$ bereinigten Pfad
	# setzt:	- $me->{contexts}{$context}
	#			- $me->{err}
	sub _get_context {
		my $me 		= shift;
		my $context = defined ($_[0])? shift : '';
		my ($stack, $seen, $item, $key, $level, $err);
		chomp $context;

		if (length $context) {
			if ($context =~ s/\*$//)  {
				unless (exists $me->{'contexts'}{$context}) {
					($item, $key, $level) = ($me->_path ($context))[1..2];
					($stack,
					 $seen	) = $item	? do {$me->{'contexts'}{$context}{'item'} = [[ $me->_init($item,1), '' ]],
					 						  $me->{'contexts'}{$context}{'seen'} = {}
					 						 }
									 	: ();
					if ($stack) {
				 		my $vp			= $stack->[0][-2];chomp $vp;
				 		$seen->{$vp}	= $stack->[0][-1];
					}
				}else{			# Kontext bekannt
					$stack	= $me->{'contexts'}{$context}{'item'};
					$seen	= $me->{'contexts'}{$context}{'seen'};
				}
			}else{			# kein Sternchen, also 1 Wert holen bzw. setzen
				$stack	= '';
				$seen	= {};
			}
		}else{			# kein  Pfad angegeben
			$stack	= $me->{'root_context'}{'item'};
			$seen	= $me->{'root_context'}{'seen'};
		}
		$me->{'err'} = $err if $err;
		return defined $stack ? ($stack, $seen, $context, $key, $level) : ();
	}

	# liefert die Adresse eines Datenobjektes [an "Pfad"]
	# ${$item} muß ge_init() werden)
	sub _get_item {
		my $me 		= shift;
		my $context = defined ($_[0]) ? shift : '';
		my ($stack, $err);

		chomp $context;

		if (length $context) {
			my ($item, $iref, $pref) = ($me->_path ($context))[1,4,-1];
 			$stack = $iref ? (defined $item	? $item : $iref)
 						   :  undef;
		}else{
			$stack =  $me->{'root_context'}{'item'}[-1][0];
		}
		$me->{'err'} = $err if $err;
		return defined $stack ? ($stack, $context) : ();
	}

	sub _handle_item {
		my $me = shift;
		my ($stack, $seen, $contexts, $context) = @_;
		my ($key, $val, $vref, $vparent, $parent, $_path, $path, $ob, $cb, $err);
		my $append =	1;

		my $level 						= $#{$stack};
ITEM:	{ 	my $item					= $stack->[-1];
			$_path 						= $item->[-1];
			$vparent					= $item->[-2];
			$parent						= $item->[0];
			($ob, $cb)					= @{$item}[-4, -3];
			($key, $vref)				= $elem{$item->[-5]}->($item);
			$val						= defined $vref ? ${$vref} : undef;

ISREF:		my ($ref_type, $is_ref) 	= $me->_ref_ex ($val, $level || 1);

			if ($is_ref) {
				my $tmp = $val;chomp $tmp;
				if (exists $seen->{$tmp}){
	  				$err = "Self reference: \'$_path$ob$key$cb\' refers to anchestor \'".(length ($seen->{$tmp}) ? $seen->{$tmp} : 'Root object')."\' ($tmp)";
					$val = undef;
					last ITEM;
				}else{
					$seen->{$tmp} 		= $_path;
				}

				if(!defined $me->{'_cfg'}{'_set_'}{'-DigLevel'} || ($level < $me->{'_cfg'}{'_set_'}{'-DigLevel'})){
						$_path 				.= $ob.$key.$cb;
						push @{$stack}, [ $init{$ref_type}->($val), $_path ];
						$seen->{$tmp} 		= $_path;
						goto ITEM if ($ref_type eq 'SCALAR');

						$me->{'_cfg'}{'_set_'}{'-Nodes'}	? ($append 		= 0)
															: do{$level		= $#{$stack};
									 				   		 	 goto ITEM};
				}
			}elsif (!defined $key){
				if ($#{$stack} > 0) {
					pop @{$stack};
					$level		= $#{$stack};
					delete $seen->{$vparent};
					goto ITEM;
				}else{
					delete $contexts->{$context};
				}
			}
		}	# end ITEM
		$path = ($append && defined $key) ? $_path.$ob.$key.$cb
										  : $_path;
		$me->{'err'} = $err;
		return defined $key ? ($path, $val, $key, $level, $vref, $_path, $parent) : ();
	}

	# liefert Wert zu einem Pfad, setzt ihn, wenn $_[1] gegeben
	# raus: Wert, Adresse, Elternadresse, Elternpfad, Level
	sub _path {
		my $me		= shift;
		my $path	= $_[0];
		$path		=~ s/[.+*]$//;
		my $do_set	= @_ > 1;
		my $level	= -1;
		my $val 	= $me->{'root'}->[0];
		my $pref	= my $vref = \$me->{'root'}->[0];

		my ($s) 	= $path =~ /^((?=\W)[^{\["'])/;
		$s			= '\.' unless $s;
		my $mc		= '[^'.$s.'\[\]{}]';
		my ($p, $pp) = '';
		my ($err, $val_added, $key, $match);

		while ($path =~ /($s?{($mc+?)}|$s?\[($mc+?)\]|(^|$s)($mc+))/g){
			$pp = $p;
			$p .= ($key = $1);
			{($match) = $key =~ /($mc+)/;
			 $match =~ s/^["']// && $match =~ s/["']$//; }
			my $r 	= defined ($2)	? 'HR'
									: (defined ($3) ? 'AR'
													: ((defined ($5) && ($match =~ /^-?\d+$/))	? 'AR'
																								: 'HR')
									  );

			if ($r eq 'HR') {
				$val = $me->_ref_ex ($val) eq 'HASH'? (exists $val->{$match} || $do_set	? do {$pref = $vref;
																							  ${$vref = \$val->{$match}}}
																						: do {$err	= "Not a valid hash key '$key': $val - '$p'";
																							  last}
													  )
													: ($do_set && $vref	? do {$pref 		= $vref;
																			  $$vref		= {};
																			  $val_added	= $val unless $val_added;
																			  $vref			= \$$vref->{$match}
																			 }
																		: do {$err	= "Not a hash reference: $val - '$p'";
																			  last}
													 );
			}elsif ($r eq 'AR') {
				$val = $me->_ref_ex ($val) eq 'ARRAY' ? (($match =~ /^-?\d+$/ && $match <= $#{$val})
														  || $do_set					?	do {$pref	= $vref;
																								${$vref = \$val->[$match]}}
																						:	do {$err	= "Not a valid array index '$key': $val - '$p'";
																								last}
														)
													  : ($do_set && $vref	? do {$pref			= $vref;
														  						  $$vref		= [];
																				  $val_added	= $val unless $val_added;
																				  $vref			= \$$vref->[$match];
																				 }
																			: do{$err		= "Not an array reference: $val - '$p'";
																				 last}
														);
			}else{
				print "Huch?!\n";
			}

			$level++;
		}
		if (length ($p) < length ($path)) {
			$err = "Syntax error in pathname: '$path'" unless $err;
		}

		$me->{'err'} = $err if $err;
		return $err	? (wantarray ? () : undef)
					: ($do_set	? do{$$vref = $_[1];
									 defined $val_added ? ($p, $val_added, $match, $level, $vref, $pp, $pref)
														: ($p, $val, $match, $level, $vref, $pp, $pref);}
								: ($p, $val, $match, $level, $vref, $pp, $pref));
	}

#--- main... ------------------------------------------------------------------
1;


__END__

=head1

=head2 Iterator.pm - liefert Pfade/Werte komplexer Datenstrukturen

=head2 B<1. Kurzbeschreibung>

Iterator.pm ist ein objektorientiertes (reines) Perl-Modul zum Durchlaufen von komplexen Datenstrukturen (LoL, LoH, HoL, HoH usf.).
Während die eingebauten Perl-Funktionen
foreach(), each(), keys() und values() nur eine Ebene einer Struktur bearbeiten können,
gräbt Iterator in die Tiefe - und betrachtet eine Struktur quasi als eindimensionalen Hash.

Zu jedem Element einer verschachtelten Struktur werden sukzessive der symbolische Name ("Datenpfad"),
der - nicht modifizierte! - Wert sowie einige Zusatzinformationen geliefert.

Damit stellt Iterator eine einheitliche Syntax zur Abarbeitung von Datenquellen unterschiedlichen Typs bereit.

Iterator modifiziert die übergebene Datenstruktur nicht. Allerdings kann der Benutzer Werte explizit via Iterator ändern.

Iterator exportiert keine Variablen oder Funktionen. Zwar lassen sich bekanntlich alle Paket-subs auch via
&Paketname::subname () aufrufen, sinnvolle Ergebnisse darf man dann aber nicht zwingend erwarten :-)

Ausnahmen gibts aber auch hier:

=over 2

=item B<Data::Iterator::cfg()>

womit sich (auch) modulweite Voreinstellungen lesen/setzen lassen.

=item B<$Data::Iterator::VERSION>

die Versionsnummer des Moduls.

=back

=head2 B<2. Abhängigkeiten>

Iterator benötigt die Module Carp und FileHandle (Bestandteile der Standarddistributionen).

=head2 B<3. Verwendung>

=begin text

    #!perl -w

	# adopt perl's path to your environment (if not on Windows)		
	
	use strict;
	use Data::Iterator;                 # assuming you put it into	
	                                    # your [/site]/lib/Data-	
	                                    # directory					

	# Create a datastructure, e.g a hash:
    my %data  = (a => 1,
                 b => [ qw(b0 b1 b2) ],
                 c => {c1 => sub {warn "No parms!" unless @_;
                                  return qw(first second third)
                                 },
                       c2 => undef,
                       c3 => 'val_of_c3'
                      }
                );

    ## Create an Iterator-object:
    my $dobj = new Data::Iterator (\%data)
         || die "Oops. Creation of Iterator-object failed: $!";

    ## Now let's get all the names + values...
    while (my ($path, $val) = $dobj->element) {
      print "all data: path: $path, value: $val\n";
      # or whatever is to be done with $path, $val :-)
    }
    # ...and prepare for a new loop, if necessary:
    $dobj->reset;
    # ...

    ## Lookup data in $data{'c'}...
    while (my ($path, $val) = $dobj->element('{c}*')) { # note the asterisk!
      print "just {c}: path: $path, value: $val\n";
      # or whatever is to be done with $path, $val :-)
    }
    # ...and prepare for a new loop, if necessary:
    $dobj->reset('{c}');
    # ...

    ## Just retrieve a single value...
    my $distinct_val   = $dobj->element ('{b}[1]');

    ## ...or set a value (autovivificates data element, if necessary)
    my $old_val_of_b_1 = $dobj->element ('{b}[1]', 'A New Value!');
    my $new_val_of_b_1 = $dobj->element ('{b}[1]');

	print "\nThe value of b.1:      $distinct_val\n",
	      "is returned on change: $old_val_of_b_1\n",
	      "b.1 is now:            $new_val_of_b_1\n";
	      
	# Now let's get all the keys:
	print "\n- Keys:   \n", join "\n", $dobj->keys;
	
	# ...and the values:
	print "\n\n- Values: \n", join "\n", $dobj->values;

    ## Lookup a file's content...
    my $fobj = new Data::Iterator ('-FILE:path/to/file.ext')
         || die "Oops. Creation of Iterator-object failed: $!";
	print "\n\n- Listing a file:\n";
    while (my ($path, $val) = $fobj->element) {
      print "path: $path, value: $val\n";
      # or whatever is to be done with $path, $val :-)
    }

    ## ...OR:
    open (FH, '< path/to/file.ext')
         || die "Oops. Could not open file: $!";
    $fobj = new Data::Iterator (\*FH)
         || die "Oops. Creation of Iterator-object failed: $!";
    # ...

=end text

=head2 B<4. Methoden>

=over 2

=item B<new()>

Liefert ein neues Iterator-Datenobjekt als blessed reference auf einen Hash; undef, falls keine Referenz auf die übergebene Quell-Datenstruktur gebildet werden konnte.

Parameter (Referenz auf die darzustellende Datenstruktur):

 (1) \%hash
 (2) \@array
 (3) \&code
 (4) \*glob
 (5) \$scalar   (nicht sehr struktural...)
 (6) '-FILE:Path/to/file.ext'
 (7) $scalar    (ditto nicht sehr struktural...)

Rückgabe:

 - Scalar: Gesegnetet Referenz auf Iterator-Objekt, oder
 - undef:  bei Mißerfolg (Objekt konnte wg. unbekannten Referenztyps nicht erstellt werden)



=item B<cfg()>

Setzt/liest je nach Aufruf die Konfiguration des respektiven Iterator-Objektes (Aufruf als I<Objektmethode>) oder die modulweite Konfiguration (Aufruf als I<Klassenmethode> Data::Iterator->cfg()). Benannte Einstellungen werden in der Reihenfolge der Übergabe in einem I<Array> zurückgegeben.

Welche Werte gesetzt und/oder gelesen werden, entscheidet sich anhand der übergebenen Parameter:

- Wird der Name einer Einstellung gegeben, gefolgt von einem Wert (== Nicht-Einstellungsname), wird diese Einstellung auf den gegebenen Wert gesetzt. Der alte Wert wird zurückgeliefert:

 my @object_opts = $dobj->cfg    (-opt1 => 'val1', -opt2 => 'val2', ...);
 my @global_opts = Data::Iterator->cfg (-opt1 => 'val1', -opt2 => 'val2', ...);

 setzt -opt1 und -opt2 auf 'val1' bzw. 'val2' und liefert:

 (old_val_of_opt1, old_val_of_opt2, ...)

- Wird nur der Einstellungsname gegeben, liefert cfg() den zugehörigen Wert:

 my @object_opts = $dobj->cfg    ('-opt2', '-opt1', ...);
 my @global_opts = Data::Iterator->cfg ('-opt2', '-opt1', ...);

 liefert:

 (val_of_opt2, val_of_opt1, ...)

- Setzen und Lesen können bei der Parameterübergabe beliebig kombiniert werden:

 my @object_opts = $dobj->cfg    (-opt3, -opt1 => 'new!', -opt2);
 my @global_opts = Data::Iterator->cfg (-opt3, -opt1 => 'new!', -opt2);

 liefert:

 (val_of_opt3, old_val_of_opt1, val_of_-opt2 )

- Wird kein Parameter gegeben, liefert cfg() alle Einstellungen in einem I<Hash> zurück:

 my %object_opts = $dobj->cfg;
 my %global_opts = Data::Iterator->cfg;

Zu den Einstellungen siehe Abschnitt B<5. Optionen>.


=item B<element()>

Liefert im Arraykontext Informationen über Elemente der an new() übergebenen Datenstruktur, eine leere Liste, wenn keine weiteren Elemente vorhanden sind.

Liefert im Scalarkontext 1, wenn ein Element gefunden wurde, undef, falls Strukturende erreicht.

element() erzeugt I<keine Liste> und I<keine Kopie> der übergebenen Daten, sondern grast die Struktur elementweise ab und liefert im Listenkontext eine Liste (sic!) mit diversen Informationen über das jeweilige Element - weshalb bspw. eine while()-Schleife hervorragend geeignet ist, den kompletten Baum zu durchforsten.

In einem foreach-Loop hingegen liefert element() nicht zwingend die gewünschten Resultate... (foreach() arbeitet eine Liste ab und stellt selber den Listenkontext her)

 my ($p, $v, $k, $l, $r, $pp, $p) = $obj->element;

wobei:

 [0] $p:  "Datenpfad", ein String im Format {'key'}|[index]{'key'}|[index] usw.
 [1] $v:  Der Wert
 [2] $k:  der Schlüssel/Index des aktuellen Elements
 [3] $l:  Ebene ("level") des aktuellen Elements in der Hierarchie
 [4] $r:  Referenz auf das aktuelle Element
 [5] $pp: "Elternpfad", Name des nächsthöheren Datenelements (Array, Hash usf.)
          Elternpfad.({Schlüssel}|{Index]) ergibt den Datenpfad [0].
 [6] $p:  Elter des aktuellen Elements

Zur sukzessiven Listung einer Datenstruktur verwende man bspw. folgenden Code:

 while (my @elm = $dobj->element) {
   print join ('|', @elm),"\n";
 }

oder:

 while ($dobj->element) {
   print $dobj->{path}.' = '.$dobj->{val}.', at '.$dobj->{vref}."\n";
 }

Soll eine Unterstruktur dargestellt werden, gebe man element() eine Pfadangabe (einen String) mit:

 while (my @elm = $dobj->element('{c}*')) {
   print join ('|', @elm),"\n";
 }

Soll ein einzelner Wert zu einem Datenpfad geliefert werden, spart man sich das Sternchen:

 print join ('|', $dobj->element ('{c}')),"\n";

Tritt ein Fehler auf, findet sich eine entsprechende Meldung in

 $dobj->{'err'}

Nützlich, wenn warn()-ungen abgeschaltet wurden.

Via element() können Werte gesetzt werden. Dazu akzeptiert die Methode einen zweiten Parameter, und liefert den alten Wert:

 print $dobj->element ('{c}{c3}', 'a new value!');
 # druckt 'val_of_c3'
 print ($dobj->element ('{c}{c3}'))[1];
 # druckt 'a new value!'

=item B<reset()>

Setzt den internen Stack von element() zurück, d.h. nach einem unvollständigen Durchlauf beginnt element() wieder am Anfang der initialen Datenstruktur. Nützlich, wenn eine while($dobj->element()){...}-Schleife vorzeitig verlassen wurde.

reset() arbeitet selektiv. Wird ein Datenpfad übergeben, wird der Stack für die der entsprechende Unterstruktur zurückgesetzt.


=item B<keys()>

Liefert einen Array mit den Datenpfaden des Objektes, über den sich bspw. mit foreach() iterieren läßt:

 my @keys   = $dobj->keys;
 my @c_keys = $dobj->keys('{c}');

keys() kann ein initialer Datenpfad mitgegeben werden. keys() liefert dann die Datenpfade des Elementes, das an [Datenpfad] gefunden wurde. Ein gegebenfalls angehängtes Sternchen wird ignoriert.


=item B<values()>

Liefert einen Array mit den Werten des Objektes, über den sich bspw. mit foreach() iterieren läßt:

 my @vals   = $dobj->values;
 my @c_vals = $dobj->values('{c}');

Auch dieser Methode kann ein initialer Datenpfad mitgegeben werden. values() liefert dann die Werte des Elementes, das an [Datenpfad] gefunden wurde. Ein gegebenfalls angehängtes Sternchen wird ignoriert.


=back

=head2 B<5. Optionen>

Iterator kennt drei Gruppen von Einstellungen, die verschiedene Bereiche beeinflussen:

=over 2

=item (1) die Darstellung:

"-Nodes"
Werte: 0|1

Schaltet die Darstellung von Knoten (Elementen, die eine Referenz bspw. auf einen Hash oder Array enthalten) ein (1) bzw. aus (0). Default ist 0.

"-DigLevel"
Werte: undef|Integer

Gibt an, ob alle Ebenen der Datenstruktur dargestellt werden (undef) oder nur Elemente bis zur (inklusive) Ebene n. Default ist undef.

=item (2) die Auflösung des als Datenobjekt übergebenen Wertes bei new():

"-SRefs"
Werte: 0|1

Gibt an, ob eine initiale Skalarreferenz bei Initialisierung bis zu ersten Nicht-Skalarreferenz aufgelöst werden soll (1) oder nicht (0). Default ist 1.

Wird hier 0 gegeben, liefert element() lediglich das Argument zurück. Es sei denn, "-DigSRefs" ist auf 1 gesetzt.

"-Files"
Werte: 0|1

Gibt an, ob ein Argument im "-File:..."-Format bei Initialisierung die angegebene Datei öffnen soll (1) oder nicht (0). Default ist 1.

Wird hier 0 gegeben, liefern element() und values() lediglich das Argument zurück. Es sei denn, "-DigFiles" ist auf 1 gesetzt.


"-Code"
Werte: 0|1

Gibt an, ob ein Coderef-Argument bei Initialisierung ausgeführt wird (1) oder nicht (0). Default ist 1.

Wird hier 0 gegeben, liefern element() und values() lediglich das Argument zurück. Es sei denn, "-DigCode" ist auf 1 gesetzt.


=item (3) die Auflösung von in der Datenstruktur enthaltenen Referenzen bei element(), keys(), values():

"-DigSRefs"
Werte: 0|1

Gibt an, ob Skalarreferenzen aufgelöst werden (1) oder nicht (0). Default ist 1.

Merke: Verkettete Skalarreferenzen werden vollständig aufgelöst.

"-DigFiles"
Werte: 0|1

Schaltet die Auflösung von "-File:..."-Elementen (i.e. Öffnen und sukzessives einlesen der Datei) ein (1) bzw. aus (0). Default ist 1.

"-DigCode"
Werte: 0|1

Schaltet die Ausführung von Codereferenzen ein (1) bzw. aus (0). Default ist 1.

"-DigGlobs"
Werte: 0|1

Schaltet die Verfolgung von Globreferenzen (i.e. Lesen vom referenzierten Handle) ein (1) bzw. aus (0). Default ist 1.

=back


=head2 B<6. Feinheiten>

=over 2

=item Datentypen

Folgende Datentypen kann Iterator handhaben:

- Skalare: werden mit ihrem Inhalt dargestellt

- Referenzen: werden aufgelöst. Erkannt werden die Perl-üblichen Typen (Scalar, Array, Hash, Code, Glob). Die unspezifische REF-Referenz wird als einfacher Skalar behandelt.

Neben diesen Typen erkennt Iterator ein FileHandle-Objekt, und liest die damit bezogene Datei.

- Weiters kennt Iterator den Verweis auf eine Datei. Dieser wird als String gegeben, und muß im Format

"-File:Pfad/dateiname"

vorliegen. Kann die angegebene Datei nicht zum Lesen geöffnet werden, wird ge-warn()-t.


=item Zirkuläre Referenzen

Referenzen, die auf einen Elter des aktuellen Datenelementes verweisen, werden nicht aufgelöst. Sie erzeugen einen nicht-tödlichen Fehler nebst Meldung. Der Wert des Elementes wird als undef geliefert.

Dies gilt auch für via "-File:..." bezogene Dateien, die einen Verweis auf sich selbst enthalten.

Wird ein Datenpfad gegeben, kann das bezogene Datenelement getrost auf einen Elter verweisen - es wird gleichwohl aufgelöst.

=item element()

- Verhalten

Wird eine Struktur via element() komplett durchlaufen, fängt element() in einer späteren Schleife von vorne an.

Wird der Durchlauf abgebrochen, machen spätere element()-Aufrufe da weiter, wo zuvor abgebrochen wurde.

Ist dies nicht gewünscht, sollte zwischenzeitlich reset() aufgerufen werden. Dies setzt element() auf das erste Element zurück.

Diese Verhalten gilt auch für die Abarbeitung von Teilstrukturen, reset() ist dann der entsprechende Datenpfad zu übergeben.

Merke: element()-Aufrufe mit unterschiedlichen Datenpfaden beeinflussen sich wechselseitig I<nicht>.

Gleiches gilt für keys()- bzw. values()-Aufrufe. Diese interferieren in keinem Fall mit element()-Aufrufen.

element() dotiert folgende Datenfelder seines Objektes:

@{$dobj}{'path','val','key','level','vref','ppath','parent','err'}

Objekttheoretisch zwar nicht ganz sauber, kann damit stets auf die letzten Ergebnisse eines element()-Aufrufes zugegriffen werden. Dies gilt I<nicht>, wenn via element() ein Wert gesetzt wurde.

- Dateien

Via "-File:...", \*Glob bzw. FileHandle-Objekt bezogene Dateien/Handles können mit element() nicht beschrieben werden. Siehe dazu Stichwort "Pseudoarrays".

- Autovivification:

Wird element() ein Datenpfad übergeben, dessen letzter Schlüssel/Index auf ein Element mit einem inexistenten Elter verweist, wird erfolgt keine Wunderzeugung des Elters. Dies im Unterschied zum Standardlookup in Perl.

Wird hingegen via element() ein Wert I<gesetzt>, werden bei Bedarf alle nicht vorhandenen Vorfahren gezeugt.

=item Ebenen

Die jeweils gelieferte Ebene eines Datenelementes gibt die Schachtelungstiefe an, gerechnet von der aktuellen Wurzel. Die Zählung beginnt mit 0.

Will sagen, die Ebene 0 der Stammstruktur ist nicht identisch mit der Ebene 0 einer Teilstruktur, die ihrerseits auf einer beliebigen Ebene der Stammstruktur angesiedelt sein kann.

Entsprechend begrenzt die Einstellung -DigLevel die Datendarstellung stets auf n Ebenen von der aktuellen Wurzel an gerechnet, gleich ob gerade die Stammstruktur (Datenpfad = '' oder undef) oder eine Teilstruktur dargestellt wird.

=back


=over 2

=item Datenpfade, Format

element(), keys() und values() sind recht tolerant hinsichtlich der Schreibweise der ggf. übergebenen Pfade zu den Daten.

Die Standardnotation entspricht der Perl-mäßigen Indizierung von Hashes/Arrays:

 my $path = "{'key1'}{'key2'}[2][1]";

Wem das zu umständlich ist, kann zur verkürzten Notation greifen:

 my $path = 'key1.key2.2.1';

Soll ein klammerloser Pfad richtig aufgelöst werden, müssen Hashschlüssel mindestens ein nicht-numerisches Zeichen enthalten. Sonst werden sie für Arrayindices gehalten - und generieren einen nicht-fatalen Fehler nebst Meldung.

Weiters kann ein beliebiger Trenner definiert werden - nützlich, wenn der "." in bezogenen Hashschlüsseln vorkommt:

 my $path = "#key1#key2#2#1";

Merke:

- Ist das erste Zeichen im Pfad nicht-alphanumerisch, wird dieses als Trenner behandelt.
  Ausnahmen: [ und {

- Ist das erste Zeichen alphanumerisch, wird der . als Trenner angenommen.

- klammerlose und klammerhaltige Schreibweise dürfen gemischt werden: "#key1{key2}[2]#[1]"

- vor dem Backslash \ als Trenner sollte man sich hüten.

- Das quoten von Hashschlüsseln ist nicht zwingend erforderlich.

=item Behandlung von Coderefs

Coderefs werden derart aufgelöst, daß der referenzierte Code ausgeführt wird. Dies geschieht bereits bei der Initialisierung des ensprechenden Datenelementes.

Vor der Ausführung werden $SIG{__WARN__} und $SIG{__DIE__} lokal auf eine eigene Routine verbogen, Fehler im referenzierten Code führen also nicht zum Tod des aktuellen Skriptes.

Die Ausgabe von im Code ausgelöstem warn bzw. die wird abgefangen und gespeichert.

Die Rückgabewerte des Codes werden in einem Pseudoarray gespeichert und von element() bzw. values() geliefert.

Findet sich im ersten Element des Ergebnisarray ein Array namens '_ERR_', hat der referenzierte Code ge-warn()t oder ge-carp()t oder ist mit die() bzw. croak() abgestorben. Wenn nicht, dann mutmaßlich nicht. Warnungen bzw. Tode können anhand der Präfixe 'WARN : ' bzw. 'FATAL: ' unterschieden werden.

=item Pseudoarrays

Werden "-FILE:..."- oder Coderef-Elemente aufgelöst, finden sich die Ergebnisse in einem Pseudoarray.

Pseudo deshalb, diese Arrays nicht als solche existieren. Entsprechend kann auf deren Elemente nicht unmittelbar - etwa über einen entsprechenden Datenpfad - zugegriffen werden.
Dies deshalb, weil Iterator die ursprüngliche Datenstruktur nicht modifizieren mag und deshalb keinen Handle/Datenpfad kennt bzw. generiert, der einen "normalen" Zugriff erlauben würde.

=back


=head2 B<7. Version>

=over 2

=item

0.021 vom 30.12.2000 (Bugfix-Release)

 - Iteration funktioniert nun auch bei einem Array-Datenobjekt,
   wenn Datenpfad gegeben
 - Einige lästige "Use of uninitialized value..."-Meldungen
   sind nun gegenstandslos
 - Beispielcode in der Dokumentation korrigiert

=item

0.02  vom 10.12.2000 (Erstveröffentlichung)

=back

=head2 B<8. Autor>

 Hartmut Camphausen <h.camp@creagen.de>
 Internet: http://www.creagen.de/


=head2 B<9.Copyright>

Copyright (c) 2000 by CREAGEN Computerkram Hartmut Camphausen <h.camp@creagen.de>. Alle Rechte vorbehalten.

Dieses Modul ist freie Software. Es kann zu den gleichen Bedingungen genutzt, verändert und weitergegeben werden wie Perl selbst.

=cut