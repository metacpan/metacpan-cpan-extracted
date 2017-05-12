#!/usr/local/bin/perl
use Cwd;
use Tk;
use Tk::DialogBox;
use Data::Reporter::VisSection;
use Data::Reporter::Datasource;
use strict;
use vars qw ($visrep);

sub resize() {
	$visrep->{VSIZEX} = $visrep->{WSIZEX}->get();
	$visrep->{VSIZEY} = $visrep->{WSIZEY}->get();
	$visrep->{ACTUAL_SEC}->configure(Size	=> $visrep->{WSIZEVAREA}->get(),
									Width	=> $visrep->{VSIZEX});
	$visrep->{TOPWIN}->configure(width	=> $visrep->{VSIZEX},
								height	=>	$visrep->{ACTUAL_SEC}->size()+
											$visrep->{VSIZEC});
	$visrep->{WWORKAREA}->configure(width => $visrep->{VSIZEX});
	#set ruler
	my $cont;
	my $rulertext="";
	for ($cont = 0; $cont < $visrep->{VSIZEX}; $cont++) {
		$rulertext .= $cont % 10;
	}
	$visrep->{WRULER}->configure(state	=> 'normal');
	$visrep->{WRULER}->configure(width => $visrep->{VSIZEX});
	$visrep->{WRULER}->delete(0,'end');
	$visrep->{WRULER}->insert(0.1, $rulertext);
	$visrep->{WRULER}->configure(state => 'disabled');

	update_section();
	update_textarea();
}

sub update_textarea() {
	my $nrows = $visrep->{ACTUAL_SEC}->size();
	my $topwin = $visrep->{TOPWIN};
	my $nactrows = @{$visrep->{AROWS}}+0;
	my $cont;
	my $workarea = $visrep->{WWORKAREA};
	my $only_code = $visrep->{ACTUAL_SEC}->only_code();
	#if nrows > nrowsact, increment rows
	if ($nrows > $nactrows) {
		for ($cont = $nactrows + 1 ; $cont <= $nrows; $cont++) {
			my $row = $workarea->Entry(width 	=> $visrep->{VSIZEX},
									relief  => 'sunken',
									font	=> "fixed")->pack(side	=> 'top');
			push @{$visrep->{AROWS}}, $row;
		}
	} elsif ($nrows < $nactrows) {
		for ($cont = $nactrows; $cont > $nrows; $cont--) {
			my $row = pop @{$visrep->{AROWS}};
			$row->destroy();
		}
	} else {
		for ($cont = 0; $cont < $nrows; $cont++) {
			my $row = $visrep->{AROWS}->[$cont];
			$row->configure(width   => $visrep->{VSIZEX});
		}
	}

	#put information on it
	my @data = $visrep->{ACTUAL_SEC}->lines();
	for ($cont = 0; $cont < $nrows; $cont++) {
		my $row = $visrep->{AROWS}->[$cont];
		$row->delete(0,'end');
		$row->insert(0.1, $data[$cont]);
	}

	#update code area
	$visrep->{WCODEAREA}->delete(0.1, 'end');
	$visrep->{WCODEAREA}->insert(0.1, $visrep->{ACTUAL_SEC}->code());
}

sub update_section() {
	my @lines = ();
	my $nrows = @{$visrep->{AROWS}}+0;
	my $cont;

	for ($cont = 0; $cont < $nrows; $cont++) {
		my $row = $visrep->{AROWS}->[$cont];
		push @lines, $row->get();
	}

	my $code="";
	my $jointext = sub {
		$code .=  @_[1];
	};
	$visrep->{WCODEAREA}->dump(-text, -command => $jointext, 0.1, 'end');

	$visrep->{ACTUAL_SEC}->configure(Lines	=> \@lines,
									Code	=> $code,
								Break_field => $visrep->{WBREAKFIELD}->get());
}

sub update_toolbar() {
	$visrep->{WAREANAME}->configure(text	=> $visrep->{ACTUAL_SEC}->name());
	$visrep->{WSIZEVAREA}->delete(0.1, 'end');
	$visrep->{WSIZEVAREA}->insert(0, $visrep->{ACTUAL_SEC}->size());
	$visrep->{WBREAKFIELD}->configure(state => 'normal');
	$visrep->{WBREAKFIELD}->delete(0.1, 'end');
	my $valor = $visrep->{ACTUAL_SEC}->break_field();
	$visrep->{WBREAKFIELD}->insert(0, $visrep->{ACTUAL_SEC}->break_field());
}

