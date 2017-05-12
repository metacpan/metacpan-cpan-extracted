#!/usr/bin/perl

use strict;
use Getopt::Long;
use File::Spec;
use IO::Dir;
use Bio::Graphics::Panel;
use Bio::Graphics::Feature;
use File::Temp 'tempfile';
use Bio::Graphics::Wiggle;

my $MANUAL = 0;
my $POD    = 0;
my $LIST   = 0;
my $PICT   = 0;
my $VIEW   = 0;
my $BOXES  = 0;
my $SVG    = 0;

my $usage = <<USAGE;
Usage: $0 [options] glyph_type 

Give usage information about Bio::Graphics glyphs.

 Options:
    -m --manual   Print the full manual page for the glyph, followed
                     by a summary of its options.
    -r --raw      Print the quick summary of the glyph\'s options in raw POD
                     format.
    -l --list     List all glyphs that are available for use.
    -p --picture  Create a PNG picture of what the indicated glyph looks like.
                    The PNG will be written to stdout
    -v --view     Launch a viewer ("xv", "display" or "firefox") to show the
                    glyph.
    -b --boxes    Outline the boxes around each glyph
    --svg         When used in conjunction with --picture, will create
                    an SVG rather than a png using GD::SVG

If neither -m nor -l are specified, the default is to print a summary
of the glyph\'s options.

To experiment with glyph options, invoke $0 this way:

   $0 -v glyph_name -- -option1 value1 -option2 value2

example:

   $0 -v christmas_arrow -- -radius 5 -fgcolor green
USAGE

GetOptions ('manual'   => \$MANUAL,
	    'raw'      => \$POD,
	    'list'     => \$LIST,
	    'picture'  => \$PICT,
	    'view'     => \$VIEW,
	    'boxes'    => \$BOXES,
	    'svg'      => \$SVG,
	   ) or die $usage;

my $glyph = shift;
$glyph || $LIST or die $usage;

if ($LIST) {
    print_list();
    exit 0;
}

