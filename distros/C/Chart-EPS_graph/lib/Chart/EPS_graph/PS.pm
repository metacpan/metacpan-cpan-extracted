# $Source: /home/aplonis/Chart-EPS_graph/Chart/EPS_graph/PS.pm $
# $Date: 2006-08-15 $

package Chart::EPS_graph::PS;

use strict;
use warnings;

our ($VERSION) = '$Revision: 0.01 $' =~ m{ \$Revision: \s+ (\S+) }xm;

BEGIN {

my $EMPTY = q{};

# Provide defaults.
our %ps_defaults = ( # Perl::Critic errs about THIS pkg var!
	pg_width     => 640,
	pg_height    => 480,
	label_top    => 'Graph Main Title Goes Here',
	label_x      => 'X Axis Measure (_units) Goes Here',
	label_x_2    => $EMPTY,
	label_y1     => 'Y1 Axis Measure & (_units) Goes Here',
	label_y1_2   => $EMPTY,
	label_y2     => 'Y2 Axis Measure (_units) Goes Here',
	label_y2_2   => $EMPTY,
	bg_color     => 'Silver',
	fg_color     => 'Black',
	web_colors   => [
		'Red', 'Gold', 'Blue',
		'Crimson', 'GoldenRod', 'BlueViolet',
		'FireBrick', 'DarkGoldenRod', 'Navy',
	],
	font_name    => 'Helvetica',
	font_size    => 10,
	label_x_proc => $EMPTY,
);

our $ps_web_colors_dict = <<'EOHD'; # Perl::Critic errs about THIS pkg var!
% Color names that are supported by most browsers
% Ref (http://www.w3schools.com/html/html_colornames.asp)
/web_colors_dict 143 dict def
web_colors_dict begin
/AliceBlue				{ 16#F0 16#F8 16#FF } def
/AntiqueWhite			{ 16#FA 16#EB 16#D7 } def
/Aqua					{ 16#00 16#FF 16#FF } def
/Aquamarine				{ 16#7F 16#FF 16#D4 } def
/Azure					{ 16#F0 16#FF 16#FF } def
/Beige					{ 16#F5 16#F5 16#DC } def
/Bisque					{ 16#FF 16#E4 16#C4 } def
/Black					{ 16#00 16#00 16#00 } def
/BlanchedAlmond			{ 16#FF 16#EB 16#CD } def
/Blue					{ 16#00 16#00 16#FF } def
/BlueViolet				{ 16#8A 16#2B 16#E2 } def
/Brown					{ 16#A5 16#2A 16#2A } def
/BurlyWood				{ 16#DE 16#B8 16#87 } def
/CadetBlue				{ 16#5F 16#9E 16#A0 } def
/Chartreuse				{ 16#7F 16#FF 16#00 } def
/Chocolate				{ 16#D2 16#69 16#1E } def
/Coral					{ 16#FF 16#7F 16#50 } def
/CornflowerBlue			{ 16#64 16#95 16#ED } def
/Cornsilk				{ 16#FF 16#F8 16#DC } def
/Crimson				{ 16#DC 16#14 16#3C } def
/Cyan					{ 16#00 16#FF 16#FF } def
/DarkBlue				{ 16#00 16#00 16#8B } def
/DarkCyan				{ 16#00 16#8B 16#8B } def
/DarkGoldenRod			{ 16#B8 16#86 16#0B } def
/DarkGray				{ 16#A9 16#A9 16#A9 } def
/DarkGreen				{ 16#00 16#64 16#00 } def
/DarkKhaki				{ 16#BD 16#B7 16#6B } def
/DarkMagenta			{ 16#8B 16#00 16#8B } def
/DarkOliveGreen			{ 16#55 16#6B 16#2F } def
/Darkorange				{ 16#FF 16#8C 16#00 } def
/DarkOrchid				{ 16#99 16#32 16#CC } def
/DarkRed				{ 16#8B 16#00 16#00 } def
/DarkSalmon				{ 16#E9 16#96 16#7A } def
/DarkSeaGreen			{ 16#8F 16#BC 16#8F } def
/DarkSlateBlue			{ 16#48 16#3D 16#8B } def
/DarkSlateGray			{ 16#2F 16#4F 16#4F } def
/DarkTurquoise			{ 16#00 16#CE 16#D1 } def
/DarkViolet				{ 16#94 16#00 16#D3 } def
/DeepPink				{ 16#FF 16#14 16#93 } def
/DeepSkyBlue			{ 16#00 16#BF 16#FF } def
/DimGray				{ 16#69 16#69 16#69 } def
/DodgerBlue				{ 16#1E 16#90 16#FF } def
/Feldspar				{ 16#D1 16#92 16#75 } def
/FireBrick				{ 16#B2 16#22 16#22 } def
/FloralWhite			{ 16#FF 16#FA 16#F0 } def
/ForestGreen			{ 16#22 16#8B 16#22 } def
/Fuchsia				{ 16#FF 16#00 16#FF } def
/Gainsboro				{ 16#DC 16#DC 16#DC } def
/GhostWhite				{ 16#F8 16#F8 16#FF } def
/Gold					{ 16#FF 16#D7 16#00 } def
/GoldenRod				{ 16#DA 16#A5 16#20 } def
/Gray					{ 16#80 16#80 16#80 } def
/Green					{ 16#00 16#80 16#00 } def
/GreenYellow			{ 16#AD 16#FF 16#2F } def
/HoneyDew				{ 16#F0 16#FF 16#F0 } def
/HotPink				{ 16#FF 16#69 16#B4 } def
/IndianRed				{ 16#CD 16#5C 16#5C } def
/Indigo					{ 16#4B 16#00 16#82 } def
/Ivory					{ 16#FF 16#FF 16#F0 } def
/Khaki					{ 16#F0 16#E6 16#8C } def
/Lavender				{ 16#E6 16#E6 16#FA } def
/LavenderBlush			{ 16#FF 16#F0 16#F5 } def
/LawnGreen				{ 16#7C 16#FC 16#00 } def
/LemonChiffon			{ 16#FF 16#FA 16#CD } def
/LightBlue				{ 16#AD 16#D8 16#E6 } def
/LightCoral				{ 16#F0 16#80 16#80 } def
/LightCyan				{ 16#E0 16#FF 16#FF } def
/LightGoldenRodYellow	{ 16#FA 16#FA 16#D2 } def
/LightGrey				{ 16#D3 16#D3 16#D3 } def
/LightGreen				{ 16#90 16#EE 16#90 } def
/LightPink				{ 16#FF 16#B6 16#C1 } def
/LightSalmon			{ 16#FF 16#A0 16#7A } def
/LightSeaGreen			{ 16#20 16#B2 16#AA } def
/LightSkyBlue			{ 16#87 16#CE 16#FA } def
/LightSlateBlue			{ 16#84 16#70 16#FF } def
/LightSlateGray			{ 16#77 16#88 16#99 } def
/LightSteelBlue			{ 16#B0 16#C4 16#DE } def
/LightYellow			{ 16#FF 16#FF 16#E0 } def
/Lime					{ 16#00 16#FF 16#00 } def
/LimeGreen				{ 16#32 16#CD 16#32 } def
/Linen					{ 16#FA 16#F0 16#E6 } def
/Magenta				{ 16#FF 16#00 16#FF } def
/Maroon					{ 16#80 16#00 16#00 } def
/MediumAquaMarine		{ 16#66 16#CD 16#AA } def
/MediumBlue				{ 16#00 16#00 16#CD } def
/MediumOrchid			{ 16#BA 16#55 16#D3 } def
/MediumPurple			{ 16#93 16#70 16#D8 } def
/MediumSeaGreen			{ 16#3C 16#B3 16#71 } def
/MediumSlateBlue		{ 16#7B 16#68 16#EE } def
/MediumSpringGreen		{ 16#00 16#FA 16#9A } def
/MediumTurquoise		{ 16#48 16#D1 16#CC } def
/MediumVioletRed		{ 16#C7 16#15 16#85 } def
/MidnightBlue			{ 16#19 16#19 16#70 } def
/MintCream				{ 16#F5 16#FF 16#FA } def
/MistyRose				{ 16#FF 16#E4 16#E1 } def
/Moccasin				{ 16#FF 16#E4 16#B5 } def
/NavajoWhite			{ 16#FF 16#DE 16#AD } def
/Navy					{ 16#00 16#00 16#80 } def
/OldLace				{ 16#FD 16#F5 16#E6 } def
/Olive					{ 16#80 16#80 16#00 } def
/OliveDrab				{ 16#6B 16#8E 16#23 } def
/Orange					{ 16#FF 16#A5 16#00 } def
/OrangeRed				{ 16#FF 16#45 16#00 } def
/Orchid					{ 16#DA 16#70 16#D6 } def
/PaleGoldenRod			{ 16#EE 16#E8 16#AA } def
/PaleGreen				{ 16#98 16#FB 16#98 } def
/PaleTurquoise			{ 16#AF 16#EE 16#EE } def
/PaleVioletRed			{ 16#D8 16#70 16#93 } def
/PapayaWhip				{ 16#FF 16#EF 16#D5 } def
/PeachPuff				{ 16#FF 16#DA 16#B9 } def
/Peru					{ 16#CD 16#85 16#3F } def
/Pink					{ 16#FF 16#C0 16#CB } def
/Plum					{ 16#DD 16#A0 16#DD } def
/PowderBlue				{ 16#B0 16#E0 16#E6 } def
/Purple					{ 16#80 16#00 16#80 } def
/Red					{ 16#FF 16#00 16#00 } def
/RosyBrown				{ 16#BC 16#8F 16#8F } def
/RoyalBlue				{ 16#41 16#69 16#E1 } def
/SaddleBrown			{ 16#8B 16#45 16#13 } def
/Salmon					{ 16#FA 16#80 16#72 } def
/SandyBrown				{ 16#F4 16#A4 16#60 } def
/SeaGreen				{ 16#2E 16#8B 16#57 } def
/SeaShell				{ 16#FF 16#F5 16#EE } def
/Sienna					{ 16#A0 16#52 16#2D } def
/Silver					{ 16#C0 16#C0 16#C0 } def
/SkyBlue				{ 16#87 16#CE 16#EB } def
/SlateBlue				{ 16#6A 16#5A 16#CD } def
/SlateGray				{ 16#70 16#80 16#90 } def
/Snow					{ 16#FF 16#FA 16#FA } def
/SpringGreen			{ 16#00 16#FF 16#7F } def
/SteelBlue				{ 16#46 16#82 16#B4 } def
/Tan					{ 16#D2 16#B4 16#8C } def
/Teal					{ 16#00 16#80 16#80 } def
/Thistle				{ 16#D8 16#BF 16#D8 } def
/Tomato					{ 16#FF 16#63 16#47 } def
/Turquoise				{ 16#40 16#E0 16#D0 } def
/Violet					{ 16#EE 16#82 16#EE } def
/VioletRed				{ 16#D0 16#20 16#90 } def
/Wheat					{ 16#F5 16#DE 16#B3 } def
/White					{ 16#FF 16#FF 16#FF } def
/WhiteSmoke				{ 16#F5 16#F5 16#F5 } def
/Yellow					{ 16#FF 16#FF 16#00 } def
/YellowGreen			{ 16#9A 16#CD 16#32 } def
% end

EOHD


our $ps_header = <<'EOHD'; # Perl::Critic errs about THIS pkg var!
%!PS-Adobe-2.0 EPSF-2.0
%%Title:
%%Version: (2006-08-05)
%%Copyright: (Gan Uesli Starling)
%%For: (Perl Module Chart::EPS_graph version 1.00)
%%BoundingBox:
%%DocumentResources:
%%EndComments
%%BeginProlog

EOHD


our $ps_prolog_generic = <<'EOHD'; # Perl::Critic errs about THIS pkg var!
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%  BEGIN Generic PROLOG  %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

/GraphDict 100 dict def
GraphDict begin

/in { 72 mul } def
/mm { 25.399 div 72 mul } def
/in2pts { 72 div } def
/mm2pts { 72 div 25.399 mul } def

/moveto_old   /moveto   load def
/lineto_old   /lineto   load def
/curveto_old  /curveto  load def
/rmoveto_old  /rmoveto  load def
/rlineto_old  /rlineto  load def

/moveto  {
	transform round exch round exch itransform moveto_old
} bind def

/lineto  {
	transform round exch round exch itransform lineto_old
} bind def

/rmoveto {
	currentpoint 3 -1 roll add 3 1 roll add exch
	transform round exch round exch itransform moveto_old
} bind def

/rlineto {
	currentpoint 3 -1 roll add 3 1 roll add exch
	transform round exch round exch itransform lineto_old
} bind def

/curveto
{ transform round exch round exch itransform 6 2 roll
	transform round exch round exch itransform 6 2 roll
	transform round exch round exch itransform 6 2 roll curveto_old
} bind def

% Divide by almost-zero when given zero.
/div { dup 0 eq {pop 1.0e-32} if div } bind def

/p   { print } def
/pf  { print flush } bind def
/xor { 1 index and not and } def
/fix { currentfile closefile clear erasepage } def

% BREAK POINT Loops for %stdin ( str --  )
/bp {
	(<<< ) p  p ( >>>\n\n) pf
	pstack flush
	{	(%stdin)(r)file 32 string readline
		{ pop exit } if
	}loop
}def

/showDot { (.) pf } bind def

% Modified from "Don Lancaster's PostScript Secrets", page 11, item 3.
/delta_xy { % ( str -- r )
	gsave
		nulldevice 0 0 moveto
		dup type (stringtype) eq
		{ show }{ cvx exec } ifelse
		currentpoint
	grestore
} def

/center_show {
	dup delta_xy pop
	-2 div 0 rmoveto
	dup type
	(stringtype) eq { show }{ cvx exec } ifelse
} def

/center_show_resized { % ( str/proc r -- )
	/max_width exch def
	dup delta_xy pop /real_width exch def
	real_width max_width gt {
		font_name findfont
		max_width real_width div font_size mul scalefont
		setfont
		center_show
		font_name findfont font_size scalefont setfont
	}
	{ center_show
	} ifelse
} def

/align_center {
	gsave
		nulldevice
		currentpoint pop
		exch show
		currentpoint pop sub
	grestore
	.5 mul 0 rmoveto
} def

/align_y2 {
	gsave
		nulldevice
		currentpoint pop
		exch show
		currentpoint pop sub
	grestore
	0 rmoveto
} def

/round_off {
	dup ceiling cvi 32 string cvs
	length
	dup 3 ge { 0 exch } if
	dup 2 eq { 1 exch } if
	dup 1 eq { 2 exch } if
	pop
	dup 0 eq { pop cvi }{
		exch 1 index { 10 mul } repeat
	 	round
	 	exch { 10 div } repeat
	} ifelse
} def

/inc_value { dup cvx exec 1 add def } def
/dec_value { dup cvx exec 1 sub def } def

/splice_asn {
	exch
	/XXX
	2 { 2 index length } repeat
	add
	2 index type
	dup /arraytype eq { pop array def false }{
		/nametype eq {
			string def
			32 string cvs exch
			32 string cvs exch
			true
		}{
			string def false
		} ifelse
	} ifelse
	exch XXX
	1 index length
	5 -1 roll
	putinterval
	XXX 0
	3 -1 roll
	putinterval
	XXX exch { cvn /XXX 1 index def } if
} bind def

/splice_as_name
{ 1 index 32 string cvs
	splice_asn cvn
} def

/tack_onto_array
{ /tack_on 1 array def
	tack_on 0 3 -1 roll
	put
	tack_on splice_asn
} bind def

/shift_array
{ dup cvx exec
	dup length dup 0 eq
	{
	pop pop pop false
	}{ 1 index 0 get
	 4 1 roll
	 dup 1 eq
	 {
		pop pop [] def
	 }{
		1 exch 1 sub
		getinterval def
		} ifelse
		true
	 } ifelse
} bind def

/inc_array_elems
{ [ exch
	{ 1 add
	} forall
	]
} def

/dec_array_elems
{ [ exch
	{ 1 sub
	} forall
	]
} def

%%%%%%%%%%%%%%%%%%%%%%%%%%
%%  END Generic PROLOG  %%
%%%%%%%%%%%%%%%%%%%%%%%%%%

EOHD


our $ps_prolog_graphing = <<'EOHD'; # Perl::Critic errs about THIS pkg var!
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%  BEGIN Graphing PROLOG  %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

/thin    { 0.20 setlinewidth } def
/thick   { 0.60 setlinewidth } def
/thicker { 1.00 setlinewidth } def

/bg_line_edge {
  gsave
    currentlinewidth 1.8 mul setlinewidth
    bg_color cvx exec set_color_rgb exec
    [ ] 0 setdash
    stroke
  grestore
} def

/show_curve_id {
	/id_size font_size 0.8 mul def
	gsave
		fg_color cvx exec set_color_rgb exec
		show_x show_y id_size 10 div sub moveto currentpoint
		/Symbol findfont id_size scalefont setfont
		id_point_char align_center
		id_point_char true charpath
		gsave
			bg_color cvx exec set_color_rgb exec
			4 setlinewidth
			stroke
		grestore
		gsave
			line_color exec fill
		grestore
		moveto
		0 id_size -0.8 mul rmoveto
		segregate? {
			y2? { ( \256)}{ ( \254)} ifelse
			dup align_center
			true charpath
			gsave
				bg_color cvx exec set_color_rgb exec
				4 setlinewidth
				stroke
			grestore
			line_color exec fill
		} if
	grestore
} def

% BELL & WHISTLE. USED TO DISPLAY DATA SET AND CURVE NUMBERS ON THE GRAPH.
/id_point_space { h_length 3 div } def

% Show an ID char for reach curve.
/id_point {
	/y exch def /x exch def
	x id_point_space
	show_y 0 eq { 2 div } if
	sub
	show_x gt {
		show_curve_id_x x
		tack_onto_array
		/show_curve_id_x exch def
		show_curve_id_y y
		tack_onto_array
		/show_curve_id_y exch def
		/show_x x def
		/show_y y def
	} if
} bind def

/add_tick_y2 { segregate? { 2 mm add } if } def
/h_line_1 { h_length 0 rlineto stroke } def

/h_line_2 {
	-2 mm 0 rmoveto
	h_length 2 mm add add_tick_y2 0 rlineto thick stroke thin
} def

/hLines {
	origin moveto
	thick h_line_2 thin
	/i 1 def
	v_ticks {
		origin vinc i mul add moveto h_line_1
		origin vinc i 1 add mul add moveto h_line_2
		/i i 2 add def
	} repeat
} def

/v_line_1 { 0 v_height rlineto stroke } def

/v_line_2 {
	0 -2 mm rmoveto
	0 v_height 2 mm add rlineto thick stroke thin
} def

/vLines {
	origin moveto thick v_line_2 thin /i 1 def
	h_ticks {
		origin exch hinc i mul add exch moveto v_line_1
		origin exch hinc i 1 add mul add exch moveto v_line_2
		/i i 2 add def
	} repeat
} def

/h_tick_value { h_max_value h_min_value sub h_ticks div } def
/v_tick_value { v_max_value v_min_value sub v_ticks div } def
/v_tick_value_y2 { v_max_value_y2 v_min_value_y2 sub v_ticks div } def
/hinc { grid_width  h_ticks 2 mul div } def
/vinc { grid_height v_ticks 2 mul div } def
/h_length { h_ticks 2 mul hinc mul } def
/v_height { v_ticks 2 mul vinc mul } def
/v_units { v_tick_value div vinc mul 2 mul } def
/v_units_y2 { v_tick_value_y2  div vinc mul 2 mul} def
/h_units { h_tick_value div hinc mul 2 mul } def

/marks_y1 {
	/i 0 def
	v_ticks -1 0 {
		origin exch 10 sub exch vinc i mul add 3 sub moveto
		gsave
			v_max_value v_tick_value 2 index mul sub
			round_off
			32 string cvs
			dup stringwidth pop neg 0 rmoveto show
		grestore
		/i i 2 add def
	} for
	pop
	gsave
		origin moveto
		90 rotate
		v_height 2 div 40 rmoveto
		currentpoint
		label_y1 v_height center_show_resized
		20 add moveto
		label_y1_2 v_height center_show_resized
	grestore
} def

/marks_y2 {
	/i 0 def
	v_ticks -1 0 {
		origin
		exch h_length add 10 add exch
		vinc i mul add 3 sub
		moveto
		gsave
			v_max_value_y2 v_tick_value_y2 2 index mul sub
			round_off
			32 string cvs
			dup show
		grestore
		/i i 2 add def
	} for
	pop
	gsave
		origin moveto
		-90 rotate
		v_height -2 div h_length 45 add rmoveto
		180 rotate
		currentpoint
		label_y2 v_height center_show_resized
		20 sub moveto
		label_y2_2 v_height center_show_resized
	grestore
} def

/marks_top {
	/i 0 def
	h_ticks -1 0
	{ origin exch hinc i mul add 3 sub exch 10 sub moveto
	gsave
		270 rotate
		h_max_value h_tick_value 2 index mul sub
		round_off
		32 string cvs
		show
	grestore
	/i i 2 add def
	} for
	pop
	origin moveto h_length 2 div v_height 20 add rmoveto
	label_top h_length origin pop add center_show_resized
} def

/center_x {
	origin moveto h_length 2 div 0 rmoveto
} def

/max_width_x { pg_width 20 sub } def

/marks_x {
	/i 0 def
	h_ticks -1 0 {
		origin exch hinc i mul add 3 sub exch 10 sub moveto
		gsave
			270 rotate
			h_max_value h_tick_value 2 index mul sub
			round_off
			32 string cvs
			show
		grestore
		/i i 2 add def
	} for
	pop
	center_x 0 -50 rmoveto
	label_x max_width_x center_show_resized
	center_x 0 -70 rmoveto
	/label_x_proc max_width_x center_show_resized
	label_x_2 length 0 gt {
		center_x 0 -90 rmoveto
		label_x_2 max_width_x center_show_resized
	} if
} def

/xpnt { 3 index exch exp mul } def

/plot_paired_arrays {
	/show_curve_id_x [] def
	/show_curve_id_y [] def
	0 1 points_array length 1 sub {
		points_array 1 index get
		column_array-0 2 index get
		h_min_value sub exch
		v_min_value
		y2? { v_ratio_y2 div } if
		sub exch
		h_units exch
		y2? {
			v_units_y2 v_min_value_y2 v_units_y2 sub v_min_value v_units add
		}{
			v_units
		} ifelse
		3 -1 roll 0 eq {
			2 copy moveto
		}{
			2 copy lineto
		} ifelse
		id_point
	} for
} bind def

/plot_pairs {
	/show_x
	curve_id
	15 mul
	data_set_id 1 sub
	10 mul add
	def
	/show_y 0 def
	gsave
		origin moveto
		currentpoint translate
		plot_paired_arrays
		bg_line_edge
		stroke
		gsave
			0 1 show_curve_id_x length 1 sub
			{ show_curve_id
			show_curve_id_x 1 index get
			/show_x exch def
			show_curve_id_y exch get
			/show_y exch def
			} for
		grestore
	grestore
} bind def

/plot_lines {
	gsave
		origin moveto currentpoint translate
		0 5 x-fin {
			y.line exch mm exch mm
			dup 0 lt { pop 0 } if
			lineOp
		} for
		stroke
	grestore
} bind def

/formula {
	-194.77 250.75 2 index mul add
	.13976 2 index 2 exp mul sub
	2.2082e-2 3 xpnt sub
	1.5757e-4 4 xpnt add
	3.2312e-7 5 xpnt sub
} def

/do_curve {
	/x-fin 200 def /y.line { formula } def
	plot_pairs stroke
} def

/graph {
	font_name findfont font_size scalefont setfont
	origin moveto
	h_tick_value v_tick_value
	hLines vLines
	segregate? { marks_y2 } if
	marks_y1 marks_top marks_x
} def

/bg_color_bbox {
	0 0 moveto
	pg_width 0 lineto
	pg_width pg_height lineto
	0 pg_height lineto
	closepath
	bg_color cvx exec set_color_rgb exec
	fill
} def

/do_graph {
	/origin { 80 110 } def
	/grid_height { pg_height origin exch pop 2 mul sub 60 add } def
	/grid_width  { pg_width origin pop 2 mul sub } def
	gsave
    fg_color cvx exec set_color_rgb exec
    graph
  grestore
} def

/compensate { } def % {1 1.08133 div mul} def

/floor_ceiling_div 10 def

/set_ceiling {
	/low_ceiling false def
	all_y_cols_max
	dup 0 gt
	1 index 1 lt and {
		floor_ceiling_div mul
		/low_ceiling true def
	} if
	ceiling
	low_ceiling { floor_ceiling_div div } if
} def

/set_floor {
	all_y_cols_min
	low_ceiling { floor_ceiling_div mul } if
	floor
	low_ceiling { floor_ceiling_div div } if
} def

/init_graph_params {
	1 setlinecap
	1 setlinejoin
	segregate? {
		segregate_y_coords
		/v_max_value set_ceiling def
		/v_min_value set_floor def

		% Must calculate v_ticks ahead of other functions, even if redundantly.
		exch_y_coords
		/v_max_value_y2 set_ceiling def
		/v_min_value_y2 set_floor def
		exch_y_coords

		/v_ticks
			v_max_value v_min_value sub
			v_max_value_y2 v_min_value_y2 sub mul
			abs cvi
		def

		/v_ticks 6 12 adjust_tick

		/v_ratio_y2
		v_max_value v_min_value sub
		v_max_value_y2 v_min_value_y2 sub
		div
		def
	}{
		/v_max_value set_ceiling def
		/v_min_value set_floor def
		/v_ticks v_max_value v_min_value sub abs cvi def
		/v_ticks 6 12 adjust_tick
	} ifelse
	/h_max_value
		max_max_vals 0 get
		100 mul
		ceiling round_off
		100 div
	def
	/h_min_value
		min_min_vals 0 get
		100 mul
		floor round_off
		100 div
	def
	/h_ticks h_max_value h_min_value sub 10 mul abs cvi def
	/h_ticks 9 25 adjust_tick
	segregate? { }{ /v_ratio_y2 .9999 def } ifelse
} def

% Adjust hTick or vTick to fall between 6 and 20
/adjust_tick { % ( /name i i -- )
	dup
	/ticks_max exch def
	/ticks_min exch def
	% Min ticks are ticks_min.
	dup cvx exec {
		dup ticks_min ge { cvi def exit } if
		2 mul
	} loop
	% Max ticks are ticks_max.
	dup cvx exec {
		dup ticks_max le { cvi def exit } if
		2 div
	} loop
} def

/draw_one_curve {
	/points_array
	(column_array-)
	curve_id 2 string cvs splice_asn
	cvx exec def
	pick_dash_&_color
	curve_id show_this_curve? { do_curve } if
} def

/spc 2.5 def
/dit spc 1.5 mul def
/dah dit 3.5 mul def
/linio dah 2.5 mul def

/dash_procs
[ {  }                                                          %  sans dash
	{ [ dit spc dah spc linio spc ] 0 setdash }                   %  .-    a
	{ [ dah spc dit spc dit spc dit spc linio spc ] 0 setdash }   %  -...  b
	{ [ dah spc dit spc dah spc dit spc linio spc ] 0 setdash }   %  -.-.  c
	{ [ dah spc dit spc dit spc linio spc ] 0 setdash }           %  -..   d
	{ [ dit spc linio spc ] 0 setdash }                           %  .     e
	{ [ dit spc dit spc dah spc dit spc linio spc ] 0 setdash }   %  ..-.  f
	{ [ dah spc dah spc dit spc linio spc ] 0 setdash }           %  --.   g
	{ [ dit spc dit spc dit spc dit spc linio spc ] 0 setdash }   %  ....  h
	{ [ dit spc dit spc linio spc ] 0 setdash }                   %  ..    i
	{ [ dit spc dah spc dah spc dah spc linio spc ] 0 setdash }   %  .---  j
	{ [ dah spc dit spc dah spc linio spc ] 0 setdash }           %  -.-   k
	{ [ dah spc dit spc dah spc dah spc linio spc ] 0 setdash }   %  -.--  l
	{ [ dah spc dah spc linio spc ] 0 setdash }                   %  --    m
	{ [ dah spc dit spc linio spc ] 0 setdash }                   %  -.    n
	{ [ dah spc dah spc dah spc linio spc ] 0 setdash }           %  ---   o
	{ [ dah spc dit spc dit spc dah spc linio spc ] 0 setdash }   %  -..-  p
	{ [ dah spc dah spc dit spc dah spc linio spc ] 0 setdash }   %  --.-  q
	{ [ dit spc dah spc dit spc linio spc ] 0 setdash }           %  .-.   r
	{ [ dit spc dit spc dit spc linio spc ] 0 setdash }           %  ...   s
	{ [ dah spc linio spc ] 0 setdash }                           %  -     t
	{ [ dah spc dit spc dit spc linio spc ] 0 setdash }           %  ..-   u
	{ [ dit spc dit spc dit spc dah spc linio spc ] 0 setdash }   %  ...-  v
	{ [ dah spc dah spc dit spc linio spc ] 0 setdash }           %  --.   w
	{ [ dah spc dit spc dit spc dah spc linio spc ] 0 setdash }   %  -..-  x
	{ [ dah spc dit spc dah spc dah spc linio spc ] 0 setdash }   %  -.--  y
	{ [ dah spc dah spc dit spc dit spc linio spc ] 0 setdash }   %  --..  z
] def

/set_color_rgb {
	3 { 16#ff div 3 1 roll } repeat
	setrgbcolor
} def

% User can add more colors by redefining this array with another
% containing the any of the common browser web color names as per
% the separate dictionary herewith included.
/web_colors [
	/Red    /Lime    /Blue
	/Yellow /Magenta /Cyan
] def

/show_color_id { % ( str i -- )
	/id_size font_size 0.8 mul def
	currentrgbcolor 5 3 roll
	1 sub web_colors length mod
	web_colors exch
	get cvx exec
	set_color_rgb
	segregate? {
		dup 1 1 index length 1 sub getinterval
		(   ) show dup show
		gsave
			align_center
			0 id_size -0.7 mul rmoveto
			0 1 getinterval
			/Symbol findfont id_size scalefont setfont
			dup align_center
			show
		grestore
	}{
		show
	} ifelse
	font_size 5 div font_size 7 div rmoveto
	gsave
		/Symbol findfont id_size scalefont setfont
		 (\267) show % bullet
	grestore
	font_size 2 div font_size -7 div rmoveto
	setrgbcolor
} def

/pick_dash_&_color {
	dash_procs data_set_id 1 sub
	dash_procs length mod get
	cvx exec

	/line_color
		web_colors
		curve_id 1 sub web_colors length mod
		get 32 string cvs
		( set_color_rgb ) splice_asn cvx
	def

	line_color exec
	/id_point_char curve_id 3 string cvs def

	data_sets 1 gt {
		/id_point_char ( ) id_point_char splice_asn def
		id_point_char 0 (A) 0 get data_set_id
		1 sub add
		put
	}if

	/curve_id inc_value
} def


%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%  END Graphing PROLOG  %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

EOHD


our $ps_prolog_data_arrays = <<'EOHD'; # Perl::Critic errs about THIS pkg var!
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%  BEGIN Data Arrays PROLOG  %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

/data_set_id 1 def

/append_data_set_id {
	(-)
	data_set_id 32 string cvs
	splice_asn
	splice_asn
} def

/pointer 0 def

/fetch_column_arrays {
	0 {
		(column_array-) 1 index
		2 string cvs splice_asn
		append_data_set_id
		cvn
		currentdict 1 index known {
			dup cvx exec
			[] ne {
				(column_array-)
				2 index 3 string cvs splice_asn
				cvn 1 index cvx exec
				dup length array
				copy def
				pop
			}{
				pop
			} ifelse
		}{
			pop pop exit
		} ifelse
		1 add
	} loop
} bind def

/min_max_cnt 50 def

/init_min_max_vals {
	/max_max_vals
		min_max_cnt array
		0 1 min_max_cnt 1 sub {
			1 index exch 16#80000000 put
		} for
	def
	/max_max_vals_y2 [ max_max_vals aload pop ] def
	/min_min_vals
		min_max_cnt array
		0 1 min_max_cnt 1 sub {
			1 index exch 16#7fffffff put
		} for
	def
	/min_min_vals_y2 [ min_min_vals aload pop ] def
} def

init_min_max_vals

/y2? {
	curve_id 1 sub false
	y2
	fake_col_zero_flag { dec_array_elems } if
	{ 2 index eq or } forall
	exch pop
} def

/segregate_y_coords {
	y2
	fake_col_zero_flag { dec_array_elems } if
	{
		min_min_vals 1 index get
		min_min_vals_y2 2 index get
		min_min_vals exch
		3 index exch put
		min_min_vals_y2 exch
		2 index exch put
		max_max_vals 1 index get
		max_max_vals_y2 2 index get
		max_max_vals exch
		3 index exch put
		max_max_vals_y2 exch
		2 index exch put
		pop
	} forall
} def

/exch_y_coords {
	/max_max_vals max_max_vals_y2
	/max_max_vals_y2 max_max_vals
	def def

	/min_min_vals min_min_vals_y2
	/min_min_vals_y2 min_min_vals
	def def
} def

/all_y_cols_max {
	16#80000000
	1 1 min_max_cnt 1 sub {
		max_max_vals exch get
		dup 2 index gt {
			exch pop
		}{
			pop
		} ifelse
	} for
} def

/all_y_cols_min {
	16#7fffffff
	1 1 min_max_cnt 1 sub {
		min_min_vals exch get
		dup 2 index lt {
			exch pop
		}{
			pop
		} ifelse
	} for
} def

/max_max_store {
	max_max_vals 3 index get
	1 index lt {
		max_max_vals 3 index
		2 index put
	} if
} def

/min_min_store {
	min_min_vals 3 index get
	1 index gt {
		min_min_vals 3 index
		2 index put
	} if
} def

/max_column_val {
	16#80000000
	0 1
	column_array length 1 sub {
		column_array exch get
		dup 2 index gt {
			exch pop
		}{
			pop
		} ifelse
	} for
	dup 0.0 eq { pop 1e-38 } if
} def

/min_column_val { % ( -- real)
	16#7fffffff
	0 1
	column_array length 1 sub {
		column_array exch get
		dup 2 index lt {
			exch pop
		}{
			pop
		} ifelse
	} for
} def

/max_all_columns {
	0 {
		(column_array-)
		1 index 32 string cvs splice_asn dup cvn
		(columnMax-) 3 index 32 string cvs
		splice_asn cvn

		currentdict 2 index known {
			1 index cvx exec length
			0 eq { pop pop pop exit} if
		}{
			pop pop pop exit
		} ifelse

		3 -1 roll pop

		/column_array 3 -1 roll cvx exec def

		max_column_val max_max_store def

		dup 32 string cvs (columnMin-) exch splice_asn cvn
			min_column_val
			min_min_store
		def

		not_shown length {
			2 add
			show_this_curve? { 2 sub exit } if
			1 sub
		} repeat

		1 add
	} loop
	pop
} def

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%  END Data Arrays PROLOG  %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% BEGIN User Overwritable DEFAULTS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Of chans provided, which not to show. Their colors will be skipped.
/not_shown [] def

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% END User Overwritable DEFAULTS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

EOHD


our $ps_prolog_drawing = <<'EOHD'; # Perl::Critic errs about THIS pkg var!
%%%%%%%%%%%%%%%%%%%%%%%%%%
%% BEGIN drawing PROLOG %%
%%%%%%%%%%%%%%%%%%%%%%%%%%

% RETURN false IF A CHANNEL IS AMONG THOSE EXCLUDED FROM DISPLAY BY USER.
/show_this_curve? {
	true
	not_shown {
		1 add
		2 index ne
		and
	} forall
} def

% DRAW CURVES FOR ALL CHANNELS NOT EXCLUDED BY USER.
/draw_all_curves {
	/curve_id 1 def
	init_graph_params
	do_graph
	thicker
	clear

	/data_sets data_set_id def

	1 1 data_set_id {
		/curve_id 1 def
		/data_set_id 1 index def
		fetch_column_arrays
		(columns_cnt-) splice_as_name cvx exec
		1 sub { draw_one_curve } repeat
		pop
	} for
} def

/external_control_config {
	1 {
		(column_array-) splice_as_name currentdict exch
		known not {
			/columns_cnt-1 exch def
			exit
		} if
		1 add
	} loop

	/rows_cnt-1 column_array-1 length def

	fake_col_zero_flag {
		/column_array-0 [
			0
			column_array-1 length {
				dup
				1 fake_col_zero_scale mul add
			} repeat
		] def
		/y2 y2 inc_array_elems def
	} if

	/segregate?
		y2 length 0 eq {
			false
		}{
			true
		} ifelse
	def

	max_all_columns
} def

%%%%%%%%%%%%%%%%%%%%%%%%
%% END drawing PROLOG %%
%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% BEGIN User-Editable DEFAULTS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Here are things the user can change by putting in different
% settings, preferably via the Perl interface, rather than here,
% although either way will work.

/data_sets 1 def                   % When used standalone (not with Perl).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% END User-Editable DEFAULTS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% BEGIN Perl-inserted CODE %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

EOHD


our $ps_tail = <<'EOHD'; # Perl::Critic errs about THIS pkg var!

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% END Perl-inserted CODE %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

external_control_config
bg_color_bbox
draw_all_curves
end % Lose the OminGraphDict
end % Lose the web_colorsDict
clear
grestore
showpage

EOHD

} # BEGIN

1;

__END__

=head1 NAME

Chart::EPS_graph::PS.pm

=head1 VERSION

Version 0.01

=head1 DESCRIPTION

Just a block of PostScript defs for use by Chart::EPS_graph.pm

=head1 AUTHOR

Gan Uesli Starling <F<gan@starling.us>>

=head1 LICENSE AND COPYRIGHT                            .

This is free software; you may distribute and/or modify it under the same terms
as Perl itself.

Copyright (c) 2006 Gan Uesli Starling. All rights reserved

=cut


