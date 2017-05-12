#!/usr/bin/perl -w
use strict;
#use warnings;

use FindBin;
use lib "$FindBin::RealBin/../lib";
#   make KEY_BTAB (shift-tab) working in XTerm
#   and also at the same time enable colors
#$ENV{TERM} = "xterm-vt220" if ($ENV{TERM} eq 'xterm');

my $debug = 0;
use Curses::UI;

# Create the root object.
my $cui = new Curses::UI ( 
    -clear_on_exit => 1, 
    -debug => $debug,
    -color_support => 1,

);

$cui->set_binding( sub{ exit }, "\cQ" );

# Demo index
my $current_demo = 1;

# Demo windows
my %w = ();
my %args = (
    -border       => 1,
    -titlereverse => 1,
    -padtop       => 1,
    -padbottom    => 3,
    );

 $w{0}=$cui->add('w0', 'Window'
		,-border=> 1
		,-y     =>-1
		,-height=> 3,);

 $w{0}->add('explain', 'Label',
  -text => "CTRL+P: previous demo  CTRL+N: next demo  "
         . "CTRL+X: menu  CTRL+Q: quit"
 );



    $w{1} = $cui->add(undef, 'Window'
       ,-title  => "Curses::UI demo: Editable Grid"
       , %args
       ,-bfg=>'red'
    );


    my $grid=$w{1}->add('grid'
        ,'Grid'
        ,-rows=>15
        ,-columns=>15
        ,-bfg=>'red'
        ,-bg=>'black'
        ,-fg=>'white'
    );

    for my $i(1 .. 15) {$grid->set_label("cell$i","Head $i");}

    $w{2} = $cui->add(undef, 'Window'
       ,-title  => "Curses::UI demo: Grid"
       , %args
    );
      $grid=$w{2}->add('grid'
	,'Grid'
	,-height=>20
	,-bg => "blue"
	,-fg => "white" 
    );



  for my $id(0 .. 25 ) {
            $grid->add_cell("cell".$id
            ,-frozen=>( $id > 2 ? 0:1)
            ,-label=>"Head $id"
            ,-width=>10
	    ,-overwrite => $id==2 ? 0:1
	    ,-readonly	=> $id==0 ? 1:0
            ,-align=> $id % 3 ? "L":"R" 
            ,-fg=>$id ==3 ? 'black':''
            ,-bg=>$id ==3 ? 'red':''  );
        }

    $grid->add_row(undef,
                    ,-fg=>'black'
                    ,-bg=>'yellow' );

   for my $i (1  ..  14 ) {
        $grid->add_row(undef,
                    ,-fg=>'white'
                    ,-bg=>'green' );
    }


   for my $i (1  ..  15 ) {
	     my %val=();
    	     for my $j(0 .. 25 ) {
		$val{'cell'.$j}="cell $j $i";
	     }
	$grid->set_values('row'.$i,%val);
    }


    $w{3} = $cui->add(undef, 'Window'
       ,-title  => "Curses::UI demo: Browser"
       , %args
    );



     my @data=(
{ ROWNUM=>1, COUNTRY=>'China', PROD=>'Home Theatre Package with DVD-Audio/Video Play',SALE =>'627.79' }
,{ ROWNUM=>2, COUNTRY=>'Poland', PROD=>'Y Box',SALE =>'81207.35' }
,{ ROWNUM=>3, COUNTRY=>'Poland', PROD=>'Bounce',SALE =>'4847' }
,{ ROWNUM=>4, COUNTRY=>'Poland', PROD=>'Mouse Pad',SALE =>'4749.5' }
,{ ROWNUM=>5, COUNTRY=>'Poland', PROD=>'Music CD-R',SALE =>'2753.84' }
,{ ROWNUM=>6, COUNTRY=>'Poland', PROD=>'Fly Fishing',SALE =>'721.82' }
,{ ROWNUM=>7, COUNTRY=>'Poland', PROD=>'Deluxe Mouse',SALE =>'7429.24' }
,{ ROWNUM=>8, COUNTRY=>'Poland', PROD=>'Finding Fido',SALE =>'1707.42' }
,{ ROWNUM=>9, COUNTRY=>'Poland', PROD=>'Xtend Memory',SALE =>'5915.53' }
,{ ROWNUM=>10, COUNTRY=>'Poland', PROD=>'Standard Mouse',SALE =>'3390.36' }
,{ ROWNUM=>11, COUNTRY=>'Poland', PROD=>'CD-R Mini Discs',SALE =>'3227.46' }
,{ ROWNUM=>12, COUNTRY=>'Poland', PROD=>'Extension Cable',SALE =>'2174.04' }
,{ ROWNUM=>13, COUNTRY=>'Poland', PROD=>'Smash up Boxing',SALE =>'4005.72' }
,{ ROWNUM=>14, COUNTRY=>'Poland', PROD=>'Endurance Racing',SALE =>'7597.6' }
,{ ROWNUM=>15, COUNTRY=>'Poland', PROD=>'Envoy Ambassador',SALE =>'163581.87' }
,{ ROWNUM=>16, COUNTRY=>'Poland', PROD=>'128MB Memory Card',SALE =>'10680.17' }
,{ ROWNUM=>17, COUNTRY=>'Poland', PROD=>'256MB Memory Card',SALE =>'11651.36' }
,{ ROWNUM=>18, COUNTRY=>'Poland', PROD=>'Comic Book Heroes',SALE =>'1180.87' }
,{ ROWNUM=>19, COUNTRY=>'Poland', PROD=>'Envoy 256MB - 40GB',SALE =>'112939.62' }
,{ ROWNUM=>20, COUNTRY=>'Poland', PROD=>'External 6X CD-ROM',SALE =>'5224.63' }
,{ ROWNUM=>21, COUNTRY=>'Poland', PROD=>'External 8X CD-ROM',SALE =>'5674.46' }
,{ ROWNUM=>22, COUNTRY=>'Poland', PROD=>'Internal 6X CD-ROM',SALE =>'3204.35' }
,{ ROWNUM=>23, COUNTRY=>'Poland', PROD=>'Internal 8X CD-ROM',SALE =>'93.29' }
,{ ROWNUM=>24, COUNTRY=>'Poland', PROD=>'Keyboard Wrist Rest',SALE =>'5179.67' }
,{ ROWNUM=>25, COUNTRY=>'Poland', PROD=>'Laptop carrying case',SALE =>'11626.13' }
,{ ROWNUM=>26, COUNTRY=>'Poland', PROD=>'8.3 Minitower Speaker',SALE =>'57999.5' }
,{ ROWNUM=>27, COUNTRY=>'Poland', PROD=>'Martial Arts Champions',SALE =>'1692.2' }
,{ ROWNUM=>28, COUNTRY=>'Poland', PROD=>'Adventures with Numbers',SALE =>'2685.08' }
,{ ROWNUM=>29, COUNTRY=>'Poland', PROD=>'Envoy External Keyboard',SALE =>'1263.85' }
,{ ROWNUM=>30, COUNTRY=>'Poland', PROD=>'SIMM- 8MB PCMCIAII card',SALE =>'30022.16' }
,{ ROWNUM=>31, COUNTRY=>'Poland', PROD=>'Envoy External 6X CD-ROM',SALE =>'4930.81' }
,{ ROWNUM=>32, COUNTRY=>'Poland', PROD=>'Envoy External 8X CD-ROM',SALE =>'7942.36' }
,{ ROWNUM=>33, COUNTRY=>'Poland', PROD=>'SIMM- 16MB PCMCIAII card',SALE =>'29378.58' }
,{ ROWNUM=>34, COUNTRY=>'Poland', PROD=>'Unix/Windows 1-user pack',SALE =>'52526.36' }
,{ ROWNUM=>35, COUNTRY=>'Poland', PROD=>'External 101-key keyboard',SALE =>'5561.56' }
,{ ROWNUM=>36, COUNTRY=>'Poland', PROD=>'OraMusic CD-R, Pack of 10',SALE =>'2118.25' }
,{ ROWNUM=>37, COUNTRY=>'Poland', PROD=>'CD-RW, High Speed Pack of 5',SALE =>'2665.15' }
,{ ROWNUM=>38, COUNTRY=>'Poland', PROD=>'PCMCIA modem/fax 19200 baud',SALE =>'20070.18' }
,{ ROWNUM=>39, COUNTRY=>'Poland', PROD=>'PCMCIA modem/fax 28800 baud',SALE =>'27085.18' }
,{ ROWNUM=>40, COUNTRY=>'Poland', PROD=>'5MP Telephoto Digital Camera',SALE =>'117447.13' }
,{ ROWNUM=>41, COUNTRY=>'Poland', PROD=>'1.44MB External 3.5" Diskette',SALE =>'890.13' }
,{ ROWNUM=>42, COUNTRY=>'Poland', PROD=>'17" LCD w/built-in HDTV Tuner',SALE =>'61366.26' }
,{ ROWNUM=>43, COUNTRY=>'Poland', PROD=>'CD-RW, High Speed, Pack of 10',SALE =>'1126.53' }
,{ ROWNUM=>44, COUNTRY=>'Poland', PROD=>'DVD-R Discs, 4.7GB, Pack of 5',SALE =>'14983.76' }
,{ ROWNUM=>45, COUNTRY=>'Poland', PROD=>'Multimedia speakers- 3" cones',SALE =>'7865.92' }
,{ ROWNUM=>46, COUNTRY=>'Poland', PROD=>'Multimedia speakers- 5" cones',SALE =>'12531.33' }
,{ ROWNUM=>47, COUNTRY=>'Poland', PROD=>'O/S Documentation Set - Kanji',SALE =>'7763.35' }
,{ ROWNUM=>48, COUNTRY=>'Poland', PROD=>'DVD-RW Discs, 4.7GB, Pack of 3',SALE =>'6259.59' }
,{ ROWNUM=>49, COUNTRY=>'Poland', PROD=>'O/S Documentation Set - French',SALE =>'4538.77' }
   );

    my $mask;
    eval {
        require 'Number::Format.pm';
	$mask= new Number::Format (  THOUSANDS_SEP=>' ', DECIMAL_POINT=>'.');
    };

    $grid=$w{3}->add('grid'
	,'Grid'
	,-height=>20
	,-bg => "blue"
	,-fg => "white" 
	,-editable=>0
	,-width=>45
        ,-onrowdraw => sub{
            my $row=shift;
            my $v=$row->get_value('SALE');
            if(int($v ||0) <  1000) {
                $row->bg('red');
            } else { $row->bg(''); }
	}

        ,-oncelldraw => sub{
            my $cell=shift;
	    return $cell if($cell->id ne 'SALE');
            my $v=$cell->text;
            if(int($v) <  1000) {
                $cell->bg('red');
            } else { $cell->bg(''); }
	}


        ,-oncelllayout => sub{
            my $cell=shift;
	    			return $cell if($cell->id ne 'SALE');
	    			my $v=$cell->text;
	    			return $mask ?  $mask->format_picture($v,'### ### ###.##') : $v;
	}

   	,-onnextpage=> sub {
	    my $grid=shift;
	    my ($pgsize,$pg)=($grid->page_size,$grid->page);
	    
	    my $row=$grid->get_foused_row;
	    my $offset=$pgsize*$grid->page($pg+1);
	    if($offset < $#data) {
				fill_data($offset,$pgsize,\@data,$grid );
	    } else { $grid->page($pg);return 0; }
	    my $last_row=$grid->get_foused_row;
            $grid->focus_row($last_row,1,0) if($last_row ne $row);
	    return $grid;
	}

   	,-onprevpage=> sub {
	    my $grid=shift;
	    my ($pgsize,$pg)=($grid->page_size,$grid->page);
	    return 0 unless $pg;
	    my $offset=$pgsize*$grid->page($pg-1);
	    if($offset < $#data) {
		fill_data($offset,$pgsize,\@data,$grid );
	    } else { $grid->page($pg);return 0;}
	    return $grid;
	}

   	,-onrowfocus=> sub {
	    my $row=shift;
	    my $p=$row->parent->parent;
	      foreach my $k (qw(COUNTRY PROD SALE)) {
		    my $o=$p->getobj($k);
		    $o->text($row->get_value($k)) if(ref($o));
	      }
	}
    );

    $w{3}->add(undef, 'Label',-text=>'Country :',-x=>48,-y=>3,-width=>9);
    $w{3}->add(undef, 'Label',-text=>'Product :',-x=>48,-y=>4,-width=>9);
    $w{3}->add(undef, 'Label',-text=>'Sale :',-x=>48,-y=>5,-width=>9);


    $w{3}->add('COUNTRY', 'TextEntry',-x=>57,-y=>3,-sbborder=>1);
    $w{3}->add('PROD', 'TextEntry',-x=>57,-y=>4,-sbborder=>1);
    $w{3}->add('SALE', 'TextEntry',-x=>57,-y=>5,-sbborder=>1);
    

      $grid->add_cell("COUNTRY"
            ,-width=>8
            ,-label=>"Country" );

      $grid->add_cell("PROD"
            ,-width=>20
            ,-label=>"Product" );

      $grid->add_cell("SALE"
            ,-width=>15
	    ,-align=>'R'
            ,-label=>"Sale" 
	    ,-bg=>'green'
	    ,-fg=>'yellow');
    $grid->layout_content;


    for my $i (0 .. $#data) {
	my $ret=$grid->add_row(undef,
                    ,-fg=>'black'
                    ,-bg=>'yellow'
		    ,-cells=>{ %{$data[$i]} } );
	last unless defined $ret;
    }
    





