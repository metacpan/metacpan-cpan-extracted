package Ante::Deluvian::Dialog;

use strict;
use warnings;
use Term::ReadKey;
use Text::Wrap qw($columns wrap);
use IO::File;

our $VERSION = 0.02;
sub FALSE { return 0; }
sub TRUE  { return 1; }
my $_isWin = FALSE;
my $_doRec = FALSE;
my $_rplay = FALSE;
my $_fhInp = undef;
my $_fhRec = undef;

#------------------------------------------------------------------
sub new {
#------------------------------------------------------------------ 
  my $class = shift;
  my %param = @_; 
	my $self = {};
  my ($iCols, $iRows);
  
  $self = bless {}, $class;
  $self->{'rows'} = 25;
  $self->{'cols'} = 80;
  $self->{'stat'} = 0;
  $self->{'from'} = 1;
  $self->{'eoln'} = "";
  $self->{'curpid'}   = $$,
  $self->{'getdrv'}   = \&_procDfCmd,
  $self->{'usable'}   = 25;
  $self->{'hcenter'}  = 12;
  $self->{'vcenter'}  = 40;
  $self->{'recary'}   = [];
  $self->{'parind'}   = $param{parindent} || 2;
  $self->{'title'}    = $param{title}     || undef;
  $self->{'header'}   = $param{header}    || " ";
  $self->{'prompt'}   = $param{prompt}    || ":";
  $self->{'platform'} = $param{platform}  || "UNIX";
  $_isWin = $param{platform} eq "MSWIN";
  $_doRec = $param{record}   || FALSE;
  $_fhInp = $param{inpfile}  || undef;
  if ((exists($param{replay})) && (-s $param{replay})) {
    my $fi = IO::File->new("< $param{replay}");
    @{$self->{'recary'}} = <$fi>;
    $fi->close();
    $_rplay = TRUE;
  }
  $self->_getWinSize();
  $self->{'usable'} = $self->{'rows'};
  if (defined($self->{'header'})) {
    $self->{'usable'}--;
    $self->{'stat'}++;
    $self->{'from'}++;
  }
  if (defined($self->{'prompt'})) {
    $self->{'usable'}--;
  }
  $self->{'hcenter'} = int ($self->{'cols'} / 2);
  $self->{'vcenter'} = int (($self->{'usable'} - $self->{'from'}) / 2);
  $self->{'lines'} = $self->_drawframe();
  $self->{'usable'} -= 2;
  return $self;
}

#------------------------------------------------------------------
sub DESTROY {
#------------------------------------------------------------------
  my $self = shift;
  
  if ($_doRec) {
    $self->_createRecFile();
    print $_fhRec "@{$self->{'recary'}}\n";
  }
}

#------------------------------------------------------------------
sub _getWinSize {
#------------------------------------------------------------------
  my $self = shift;
  my ($maxCol, $maxRow);
  
  if ($_isWin) {
    require Win32::Console;
    my $cns = new Win32::Console();
    my @info =$cns->Info();
    ($maxCol, $maxRow) = $cns->MaxWindow();
    $self->{'gdrv'} = \&_procNetUse;
    $self->{'eoln'} = "\n";
  }
  else {
    ($maxCol, $maxRow) = GetTerminalSize();
  }
  $self->{'cols'} = $maxCol;
  $self->{'rows'} = $maxRow;
}

#------------------------------------------------------------------
sub _createRecFile {
#------------------------------------------------------------------
  my $self  = shift;
  my $tmpth = $_isWin ? "C:/temp/addialog" : "/tmp/addialog";
  my $tmpf  = sprintf("%s/%s_%d", $tmpth, $_isWin ? $ENV{USERNAME} : $ENV{USER}, $self->{'curpid'});
  
  if (! -d $tmpth) {
    mkdir($tmpth);
  }
  $_fhRec = IO::File->new("> $tmpf");
  print "File $tmpf created to record user input ...\n";
}

#------------------------------------------------------------------
sub _drawframe {
#------------------------------------------------------------------
  my $self = shift;
  my $rows = $self->{'rows'} - 1;
  my $cols = $self->{'cols'} - 2;
  my ($line, @lines, $inp);
  
  if (defined($self->{'prompt'})) {
    $rows--;
  }
  for my $i (0 .. $rows) {
    if (($i == 0) || ($i == $rows)) {
      push @lines, "+" . "-" x $cols . "+";
    }
    else {
      push @lines, "|" . " " x $cols . "|";
    }
  }
  if (defined($self->{'title'})) {
    _formatline(\$lines[0], $self->{'title'}, "C");
  }
  if (defined($self->{'prompt'})) {
    push @lines, "$self->{'prompt'} ";
  }
  return [ @lines ];
}

