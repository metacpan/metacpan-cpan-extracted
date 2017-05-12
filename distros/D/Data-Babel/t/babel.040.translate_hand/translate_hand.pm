package translate_hand;
use t::util;
use t::utilBabel;
use t::stash;
use Carp;
use File::Spec;
use Getopt::Long;
use Hash::AutoHash;
use List::Util qw(min);
use List::MoreUtils qw(none);
use Test::More;
use Text::Abbrev;
use Class::AutoDB;
use Data::Babel;
use strict;
our @ISA=qw(Exporter);

our @EXPORT=qw($OPTIONS $autodb $babel $dbh 
	       $data @idtypes @filter_subsets @output_subsets @ids
	       init make_ids make_invalid_ids idtype2ids empty_result num_range
	       check_babel_sanity check_database_sanity
	     );
our($OPTIONS,%OPTIONS,@OPTIONS,$autodb,$babel,$dbh,$data,
    @idtypes,@idtypes_subsets,@filter_subsets,@output_subsets,@ids);
@ids=qw(000 001 010 011 100 101 110 111);

# configuration options 
# these control
#    inifiles used for masters & data
#    params for sanity tests
#    idtype prefixes for history tests
#  ini - name of configuration file - default 'translate_hand.ini'
#  what - test case
#    baseline (default)
#    history - some idtypes have histories
#    pdups_multi - databse generates pdups via multi-table queries
#    pdups_wide - databse generates pdups via single wide table
#  ----- ones below here generally set from ini file -----
#  maptables - list of expected maptable names
#  idtypes - list of expected idtype names
#  explicits - list of idtypes (names) expected to have explicit masters
#  implicits - list of idtypes (names) expected to have implicit masters
#              generally computed from idtypes and explicits
#  histories - list of idtypes (names) expected to have histories
#  count_<maptable>, count_ur - number of rows expected in each table
#  idtype_ini - idtype ini filename - computed from what
#  master_ini - master ini filename - computed from what
#  maptable_ini - maptable ini filename - computed from what
#  data_ini - data ini filename - computed from what
#
# active test options
# 
# count causes 'count' option to be added to translate
# validate causes 'validate' option to be added to translate
# keep_pdups causes 'keep_pdups' option to be added to translate
#
# filter set automatically - controls calculation of @filter_subsets
# num_invalid_ids added to input_ids
# limit - if set, test run w/o then w/ limit
# num_input_ids, num_invalid_ids, num_filters, num_outputs
#   specify ranges - min,max - eg '1,5'
#   if min absent, eg, ',5', min=0
#   if max absent, eg, '1,', max=number of idtypes
#   if only one number, eg, '5', it's exact: min=max=number
#   'all' permitted for max (except for num_invalid_ids, limit)
#   negative values equivalent to all minus value, eg, '-2' is all-2

@OPTIONS=qw(what=s maptables=s idtypes=s explicits=s implicits=s histories=s
	    ini=s idtype_ini=s master_ini=s history_ini=s data_ini=s
	    count validate keep_pdups
	    num_input_ids=s num_invalid_ids=s num_filters=s num_outputs=s limit=s);

# unclear what defaults appropriate for quick CPAN install
# these defaults seem to be fast enough. for pdups_multi, most cases produce no pdups...
# num_outputs default set in code - depends on test case
our %DEFAULTS=(what=>'baseline',
	       num_input_ids=>'0,2',num_invalid_ids=>'0,2',num_filters=>'1,2',
	       ini=>File::Spec->catfile(scriptpath,join('.',scripthead,'ini')));
our %what=abbrev qw(baseline history pdups_multi pdups_wide);

