## -------------- Effects registry ---------------

package Audio::Nama;
use v5.36;
use Audio::Nama::Util qw(round);
no warnings 'uninitialized';

## register data about LADSPA plugins, and Ecasound effects and
#  presets (names, ids, parameters, hints) 

sub prepare_static_effects_data{
	my $source = shift; 
	
	logsub((caller(0))[3]);

	if (not is_test_script() ){
		logpkg(__FILE__,__LINE__,'debug', join "\n", "newplugins:", new_plugins());
		if (! $source and ($config->{opts}->{r} or new_plugins())){ 

			rename $file->effects_cache, $file->effects_cache . ".bak";
			print "Regenerating effects data cache\n";
		}
	}

	# maybe $source
	
	if ($config->{opts}->{T} )
	{
		logpkg(__FILE__,__LINE__,'debug', "using dummy effects data");
		$source = $fx_cache->{fake};
	}
	elsif (-f $file->effects_cache and ! $config->{opts}->{C})
	{  
		logpkg(__FILE__,__LINE__,'debug', "found effects cache: ",$file->effects_cache);
		$source = read_file($file->effects_cache); # scalar assign
	} 
	if ($source)
	{
		assign(
			data => decode($source, 'json'),
			vars => [qw($fx_cache)],
			class => 'Audio::Nama'
		);
	}
	else 
	{
		logpkg(__FILE__,__LINE__,'debug', "reading in effects data, please wait...");
		initialize_effect_index();
		read_in_effects_data();  
		# cop-register, preset-register, ctrl-register, ladspa-register
		get_ladspa_hints();     
		get_lv2_hints() unless $config->{opts}->{J};
		integrate_ladspa_hints();
		integrate_cop_hints();
		sort_ladspa_effects();
		logpkg(__FILE__,__LINE__,'debug', "updating effects cache on disk: ",$file->effects_cache);
		serialize (
			file => $file->effects_cache, 
			vars => [qw($fx_cache)],
			class => 'Audio::Nama',
			format => 'json') unless is_test_script();
				
	}
	generate_mappings_for_shortcuts();
}

sub ladspa_plugin_list {
	my @plugins;
	my %seen;
	for my $dir ( split ':', ladspa_path()){
		next unless -d $dir;
		opendir(my $dirh, $dir)
			or die "can't open directory $dir for read: $!";
		push @plugins,  
			map{"$dir/$_"} 						# full path
			grep{ ! $seen{$_} and ++$seen{$_}}  # skip seen plugins
			grep{ /\.so$/} readdir $dirh;			# get .so files
		closedir $dirh;
	}
	@plugins
}
sub lv2_plugin_list {
	my @plugins;
	my %seen;
	for my $dir ( split ':', lv2_path()){
		next unless -d $dir;
		opendir(my $dirh, $dir)
			or die "can't open directory $dir for read: $!";
		push @plugins,  
			map{"$dir/$_"} 						# full path
			grep{ ! $seen{$_} and ++$seen{$_}}  # skip seen plugins
			grep{ /\.lv2$/} readdir $dirh;			# get .lv2 files
		closedir $dirh;
	}
	@plugins
}

sub new_plugins {
	my @filenames = ladspa_plugin_list();	
	push @filenames, lv2_plugin_list();
	push @filenames, '/usr/local/share/ecasound/effect_presets',
                 '/usr/share/ecasound/effect_presets',
                 "$ENV{HOME}/.ecasound/effect_presets";
	my $effects_cache_stamp = modified_stamp($file->effects_cache);
	my $latest;
	map{ my $mod = modified_stamp($_);
		 $latest = $mod if $mod > $latest } @filenames;

	$latest > $effects_cache_stamp;
}