#------------------------------------------------------------------
sub _doselection {
#
# This function is likely to be called recursively ...
#------------------------------------------------------------------
  my $self  = shift;
  my %param = @_;
  
  my $rpag = $param{pagary};
  my $rsel = $param{selary};
  my $inpt = $param{input};
  my $mode = $param{selmod};
  
  my $j = int($inpt / $self->{'usable'}) + 1;
  my $k = int($inpt % $self->{'usable'}) + $self->{'from'};
  print "_doselection (..., $inpt, $mode)   j = $j   k = $k ...\n";
  if ($mode eq "single") {
    if (defined($rsel->[0])) {
      $self->_doselection(
              selary => $rsel,
              pagary => $rpag,
              input  => $rsel->[0],
              selmod => "discard",
      );
    }
    $self->_doselection(
            selary => $rsel,
            pagary => $rpag,
            input  => $inpt,
            selmod => "select",
    );
    $rsel->[0] = $inpt;
  }
  elsif ($mode eq "multi") {
    $self->_doselection(
            selary => $rsel,
            pagary => $rpag,
            input  => $inpt,
            selmod => "toggle",
    );
  }
  elsif ($mode eq "toggle") {
    if (substr($rpag->[$j][$k], 2, 1) eq " ") {
      substr($rpag->[$j][$k], 2, 1) = "*";
      $rsel->[$inpt + 1] = 1;
    }
    else {
      substr($rpag->[$j][$k], 2, 1) = " ";
      $rsel->[$inpt + 1] = 0;
    }
  }
  elsif ($mode eq "discard") {
    substr($rpag->[$j][$k], 2, 1) = " ";
    $rsel->[$inpt + 1] = 0;
  }
  elsif ($mode eq "select") {
    substr($rpag->[$j][$k], 2, 1) = "*";
    $rsel->[$inpt + 1] = 1;
  }
  elsif ($mode eq "all") {
    foreach my $elm (1 .. $#$rsel) {
      $self->_doselection(
              selary => $rsel,
              pagary => $rpag,
              input  => $elm - 1,
              selmod => "select",
      );
    }
  }
  elsif ($mode eq "clear") {
    foreach my $elm (1 .. $#$rsel) {
      $self->_doselection(
              selary => $rsel,
              pagary => $rpag,
              input  => $elm - 1,
              selmod => "discard",
      );
      $rsel->[0] = undef;
    }
  }
}

#------------------------------------------------------------------
sub _getDrives {
#------------------------------------------------------------------
  my $self  = shift;
  my (@drives, @drvlst, $line, $cmd, $pattern, $drv,
      %windrv,
  );
  
  if ($_isWin) {
    for $drv ("A" .. "Z") {
      $windrv{"$drv:"} = 0;
    }
    $cmd = "net use";
    $pattern = "\\A\\w+\\s+([A-Z]:)\\s+(\\\\\\\\\\S+)";
  }
  else {
    $cmd = "df | awk '{ print \$NF }'";
    $pattern = "%\\s+(\/\\S*)\\z";
  }
  open(SYST, "$cmd |");
  while ($line = <SYST>) {
    if ($line =~ /$pattern/) {
      push @drives, "$1/";
      push @drvlst, "$1/  $2";
      if (exists($windrv{$1})) {
        delete($windrv{$1});
      }
    }
  }
  close(SYST);
  if ($_isWin) {
    foreach $drv (keys %windrv) {
      if (-d "$drv/") {
        push @drives, "$drv/";
        push @drvlst, "$drv/  Local directory";
      }
    }
  }
  @drvlst = sort(@drvlst);
  $drv = $self->listbox(\@drvlst, select => "atonce", prompt => "Please select a drive or partition:");
  if ($_isWin && ($drv =~ /\A([A-Z]:\/)\s+/)) {
    $drv = $1;
  }
  elsif ($drv =~ /\A(\/\S*)/) {
    $drv = $1;
  }
  else {
    $drv = undef;
  }
  # print "Selected drive: $drv ...\n";
  return($drv);
}