sub load_section($) {
	my $section = shift;
	$visrep->{ACTUAL_SEC} = $section;
	$visrep->{WSIZEVAREA}->configure(state => 'normal');
	$visrep->{WBREAKFIELD}->configure(state => 'normal');
	update_toolbar();
	update_textarea();
	$visrep->{WSIZEVAREA}->configure(state => 'disabled')
		if ($section->{ONLY_CODE});
	$visrep->{WBREAKFIELD}->configure(state => 'disabled')
		unless ($section->{NAME} =~ /^BREAK/);
}

sub create_toolbar() {
	#create array of rows
	my @rows=();
	$visrep->{AROWS} = \@rows;

	my $topwin = $visrep->{TOPWIN};
	my $chars = $topwin->Frame()->pack(side   => 'top',
										fill  => 'x');
	#create dimensions
	$chars->Label(text   		=> 'width',
					relief   	=> 'groove',
					borderwidth	=> 2)->pack(side	=> 'left');
	$visrep->{WSIZEX} =$chars->Entry(relief 	=> 'sunken',
										width	=> 3)->pack(side => 'left');

	$chars->Label(text   		=> 'height',
					relief		=> 'groove',
					borderwidth	=> 2)->pack(side	=> 'left');
	$visrep->{WSIZEY} =$chars->Entry(relief 	=> 'sunken',
										width	=> 3)->pack(side => 'left');

	$visrep->{WSIZEX}->insert(0, $visrep->{VSIZEX});
	$visrep->{WSIZEY}->insert(0, $visrep->{VSIZEY});
	$visrep->{WSIZEX}->bind('<Return>'   => \&resize);
	$visrep->{WSIZEY}->bind('<Return>'   => \&resize);

	#create section info
	$chars->Label(text   		=> 'Active section',
				relief   		=> 'groove',
					borderwidth	=> 2)->pack(side	=> 'left');
	$visrep->{WAREANAME} =$chars->Label(
					text   		=> $visrep->{ACTUAL_SEC}->name(),
					relief   	=> 'groove',
					borderwidth	=> 2,)->pack(side	=> 'left');

	$chars->Label(text 			=> 'Rows in section',
					relief	   	=> 'groove',
					borderwidth	=> 2)->pack(side	=> 'left');
	$visrep->{WSIZEVAREA} =$chars->Entry(
								width 	=> 3,
								relief	=> 'sunken')->pack(side	=> 'left');
	$visrep->{WSIZEVAREA}->insert(0, $visrep->{ACTUAL_SEC}->size());
	$visrep->{WSIZEVAREA}->bind('<Return>'   => \&resize);

	$chars->Label(
				text   		=> 'Break field',
				relief	   	=> 'groove',
				borderwidth	=> 2)->pack(side	=> 'left');
	$visrep->{WBREAKFIELD} =$chars->Entry(
								width 	=> 3,
								relief	=> 'sunken')->pack(side	=> 'left');
	$visrep->{WBREAKFIELD}->insert(0, $visrep->{ACTUAL_SEC}->break_field());
	$visrep->{WBREAKFIELD}->configure(state => 'disabled');
	$visrep->{WBREAKFIELD}->bind('<Return>'   => \&resize);

	#create widget to contain code area, ruler and draw area
	my $workarea = $topwin->Frame()->pack(
										side   => 'top',
										fill  => 'x');
	$workarea->configure(width => $visrep->{VSIZEX});

	$visrep->{WCODEAREA} =
	$workarea->Text(
				width => 10,
				relief	=> 'groove',
				height	=> 5)->pack(side => 'top', fill	=> 'x');
	my $cont;
	my $rulertext="";
	for ($cont = 0; $cont < $visrep->{VSIZEX}; $cont++) {
		$rulertext .= $cont % 10;
	}
	$visrep->{WRULER} =$workarea->Entry(
									width	=> $visrep->{VSIZEX},
                 					relief	=> 'groove',
                              		font	=> 'fixed')->pack(side => 'top');
	$visrep->{WRULER}->insert(0.1, $rulertext);
	$visrep->{WRULER}->configure(state => 'disabled');
	$visrep->{WWORKAREA} = $workarea;
}

sub gen_error($) {
	my $text = shift;
	my $errdiag = $visrep->{TOPWIN}->Dialog(-text=> $text);
	$errdiag->Show();
}

