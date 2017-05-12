	#!/usr/local/bin/perl
use Carp;
use lib qw( blib/lib/ ../lib ../../..);
use Getopt::Long;
use File::Path;
use Bio::ConnectDots::Config;
use Bio::ConnectDots::DB;
use strict;

my($HELP,$VERBOSE,$ECHO_CMD,$DATABASE,$HOST,$USER,$PASSWORD,$LOADDIR,$LOADSAVE,$SQLLOG);

GetOptions ('help' => \$HELP,
	    'verbose' => \$VERBOSE,
	    'X|echo' => \$ECHO_CMD,
	    'database=s'=>\$DATABASE,
            'db=s'=>\$DATABASE,
            'host=s'=>\$HOST,
            'user=s'=>\$USER,
            'password=s'=>\$PASSWORD,
	    'loaddir=s'=>\$LOADDIR,
	    'loadsave=s'=>\$LOADSAVE,
	    'sqllog=s'=>\$SQLLOG,
	   ) and !$HELP or die <<USAGE;
Usage: $0 [options] cnf_file data_file

Load LocusLink into Connect-the-Dots database

Options
-------
   --help		Print this message
   --verbose		(for testing)
   -X or --echo		Echo command line (for testing and use in scripts)
  --database            Postgres database (default: --user)
  --db                  Synonym for --database
  --host                Postgres database (default: socks)
  --user                Postgres user (default: ngoodman)
  --password            Postgres password (default: undef)
  --loaddir             Directory for load files (default: /usr/tmp/user_name)
	--sqllog							Specifies log file name for SQL being used
  --loadsave            Specifies whether to save load files
                        Options: 'none', 'last', 'all'. Default: 'none'

Options  may be abbreviated.  Values are case insenstive.

USAGE
;

my $dbinfo = Bio::ConnectDots::Config::db('production');
$HOST or $HOST=$dbinfo->{host};
$USER or $USER=$dbinfo->{user};
$PASSWORD or $PASSWORD=$dbinfo->{password};
$DATABASE or $DATABASE=$dbinfo->{dbname};

my($CNF_FILE,$DATA_FILE)=@ARGV;
confess "Required parameter cnf_file missing" unless $CNF_FILE;
confess "Required parameter data_file missing" unless $DATA_FILE;
my $cnf=parse_cnf($CNF_FILE);
my($name,$module,$dotsets, $cs_version, 
		$ftp, $ftp_files, $label_annotations,
		$source_version, $source_date, 
		$download_date, $comment) = @$cnf{qw(name module dotsets cs_version ftp ftp_files 
			                                   label_annotations source_version source_date 
			                                   download_date comment)};
print "### Loading ConnectorSet: $name\n";

my $db=new Bio::ConnectDots::DB
  (-database=>$DATABASE,-host=>$HOST,-user=>$USER,-password=>$PASSWORD,-ext_directory=>$LOADDIR, -sql_log=>$SQLLOG);
my $connectorset= new Bio::ConnectDots::ConnectorSet
  (-name=>$name,-module=>$module,-cs_version=>$cs_version,-ftp=>$ftp,-ftp_files=>$ftp_files,-dotsets=>$dotsets,
   -label_annotations=>$label_annotations,-db=>$db,-file=>$DATA_FILE, -source_version=>$source_version, 
   -source_date=>$source_date, -download_date=>$download_date, -comment=>$comment);
$connectorset->load_file($LOADSAVE);

sub parse_cnf {
  my($cnf_file)=@_;
  open(CNF,"< $cnf_file") || confess "Cannot open cnf_file $cnf_file: $!";
  my $cnf;
  my $dotsets;
  my $label_annotations;
  while(<CNF>) {
    s/\#.*$//;
    my($field,$value)=/^\s*(.*?)\s*=\s*(.*?)\s*$/;
    next unless $field;
    if ($field=~/name/i) {
      confess "Multiple name fields in cnf_file $cnf_file: ".$cnf->{name}." and $value"	if $cnf->{name};
      $cnf->{name}=$value;
    } elsif ($field=~/module/i) {
      confess "Multiple module fields in cnf_file $cnf_file: ".$cnf->{module}." and $value"	if $cnf->{module};
      $cnf->{module}=$value;
    } elsif ($field eq 'version') {
      confess "Multiple version fields in cnf_file $cnf_file: ".$cnf->{cs_version}." and $value"	if $cnf->{cs_version};
      $cnf->{cs_version} = $value;    	    	    
    } elsif ($field eq 'ftp') {
      $cnf->{ftp} = $value;	
    } elsif ($field eq 'ftp_files') {
      $cnf->{ftp_files} = $value;
		} elsif ($field=~/source_version/i) {
			$cnf->{source_version} = $value;
		} elsif ($field=~/source_date/i) {			
			$cnf->{source_date} = $value;
		} elsif ($field=~/download_date/i) {			
			$cnf->{download_date} = $value;
		} elsif ($field=~/comment/i) {			
			$cnf->{comment} = $value;
    } elsif ($field=~/^label/i) {
			my @entries = split /,/, $_;
      my($label,$dotset,$source_label,$descr);
			foreach my $entry (@entries) {
				my ($f,$val) = $entry =~ /\s*(.*?)\s*=\s*(.*?)\s*$/;
				if($f=~/label/i) {
					$label = $val;
				}			
				if($f=~/dotset/i) {
					$dotset = $val;
				}			
				if($f=~/source_label/i) {
					$source_label = $val;
				}			
				if($f=~/description/i) {
					$descr = $val;
				}			
			}
      push(@$dotsets,$label) if $label && !$dotset;
      push(@$dotsets,{$label=>$dotset}) if $dotset && $label;
      $label_annotations->{$label}->{source_label} = $source_label if $source_label;
      $label_annotations->{$label}->{description} = $descr if $descr;     
    }
    else {
      confess "Unrecognized field $field in cnf_file $cnf_file";
    }
  }
  $cnf->{dotsets}=$dotsets if $dotsets;
  $cnf->{label_annotations}=$label_annotations if $label_annotations;
  confess "Incomplete cnf_file $cnf_file: no name" unless $cnf->{name};
  confess "Incomplete cnf_file $cnf_file: no module" unless $cnf->{module};
  confess "Incomplete cnf_file $cnf_file: no version" unless $cnf->{cs_version};
  confess "Incomplete cnf_file $cnf_file: no dotsets" unless $cnf->{dotsets};
  return $cnf;
}