sub init {
  my $setup=shift;
  $autodb=new Class::AutoDB(database=>'test',create=>$setup); 
  isa_ok($autodb,'Class::AutoDB','sanity test - $autodb');
  $dbh=$autodb->dbh;
  $OPTIONS=get_options($setup);
  $data=new Data::Babel::Config(file=>$OPTIONS->data_ini)->autohash;
  unless ($setup) {
    # expect 'old' to return the babel
    $babel=old Data::Babel(name=>'test',autodb=>$autodb);
    check_babel_sanity('old');
    check_database_sanity();
    # generate subsets of idtypes
    @idtypes=@{$babel->idtypes}; # already checked that this is correct
    @filter_subsets=idtype_subsets('num_filters') if $OPTIONS->filter;
    @output_subsets=idtype_subsets('num_outputs');
    @output_subsets=grep {none {$_=~/multi/} @$_} @output_subsets
      if $OPTIONS->what eq 'pdups_multi';
    # set pdups removal options if necessary
    my($pdups_group_cutoff,$pdups_prefixmatcher_cutoff,$pdups_prefixmatcher_class)=
      @$OPTIONS{qw(pdups_group_cutoff pdups_prefixmatcher_cutoff pdups_prefixmatcher_class)};
  } else {			# setup new database
    cleanup_db($autodb);		# cleanup database from previous test
    Data::Babel->autodb($autodb);
    # rest of setup done by test
  }
}
# returns Hash::AutoHash
sub get_options {
  my $setup=shift;
  # initialize to defaults then overwrite with ones explicitly set
  %OPTIONS=%DEFAULTS;
  if (!$setup) {
    # if not setup, add in options saved from setup
    my $saved_options=get t::stash autodb=>$autodb,id=>'translate_hand_options';
    @OPTIONS{keys %$saved_options}=values %$saved_options if $saved_options;
  }
  GetOptions(\%OPTIONS,@OPTIONS);
  if ($setup) {
    # if setup, get configuration options from scriptname and conf file
    my($what,$ini)=@OPTIONS{qw(what ini)};
    my $conf=new Config::IniFiles -file=>$ini;
    confess "No section found for --what $what in $ini" unless $conf->SectionExists($what);
    for my $option (qw(maptables idtypes explicits histories)) {
      next if defined $OPTIONS{$option};
      my $value=$conf->val($what,$option);
      confess "No $option parameter found in section $what" unless defined $value;
      my @values=split(/\s+/,$value);
      $OPTIONS{$option}=\@values; 
    }
    unless (defined $OPTIONS{implicits}) {
      my %explicit=map {$_=>$_} @{$OPTIONS{explicits}};
      my @implicits=grep {!exists $explicit{$_}} @{$OPTIONS{idtypes}};
      $OPTIONS{implicits}=\@implicits;
    }
    for my $table (@{$OPTIONS{maptables}},'ur') {
      my $option="count_$table";
      next if defined $OPTIONS{$option};
      my $count=$conf->val($what,$option);
      confess "No count parameter found for $table in section $what" unless defined $count;
      confess "count parameter is 0 for $table in section $what" unless $count;
      $OPTIONS{$option}=$count;
    }
    for my $filetype (qw(maptable idtype master data)) {
      my $option="${filetype}_ini";
      next if defined $OPTIONS{$option};
      my $ini=File::Spec->catfile(scriptpath,join('.',scripthead,$filetype,$what,'ini'));
      confess "infile $ini does not exist" unless -e $ini;
      $OPTIONS{$option}=$ini;
    }
    # save options for later tests
    put t::stash autodb=>$autodb,id=>'translate_hand_options',data=>\%OPTIONS;
  }
  # filter set automatically from script name
  $OPTIONS{filter}=1 if !defined($OPTIONS{filter}) && scriptbasename=~/filter/;

  # deal with range options
  # set num_outputs default. depends on 'what'
  unless (defined $OPTIONS{num_outputs}) {
    if ($OPTIONS{what} eq 'pdups_multi') {$OPTIONS{num_outputs}='2,3'}
    elsif ($OPTIONS{what} eq 'pdups_wide') {$OPTIONS{num_outputs}='3,all'}
    elsif ($OPTIONS{filter}) {$OPTIONS{num_outputs}='all'}
    else {$OPTIONS{num_outputs}='0,all'}
  }
  for my $option (qw(num_input_ids num_invalid_ids num_outputs num_filters limit)) {
    my $value=$OPTIONS{$option};
    $value=~s/^\s+|\s+$//g;	# strip leading, trailing whitespace
    if (!length($value) || $value=~/freeze/i) {
      # option missing or undef: set 'freeze'
      $OPTIONS{$option}=undef;
    } else {
      my @range=split(/\s*[\s,.]+\s*/,$value,2);
      my($min,$max)=@range==1? ($range[0],$range[0]): @range;
      $min=0 unless length $min;
      $max=0 unless length $max;
      $OPTIONS{$option}=[$min,$max];
    }}

  $OPTIONS=new Hash::AutoHash %OPTIONS;
}

# generate idtype subsets
# @idtypes, @idtype_subsets global!!
sub idtype_subsets {
  my($option)=@_;
  my @subsets;
  my @idtype_names=map {$_->name} @idtypes;
  my $num_subsets=$OPTIONS->$option;
  if (defined $num_subsets) {
    my($min,$max)=map {$_=~/all/? scalar(@idtypes): ($_<0? scalar(@idtypes)+$_: $_)}
      @$num_subsets;
    @subsets=power_subsets(\@idtype_names,$min,$max);
    } else {
      @subsets=power_subsets(\@idtype_names,1);
    }
  wantarray? @subsets: \@subsets;
}
# generate num ranges for input, invalid, limit
sub num_range {
  my($what,$idtype,$freeze_num)=@_;
  my $option="num_${what}_ids";
  my($min,$max);
  my $range=$OPTIONS->$option;
  return ($freeze_num,$freeze_num) unless defined $range;
  if ($what=~/input/) {
    my @ids=idtype2ids($idtype);
    ($min,$max)=map {$_=~/all/? scalar(@ids): ($_<0? scalar(@ids)+$_: $_)} @$range;
  } else {
    ($min,$max)=@$range;
  }
  ($min,$max);
}