sub save() {
	#update actual section
	update_section();

	#ask file
	my $dialog = $visrep->{TOPWIN}->DialogBox(-title	=> "Program name");
	my $filename = $dialog->add('Entry', width 	=> 35,
	relief   => 'sunken');
	if ($visrep->{PROGRAMNAME} ne "") {
		$filename->insert(0.1, $visrep->{PROGRAMNAME});
	}
	$filename->pack();
	$dialog->Show();
	$visrep->{PROGRAMNAME} = $filename->get();

	if ($visrep->{PROGRAMNAME} eq "") {
		gen_error("Invalid Program name!!!");
		return;
	}

	$dialog->configure(-title  => "Output file");
	$filename->delete(0.1, 'end');
	if ($visrep->{OUTPUTFILE} ne "") {
		$filename->insert(0.1, $visrep->{OUTPUTFILE});
	}
	$dialog->Show();
	$visrep->{OUTPUTFILE} = $filename->get();

	if ($visrep->{OUTPUTFILE} eq "" or
			$visrep->{OUTPUTFILE} eq $visrep->{PROGRAMNAME}) {
		gen_error("Invalid Output file!!!");
		return;
	}

	#open output file
	my $error=0;
	open OUT, ">$visrep->{PROGRAMNAME}" or $error=1;
	if ($error) {
		gen_error("Can't create $visrep->{PROGRAMNAME}");
		return;
	}

	#print unix command
	print OUT "#!/usr/local/bin/perl\n";

	#print dimensions
	print OUT "#SIZE $visrep->{VSIZEX} $visrep->{VSIZEY}\n";

	#print output file
	print OUT "#OUTPUTFILE $visrep->{OUTPUTFILE}\n";

	#print source
	if ($visrep->{SOURCE} eq "Filesource") {
		print OUT "#SOURCE Filesource $visrep->{SOURCEFILENAME}\n";
	} else {
		print OUT "#SOURCE $visrep->{SOURCE} ";
		if ($visrep->{CONNECTION} eq "file") {
			print OUT "$visrep->{CONNECTIONFILENAME}\n";
		} else {
			print OUT "0\n";
		}
		map {
			print OUT "#QUERY $_\n";
		} split(/\n/, $visrep->{QUERY});
	}

	#print uses section
	print OUT "#SECTION: DEFAULT_USES 0\n";
	print OUT "#CODE AREA\n";
	$visrep->{USES_EXTRACODE} = "use strict;\nuse Data::Reporter;\n".
											"use Data::Reporter::RepFormat;\n";
	if ($visrep->{SOURCE} eq "Filesource") {
		$visrep->{USES_EXTRACODE} .= "use Data::Reporter::Filesource;\n";
	} else {
		$visrep->{USES_EXTRACODE} .= "use Data::Reporter::$visrep->{SOURCE};\n";
	}
	print OUT $visrep->{USES_EXTRACODE};
	print OUT "#END\n";

	#print uses section
	$visrep->{USES_SEC}->generate(\*OUT);

	#print header section
	$visrep->{HEADER_SEC}->generate(\*OUT);

	#print title section
	$visrep->{TITLE_SEC}->generate(\*OUT);

	#print detail section
	$visrep->{DETAIL_SEC}->generate(\*OUT);

	#print functions section
	$visrep->{FUNCTIONS_SEC}->generate(\*OUT);

	#print footer section
	$visrep->{FOOTER_SEC}->generate(\*OUT)
										if (defined($visrep->{FOOTER_SEC}));

	#print final section
	$visrep->{FINAL_SEC}->generate(\*OUT)
										if (defined($visrep->{FINAL_SEC}));

	#print breaks
	if ($visrep->{VBREAKS} > 0) {
		my $cont;
		for ($cont = 1; $cont <= $visrep->{VBREAKS}; $cont++) {
			my $name_break =  "BREAK_".$cont;
			$visrep->{$name_break}->generate(\*OUT);
			my $break_field = $visrep->{$name_break}->break_field();
			$visrep->{BREAKS}->{$break_field} = "\\&$name_break";
		}
	}

	#print main section
	$visrep->{MAIN_SEC}->generate(\*OUT);

	#print default main
	print OUT "\n#SECTION: DEFAULT_MAIN 0\n";
	print OUT "#CODE AREA\n";
	my $code="";
	if ($visrep->{VBREAKS} > 0) {
		$code .= "\tmy %rep_breaks = ();\n";
		foreach my $key (keys %{$visrep->{BREAKS}}) {
			$code .= "\t\$rep_breaks{$key} = $visrep->{BREAKS}->{$key};\n";
		}
	}
	if ($visrep->{SOURCE} eq "Filesource") {
		$code .= "\tmy \$source = new Data::Reporter::Filesource(File => ".
					"\"$visrep->{SOURCEFILENAME}\");\n";
	} else {
		if ($visrep->{CONNECTION} eq "file") {
			$code .= "\tmy \$source = new Data::Reporter::$visrep->{SOURCE}(File => ".
						"\"$visrep->{CONNECTIONFILENAME}\",\n";
		}elsif ($visrep->{CONNECTION} eq "arguments") {
			$code .= "\tmy \$source = new Data::Reporter::$visrep->{SOURCE}(Arguments => ".
						"\\\@ARGV,\n";
		}
		$code .= "\t\tQuery => '$visrep->{QUERY}');\n";
	}
	$code .= "\tmy \$report = new Data::Reporter();\n";
	#print report configure"
	$code .= "\t\$report->configure(\n";
	$code .= "\t\tWidth\t=> $visrep->{VSIZEX},\n";
	$code .= "\t\tHeight\t=> $visrep->{VSIZEY},\n";
  	if (defined($visrep->{FOOTER_SEC})) {
		$code .= "\t\tSubFooter\t=> \\&FOOTER,\n";
		my $size = $visrep->{FOOTER_SEC}->size();
		$code .= "\t\tFooter_size\t=> $size,\n";
	}
	$code .= "\t\tSubFinal \t=> \\&FINAL,\n"
   									if (defined($visrep->{FINAL_SEC}));
	$code .= "\t\tBreaks\t=> \\%rep_breaks,\n" if ($visrep->{VBREAKS} > 0);
	$code .= "\t\tSubHeader\t=> \\&HEADER,\n";
	$code .= "\t\tSubTitle\t=> \\&TITLE,\n";
	$code .= "\t\tSubDetail\t=> \\&DETAIL,\n";
	$code .= "\t\tSource\t=> \$source,\n";
	$code .= "\t\tFile_name\t=> \"$visrep->{OUTPUTFILE}\"\n";
	$code .= "\t);\n";
	$code .= "\t\$report->generate();\n";
	print OUT $code;
	print OUT "#END\n";

	#close output file
	close OUT;
}