my $file_menu = [
    { -label => 'Quit program',       -value => sub {exit(0)}        },
],

my $demo_menu = [
    { -label => 'Editable Grid',          -value   =>  sub{select_demo(1)}   },
    { -label => 'Frozen Grid',            -value   =>  sub{select_demo(2)}   },
    { -label => 'Browser',                 -value   =>  sub{select_demo(3)}   },
];

my $menu = [
    { -label => 'File',               -submenu => $file_menu         },
    { -label => 'Select demo',        -submenu => $demo_menu         },
];


$cui->add('menu', 'Menubar', -menu => $menu);


# ----------------------------------------------------------------------
# Setup bindings and focus
# ----------------------------------------------------------------------

sub goto_next_demo()
{
    $current_demo++;
    $current_demo = 3 if $current_demo > 3;
    $w{$current_demo}->focus;
}


sub goto_prev_demo()
{
    $current_demo--;
    $current_demo = 1 if $current_demo < 1;
    $w{$current_demo}->focus;
}


# Bind <CTRL+Q> to quit.
$cui->set_binding( sub{ exit }, "\cQ" );
$cui->set_binding( \&goto_next_demo, "\cN" );
$cui->set_binding( \&goto_prev_demo, "\cP" );

# Bind <CTRL+X> to menubar.
$cui->set_binding( sub{ shift()->root->focus('menu') }, "\cX" );





sub select_demo($;)
{
    my $nr = shift;
    $current_demo = $nr;
    $w{$current_demo}->focus;
}

sub fill_data($;) {
my $offset=shift;
my $limit=shift;
my $data=shift;
my $grid=shift;

    for my $i (0 .. $limit) {
          my $row=$grid->get_row( $grid->{_rows}[$i+1] );
	  next unless ref($row);

	  if($#{$data} <= $offset+$i) {
	    $row->hide;
	    $row->{-focusable}=0;
	    next;
	    }
	    $row->show;
	    $row->{-focusable}=1;

	  $row->set_values( %{$$data[$offset+$i]} );
    }
}


&select_demo(1);

MainLoop;