# prepend idtype to ids. if no indexes, convert all ids
sub make_ids {
  my $idtype=shift;
  my $id_prefix=$babel->name2idtype($idtype)->history? "${idtype}/x_": "${idtype}/a_";
  @_? map {"${id_prefix}$_"} @_: map {"${id_prefix}$_"} @ids;
}
# if no $num, make 1 id and don't append _<nnn>
sub make_invalid_ids {
  my($idtype,$num)=@_;
  my $id_prefix=$babel->name2idtype($idtype)->history? "${idtype}/x_": "${idtype}/a_";
  defined $num? map {"${id_prefix}invalid_".sprintf('%03i',$_)} 1..$num: "${id_prefix}invalid";
}
# result can be table or count
sub empty_result {
  my $result=shift;
  ref $result? scalar @$result: $result;
}
# all valid input id for a given type
# arg is IdType or name
our %IDS;			# cache of id lists
our %IDX_NEXT;			# idx of next id to use - so we cycle through them...
sub idtype2ids {
  my($idtype,$name)=ref $_[0]? ($_[0],$_[0]->name): ($babel->name2idtype($_[0]),$_[0]);
  my $ids=$IDS{$name} || ($IDS{$name}=fetch_ids($idtype,$name));
  my $all=scalar @$ids;
  my $num=@_>1? $_[1]: $all;
  my $next=defined $IDX_NEXT{$name}? $IDX_NEXT{$name}: ($IDX_NEXT{$name}=0);
  my @idxs=map {($next+$_)%$all} (0..$num-1);
  my @ids=@$ids[@idxs];
  $IDX_NEXT{$name}++;
  wantarray? @ids: \@ids;
}
sub fetch_ids {
  my($idtype,$name)=@_;
  my $column=!$idtype->history? $name: "_X_$name";
  my $table=$idtype->master->name;
  my $sql=qq(SELECT $column FROM $table);
  my $ids=$dbh->selectcol_arrayref($sql);
}

################################################################################
# these tests should be done in an earlier suite
sub check_babel_sanity {
  my($op)=@_;
  my $name='test';
  is_quietly(ref $babel,'Data::Babel',
	     "sanity test - $op Babel returned Babel object") or return;
  # test simple attributes
  cmp_quietly($babel->name,$name,
	      "sanity test - $op Babel has expected attribute: name") or return;
  cmp_quietly($babel->id,"babel:$name",
	      "sanity test - $op Babel has expected attribute: id") or return;
  cmp_quietly($babel->autodb,$autodb,
	      "sanity test - $op Babel has expected attribute: autodb") or return;
  # test components
  my @actual=map {$_->name} @{$babel->maptables};
  cmp_set_quietly(\@actual,$OPTIONS->maptables,
		  "sanity test - $op Babel has expected MapTables") or return;
  my @actual=map {$_->name} @{$babel->idtypes};
  cmp_set_quietly(\@actual,$OPTIONS->idtypes,
		  "sanity test - $op Babel has expected IdTypes") or return;
  my @actual=map {$_->idtype->name} grep {$_->explicit} @{$babel->masters};
  cmp_set_quietly(\@actual,$OPTIONS->explicits,
		  "sanity test - $op Babel has expected explicit Masters") or return;
  my @actual=map {$_->idtype->name} grep {$_->implicit} @{$babel->masters};
  cmp_set_quietly(\@actual,$OPTIONS->implicits,
		  "sanity test - $op Babel has expected implicit Masters") or return;
  my @actual=map {$_->idtype->name} grep {$_->history} @{$babel->masters};
  cmp_set_quietly(\@actual,$OPTIONS->histories,
		  "sanity test - $op Babel has expected Masters with histories") or return;

  pass("sanity test - $op Babel returned Babel object with expected attributes and components");
}

# make sure tables have expected number of rows
sub check_database_sanity {
  my @tables=(@{$OPTIONS->maptables},'ur');
  for my $table (@tables) {
    my $sql=qq(SELECT COUNT(*) FROM $table);
    my($actual)=$dbh->selectrow_array($sql);
    report_fail(!$dbh->err,"database query failed: ".$dbh->errstr) or return 0;
    is_quietly($actual,$OPTIONS->{"count_$table"},
	       "sanity test - $table has expected number of rows") or return;
  }
  pass("sanity test - maptables and ur have expected numbers of rows");

  # test ur construction
  my $correct=prep_tabledata($data->ur->data);
  my @columns=@{$OPTIONS->idtypes};
  push(@columns,map {"_X_$_"} @{$OPTIONS->histories});
  my $columns=join(',',@columns);
  my $actual=$dbh->selectall_arrayref(qq(SELECT $columns FROM ur));
  cmp_table($actual,$correct,'sanity test - ur construction');

  # check implicit masters
  my @implicits=@{$OPTIONS->implicits};
  for my $implicit (@implicits) {
    my $master="${implicit}_master";
    my $correct=prep_tabledata($data->$master->data);
    my $actual=$dbh->selectall_arrayref(qq(SELECT * FROM $master));
    report_fail(!$dbh->err,"database query failed: ".$dbh->errstr) or return 0;
    cmp_table_quietly($actual,$correct,
		      "sanity test - implicit master $implicit has expected data") or return 0;
  }
  pass('sanity test - implicit masters have expected data');

  # check general database consistency 
  t::utilBabel::check_database_sanity($babel,'sanity test',scalar @{$OPTIONS->maptables}) 
      or return 0;

  pass("sanity test - database looks good");
}
1;