sub create_menu() {
	my $topwin = $visrep->{TOPWIN};

	my $menu_bar = $topwin->Frame()->pack(side 	=> 'top',
											fill	=> 'x');

	#create file menu
	my $file_menu = $menu_bar->Menubutton(text   	=> 'File',
											relief	=> 'raised',
											borderwidth => 2,
											)->pack(side  => 'left',
													padx  => 2
													);

	#New option
	$file_menu->command(-label			=> 'New',
						accelerator => 'Meta+N',
						underline   => 0,
						command     => sub {delete_extrasections();
											defaults();
											update_textarea();
											}
						);

	#Open option
	$file_menu->command(-label			=> 'Open',
							accelerator => 'Meta+O',
							underline   => 0,
							command     => sub { open_file();}
						);
	#Save option
	$file_menu->command(-label			=> 'Save',
							accelerator => 'Meta+S',
							underline   => 0,
							command     => sub { save();}
						);

	#Quit option
	$file_menu->command(-label			=> 'Quit',
							accelerator => 'Meta+Q',
							underline   => 0,
							command     => sub {exit(0)}
						);
	
	#create Section menu
	my $section_menu = $menu_bar->Menubutton(text   	=> 'Section',
												relief	=> 'raised',
											borderwidth => 2,
											)->pack(side  => 'left',
													padx  => 2
													);
   
	#Header option
	$section_menu->command(-label		=> 'Header',
							accelerator => 'Meta+H',
							underline   => 0,
							command     => sub { update_section();
											load_section($visrep->{HEADER_SEC});
 				                                }
							);

	#Title option
	$section_menu->command(-label		=> 'Title',
							accelerator => 'Meta+T',
							underline   => 0,
							command     => sub { update_section();
											load_section($visrep->{TITLE_SEC});
												}
							);

	#Detail option
	$section_menu->command(-label		=> 'Detail',
							accelerator => 'Meta+D',
							underline   => 0,
							command     => sub { update_section();
											load_section($visrep->{DETAIL_SEC});
												}
							);

	#create the separator
	$section_menu->separator();

	$visrep->{SECTIONMENU} = $section_menu;

	#create the areas menu
	my $area_menu = $menu_bar->Menubutton(text   	=> 'Areas',
											relief	=> 'raised',
										borderwidth => 2,
										)->pack(side  => 'left',
												padx  => 2
												);
										
	#Uses option
	$area_menu->command(-label		=> 'Uses',
						accelerator => 'Meta+U',
						underline   => 0,
						command     => sub { update_section();
											load_section($visrep->{USES_SEC});
											}
						);

	#functions option
	$area_menu->command(-label		=> 'Functions',
						accelerator => 'Meta+F',
						underline   => 0,
						command     => sub { update_section();
										load_section($visrep->{FUNCTIONS_SEC});
											}
						);

	#main option
	$area_menu->command(-label		=> 'Main',
						accelerator => 'Meta+M',
						underline   => 0,
						command     => sub { update_section();
											load_section($visrep->{MAIN_SEC});
											}
						);

	#create the insert menu
	my $insert_menu = $menu_bar->Menubutton(text   	=> 'Insert',
											relief	=> 'raised',
										borderwidth => 2,
											)->pack(side  => 'left',
													padx  => 2
													);

	#Break option
	$insert_menu->command(-label		=> 'Break',
							accelerator => 'Meta+B',
							underline   => 0,
							command     => sub {insert_sec("BREAK");}
							);

	#Footer option
	$insert_menu->command(-label		=> 'Footer',
							accelerator => 'Meta+F',
								underline   => 0,
							command     => sub {insert_sec("FOOTER");}
							);

	#Final option
	$insert_menu->command(-label		=> 'Final',
							accelerator => 'Meta+i',
							underline   => 1,
							command     => sub {insert_sec("FINAL");}
							);

	#create the source menu
	my $source_menu = $menu_bar->Menubutton(text   	=> 'Source',
											relief	=> 'raised',
										borderwidth => 2,
											)->pack(side  => 'left',
													padx  => 2
													);

	#File option
	$source_menu->radiobutton(-label		=> 'Filesource',
								value       => 'Filesource',
								variable    => \$visrep->{SOURCE},
								command     => \&ask_sourcefile
							);

	#sources options
	foreach my $type (keys %{$visrep->{SOURCES}}) {
		$source_menu->radiobutton(-label		=> $type,
									value       => $type,
									variable    => \$visrep->{SOURCE},
									command     => \&ask_query
									);
	}

	#create the connection menu
	my $connection_menu = $menu_bar->Menubutton(text   	=> 'Connection',
												relief	=> 'raised',
											borderwidth => 2,
												)->pack(side  => 'left',
														padx  => 2
														);
	#File option
	$connection_menu->radiobutton(-label		=> 'File',
									value       => 'file',
									variable    => \$visrep->{CONNECTION},
									command     => \&ask_connectionfile
								);

	#Argument option
	$connection_menu->radiobutton(-label		=> 'Arguments',
									value       => 'arguments',
									variable    => \$visrep->{CONNECTION}
								);

}