sub modified_stamp {
	# timestamp that file was modified
	my $filename = shift;
	#print "file: $filename\n";
	my @s = stat $filename;
	$s[9];
}
sub initialize_effect_index {
	$fx_cache->{partial_label_to_full} = {};
}
sub generate_mappings_for_shortcuts {
	logsub((caller(0))[3]);
	map{ 
		my $code = $_;
 		
		# abbrevations for lv2: lv2-foo for elv2:http://something.com/other/foo
		if ( my ($suffix) = $code =~ /(?:elv2:).*?([^\/]+)$/ )
		{
			$fx_cache->{partial_label_to_full}->{"lv2-$suffix"} = $code;
		}
		else {
		my ($short) = $code =~ /:([-\w]+)/;
		if ( $short ) { 
			if ($fx_cache->{partial_label_to_full}->{$short}) { warn "name collision: $_\n" }
			else { $fx_cache->{partial_label_to_full}->{$short} = $code }
		}
		}
		$fx_cache->{partial_label_to_full}->{$code} = $code;
	} keys %{$fx_cache->{full_label_to_index}};
	#print json_out $fx_cache->{partial_label_to_full};
}
{ my %dispatch =
		(
			ctrl 	=> \&generate_help,
			lv2	 	=> \&generate_lv2_help,
			ladspa 	=> \&generate_ladspa_help,
			cop		=> \&generate_help,
			preset	=> \&generate_help,
		);
		
sub extract_effects_data {
	logsub((caller(0))[3]);
	my ($plugin_type, $lower, $upper, $regex, $separator, @lines) = @_;
	carp ("incorrect number of lines ", join ' ',$upper-$lower,scalar @lines)
		if $lower + @lines - 1 != $upper;
	logpkg(__FILE__,__LINE__,'debug',"lower: $lower upper: $upper  separator: $separator");
	logpkg(__FILE__,__LINE__,'debug', "lines: ". join "\n",@lines);
	logpkg(__FILE__,__LINE__,'debug', "regex: $regex");
	my $j = $lower - 1;
	while(my $line = shift @lines){
		$j++;
		$line =~ /$regex/ or 
		carp("bad effect data line: $line\n", 
			join " ", map{ ord($_) } split //, $line), next;
		my ($no, $name, $id, $rest) = ($1, $2, $3, $4);
		# $no is unimportant; it from the list numbering
		logpkg(__FILE__,__LINE__,'debug', "Number: $no Name: $name Code: $id Rest: $rest");
		my @p_names = split $separator,$rest; 
		map{s/'//g}@p_names; # remove leading and trailing q(') in ladspa strings
		logpkg(__FILE__,__LINE__,'debug', "Parameter names: @p_names");
		$fx_cache->{registry}->[$j]={};
		#$fx_cache->{registry}->[$j]->{number} = $no;
		$fx_cache->{registry}->[$j]->{code} = $id;
		$fx_cache->{registry}->[$j]->{name} = $name;
		$fx_cache->{registry}->[$j]->{count} = scalar @p_names;
		$fx_cache->{registry}->[$j]->{params} = [];
		$fx_cache->{registry}->[$j]->{display} = qq(field);
		$fx_cache->{registry}->[$j]->{plugin_type} = $plugin_type;
		$fx_cache->{user_help}->[$j] = $dispatch{$plugin_type}->($line);
		map{ push @{$fx_cache->{registry}->[$j]->{params}}, {name => $_} } @p_names
			if @p_names;
	}

}
}
sub sort_ladspa_effects {
	logsub((caller(0))[3]);
#	print json_out($fx_cache->{split}); 
	my $aa = $fx_cache->{split}->{ladspa}{a};
	my $zz = $fx_cache->{split}->{ladspa}{z};
#	print "start: $aa end $zz\n";
	map{push @{$fx_cache->{ladspa_sorted}}, 0} ( 1 .. $aa ); # fills array slice [0..$aa-1]
	splice @{$fx_cache->{ladspa_sorted}}, $aa, 0,
		 sort { $fx_cache->{registry}->[$a]->{name} cmp $fx_cache->{registry}->[$b]->{name} } ($aa .. $zz) ;
	logpkg(__FILE__,__LINE__,'debug', "sorted array length: ". scalar @{$fx_cache->{ladspa_sorted}});
}		
sub run_external_ecasound_cmd {
	my $cmd = shift;
	my $output = qx(sh -c 'echo $cmd | ecasound -c '); 
	trim_output($output)
}
sub trim_output {
	my $output = shift;
	$output =~ s/\n\.{3} //g;
	$output =~ s/\r//;
	$output =~ s/^.+?Registered \w+ plugins:\s*//s; # XXX HARDCODED for plugins only
	$output =~ s/^ecasound .+?\Z//ms;
	my @output = split "\n",$output;
	#splice @output, 0,8;
	#splice @output, -3,3;
	join "\n",@output;
}
sub read_in_effects_data {
	
	logsub((caller(0))[3]);


	#### LADSPA

	my $lr = run_external_ecasound_cmd('ladspa-register') ;

	logpkg(__FILE__,__LINE__,'debug',"ladpsa-register output:\n",$lr);

	my @ladspa =  split "\n", $lr;
	
	# join the two lines of each entry
	my @lad = map { join " ", splice(@ladspa,0,2) } 1..@ladspa/2; 
	#logpkg(__FILE__,__LINE__,'debug',join "\n","ladpsa-register processed output:",@lad);
	generate_ladspa_help($_) for @lad;

	#### LV2

	my $lv2 = run_external_ecasound_cmd('lv2-register') ;
										# TODO test fake lv2-register
										# get_data_section('fake_lv2_register');
	logpkg(__FILE__,__LINE__,'debug',"lv2-register output:\n",$lv2);

	# join pairs of lines
	$lv2 =~ s/\s+(?=-elv2)/ /g;

	# now we can handle similar to LADSPA	
	
	# split on newlines
	my @lv2 = split /\n/,$lv2;
	generate_lv2_help($_) for @lv2;

#	logpkg(__FILE__,__LINE__,'debug',sub{ json_out(\@lv2) });

	logpkg(__FILE__,__LINE__,'trace',sub{ json_out(\@lv2) });

	my $preset = ecasound_iam("preset-register");
	my @preset = grep {! /^\s*$/ } split "\n", $preset;
	generate_help($_) for @preset;
	logpkg(__FILE__,__LINE__,'debug',"preset-register output:\n",$preset);

	my $ctrl = 	ecasound_iam("ctrl-register");
	my @ctrl  = grep {! /^\s*$/ } split "\n", $ctrl;
	logpkg(__FILE__,__LINE__,'debug',"ctrl-register output:\n",$ctrl);
	generate_help($_) for @ctrl;

	my $cop = ecasound_iam("cop-register");
	my @cop = grep {! /^\s*$/ } split "\n", $cop;
	generate_help($_) for @cop;

	logpkg(__FILE__,__LINE__,'debug',"cop-register output:\n",$cop);

	logpkg(__FILE__,__LINE__,'debug', "found ", scalar @cop, " Ecasound chain operators");
	logpkg(__FILE__,__LINE__,'debug', "found ", scalar @preset, " Ecasound presets");
	logpkg(__FILE__,__LINE__,'debug', "found ", scalar @ctrl, " Ecasound controllers");
	logpkg(__FILE__,__LINE__,'debug', "found ", scalar @lad, " LADSPA effects");
	logpkg(__FILE__,__LINE__,'debug', "found ", scalar @lv2, " LV2 effects");

	# index boundaries we need to make effects list and menus
	$fx_cache->{split}->{cop}{a}   = 1;
	$fx_cache->{split}->{cop}{z}   = @cop; # scalar
	$fx_cache->{split}->{ladspa}{a} = $fx_cache->{split}->{cop}{z} + 1;
	$fx_cache->{split}->{ladspa}{b} = $fx_cache->{split}->{cop}{z} + int(@lad/4);
	$fx_cache->{split}->{ladspa}{c} = $fx_cache->{split}->{cop}{z} + 2*int(@lad/4);
	$fx_cache->{split}->{ladspa}{d} = $fx_cache->{split}->{cop}{z} + 3*int(@lad/4);
	$fx_cache->{split}->{ladspa}{z} = $fx_cache->{split}->{cop}{z} + @lad;
	$fx_cache->{split}->{preset}{a} = $fx_cache->{split}->{ladspa}{z} + 1;
	$fx_cache->{split}->{preset}{b} = $fx_cache->{split}->{ladspa}{z} + int(@preset/2);
	$fx_cache->{split}->{preset}{z} = $fx_cache->{split}->{ladspa}{z} + @preset;
	$fx_cache->{split}->{ctrl}{a}   = $fx_cache->{split}->{preset}{z} + 1;
	$fx_cache->{split}->{ctrl}{z}   = $fx_cache->{split}->{preset}{z} + @ctrl;
	$fx_cache->{split}->{lv2}{a}   = $fx_cache->{split}->{ctrl}{z} + 1;
	$fx_cache->{split}->{lv2}{z}   = $fx_cache->{split}->{ctrl}{z} + @lv2;

	my $cop_re = qr/
		^(\d+) # number
		\.    # dot
		\s+   # spaces+
		(\w.+?) # name, starting with word-char,  non-greedy
		# (\w+) # name
		,\s*  # comma spaces* 
		-(\w+)    # effect_id 
		:?     # maybe colon (if parameters)
		(.*$)  # rest
	/x;

	my $preset_re = qr/
		^(\d+) # number
		\.    # dot
		\s+   # spaces+
		 (\w+) # name
		,\s*  # comma spaces* 
		-(pn:\w+)    # preset_id 
		:?     # maybe colon (if parameters)
		(.*$)  # rest
	/x;

	my $ladspa_re = qr/
		^(\d+) # number
		\.    # dot
		\s+  # spaces
		(.+?) # name,  any non-greedy
		\s+     # spaces
		-(el:[-\w]+),? # ladspa_id maybe followed by comma
		(.*$)        # rest
	/x;
	my $lv2_re = qr/
		^(\d+) # number
		\.    # dot
		\s+  # spaces
		(.+?) # name,  any non-greedy
		\s+     # space

		-(?<name> # named captured named 'name'
		elv2:     # prefix is -elv2:
		[^,]+        # URL: non-comma chars 
		), 			# comma
		(.*$)        # rest
	/x;

	my $ctrl_re = qr/
		^(\d+) # number
		\.     # dot
		\s+    # spaces
		(\w.+?) # name, starting with word-char,  non-greedy
		,\s*    # comma, zero or more spaces
		-(k\w+):?    # ktrl_id maybe followed by colon
		(.*$)        # rest
	/x;

	extract_effects_data(
		'cop',
		$fx_cache->{split}->{cop}{a},
		$fx_cache->{split}->{cop}{z},
		$cop_re,
		q(,),
		@cop,
	);
	extract_effects_data(
		'ladspa',
		$fx_cache->{split}->{ladspa}{a},
		$fx_cache->{split}->{ladspa}{z},
		$ladspa_re,
		q(','),
		@lad,
	);
	extract_effects_data(
		'lv2',
		$fx_cache->{split}->{lv2}{a},
		$fx_cache->{split}->{lv2}{z},
		$lv2_re,
		q(','),
		@lv2,
	);

	extract_effects_data(
		'preset',
		$fx_cache->{split}->{preset}{a},
		$fx_cache->{split}->{preset}{z},
		$preset_re,
		q(,),
		@preset,
	);
	extract_effects_data(
		'ctrl',
		$fx_cache->{split}->{ctrl}{a},
		$fx_cache->{split}->{ctrl}{z},
		$ctrl_re,
		q(,),
		@ctrl,
	);



	for my $i (0..$#{$fx_cache->{registry}}){
		 $fx_cache->{full_label_to_index}->{ $fx_cache->{registry}->[$i]->{code} } = $i; 
		 logpkg(__FILE__,__LINE__,'debug', "i: $i code: $fx_cache->{registry}->[$i]->{code} display: $fx_cache->{registry}->[$i]->{display}");
	}

	logpkg(__FILE__,__LINE__,'debug', sub{"$fx_cache->{registry}\n======\n", json_out($fx_cache->{registry})}); ; 
}

sub integrate_cop_hints {

	my @cop_hints =  @{ yaml_in( get_data_section('ecasound_chain_operator_hints_yml')) };
	for my $hashref ( @cop_hints ){
		#print "cop hints ref type is: ",ref $hashref, $/;
		my $code = $hashref->{code};
		$fx_cache->{registry}->[ $fx_cache->{full_label_to_index}->{ $code } ] = $hashref;
	}
}
sub ladspa_path {
	$ENV{LADSPA_PATH} || q(/usr/lib/ladspa);
}
sub lv2_path {
	$ENV{LV2_PATH} || q(/usr/lib/lv2);
}
sub get_ladspa_hints{
	logsub((caller(0))[3]);
	my @dirs =  split ':', ladspa_path();
	my $data = '';
	my %seen = ();
	my @plugins = ladspa_plugin_list();
	#pager join $/, @plugins;

	# use these regexes to snarf data
	
	my $pluginre = qr/
	Plugin\ Name:       \s+ "([^"]+)" \s+
	Plugin\ Label:      \s+ "([^"]+)" \s+
	Plugin\ Unique\ ID: \s+ (\d+)     \s+
	[^\x00]+(?=Ports) 		# swallow maximum up to Ports
	Ports: \s+ ([^\x00]+) 	# swallow all
	/x;

	my $paramre = qr/
	"([^"]+)"   #  name inside quotes
	\s+
	(.+)        # rest
	/x;
		
	my $i;

	for my $file (@plugins){
		my @stanzas = split "\n\n", qx(analyseplugin $file);
		for my $stanza (@stanzas) {

			my ($plugin_name, $plugin_label, $plugin_unique_id, $ports)
			  = $stanza =~ /$pluginre/ 
				or carp "*** couldn't match plugin stanza $stanza ***";
			logpkg(__FILE__,__LINE__,'debug', "plugin label: $plugin_label $plugin_unique_id");

			my @lines = grep{ /control/ } split "\n",$ports;

			my @params;  # data
			my @names;
			for my $p (@lines) {
				next if $p =~ /^\s*$/;
				$p =~ s/\.{3}/10/ if $p =~ /amplitude|gain/i;
				$p =~ s/\.{3}/60/ if $p =~ /delay|decay/i;
				$p =~ s(\.{3})($config->{sample_rate}/2) if $p =~ /frequency/i;
				$p =~ /$paramre/;
				my ($name, $rest) = ($1, $2);
				my ($dir, $type, $range, $default, $hint) = 
					split /\s*,\s*/ , $rest, 5;
				logpkg(__FILE__,__LINE__,'debug', join( 
				"|",$name, $dir, $type, $range, $default, $hint) ); 
				#  if $hint =~ /logarithmic/;
				if ( $range =~ /toggled/i ){
					$range = q(0 to 1);
					$hint .= q(toggled);
				}
				my %p;
				$p{name} = $name;
				$p{dir} = $dir;
				$p{hint} = $hint;
				my ($beg, $end, $default_val, $resolution) 
					= range($name, $range, $default, $hint, $plugin_label);
				$p{begin} = $beg;
				$p{end} = $end;
				$p{default} = $default_val;
				$p{resolution} = $resolution;
				push @params, { %p };
			}

			$plugin_label = "el:" . $plugin_label;
			$fx_cache->{ladspa_help}->{$plugin_label} = $stanza;
			$fx_cache->{ladspa_id_to_filename}->{$plugin_unique_id} = $file;
			$fx_cache->{ladspa_label_to_unique_id}->{$plugin_label} = $plugin_unique_id; 
			$fx_cache->{ladspa_label_to_unique_id}->{$plugin_name} = $plugin_unique_id; 
			$fx_cache->{ladspa_id_to_label}->{$plugin_unique_id} = $plugin_label;
			$fx_cache->{ladspa}->{$plugin_label}->{name}  = $plugin_name;
			$fx_cache->{ladspa}->{$plugin_label}->{id}    = $plugin_unique_id;
			$fx_cache->{ladspa}->{$plugin_label}->{params} = [ @params ];
			$fx_cache->{ladspa}->{$plugin_label}->{count} = scalar @params;
			$fx_cache->{ladspa}->{$plugin_label}->{display} = 'scale';
		}	#	pager( join "\n======\n", @stanzas);
		#last if ++$i > 10;
	}
		
	for (1..scalar @{ $fx_cache->{user_help}} )
	{
		next if $fx_cache->{registry}->[$_]->{plugin_type} ne 'ladspa';
		my $code = $fx_cache->{registry}->[$_]->{code};
		my $id = $fx_cache->{ladspa_label_to_unique_id}->{$code};
		$fx_cache->{user_help}->[$_] =~ s/^\d+/$id/;
	}
	logpkg(__FILE__,__LINE__,'debug', sub{json_out($fx_cache->{ladspa})});
}