my $class = "Bio::Graphics::Glyph::$glyph";
unless (eval "require $class;1") {
    my $mesg = $@;
    $mesg    =~ s/\(.+$//;
    $mesg    =~ s/at \(eval.+$//;
    $mesg    =~ s/\s+$//s;
    warn $mesg,".\n";
    die "Please run $0 -l for a list of valid glyphs.\n";
}

if ($PICT || $VIEW) {
    print_picture($glyph,$VIEW,$SVG);
    exit 0;
}

if ($MANUAL) {
    system "perldoc",$class;
} elsif ($POD) {
    print $class->options_pod();
} else {
    print $class->options_man();
}
exit 0;

sub print_list {
    my %glyphs;
    for my $inc (@INC) {
	my $dir = File::Spec->catfile($inc,'Bio','Graphics','Glyph');
	next unless -d $dir;
	my $d = IO::Dir->new($dir) or die "Couldn't open $dir for reading: $!";
	while (defined(my $entry = $d->read)) {
	    next unless $entry =~ /\.pm$/;
	    (my $base = $entry) =~ s/\.pm$//;
	    eval "use Bio::Graphics::Glyph::$base";
	    next unless "Bio::Graphics::Glyph::$base"->isa('Bio::Graphics::Glyph');
	    my $f  = File::Spec->catfile($dir,$entry);
	    my $io = IO::File->new($f) or next;
	    while (<$io>) {
		chomp;
		next unless /^=head1 NAME/../=head1 (SYNOPSIS|DESCRIPTION)/;
		my ($name,$description) = /^Bio::Graphics::Glyph::(\w+)\s+(.+)/ or next;
		$description =~ s/^[\s-]+//;
		next if $description =~ /base class/;
		$glyphs{$name} = $description;
	    }
	}
    }
    for my $name (sort keys %glyphs) {
	my $description = $glyphs{$name};
	printf "%-20s %s\n",$name,$description;
    }

    exit 0;
}

sub print_picture {
    my $glyph  = shift;
    my $viewit = shift;
    my $svg    = shift;

    my $panel = Bio::Graphics::Panel->new(-length => 500,
					  -width  => 250,
					  -pad_left => 20,
					  -pad_right => 20,
					  -pad_top   => 10,
					  -pad_bottom => 10,
					  -key_style  => 'between',
					  -truecolor  => 1,
					  -image_class => $svg ? 
					            'GD::SVG' : 'GD'
	);


    my @additional_args = @ARGV;

    my $sort_order = sub ($$) {
	my ($g1,$g2) = @_;
	return $g1->feature->display_name cmp $g2->feature->display_name;
    };

    my @track_args = (
	-glyph => $glyph,
	-label       => 1,
	-description => 1,
	-height      => 16,
	-sort_order  => $sort_order,
	@additional_args
	);

    my $class = "Bio::Graphics::Glyph::$glyph";
    eval "require $class";
    warn $@ if $@;

    my @example_features = eval{$class->demo_feature};
    warn $@ if $@;

    if (@example_features) {
	$panel->add_track(
	    \@example_features,
	    @track_args,
	    -key         => 'Demo feature provided by glyph',
	    );
    } else {
	create_tracks($panel,$glyph,\@track_args);
    }

    if ($BOXES) {
	my $gd    = $panel->gd;
	my $boxes = $panel->boxes;
	for my $box (@$boxes) {
	    my ($f,$x1,$y1,$x2,$y2) = @$box;
	    my $red = $panel->translate_color('red');
	    $gd->rectangle($x1,$y1,$x2,$y2,$red);
	}
    }

    my $png = $svg ? $panel->svg : $panel->png;
    unless ($viewit) {
	print $png;
	return;
    }
    
    # special stuff for displaying on linux systems
    for my $viewer (qw(xv display)) { # can read from stdin
	$ENV{SHELL} && `which $viewer` or next;
	my $child = open my $fh,"|-";
	if ($child) {
	    print $fh $png;
	    close $fh;
	    return;
	} else {
	    fork() && exit 0;
	    exec $viewer,'-';
	}
    }

    # if we get here, then launch firefox
    my ($fh,$filename) = tempfile(SUFFIX=>'.png',
				  UNLINK=>1,
	);
    print $fh $png;
    close $fh;
    my $child = fork() && sleep 2 && exit 0;
    exec 'firefox',$filename;
}

sub create_tracks {
    my ($panel,$glyph,$args) = @_;

    # the next bit of code is here to manufacture some wiggle data for demo purposes
    my $wig = Bio::Graphics::Wiggle->new(undef,
					 1,
					 {seqid=>'chr1',
					  start=>1,
					  end  =>500}
	);
    my @values = map {
	(sin($_/60)+sin($_/12))*100+rand(100)
    } 1..500;
    if (eval "require Statistics::Descriptive; 1") {
	my $stat = Statistics::Descriptive::Sparse->new;
	$stat->add_data(@values);
	$wig->min($stat->min);
	$wig->max($stat->max);
	$wig->mean($stat->mean);
	$wig->stdev($stat->standard_deviation);
    } else {
	my $min = $values[0];
	my $max = $values[0];
	my $tot = 0;
	for (@values) {$min = $_ if $min > $_;
		       $max = $_ if $max < $_;
		       $tot += $_;
	}
	$wig->min($min);
	$wig->max($max);
	$wig->stdev(120); # just make it up
	$wig->mean($tot/@values);
    }
    $wig->set_value($_=>$values[$_-1]) for(1..500);
    
    my $f0   = Bio::Graphics::Feature->new(-start => 1,
					   -end   => 30,
					   -score => 10,
					   -strand=> +1,
					   -source => 'confirmed',
					   -type  => 'UTR',
	);
    my $f1   = Bio::Graphics::Feature->new(-start => 31,
					   -end   => 100,
					   -score => 20,
					   -strand=> +1,
					   -source => 'confirmed',
					   -type  => 'CDS',
	);
    my $f2   = Bio::Graphics::Feature->new(-start => 200,
					   -end   => 300,
					   -score => 30,
					   -strand=> +1,
					   -source=> 'unconfirmed',
					   -type  => 'CDS',
	);
    my $f3   = Bio::Graphics::Feature->new(-start => 400,
					   -end   => 450,
					   -score => 40,
					   -strand=> +1,
					   -source=> 'unconfirmed',
					   -type  => 'CDS',
	);
    my $f4   = Bio::Graphics::Feature->new(-start => 451,
					   -end   => 500,
					   -score => 50,
					   -strand=> +1,
					   -source=>'confirmed',
					   -type  => 'UTR',
	);

    my $feature1 = Bio::Graphics::Feature->new(-type=>'mRNA',
					       -name=>'f1',
					       -desc=>'This is a one-level feature',
					       -strand=>+1,
					       -start=>1,
					       -end=>500,
					       -attributes=>{
						   wigfile=>$wig,
						   wigfileA=>$wig,
						   wigfileB=>$wig,
					       }
	);
    my $feature2 = Bio::Graphics::Feature->new(-type=>'mRNA',
					      -name=>'f2',
					      -desc=>'This is a two-level feature',
					      -strand=>+1,
					      -attributes=>{
						  wigfile=>$wig,
						  wigfileA=>$wig,
						  wigfileB=>$wig,
					      }
	);
    my $feature3 = Bio::Graphics::Feature->new(-type=>'mRNA',
					       -name=>'f3',
					       -desc=>'This is a two-level feature',
					       -strand=>+1,
					       -attributes=>{
						   wigfile=>$wig,
						   wigfileA=>$wig,
						   wigfileB=>$wig,
					       }
	);
					       
    $feature2->add_SeqFeature($_) foreach ($f0,$f1,$f2,$f3,$f4);
    $feature3->add_SeqFeature($_) foreach ($f0,$f1,$f3,$f4);

    my $feature4 = Bio::Graphics::Feature->new(-type=>'gene',
					       -name=>'f4',
					       -desc=>'This is a three-level feature',
					       -attributes=>{
						   wigfile=>$wig,
						   wigfileA=>$wig,
						   wigfileB=>$wig,
					       }
	);
    $feature4->add_SeqFeature($feature2,$feature3);
    
    $panel->add_track([$feature1,$feature2,$feature4],
		      @$args,
		      -key         => 'No connector',
	);

    $panel->add_track([$feature1,$feature2,$feature4],
		      @$args,
		      -connector   => 'dashed',
		      -key         => 'Dashed connector',
	);
}


1;