sub delete_extrasections() {
	my $menu = $visrep->{SECTIONMENU}->cget("-menu");
	my $cont = $visrep->{VBREAKS};
	$cont++ if (defined($visrep->{FOOTER_SEC}));
	$cont++ if (defined($visrep->{FINAL_SEC}));
	$menu->delete(5,4+$cont) if ($cont > 0);
}

sub open_file() {
	my $FS = $visrep->{TOPWIN}->FileSelect(-directory => cwd());
	my $filename = $FS->Show();

	if ($filename ne "") {
		delete_extrasections();
		defaults();
		$visrep->{PROGRAMNAME} = $filename;
		parse_file();
		load_section($visrep->{HEADER_SEC});
		resize();
	}
}

sub parse_file() {
	my $error = 0;
	open INPUTFILE, $visrep->{PROGRAMNAME} or $error=1;
	if ($error) {
		gen_error("Can´t open file $visrep->{PROGRAMNAME}!!!");
		return;
	}

	my @data = <INPUTFILE>;
	close INPUTFILE;

	my $nlines = @data + 0;
	my $laststage = 0;
	my $actualstage=0;
	my $index = 1;
	my $line;
	my $only_code = 1;
	my $section="";
	my $break_field=0;
	my $subname="";
	my $codearea="";
	my @outputarea=();

	print "loading file $visrep->{PROGRAMNAME}...\n";
	while ($index <= $nlines) {
		my $line = $data[$index-1];
		chomp($line);
		if ($line =~ /#SIZE (\d+) (\d+)/) {
			$visrep->{VSIZEX} = $1;
			$visrep->{VSIZEY} = $2;
			$visrep->{WSIZEX}->delete(0.1, 'end');
			$visrep->{WSIZEX}->insert(0.1, $visrep->{VSIZEX});
			$visrep->{WSIZEY}->delete(0.1, 'end');
			$visrep->{WSIZEY}->insert(0.1, $visrep->{VSIZEY});
		} elsif ($line =~ /#QUERY (\w.*)$/) {
			$visrep->{QUERY} .= "$1\n";
		} elsif ($line =~ /#OUTPUTFILE (\w.*)$/) {
			$visrep->{OUTPUTFILE} = $1;
		} elsif ($line =~ /#SOURCE ([^\s]+) ([^\s]+)/) {
			if ($1 eq "Filesource") {
				$visrep->{SOURCE} = $1;
				unless (defined($2)) {
					gen_error("Incorrect input file (SOURCE). line $index!!!");
					defaults();
					return;
				}
				$visrep->{SOURCEFILENAME} = $2;
			} else {
				unless (defined($visrep->{SOURCES}{$1})) {
					gen_error("$1 is not a valid source!!!");
					defaults();
					return;
				}
				$visrep->{SOURCE} = $1;
				unless (defined($2)) {
					gen_error("Incorrect input file (SOURCE). line $index!!!");
					defaults();
					return;
				}
				if ($2 eq "0") {
					$visrep->{CONNECTION} = "arguments";
				} else {
					$visrep->{CONNECTION} = "file";
					$visrep->{CONNECTIONFILENAME} = $2;
				}
			}
		} elsif ($line =~ /#SECTION: (\w+) (\d+)$/) {
			$actualstage = 1;
			if ($laststage != 0 && $laststage != 4){
				print "last = $laststage\n";
				gen_error("Invalid format file (SECTION). line $index!!!");
				defaults();
				return;
			}
			$section = $1;
			$break_field = $2;
		} elsif ($line =~ /#CODE AREA/) {
			if ($laststage != 1){
				gen_error("Invalid format file (CODE). line $index!!!");
				defaults();
				return;
			}
			$actualstage=2;
		} elsif ($line =~ /#OUTPUT AREA/) {
			if ($laststage != 2){
				gen_error("Invalid format file (OUTPUT). line $index!!!");
				defaults();
				return;
			}
			$actualstage=3;
		} elsif ($line =~ /#END/) {
			if ($laststage != 2 && $laststage != 3){
				gen_error("Invalid format file (END). line $index!!!");
				defaults();
				return;
			}
			$actualstage=4;
		} else {
			if ($actualstage == 1) {
				if ($line !~ /sub (\w+)/) {
					$only_code = 0;
					$subname=$1;
				} elsif ($subname ne "") {
					gen_error("Invalid format file (END). line $index!!!");
					defaults();
					return;
				}
			} elsif ($actualstage == 2) {
				$codearea .= "$line\n";
			} elsif ($actualstage == 3) {
				if ($line =~ /#ORIG LINE (.*)$/) {
					push @outputarea, $1;
				}
			} elsif ($actualstage == 4) {
				my @lines = @outputarea;
				if ($section =~ /BREAK_(\d+)/) {
					my $nbreak = $1;
					$visrep->{VBREAKS}++;
					my $name_break = "BREAK_".$nbreak;
					#create break section

					$visrep->{$name_break} = Data::Reporter::VisSection->new(Size => 5,
												Name  => "$name_break",
												Width	=> $visrep->{VSIZEX},
											Break_field => $break_field,
												Code	=> $codearea,
												Lines	=> \@lines);
					my $menu = $visrep->{SECTIONMENU};
					my $label_break = "Break_".$nbreak;
					$menu->command(-label	=> $label_break,
									command	=> sub { update_section();
										load_section($visrep->{$name_break});
													}
									);
					load_section($visrep->{$name_break});
				} elsif($section =~ /FOOTER/) {
					defaults() if (insert_sec("FOOTER"));
					$visrep->{FOOTER_SEC}->configure(Size => @lines + 0,
												Width	=> $visrep->{VSIZEX},
												Code	=>	$codearea,
												Lines	=> \@lines);
					load_section($visrep->{FOOTER_SEC});
				} elsif($section =~ /FINAL/) {
					defaults() if (insert_sec("FINAL"));
					$visrep->{FINAL_SEC}->configure(Size => @lines + 0,
												Width	=> $visrep->{VSIZEX},
												Code	=>	$codearea,
												Lines	=> \@lines);
					load_section($visrep->{FINAL_SEC});
				} elsif($section =~ /HEADER/) {
					$visrep->{HEADER_SEC}->configure(Size => @lines + 0,
												Width	=> $visrep->{VSIZEX},
												Code	=>	$codearea,
												Lines	=> \@lines);
					load_section($visrep->{HEADER_SEC});
				} elsif($section =~ /TITLE/) {
					$visrep->{TITLE_SEC}->configure(Size => @lines + 0,
												Width	=> $visrep->{VSIZEX},
												Code	=>	$codearea,
												Lines	=> \@lines);
					load_section($visrep->{TITLE_SEC});
				} elsif($section =~ /DETAIL/) {
					$visrep->{DETAIL_SEC}->configure(Size => @lines + 0,
												Width	=> $visrep->{VSIZEX},
												Code	=>	$codearea,
												Lines	=> \@lines);
					load_section($visrep->{DETAIL_SEC});
				}  elsif($section =~ /FUNCTIONS/) {
					$visrep->{FUNCTIONS_SEC}->configure(
												Width	=> $visrep->{VSIZEX},
												Code	=>	$codearea);
					load_section($visrep->{FUNCTIONS_SEC});
				} elsif($section =~ /USES/) {
					$visrep->{USES_SEC}->configure(
												Width	=> $visrep->{VSIZEX},
												Code	=>	$codearea);
					load_section($visrep->{USES_SEC});
				} elsif($section =~ /^MAIN/) {
					$visrep->{MAIN_SEC}->configure(
												Width	=> $visrep->{VSIZEX},
												Code	=>	$codearea);
					load_section($visrep->{MAIN_SEC});
				}
				$codearea = "";
				@outputarea=();
				$section="";
				$subname="";
			}
		}
		$index++;
		$laststage = $actualstage;
	}
	print "load complete\n";
}