sub get_lv2_hints {
	my @plugins = split " ", qx(lv2ls);
	logpkg(__FILE__,__LINE__,'debug','No LV2 plugins found'), return unless @plugins;
	map { $fx_cache->{lv2_help}->{"elv2:$_"} = join '', Audio::Nama::AnalyseLV2::lv2_help($_) } @plugins;
}

sub srate_val {
	my $input = shift;
	my $val_re = qr/(
			[+-]? 			# optional sign
			\d+				# one or more digits
			(\.\d+)?	 	# optional decimal
			(e[+-]?\d+)?  	# optional exponent
	)/ix;					# case insensitive e/E
	my ($val) = $input =~ /$val_re/; #  or carp "no value found in input: $input\n";
	$val * ( $input =~ /srate/ ? $config->{sample_rate} : 1 )
}
	
sub range {
	my ($name, $range, $default, $hint, $plugin_label) = @_; 
	my $multiplier = 1;;
	my ($beg, $end) = split /\s+to\s+/, $range;
	$beg = 		srate_val( $beg );
	$end = 		srate_val( $end );
	$default = 	srate_val( $default );
	$default = $default || $beg;
	logpkg(__FILE__,__LINE__,'debug', "beg: $beg, end: $end, default: $default");
	if ( $name =~ /gain|amplitude/i ){
		$beg = 0.01 unless $beg;
		$end = 0.01 unless $end;
	}
	my $resolution = ($end - $beg) / 100;
	if    ($hint =~ /integer|toggled/i ) { $resolution = 1; }
	elsif ($hint =~ /logarithmic/ ) {

		$beg = round ( log $beg ) if $beg;
		$end = round ( log $end ) if $end;
		$resolution = ($end - $beg) / 100;
		$default = $default ? round (log $default) : $default;
	}
	
	$resolution = d2( $resolution + 0.002) if $resolution < 1  and $resolution > 0.01;
	$resolution = dn ( $resolution, 3 ) if $resolution < 0.01;
	$resolution = int ($resolution + 0.1) if $resolution > 1 ;
	
	($beg, $end, $default, $resolution)

}
sub integrate_ladspa_hints {
	logsub((caller(0))[3]);
	map{ 
		my $i = $fx_cache->{full_label_to_index}->{$_};
		# print("$_ not found\n"), 
		if ($i) {
			$fx_cache->{registry}->[$i]->{params} = $fx_cache->{ladspa}->{$_}->{params};
			# we revise the number of parameters read in from ladspa-register
			$fx_cache->{registry}->[$i]->{count} = scalar @{$fx_cache->{ladspa}->{$_}->{params}};
			$fx_cache->{registry}->[$i]->{display} = $fx_cache->{ladspa}->{$_}->{display};
		}
	} keys %{$fx_cache->{ladspa}};

my %L;
my %M;

map { $L{$_}++ } keys %{$fx_cache->{ladspa}};
map { $M{$_}++ } grep {/el:/} keys %{$fx_cache->{full_label_to_index}};

for my $k (keys %L) {
	$M{$k} or logpkg(__FILE__,__LINE__,'debug', "$k not found in ecasound listing");
}
for my $k (keys %M) {
	$L{$k} or logpkg(__FILE__,__LINE__,'debug', "$k not found in ladspa listing");
}


logpkg(__FILE__,__LINE__,'debug', sub {join "\n", sort keys %{$fx_cache->{ladspa}}});
logpkg(__FILE__,__LINE__,'debug', '-' x 60);
logpkg(__FILE__,__LINE__,'debug', sub{join "\n", grep {/el:/} sort keys %{$fx_cache->{full_label_to_index}}});

#print json_out $fx_cache->{registry}; exit;

}


sub generate_help {
	my $line = shift;
	$line =~ s/^.*? //; 				# remove initial number
	$line .= "\n";						# add newline
	s/,/, /g;							# to help line breaks
	$line;
}


sub generate_lv2_help {

		my $line = shift;
 		if ($line =~ /elv2:/){

			my $trimmed = $line;
			$trimmed =~ s/^\d+\.\s*//;
			$trimmed =~ s/\t/ /g;
			$trimmed =~ s/'//g;
			$trimmed =~ s/,/, /g;
			$trimmed = "LV2 $trimmed";
			$line = $trimmed;
 		}
		# remove Ecasound registry index No., if present
		$line =~ s/^\d+\.\s*//;
		$line

}
sub generate_ladspa_help {
	my $line = shift;
		my ($label) = $line =~ /-(el:[-\w]+)/;
		$line =~ s/^\s{2,} //g;			 # trim spaces 
		$line =~ s/\t/ /g; 				# convert tabs to spaces
		$line =~ s/'//g;     			 # remove apostrophes
		$line =~ s/,/, /g; 				# for nice linebreaks
		$line =~ s/\s+$/ /;  			 # remove trailing spaces
		$line .="\n";               	 # add newline
}

1;