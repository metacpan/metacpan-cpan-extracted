package Bio::Maxd;

require 5.005_62;
use strict;
use warnings;
use File::Basename;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);
our $VERSION = '0.04';

sub new {
  my $self=shift;
  my $class=ref($self) || $self;
  my(%data,$tag);
  while (@_) {$tag = shift; if ($tag =~ /^-/) {$tag =~ s/^-//;$data{lc($tag)} = shift;}}
  $data{'dbase'} = "maxd" if (!$data{'dbase'});
  if (!$data{'host'}) {
    use Sys::Hostname;
    my $hostname = hostname();
    $data{'host'} = $data{'host'} || $ENV{'MAXD_HOSTDB'} || $hostname || "localhost";
  }
  if (!$data{'user'} || !$data{'pass'}) { 
    ($data{'user'},$data{'pass'}) = split(/\//,$ENV{'MAXD_USERID'});
  }
  $data{'dbh'} = _dbconnect ($data{'host'},$data{'dbase'},$data{'user'},$data{'pass'}); 
  # verify special tables
  my($ok,$tname);
  my $st = "show tables";
  my $sh = $data{'dbh'}->prepare($st);
  my $rv = $sh->execute;
  while($tname= $sh->fetchrow_array) {
    if ($tname =~ /^Image_Seq$/i) { $ok = 1; last; }
  }
  if (!$ok) {
    print STDERR "WARNING: Run 'extendMaxD' to configure database\n";
    $data{'dbh'} = undef;
  }
  $self = bless {} => $class;
  foreach $tag (keys %data) { $self->{$tag} = $data{$tag}; }
  return $self;
}

sub export { 
  my $self=shift;
  my(%data,$tag);
  foreach $tag (keys %{$self}) { $data{$tag} = $self->{$tag};}
  while (@_) {$tag = shift; if ($tag =~ /^-/) {$tag =~ s/^-//;$data{lc($tag)} = shift;}}
  return 0 if (ref($data{'dbh'}) ne "DBI::db");

  # valid submitter ?
  ($data{'submitter_id'},$data{'submitter_name'}) =
            _submitterFromSubmitterData($data{'dbh'},$data{'submitter'});
  return (_error(501,$data{'submitter'})) if ($data{'submitter_id'}< 0);
  print "Submitter:\tname:$data{'submitter_name'}\tID:$data{'submitter_id'}\n"
        if ($data{'verbose'});

  # valid repository URL ?
  $data{'repository_url'} = "." if (!-d $data{'repository_url'});
  $data{'repository_url'} .= "/" . $data{'submitter_name'};
  $data{'repository_url'} =~ s/ +/_/g;
  mkdir($data{'repository_url'},0755);

  # valid experiment ?  
  return 0 if (!$data{'experiment'});
  ($data{'experiment_id'},$data{'experiment_name'})
       = _experimentIDfromExperiment($data{'dbh'},$data{'experiment'},
       $data{'submitter_id'});
  return (_error(502,"experiment $data{'experiment'} unknown"))
        if ($data{'experiment_id'} < 0);
  print "Experiment:\tname:$data{'experiment_name'}\tID:$data{'experiment_id'}\n"
        if ($data{'verbose'});

  # valid array type ?
  return 0 if (not defined $data{'array_type'});
  $data{'array_name'} = $data{'array_type'} if (!$data{'array_name'});
  $data{'array_id'} = $data{'array_type'} if ($data{'array_type'} =~ /^\d+/);
  $data{'array_id'} = _arrayIDfromArrayType($data{'dbh'},$data{'array_type'})
                      if (!$data{'array_id'});
  return (_error(502,"array $data{'array_type'} unknown")) if ($data{'array_id'} < 0);
  print "Array Type:\tname:$data{'array_type'}\tID:$data{'array_id'}\n"
        if ($data{'verbose'});

  #valid export format ?
  $data{'format'} = lc($data{'format'});
  $data{'format'} = "genespring" if (!$data{'format'});
  return (_error(501,"unknown export format $data{'format'}"))
    if ($data{'format'} !~ /\bgenespring\b/);
  my $templateDir = $ENV{'MAXD_TEMPLATES'} || ".";
  return (_error(501,"unable to find template for $data{'format'}"))
    if (!-f "$templateDir/$data{'format'}\.tmpl");
  print "Export format:\t$data{'format'}\n" if ($data{'verbose'});

  print "collecting hybridisation\n" if ($data{'verbose'});
  my %hybD = _hybridisationByExperimentIDArrayID($data{'dbh'},
              $data{'experiment_id'},$data{'array_id'});
  print "collecting tissue\n" if ($data{'verbose'});
  my(%TisSrc) = _sourceNameTissueByExperiment($data{'dbh'},\%hybD);
  my $numOfExp = scalar(keys %hybD);
  my($imgname,$img,$mesname,$mes,$hybname,$hyb,$k,$v,%tmp,%spotD);

  my $numOfHyb = scalar(keys %hybD); my $hybCounter = 1;
  foreach $hybname (sort {$hybD{$a} <=> $hybD{$b}} keys %hybD) {
    print "collecting measurement for $hybname ($hybCounter/$numOfHyb)\n" 
         if ($data{'verbose'});
    $hybCounter++;
    $hyb = sprintf("%04d",$hybD{$hybname});
    ($imgname,$img) = _imageFromHybridisationID($data{'dbh'},$hyb);
    ($mesname,$mes) = _measurementFromImageID($data{'dbh'},$img);
    %tmp = _spotMeasurementByMeasurementID($data{'dbh'},$mes);
    while (($k,$v)=each %tmp) {$spotD{$hyb}{$k} = $v;}
  }
  my %spotName = _spotNameBySpotID($data{'dbh'},\%tmp);

  # export data in txt format
  print "exporting data in txt format\n" if ($data{'verbose'});
  my $dataFileName; 
  ($dataFileName = "$data{'repository_url'}/$data{'array_name'}") =~ s/\s+/_/g;
  open(OUT,">$dataFileName\.txt");
  foreach $mes (sort {$a<=>$b} keys %spotName) {
    print OUT "$spotName{$mes}\t";
    foreach $hyb (sort keys %spotD) { 
      print OUT $spotD{$hyb}{$mes},"\t";
    }
    print OUT "$spotName{$mes}";
    print OUT "\n";
  }
  close(OUT);

  # export master in html format
  print "exporting master in htmlformat\n" if ($data{'verbose'});
  my $date = `date`;
  use HTML::Template;
  my $template = HTML::Template->new(filename => "$templateDir/GeneSpring.tmpl");
  $template->param(SUBMITTER_NAME => $data{'submitter_name'});
  $template->param(EXPERIMENT_NAME => $data{'experiment_name'});
  $template->param(ORGANIZ_NAME => $data{'organization_name'});
  $template->param(DATE => $date);
  $template->param(ARRAY_NAME => $data{'array_name'});
  $template->param(NUM_OF_EXP => $numOfExp);

  my $expCount = 0;
  my @expLoop;
  foreach my $hybname (sort {$hybD{$a} <=> $hybD{$b}} keys %hybD) {
    $expCount++;
    my %row = (EXPCOUNT => $expCount,
               EXPTISSUE => $TisSrc{'tissue'}{$hybD{$hybname}},
               EXPNAME => $hybD{$hybname},
               EXPSOURCE => $TisSrc{'source'}{$hybD{$hybname}} );
    push(@expLoop, \%row);
  }
  $template->param(EXPERIMENT_INFO => \@expLoop);

  my($i,$eLine,$xLine,$sLine,$I);
  $eLine = "";$sLine="";
  foreach $i (1 .. $numOfExp) {
    $xLine .= "<TD>Exp. $i</TD>";
    $eLine .= "<TD>&nbsp;</TD>";
    if ($i == 1) {
      $sLine .= "<TD>&nbsp;</TD>";
    } else {
      $I = $i + 1;
      $sLine .= "<TD>$I</TD>";
    }
  }

  my $f = basename($dataFileName) . ".txt";
  $template->param(EXPLINE => $xLine);
  $template->param(SLINE => $sLine);
  $template->param(ELINE => $eLine);
  $template->param(DFILENAME => $f);

  open(OUT,">$dataFileName\.html");
  print OUT $template->output;
  close(OUT);
  return 1;
}

sub load_file {
  my $self=shift;
  my(%data,$tag);
  foreach $tag (keys %{$self}) { $data{$tag} = $self->{$tag};}
  while (@_) {$tag = shift; if ($tag =~ /^-/) {$tag =~ s/^-//;$data{lc($tag)} = shift;}}
  return 0 if (ref($data{'dbh'}) ne "DBI::db");
  return 0 if (!-f $data{'matrix_file'});

  # valid data format ?
  $data{'format'} = $data{'format'} || _theFileFormat($data{'matrix_file'});
  return (_error(500,$data{'matrix_file'})) if ($data{'format'} !~ /AFF|TOR/);

  # valid image_analysis_protocol ?
  return(_error(123,"missing image_analysis_protocol")) 
       if (not defined $data{'image_analysis_protocol'});
  ($data{'image_analysis_protocol_id'},$data{'image_analysis_protocol_name'}) = 
       _imageAnalysisProtocolID($data{'dbh'},$data{'image_analysis_protocol'});
  return (_error(501,"Image Analysis Protocol $data{'image_analysis_protocol'} unknown")) 
       if ($data{'image_analysis_protocol_id'}< 0);
  print "Image Protocol:\tname:$data{'image_analysis_protocol_name'}\t",
        "ID:$data{'image_analysis_protocol_id'}\n" if ($data{'verbose'});

# valid scanning_protocol ?
  return(_error(123,"missing scanning_protocol"))
       if (not defined $data{'scanning_protocol'});
  ($data{'scanning_protocol_id'},$data{'scanning_protocol_name'}) =
       _imageAnalysisProtocolID($data{'dbh'},$data{'scanning_protocol'});
  return (_error(501,"Scanning Protocol $data{'scanning_protocol'} unknown"))
       if ($data{'scanning_protocol_id'}< 0);
  print "Scanning Protocol:\tname:$data{'scanning_protocol_name'}\t",
        "ID:$data{'scanning_protocol_id'}\n" if ($data{'verbose'});

# valid hybridisation_protocol ?
  return(_error(123,"missing hybridisation_protocol"))
       if (not defined $data{'hybridisation_protocol'});
  ($data{'hybridisation_protocol_id'},$data{'hybridisation_protocol_name'}) =
       _imageAnalysisProtocolID($data{'dbh'},$data{'hybridisation_protocol'});
  return (_error(501,"Hybridisation Protocol $data{'hybridisation_protocol'} unknown"))
       if ($data{'hybridisation_protocol_id'}< 0);
  print "Hybridisation Protocol:\tname:$data{'hybridisation_protocol_name'}\t",
        "ID:$data{'hybridisation_protocol_id'}\n" if ($data{'verbose'});

  # valid submitter ?
  ($data{'submitter_id'},$data{'submitter_name'}) = 
            _submitterFromSubmitterData($data{'dbh'},$data{'submitter'});
  return (_error(501,"submitter $data{'submitter'} unknown")) 
          if ($data{'submitter_id'}< 0);
  print "Submitter:\tname:$data{'submitter_name'}\tID:$data{'submitter_id'}\n"
        if ($data{'verbose'});

  # valid array type ?
  return 0 if (not defined $data{'array_type'});
  $data{'array_id'} = $data{'array_type'} if ($data{'array_type'} =~ /^\d+/);
  $data{'array_id'} = _arrayIDfromArrayType($data{'dbh'},$data{'array_type'}) 
                      if (!$data{'array_id'});
  return (_error(502,"array $data{'array_type'} unknown")) if ($data{'array_id'} < 0);
  print "Array Type:\tname:$data{'array_type'}\tID:$data{'array_id'}\n"
        if ($data{'verbose'});

  # valid experiment ?
  return 0 if (!$data{'experiment'});
  ($data{'experiment_id'},$data{'experiment_name'}) 
       = _experimentIDfromExperiment($data{'dbh'},$data{'experiment'},
       $data{'submitter_id'});
  return (_error(502,"experiment $data{'experiment'} unknown")) 
        if ($data{'experiment_id'} < 0);
  print "Experiment:\tname:$data{'experiment_name'}\tID:$data{'experiment_id'}\n" 
        if ($data{'verbose'});

  # valid extract ?
  return (_error(600,"extract")) if (!$data{'extract'});
  ($data{'extract_id'},$data{'extract_name'}) =
          _extractfromExtractData($data{'dbh'},$data{'extract'});
  return (_error(502,"extract $data{'extract'} unknown")) if ($data{'extract_id'} < 0);
  print "Extract:\tname:$data{'extract_name'}\tID:$data{'extract_id'}\n" 
        if ($data{'verbose'});

  if (($data{'public'} =~ /true/i) or ($data{'public'} eq "1")) {
    $data{'public'} = "true"; } else {$data{'public'} = "false";}
  print "Public:\t$data{'public'}\n" if ($data{'verbose'});

  $data{'repository_url'} =~ s/[\\\/]$//;
  print "Repository URL:\t$data{'repository_url'}\n" if ($data{'verbose'});


  $data{'description_id'} = "NULL"; # TEMPORARY
  $data{'image_attribute_description_id'} = "NULL"; # TEMPORARY RawQ

  $data{'dbh'}->begin_work;

  my $Hybridisation_ID = -1;
  if ($data{'hybridisation'}) {
    $Hybridisation_ID = _hybridisationIDfromHybridisationData(
                        $data{'dbh'},$data{'hybridisation'});
    return (_error(501,$data{'hybridisation'})) if ($Hybridisation_ID < 0);
  }
  if ($Hybridisation_ID < 0) {
    # create Hybridisation entry
    $Hybridisation_ID = _getNextIDForTable($data{'dbh'},"Hybridisation");
    $data{'dbh'}->do(qq{insert into Hybridisation 
    (Name,ID,Description_ID,Experiment_ID,Hybridisation_Protocol_ID,Extract_ID,Array_ID) 
    VALUES ("$data{'extract_name'}",$Hybridisation_ID,$data{'description_id'},
    $data{'experiment_id'},$data{'hybridisation_protocol_id'},
    $data{'extract_id'},$data{'array_id'})});
  }
  print "Hybridisation ID:\t$Hybridisation_ID\n" if ($data{'verbose'});

  my $Image_ID = -1;
  if ($data{'image'}) {
    $Image_ID = _imageIDfromImageData ($data{'dbh'},$data{'image'});
    return (_error(501,$data{'image'})) if ($Image_ID < 0);
  }
  if ($Image_ID < 0) {
    # create Image entry
    $Image_ID = _getNextIDForTable($data{'dbh'},"Image");
    my $imageURL = 
        "$data{'repository_url'}/$data{'submitter_name'}/$data{'extract_name'}\.dat";
    $imageURL =~ s/ +/_/g;
    $data{'dbh'}->do(qq{insert into Image
    (Name,ID,Digitised_Image_URL,Hybridisation_ID,Scanning_Protocol_ID) VALUES
    ("$data{'extract_name'}",$Image_ID,"$imageURL",
    $Hybridisation_ID,$data{'scanning_protocol_id'})});
  }
  print "Image ID:\t$Image_ID\n" if ($data{'verbose'});

  # create Measurement entry
  my $Measurement_ID = _getNextIDForTable($data{'dbh'},"Measurement");
  $data{'dbh'}->do(qq{insert into Measurement
  (Name,ID,Image_ID,Image_Analysis_Protocol_ID,Image_Attribute_Description_ID,Public)
  VALUES ("$data{'extract_name'}",$Measurement_ID,$Image_ID,
  $data{'image_analysis_protocol_id'},$data{'image_attribute_description_id'},
  "$data{'public'}")});
  print "Measurement ID:\t$Measurement_ID\n" if ($data{'verbose'});

  # insert SpotMeasurement data
  print "Loading Spot data\n" if ($data{'verbose'});
  my %spots = _loadSpotID($data{'dbh'},$data{'array_id'});
  print "Loading Experiment data\n" if ($data{'verbose'});
  my @expression_level = _loadFromFile($data{'format'},$data{'matrix_file'},"Avg Diff"); 
  my @significance = _loadFromFile($data{'format'},$data{'matrix_file'},"Pos Fraction"); 
  my @spot_name = _loadFromFile($data{'format'},$data{'matrix_file'},"Probe Set Name");
  print "Inserting experiment data\n" if ($data{'verbose'});
  my $st = "insert into SpotMeasurement
  (Expression_Level,Significance,Output_Description_ID,Spot_ID,Measurement_ID)
  VALUES (?,?,?,?,$Measurement_ID)";
  my $sh = $data{'dbh'}->prepare($st);
  my($rv,$level,$signif,$desc,$spotNam,$spotID);
  foreach $spotNam (@spot_name) {
    $level = shift(@expression_level);
    $signif= shift(@significance);
    $desc = "NULL";
    $spotID = $spots{$spotNam};
    return(_error(600,"unknown Spot name $spotNam\n")) if (!$spotID);
    $rv = $sh->execute($level,$signif,$desc,$spotID);
  }

  $data{'dbh'}->commit;
  return 1;
}

sub version {
  return $VERSION;
}

sub disconnect {
  my $self=shift;   
  $self->{'dbh'}->disconnect;
  delete $self->{'dbh'};
}

### internal routines and methods

sub _dbconnect {
  my($host,$dbase,$user,$pass) = @_;
  my $MAXD = "DBI:mysql:$dbase:$host";
  my $db = DBI->connect($MAXD,$user,$pass) || $DBI::errstr;
  return $db;
}

sub _measurementFromImageID {
  my($dbh,$id) = @_;
  my $st = qq{select Name,ID from Measurement where Image_ID = $id};                 
  my $sh = $dbh->prepare($st);
  my $rv = $sh->execute;
  my $name;
  ($name,$id) =$sh->fetchrow_array;
  return ($name,$id);
}

sub _spotMeasurementByMeasurementID {
  my($dbh,$id)=@_;
  my(%data,$Expression_Level,$Spot_ID);
  my $st = qq{select Expression_Level,Spot_ID
from SpotMeasurement where Measurement_ID = $id};
  my $sh = $dbh->prepare($st);
  my $rv = $sh->execute;
  while (($Expression_Level,$Spot_ID) = $sh->fetchrow_array) {
    $data{$Spot_ID} = $Expression_Level;
  }
  return %data;
}

sub _imageFromHybridisationID {
  my($dbh,$id) = @_;
  my $st = qq{select Name,ID from Image where Hybridisation_ID = $id};
  my $sh = $dbh->prepare($st);
  my $rv = $sh->execute;
  my $name;
  ($name,$id) =$sh->fetchrow_array;
  return ($name,$id);
}

sub _spotNameBySpotID {
  my($dbh,$spot) =@_;
  my($id,%data,$name);
  my $sh = $dbh->prepare("select Name from Spot where ID = ?");
  foreach $id (keys %{$spot}) {
    my $rv = $sh->execute($id);
    ($name) = $sh->fetchrow_array;
    $data{$id} = $name;
  }
  return %data;
}

sub _sourceNameTissueByExperiment {
  my ($dbh,$exp) = @_;
  my $st = qq{select Source.Name,Source.Tissue 
from Source,Sample,Extract,Hybridisation 
where Source.ID = Sample.Source_ID 
and Sample.ID = Extract.Sample_ID 
and Extract.ID = Hybridisation.Extract_ID 
and Hybridisation.ID = ?};
  my(%data);
  my $sh = $dbh->prepare($st);
  foreach my $expname (keys %{$exp}) {
    my $expid = $$exp{$expname};
    my $rv = $sh->execute($expid);
    my ($name,$tissue) = $sh->fetchrow_array;
    $data{'tissue'}{$expid} = $tissue;
    $data{'source'}{$expid} = $name;
  }
  return(%data);
}

sub _hybridisationByExperimentIDArrayID {
  my($dbh,$id,$array)=@_;
  my(%data,$ID,$Array_ID,$name);
  my $st = qq{select Name,ID,Array_ID from Hybridisation 
  where Experiment_ID = $id and Array_ID = $array};
  my $sh = $dbh->prepare($st);
  my $rv = $sh->execute;
  while (($name,$ID,$Array_ID) = $sh->fetchrow_array) {
    $data{$name} =  $ID;
  }
  return %data;
}

sub _loadSpotID {
  my($dbh,$array_id) = @_;
  my(%spot,$name,$id);
  my $st = "select name,id from spot where Array_Type_ID = $array_id";
  my $sh = $dbh->prepare($st);
  my $rv = $sh->execute;
  while (($name,$id)= $sh->fetchrow_array) {
    $spot{$name} = $id;
  }
  return %spot;
}

sub _getNextIDForTable {
  my($dbh,$table)=@_;
  $table .= "_Seq";
  $dbh->do("UPDATE $table SET id=LAST_INSERT_ID(id+1)");
  my $st = "select ID from $table";
  my $sh = $dbh->prepare($st);
  my $rv = $sh->execute;
  my ($id)= $sh->fetchrow_array;
  return $id;
}

sub _imageAnalysisProtocolID {
  my($dbh,$name) = @_;
  my($id); 
  my $st = "select Name,ID from imageanalysisprotocol where ";
  if ($name =~ /^\d+$/) {$st .= qq{ID = "$name"};} else {$st .= qq{ Name = "$name"};}
  my $sh = $dbh->prepare($st);
  my $rv = $sh->execute;
  ($name,$id)= $sh->fetchrow_array;
  $id = "-1" unless defined $id;
  $name = "" unless defined $name;
  return ($id,$name);
}

sub _extractfromExtractData {
  my($dbh,$name) = @_;
  my($id);
  my $st = "select Name,ID from Extract where ";
  if ($name =~ /^\d+$/) {$st .= qq{ID = "$name"};} else {$st .= qq{ Name = "$name"};}
  my $sh = $dbh->prepare($st);
  my $rv = $sh->execute;
  ($name,$id)= $sh->fetchrow_array;
  $id = "-1" unless defined $id;
  $name = "" unless defined $name;
  return ($id,$name);
}

sub _submitterFromSubmitterData {
  my($dbh,$name) = @_;
  my($id);
  my $st = "select Name,ID from Submitter where ";
  if ($name =~ /^\d+$/) {$st .= qq{ID = "$name"};} else {$st .= qq{ Name = "$name"};}
  my $sh = $dbh->prepare($st);
  my $rv = $sh->execute;
  ($name,$id)= $sh->fetchrow_array;
  $id = "-1" unless defined $id;
  $name = "" unless defined $name;
  return ($id,$name);
}

sub _hybridisationIDfromHybridisationData {
  my($dbh,$name) = @_;
  my($id);
  my $st = "select Name,ID from Hybridisation where ";
  if ($name =~ /^\d+$/) {$st .= qq{ID = "$name"};} else {$st .= qq{ Name = "$name"};}
  my $sh = $dbh->prepare($st);
  my $rv = $sh->execute;
  ($name,$id)= $sh->fetchrow_array;
  $id = "-1" unless defined $id;
  $name = "" unless defined $name;
  return ($id,$name);
}

sub _imageIDfromImageData {
  my($dbh,$name) = @_;   
  my($id);
  my $st = "select Name,ID from Image where ";  
  if ($name =~ /^\d+$/) {$st .= qq{ID = "$name"};} else {$st .= qq{ Name = "$name"};}
  my $sh = $dbh->prepare($st);
  my $rv = $sh->execute;
  ($name,$id)= $sh->fetchrow_array;
  $id = "-1" unless defined $id;
  $name = "" unless defined $name;
  return ($id,$name);
}

sub _columns_in_file {
  my($f) = @_;
  my($fileType,$l,$name,@col);
  $fileType = _theFileFormat($f);
  open(IN,$f);
  if ($fileType eq "AFF") {
    $l = ""; while ($l !~ /Analysis Name/) {$l = <IN>;} chomp($l);
    foreach $name (split(/\t/,$l)) {
      push(@col,$name);
    }
  } elsif ($fileType eq "TOR") {
    while ($l = <IN>) { last if ($l =~ /Begin Measurements/); }
    $l = <IN>; chomp($l);
    foreach $name (split(/\t/,$l)) {
      push(@col,$name);
    }
  }
  close(IN);
  return @col;
}

sub _loadFromAffimetrixFile {
  my ($f,$column)=@_;
  my(@data,$value,$l);
  open(IN,$f);
  while ($l = <IN>) {
    next if ($l !~ /^\d/);
    chomp($l);
     $value = (split(/\t/,$l))[$column];
     push(@data,$value);
  }
  close(IN);
  return @data;
}

sub _loadFromOtherFile{
  my ($f,$column)=@_;
  my($l,@data,$value);
  open(IN,$f);
  while ($l = <IN>) { last if ($l =~ /Begin Measurements/); }
  while ($l = <IN>) {
    last if ($l =~ /^End/);
    next if ($l !~ /^\d/);
    chomp($l);
    $value = (split(/\t/,$l))[$column];
    push(@data,$value); 
  }
  close(IN);
  return @data;
}

sub _loadFromFile {
  my($fileType,$f,$column) = @_;
  my @data;
  if ($column !~ /^\d+$/) {
    my @col = _columns_in_file($f);
    my $i = 0; my $a;
    foreach $a (@col) {
      if ($a eq $column) {
        $column = $i;
        last;
      }
      $i++;
    }
  }
  if ($fileType eq "AFF") {
    @data = _loadFromAffimetrixFile($f,$column);
  } elsif ($fileType eq "TOR") {
    @data = _loadFromOtherFile($f,$column);
  } else {
    print "Unknown file type\n";
  }
  return @data;
}

sub _experimentIDfromExperiment {
  my($dbh,$name,$subid) = @_;
  my($id);
  my $st = "select Name,ID from Experiment where submitter_id = $subid and ";
  if ($name =~ /^\d+$/) {$st .= qq{ID = "$name"};} else {$st .= qq{ Name = "$name"};}
  my $sh = $dbh->prepare($st);
  my $rv = $sh->execute;
  ($name,$id)= $sh->fetchrow_array;
  $id = "-1" unless defined $id;
  $name = "" unless defined $name;
  return ($id,$name);
}

sub _arrayIDfromArrayType {
  my($dbh,$arrayType)=@_;
  my $st = qq{select ID from ArrayType where Name = "$arrayType"};
  my $sh = $dbh->prepare($st);
  my $rv = $sh->execute;
  my $id = $sh->fetchrow_array;
  $id = "-1" unless defined $id;
  return $id;
}

sub _theFileFormat {
  my($f) = @_; my($l,$fileType);
  open(IN,$f); $l = <IN>; close(IN);
  if ($l =~ /Expression Analysis: Metrics Tab/) {
    $fileType = "AFF";
  } elsif ($l =~ /^\?\?/) {
    $fileType = "TOR";
  } else {
    $fileType = "UNK";
  }
  return $fileType;
}

sub _error {
  my($errnum,$errval)=@_;
  print STDERR "Error $errnum: $errval\n";
  return 0;
}

1;
__END__
=head1 NAME

Bio::Maxd - Perl extension for storing and retrieving data from maxd

=head1 SYNOPSIS

  use Bio::Maxd;
  my $maxd_db = new Bio::Maxd (-user=>'user', -pass=>'pass', 
                               -host=>'host', -dbase=>'database');
  $maxd_db->load_file(-file=>'path_to_data_file',
                  -experiment=>'experimentName', -array_type=>'geneChipName');
  $maxd_db->disconnect();

=head1 DESCRIPTION

B<Bio::Maxd> provides methods for uploading and retrieving
data to/from a maxd (MySQL) database.

"maxd" is a data warehouse and visualization environment for microarray
expression data developed by the Microarray Group at
Manchester Bioinformatics (http://www.bioinf.man.ac.uk/microarray/)

=head2 Bio::Maxd METHODS

B<new()>, This is the constructor for B<Bio::Maxd>.

 my $maxd_db = new Bio::Maxd();

This is the constructor for B<Bio::Maxd>. 
It establishes a database connection, or session, to the requested database.
Parameters:

=over 4

=item B<-user> and B<-pass>, default to $ENV{'MAXD_USERID'} with user/password.

=item B<-host>, defaults to $ENV{'MAXD_DBHOST'}, hostname or "localhost".

=item B<-dbase>, defaults to 'maxd'.

=item B<-verbose>, defaults to false.

=back

B<load_file()>, Parses and loads a datafile into a maxd database.. 

=over 4

=item B<-file>, datafile to parse.

=item B<-format>, data file format; Bio::Maxd will guess it, if not provided. 
Valid values are 'AFF' (Affimetrix matrics file)

=item B<-experiment>, Experiment ID or Experiment name.

=item B<-array_type>, ArrayType ID or ArrayType name

=back

B<export()>, Exports data from maxd database..

=over 4

=item B<-verbose>, reports activity.

=item B<-format>, desired format for the data to be exporte to. Valid values are 'GeneSpring'.

=item B<-submitter>, submitter name or id.

=item B<-experiment>, experiment name or id.

=item B<-array_type>, array name, i.e. 'HG-U95A2'

=item B<-repository_URL>, where to install files.

=item B<-image>, image name or id.

=item B<-hybridisation>, hybridisation name or id.

=back

=head1 MISCELLANEOUS

B<version()> Returns Bio::Maxd version

B<$ENV{'MAXD_USERID'}>, contains userid/password

B<$ENV{'MAXD_HOSTDB'}>, contains database host

B<$ENV{'MAXD_TEMPLATES'}>, directory for export templates

=head1 EXAMPLES

  use Bio::Maxd;
  my $maxd_db = new Bio::Maxd (-user=>'user', -pass=>'pass',
                               -host=>'host', -dbase=>'database');
  $maxd_db->load_file(-file=>'path_to_data_file',
                  -experiment=>'experimentName', -array_type=>'geneChipName');
  $maxd_db->disconnect();

See the 'examples' directory in the distribution for scripts loadData and exportData

=head1 EXPORT

None by default.

=head1 KNOWN BUGS

None, but that does not mean there are not any.

=head1 COPYRIGHT

Copyright (C) 2002 Jaime Prilusky. All rights reserved.     

=head1 AUTHOR

Jaime Prilusky <Jaime.Prilusky@weizmann.ac.il>

=head1 SEE ALSO

perl(1).

=cut