sub insert_sec($) {
	my $sectionname = shift;
	if ($sectionname eq "FINAL") {
		if (defined($visrep->{FINAL_SEC})) {
			gen_error("Final has already been defined!!!");
			return 1;
		}
		#create final section
		$visrep->{FINAL_SEC} = Data::Reporter::VisSection->new(Size		=> 5,
												Name	=> "FINAL",
												Width	=> $visrep->{VSIZEX});
		my $menu = $visrep->{SECTIONMENU};
		$menu->command(-label		=> 'Final',
						accelerator => 'Meta+i',
						underline   => 1,
						command     => sub { update_section();
											load_section($visrep->{FINAL_SEC});
											}
						);
		update_section();
		load_section($visrep->{FINAL_SEC});
	} elsif ($sectionname eq "FOOTER") {
		if (defined($visrep->{FOOTER_SEC})) {
			gen_error("Footer has already been defined!!!");
			return 1;
		}
		#create footer section
		$visrep->{FOOTER_SEC} = Data::Reporter::VisSection->new(Size	=> 5,
												Name	=> "FOOTER",
												Width	=> $visrep->{VSIZEX});
		my $menu = $visrep->{SECTIONMENU};
		$menu->command(-label		=> 'Footer',
						accelerator => 'Meta+F',
						underline   => 0,
						command     => sub { update_section();
											load_section($visrep->{FOOTER_SEC});
											}
					);
		update_section();
		load_section($visrep->{FOOTER_SEC});
	} elsif ($sectionname eq "BREAK") {
		$visrep->{VBREAKS}++;
		my $name_break = "BREAK_".$visrep->{VBREAKS};
		#create break section
		$visrep->{$name_break} = Data::Reporter::VisSection->new(Size	=> 5,
												Name	=> "$name_break",
												Width	=> $visrep->{VSIZEX});
		my $menu = $visrep->{SECTIONMENU};
		my $label_break = "Break_".$visrep->{VBREAKS};
		$menu->command(-label		=> $label_break,
						command     => sub { update_section();
										load_section($visrep->{$name_break});
											}
						);
		update_section();
		load_section($visrep->{$name_break});
	}
	return 0;
}

