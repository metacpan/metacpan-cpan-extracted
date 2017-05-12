package filter_object;
use t::util;
use t::utilBabel;
use Carp;
use Class::AutoDB;
use Clone qw(clone);
use File::Spec;
use Getopt::Long;
use Hash::AutoHash;
use List::MoreUtils qw(uniq);
use List::Util qw(min);
use Test::More;
use Text::Abbrev;
use Text::Balanced qw(extract_bracketed extract_delimited extract_multiple);
use Data::Babel;
use strict;
our @ISA=qw(Exporter);

our @EXPORT=qw($OPTIONS $autodb $babel $dbh $history $filter %ids @ids @qids @ops
	       init colname
	       test_setget test_setget_choices test_filter test_sql
	       cmp_sql cmp_sql_quietly
	     );
our($OPTIONS,%OPTIONS,@OPTIONS,%DEFAULTS,$autodb,$babel,$dbh,$history,$filter,%ids,@ids,@qids,@ops);

%ids=(word=>'word',
      number=>123,
      phrase=>'two words',
      embedded_quote=>q(embedded'quote),
      embedded_paren=>q{embedded(paren},
      embedded_marker=>q{embedded:marker});
@ids=sort values %ids;
# @qids defined in init
@ops=('LIKE','NOT LIKE','=','!=','<','<=','>=','>');

# configuration options - none yet
# active test options - none yet
@OPTIONS=qw();
%DEFAULTS=();

sub init {
  $history=shift;		# $history is global
  $history='none' unless defined $history;
  $autodb=new Class::AutoDB(database=>'test',create=>1); 
  isa_ok_quietly($autodb,'Class::AutoDB','sanity test - $autodb');
  $dbh=$autodb->dbh;
  @qids=map {$dbh->quote($_)} @ids;
  cleanup_db($autodb);	# cleanup database from previous test
  # make component objects and Babel.
  my @idtypes=map {new Data::Babel::IdType(name=>"type_$_",sql_type=>'VARCHAR(255)')} (0..3);
  my @masters=map {
    new Data::Babel::Master
      (name=>"type_${_}_master",idtype=>$idtypes[$_],history=>has_history($_))} (0..3);
  my $maptable=new Data::Babel::MapTable(name=>"maptable",idtypes=>\@idtypes);
  $babel=new Data::Babel
    (name=>'test',autodb=>$autodb,idtypes=>\@idtypes,masters=>\@masters,maptables=>[$maptable]);
  isa_ok_quietly($babel,'Data::Babel','sanity test - $babel');
  # setup the database. just creates the tables
  load_maptable($babel,'maptable');
  map {load_master($babel,$_)} @{$babel->masters};
  load_ur($babel,'ur');
}
sub has_history {
  my $i=shift;
  ($history eq 'none' || ($history eq 'odd' && !($i%2)) || ($history eq 'even' && $i%2))? 0: 1;
}
# generate column name for type taking into account histories
sub colname {
  my($i)=$_[0]=~/(\d+)/;
  has_history($i)? "_X_type_$i": "type_$i";
}
####################.
sub test_setget {
  my($attribute,$value)=@_;
  my $ok=1;
  $ok&&=cmp_quietly($filter->$attribute($value),$value,"set attribute: $attribute");
  $ok&&=cmp_quietly($filter->$attribute,$value,"re-get attribute: $attribute");
  report_pass($ok,"set and re-get attribute: $attribute");
}
# 1st element of choices mut be default
sub test_setget_choices {
  my($attribute,@choices)=@_;
  push(@choices,@choices);	# do it twice just because
  my $ok=1;
  for my $value (@choices) {
    $ok&&=cmp_quietly($filter->$attribute($value),$value,"set attribute: $attribute");
    $ok&&=cmp_quietly($filter->$attribute,$value,"re-get attribute: $attribute");
    last unless $ok;
  }
  # undef restores default
  my $value=$choices[0];
  $ok&&=cmp_quietly($filter->$attribute(undef),$value,"re-set attribute to default: $attribute");
  $ok&&=cmp_quietly($filter->$attribute,$value,
		   "re-get attribute after setting to default: $attribute");
  eval {$filter->$attribute('BAD')};
  $ok&&=report_fail(scalar($@=~/Invalid value BAD for attribute $attribute/),
		   "set attribute to illegal value: $attribute");
  report_pass($ok,"set and re-get attribute: $attribute");
}
# test one simple case. $filter_idtypes defaults to [type_0]
# $narray is max size ARRAY to test. default 3. if 0, ARRAY not tested
# $ncorrect is correct value for ARRAY. defaults to $correct
sub test_filter {
  my($conditions,$correct,$label,$narray,$ncorrect,$correct_idtypes)=@_;
  # $label="history=$history, $label";
  $correct_idtypes=['type_0'] unless defined $correct_idtypes;
  test_filter_one($conditions,$correct,$label,$correct_idtypes) or return 0;
  $narray=3 unless defined $narray;
  $ncorrect=$correct unless defined $ncorrect;
  for my $n (1..$narray) {
    # use clone so refs are identical by content not by address 
    my $array=[map {clone($conditions)} 1..$n];
    test_filter_one($array,$ncorrect,"ARRAY of $n $label",$correct_idtypes) or return 0;
  }
  # pass($label);
  1;
}
sub test_filter_one {
  my($conditions,$correct,$label,$correct_idtypes)=@_;
  my $filter=new Data::Babel::Filter
    (babel=>$babel,filter_idtype=>'type_0',conditions=>$conditions);
  my $sql=$filter->sql;
  cmp_sql_quietly($sql,$correct,$label) or return 0;
  my @actual_idtypes=map {$_->name} @{$filter->filter_idtypes};
  cmp_bag_quietly(\@actual_idtypes,$correct_idtypes,"$label: filter_idtypes") or return 0;
  $dbh->selectall_arrayref(qq(SELECT * FROM ur WHERE $sql));
  report_fail(!$dbh->err,"$label: valid SQL syntax: ".$dbh->errstr) or return 0;
  1;
}
# compare SQL expressions
# specialized for SQL generated in this test script - very limited!!
# single clause - must match exactly except for surrounding parens
# multiple expressions, surrounded by parens, seprated by OR
#  expressions must match exactly but order may vary
sub cmp_sql {
  my($actual,$correct,$label,$file,$line)=@_;
  my $ok=cmp_sql_quietly($actual,$correct,$label,$file,$line);
  report_pass($ok,$label);
}
sub cmp_sql_quietly {
  my($actual,$correct,$label,$file,$line)=@_;
  my $actual_norm=norm_sql($actual);
  my $correct_norm=norm_sql($correct);
  return 1 if $actual_norm eq $correct_norm;
  # adapted from report_fail
  # ($file,$line)=called_from($file,$line);
  my $callers=callers($file,$line);
  fail($label);
  diag_callers($callers);
  diag("expected SQL fragment\n  $correct_norm\ngot\n  $actual\n");
  return 0;
}
sub norm_sql {
  my($sql)=@_;
  # strip leading and trailing whitespace
  $sql=~s/^\s+|\s+$//g;
  # check for unmatched quotes, then strip extra whitespace except inside quoted strings
  my @parts=extract_multiple($sql,[{Quote=>sub {extract_delimited($_[0],q{'"})}},]);
  map {confess "Unmatched quote in SQL fragment $_" if !ref($_) && /["']/} @parts;
  $sql=join('',map {ref $_? $$_: do {
    s/\s+/ /g; s/\(\s+/\(/g; s/\s+\)/\)/g; s/\s*=\s*/=/g; $_}} @parts);
  # check for unmatched parens
  my @parts=extract_multiple($sql,
			     [{Quote=>sub {extract_delimited($_[0],q{'"})}},
			      {Paren=>sub {extract_bracketed($_[0],q{()'"})}},
			     ]);
  map {confess "Unmatched parenthesis in SQL fragment $_" if !ref($_) && /[()]/} @parts;
  # NG 13-09-21: do not remove surrounding parens. code & test should match exactly
  # ${$parts[0]}=~s/^\(|\)$//g if @parts==1 && ref($parts[0]);
  # $sql=join('',map {ref $_? $$_: $_} @parts); 
  
  # split on 'OR'
  # CAUTION: obviously won't work if quoted string contains 'OR' so DON"T DO IT !!!
  my @parts=split(/\s+OR\s+/,$sql);
  @parts=sort(uniq(@parts));
  join(' OR ',@parts);
}

# test whether SQL works
# specialized for SQL generated in this test script - very limited!!
sub test_sql {
  my($conditions,$correct,$label,$filter_idtype)=@_;
  $filter_idtype='type_0' unless @_>=4;
  my $filter=new Data::Babel::Filter
    (babel=>$babel,filter_idtype=>$filter_idtype,,conditions=>$conditions);
  my $sql=$filter->sql;
  my $actual=$dbh->selectcol_arrayref(qq(SELECT type_3 FROM ur WHERE $sql));
  cmp_bag_quietly($actual,$correct,$label);
}
1;