#------------------------------------------------------------------
sub printscreen {
#------------------------------------------------------------------
  my $self   = shift;
  my $rlines = shift;
  my (@lines, $prompt);
  
  if (defined($rlines)) {
    @lines = @$rlines;
  }
  else {
    @lines = @{$self->{'lines'}};
  }
  if (defined($self->{'prompt'})) {
    $prompt = pop(@lines);
  }
  foreach my $line (@lines) {
    print "$line" . $self->{'eoln'};
  }
  if (defined($prompt)) {
    print "$prompt ";
  }
}

#------------------------------------------------------------------
sub _getinput {
#------------------------------------------------------------------
  my $self   = shift;
  my $rLines = shift;
  
  $self->printscreen($rLines);
  if ($_rplay && ($#{$self->{'recary'}} >= 0)) {
    $self->{'input'} = shift(@{$self->{'recary'}});
    print "$self->{'input'}";
  }
  else {
    $self->{'input'} = <STDIN>;
  }
  chomp($self->{'input'});
  if ($_doRec) {
    # print $self->{'recfile'} "$self->{'input'}";
    push @{$self->{'recary'}}, $self->{'input'};
  }
}

#------------------------------------------------------------------
sub _clearselection {
#------------------------------------------------------------------
  my $self = shift;
}

#------------------------------------------------------------------
sub _formatline {
#------------------------------------------------------------------
  # my $self = shift;
  my $line = shift;
  my $text = shift;
  my $frmt = shift;
  my ($llng, $ltxt, $beg);
  
  $llng = length($$line);
  $ltxt = length($text);
  if ($llng > $ltxt) {
    if ($frmt eq "C") {
      $beg = int(($llng - $ltxt) / 2);
    }
    elsif ($frmt eq "R") {
      $beg = $llng - $ltxt - 1;
    }
    elsif ($frmt eq "L") {
      $beg = 1;
    }
    elsif ($frmt =~ /\A(\d+)/) {
      $beg = $1;
    }
  }
  else {
    $text = substr($text, 0, $llng - 5) . "...";
    $ltxt = length($text);
    $beg  = 1;
  }
  # print "LINE: $$line\nTEXT: $text\nFRMT: $frmt BEG: $beg LTXT: $ltxt\n";
  substr($$line, $beg, $ltxt, $text);
}

#------------------------------------------------------------------
sub alert {
#------------------------------------------------------------------
  my $self    = shift;
  my $rAlert  = shift;
  my $rLines  = shift || undef;
  my ($i, $beg, @lines,
  );
  
  if (defined($rLines)) {
    @lines = @$rLines;
  }
  else {
    @lines = @{$self->{'lines'}};
  }
  if (defined($self->{'prompt'})) {
    $lines[-1] = $rAlert->[0];
  }
  $beg = $self->{'vcenter'} - int(($#$rAlert - 1) / 2);
  for $i (1 .. $#$rAlert) {
    _formatline(\$lines[$beg + $i - 1], $rAlert->[$i], "C");
  }
  $self->_getinput(\@lines);
}

#------------------------------------------------------------------
sub listbox {
#------------------------------------------------------------------
  my $self    = shift;
  my $rList   = shift;
  my %param = @_;
  my ($i, $j, $k, $nelm, $nopg, @pages, $len, $elm,
      $entry, $currpg, $inp, @inps, @lines, $rpage, $selmode,
      @selary, $isTxt, $rLines,
  );
  
  $rLines  = $param{lines}  || undef;
  $selmode = $param{select} || "single";
  if ((defined($param{input})) && ($param{input} eq "text")) {
    $isTxt = TRUE;
  }
  else { $isTxt = FALSE; }
  $nelm = $#$rList + 1;
  if (0 == $nelm) { return; }
  else {
    $selary[0] = undef;
    for $i (1 .. $nelm) {
      $selary[$i] = 0;
    }
  }
  if (defined($rLines)) {
    @lines = @$rLines;
  }
  else {
    @lines = @{$self->{'lines'}};
  }
  if ((exists($param{'prompt'})) && (defined($self->{'prompt'}))) {
    $lines[-1] = $param{'prompt'};
  }
  $len = length($nelm);
  $nopg = int($nelm / $self->{'usable'});
  if ($nelm % $self->{'usable'} > 0) { $nopg++; };
  print "List contains $nelm elements and will result in $nopg pages ...\n";
  for $i (1 .. $nopg) {
    $pages[$i] = [ @lines ];
    _formatline(\$pages[$i]->[$self->{'stat'}], "Page $i from $nopg ...", "R");
  }
  $i = 0;
  foreach $elm (@$rList) {
    # $i++;
    $j = int($i / $self->{'usable'}) + 1;
    $k = int($i % $self->{'usable'});
    $rpage = $pages[$j];
    $i++;
    if ($isTxt) {
      $entry = $elm;
    }
    else {
      $entry = sprintf(" %*d. %s", $len, $i, $elm);
    }
    # print "_formatline(rpage->[$k], $entry)\n";
    _formatline(\$rpage->[$self->{'from'} + $k], $entry, "3");
  }
  $currpg = 1;
  LISTBOX:
  while (TRUE) {
    $self->_getinput($pages[$currpg]);
    $inp = $self->{'input'};
    @inps = split(/\s+/, $inp);
    foreach $inp (@inps) {
      # if (($inp =~ /\A\d+\z/) && ($inp >= 1) && ($inp <= $#$rList)) {
      if (($inp =~ /\A\d+\z/) && ($inp >= 1) && ($inp <= $nelm)) {
        if ($selmode eq "atonce") {
          return $rList->[$inp - 1];
        }
        $self->_doselection(
                selary => \@selary,
                pagary => \@pages,
                input  => $inp - 1,
                selmod => $selmode,
              );
      }
      elsif (($inp =~ /\A(\d+)-(\d+)/)) {
        my ($from, $to) = ($1, $2);
        $to = $nelm if ($to > $nelm);
        for $i ($from .. $to) {
          $self->_doselection(
                  selary => \@selary,
                  pagary => \@pages,
                  input  => $i - 1,
                  selmod => $selmode,
              );
        }
      }
      elsif (($inp =~ /\A[Aa][Ll][Ll][Ee]?\z/) && ($selmode eq "multi")) {
        $self->_doselection(
                selary => \@selary,
                pagary => \@pages,
                input  => 0,
                selmod => "all",
              );
      }
      elsif ($inp =~ /\A[Cc][Ll][EeAa]*[Rr]\z/) {
        $self->_doselection(
                selary => \@selary,
                pagary => \@pages,
                input  => 0,
                selmod => "clear",
              );
      }
      elsif ($inp =~ /\A:?[nNvV]/) {
        if ($currpg < $nopg) {
          $currpg++;
        }
      }
      elsif ($inp =~ /\A:?[pPrR]/) {
        if ($currpg > 1) {
          $currpg--;
        }
      }
      elsif ($inp =~ /\A:(\d+)\z/) {
        $inp = $1;
        if (($inp >= 1) && ($inp <= $nopg)) {
          $currpg = $inp;
        }
      }
      elsif ($inp =~ /\A:?[Oo][Kk]\z/) {
        return("OK") if ($selmode ne "multi");
        last LISTBOX;
      }
      elsif ($inp =~ /\A:?[Ee][Ss][Cc]\z/) {
        return(undef);
        # last LISTBOX;
      }
    }
  }
  @lines = ();
  for $i (1 .. $nelm) {
    if ($selary[$i] > 0) {
      push @lines, $rList->[$i - 1];
    }
  }
  return(@lines);
}

#------------------------------------------------------------------
sub radiolist {
#------------------------------------------------------------------
  my $self    = shift;
  my $rRadLst = shift;
  my %param   = @_;
  my ($i, $inp, $beg, $line, $lng, @radlist, @lines,
      $selected, $mark, $radio, $rLines,
  );
  
  $rLines  = $param{'lines'} || undef;
  if (defined($rLines)) {
    @lines = @$rLines;
  }
  else {
    @lines = @{$self->{'lines'}};
  }
  RADIO:
  while (TRUE) {
    @radlist = ();
    if (defined($rRadLst->[0]->[0])) {
      push @radlist, "$rRadLst->[0]->[0]";
      $lng = length($rRadLst->[0]->[0]);
      if ($rRadLst->[0]->[1]) {
        push @radlist, "-" x $lng;
      }
    }
    for $i (1 .. $#$rRadLst) {
      if ($rRadLst->[$i]->[2] == 1) {
        $mark = "X";
        $selected = $i;
      }
      else {
        $mark = " ";
      }
      $line = sprintf ("%2d. (%s) %s", $i, $mark, $rRadLst->[$i]->[0]);
      push @radlist, "$line";
    }
    $beg = $self->{'vcenter'} - int(($#radlist - 1) / 2);
    for $i (0 .. $#radlist) {
      _formatline(\$lines[$beg + $i], $radlist[$i], "3");
    }
    $self->_getinput(\@lines);
    $inp = $self->{'input'};
    if ($inp =~ /:?[Oo][Kk]/) {
      $radio = $rRadLst->[$selected]->[1];
      last RADIO;
    }
    elsif ($inp =~ /:?[Ee][Ss][Cc]/) {
      $radio = undef;
      last RADIO;
    }
    elsif (($inp >= 1) && ($inp <= $#$rRadLst)) {
      $rRadLst->[$selected]->[2] = 0;
      $rRadLst->[$inp]->[2]      = 1;
    }
  }
  return $radio;
}

#------------------------------------------------------------------
sub _select {
#------------------------------------------------------------------
  my $self   = shift;
  my $start  = shift;
  my $fmode  = shift;
  my $rLines = shift;
  my %hmodes = (
    "FILE" => [ "atonce", "Please select a file:"               ],
    "DIR"  => [ "atonce", "Please select a directory:"          ],
    "MULT" => [ "multi",  "Please select one or more entities:" ],
  );
  my (@files, $file, @flist, $inp, @lines, $stln,
  );
  
  if (defined($rLines)) {
    @lines = @$rLines;
  }
  else {
    @lines = @{$self->{'lines'}};
  }
  if (defined($self->{'prompt'})) {
    $lines[-1] = $hmodes{$fmode}[1];
  }
  if ((!defined($start)) || ($start eq "")) {
    $start = $self->_getDrives();   
  }
  elsif ($start !~ /[\\\/]\z/) {
    $start .= "/";
  }
  print "fselect(..., $start, ...)\n";
  while (TRUE) {
    @files = ();
    @flist = ();
    opendir (DIR, "$start");
    @files = readdir(DIR);
    closedir(DIR);
    foreach $file (sort @files) {
      if ($file eq ".") {
        next;
      }
      elsif (-d "$start/$file") {
        push @flist, "$file/";
      }
      elsif ((-f "$start/$file") && ($fmode ne "DIR")) {
        push @flist, $file;
      }
    }
    $stln = sprintf("%-*s", $self->{'cols'} - 2, $start);
    _formatline(\$lines[$self->{'stat'}], $stln, "L");
    $inp = $self->listbox(\@flist, lines => \@lines, select => $hmodes{$fmode}[0]);
    if (defined($inp)) {
      print "FSEL: $inp\n";
      if ($inp =~ /\A\.\.[\\\/]*/) {
        @files = split(/[\\\/]+/, $start);
        $start = $files[0];
        pop(@files); shift(@files);
        $start = join "/", $start, @files, "";
      }
      elsif (-d "$start/$inp") {
        $start .= $inp;
      }
      elsif (-f "$start/$inp") {
        return("$start$inp");
      }
      elsif ($inp eq "OK") {
          return($start);
      }
      print "Neues Verzeichnis: $start ...\n";
    }
    else {
      return(undef);
    }
  }
}

#------------------------------------------------------------------
sub fselect {
#------------------------------------------------------------------
  my $self   = shift;
  my $start  = shift;
  my $rLines = shift;
  my $fmode  = shift || "FILE";
  
  $self->_select($start, $fmode, $rLines);
}

#------------------------------------------------------------------
sub dselect {
#------------------------------------------------------------------
  my $self   = shift;
  my $start  = shift;
  my $rLines = shift;
  my $fmode  = "DIR";
  
  my $dir = $self->_select($start, $fmode, $rLines);
  return($dir);
}

#------------------------------------------------------------------
sub textbox {
#------------------------------------------------------------------
  my $self   = shift;
  my $itxt   = shift;
  my %param  = @_;
  my $text   = undef;
  my $doFmt  = $param{keepformat} || TRUE;
  my @stNames = qw(
      dev ino mode nlink uid gid rdev size
      atime mtime ctime blksize blocks
  );
  my (@lines, $fmtxt, $pref,
      @txtlns, @filstat,
  );
  
  if (!defined($itxt)) {
    return;
  }
  $pref = ref($itxt);
  if ($pref eq "ARRAY") {
    @txtlns = @$itxt; 
  }
  elsif ($pref eq "SCALAR") {
    $text = $$itxt;
    # @txtlns = split(/\n/, $$itxt);
  }
  elsif ($pref eq "IO::File") {
    @txtlns = <$itxt>;
  }
  elsif (($pref eq "") && (-f $itxt)) {
    my $fi = IO::File->new("< $itxt");
    if (-T $itxt) {
      @txtlns = <$fi>;
    }
    else {
      #$/ = "\0";
      #while (<$fi>) {
      #  while (/([\040-\176\s]{4,})/g) {
      #    push @txtlns, $1;
      #  }
      #}
      $doFmt = FALSE;
      @filstat = stat($itxt);
      @txtlns  = ( "$itxt", "appears to be a binary file ...", "");
      foreach my $i (0 .. $#filstat) {
        push @txtlns, sprintf("%-10s  ->  %s", $stNames[$i], $stNames[$i] =~ /time/ ? scalar localtime($filstat[$i]) : $filstat[$i]);
      }
    }
    $fi->close();
  }
  if ($doFmt) {
    if (!defined($text)) {
      $text = join "", @txtlns;
    } 
    $text =~ s/\n\n+/#PAR#/g;
    $text =~ tr/[\n\t ]/ /s;
    print "$text\n";
    $text =~ s/#PAR#/\n\n/g;
    $text =~ s/#LN#/\n/g;
    @txtlns = split(/\t/, $text);
    $columns = $self->{'cols'} - 4;
    $text = wrap("", "", @txtlns);
    @lines = split(/\n/, $text);
  }
  else {
    @lines = @txtlns;
  }
  print "Maximal $columns Spalten ...\n\n@lines\n";
  $self->listbox(\@lines, input => "text");
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Ante::Deluvian::Dialog - Perl extension for very old style user interaction

=head1 SYNOPSIS

  use Ante::Deluvian::Dialog;
  
  $d = Ante::Deluvian::Dialog->new(
    platform  => "MSWIN",
    drawframe => 1,
    title     => "Title of Window",
    prompt    => "Please make your choice:",
    # record    => 1,
    # replay    => "C:/temp/addialog/<username>_<pid>.txt",
  );

  $fdir  = $d->dselect();
  print "You have selected directory $fdir ...\n";
  
  $fname = $d->fselect($fdir);
  print "You have selected file $fname ...\n";
  
  @aLst = ( "A" .. "Z", "a" .. "z" );
  @aRes = $d->listbox(\@aLst, select => "multi");
  
  $rd = $d->radiolist([
		[ "List of radio buttons", 1, ],
		[ "red",    "RED", 0 ],
		[ "green",  "GRN", 1 ],
		[ "blue",   "BLU", 0 ],
		[ "yellow", "YLW", 0 ],
	]);

  $d->alert([
  	"Press <RETURN> to continue ...",
  	"Attention! This is considered to be",
  	"an alert box (see below) ...",
  	"The recent radio list resulted in $rd",
  ]);

  if (-T $fname) {
    $inpf = IO::File->new($fname);
    $d->textbox($inpf);
  }
  else {
    $d->textbox($fname);
  }

=head1 CONSTRUCTOR

=over 4

=item new (platform => "MSWIN", title => "Window's title", prompt => "What do you want");

There are two other options C<record>, which can be set to a boolean value, and C<replay>, which
expects to get some previously recorded input file. This is mainly for testing purposes, if you
don't like to repeat a special input sequence by hand... I'm sure you will find out if this is
interesting to you.

=back

=head1 DESCRIPTION

After several attempts to get curses running on windows (without having to install cygwin),
I made up my mind to do some programming to get a pure ASCII based and very simple dialog
window.

I'm sure there won't be many users preferring this kind of interface, but I don't want to
be obliged to produce some GUI just for controling or testing communication.

Whoever will try this program, will think that I have gone mad, and he will certainly be
right.

=head1 SEE ALSO

There are many packages with much more comfort, e. g. UI::Dialog, but they didn't do what
I really wanted ...

=head1 AUTHOR

Berthold H. Michel, E<lt>berthold.michel@freenet.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by B. H. Michel

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