sub ask_sourcefile() {
	my $dialog = $visrep->{TOPWIN}->DialogBox(-title	=> "Source file");
	my $filename = $dialog->add('Entry', width	=> 15,
										relief	=> 'sunken');
	if ($visrep->{SOURCEFILENAME} ne "") {
		$filename->insert(0.1, $visrep->{SOURCEFILENAME});
	}
	$filename->pack();
	$dialog->Show();
	$visrep->{SOURCEFILENAME} = $filename->get();
}

sub ask_query() {
	my $dialog = $visrep->{TOPWIN}->DialogBox(-title => "Query to execute",
											-default_button => "none");
	my $textquery = $dialog->Text(width => 50,
								relief	=> 'groove',
								height	=> 5)->pack(side => 'top', fill	=> 'x');

	if ($visrep->{QUERY} ne "") {
		$textquery->insert(0.1, $visrep->{QUERY});
	}
	$textquery->pack();
	$dialog->Show();
	$visrep->{QUERY}="";
	my $jointext = sub {
		$visrep->{QUERY} .=  @_[1];
	};
	$textquery->dump(-text, -command => $jointext, 0.1, 'end');
}

sub ask_connectionfile() {
	my $dialog = $visrep->{TOPWIN}->DialogBox(-title	=> "Connection file");
	my $filename = $dialog->add('Entry', width	=> 15,
										relief	=> 'sunken');
	if ($visrep->{CONNECTIONFILENAME} ne "") {
		$filename->insert(0.1, $visrep->{CONNECTIONFILENAME});
	}
	$filename->pack();
	$dialog->Show();
	$visrep->{CONNECTIONFILENAME} = $filename->get();
}

sub defaults() {
	#default size 80, 66
	$visrep->{VSIZEX} = 80;
	$visrep->{VSIZEY} = 66;

	#create header section
	$visrep->{HEADER_SEC} = Data::Reporter::VisSection->new(Size	=> 5,
											Name	=> "HEADER",
											Width	=> $visrep->{VSIZEX});

	#create detail section
	$visrep->{TITLE_SEC} = Data::Reporter::VisSection->new(Size		=> 5,
											Name	=> "TITLE",
											Width	=> $visrep->{VSIZEX});

	#create detail section
	$visrep->{DETAIL_SEC} = Data::Reporter::VisSection->new(Size	=> 5,
											Name	=> "DETAIL",
											Width	=> $visrep->{VSIZEX});

	#create uses section
	$visrep->{USES_SEC} = Data::Reporter::VisSection->new(Size 			=> 0,
											Name  		=> "USES",
											Only_code   => 1,
											Width		=> $visrep->{VSIZEX});

	#create detail section
	$visrep->{FUNCTIONS_SEC} = Data::Reporter::VisSection->new(Size		=> 0,
												Name	=> "FUNCTIONS",
											Only_code   => 1,
											Width		=> $visrep->{VSIZEX});

	#create detail section
	$visrep->{MAIN_SEC} = Data::Reporter::VisSection->new(Size		=> 0,
											Name	=> "MAIN",
										Only_code   => 1,
											Width	=> $visrep->{VSIZEX});


	#default section = header
	$visrep->{ACTUAL_SEC} = $visrep->{HEADER_SEC};

	#size of the configuration area
	$visrep->{VSIZEC} = 3;

	#read all types of DB sources
	read_sources();

	#default source
	$visrep->{SOURCE} = "Filesource";

	#default connection
	$visrep->{CONNECTION} = "arguments";

	#default query
	$visrep->{QUERY} = "";

	#number of breaks
	$visrep->{VBREAKS} = 0;

	$visrep->{SOURCEFILENAME}="";
	$visrep->{CONNECTIONFILENAME}="";
	$visrep->{PROGRAMNAME}="";
	$visrep->{OUTPUTFILE}="";
	undef($visrep->{FOOTER_SEC}) if (defined($visrep->{FOOTER_SEC}));
	undef($visrep->{FINAL_SEC}) if (defined($visrep->{FINAL_SEC}));
}

sub read_sources() {
	open CON, "Sources.cfg";
	my @data = <CON>;
	close CON;
	foreach my $type (@data) {
		chomp($type);
		$visrep->{SOURCES}{$type}=1;
	}
}

#main
{
	#load defaults
	defaults();

	#create main window
	my $topwin = MainWindow->new(width	=> $visrep->{VSIZEX});
	$topwin->title('VisRep');
	$visrep->{TOPWIN} = $topwin;

	#create the menu
	create_menu();

	#create toolbar
	create_toolbar();

	#draw text area
	update_textarea();

	#initiates the program
	MainLoop();
}
