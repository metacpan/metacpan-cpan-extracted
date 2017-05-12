package Bio::ConnectDots::Parser;
use vars qw(@ISA @AUTO_ATTRIBUTES @OTHER_ATTRIBUTES %SYNONYMS %DEFAULTS);
use strict;
use Text::Balanced qw(extract_delimited extract_bracketed extract_quotelike);
use Class::AutoClass;
@ISA = qw(Class::AutoClass);

@AUTO_ATTRIBUTES=qw();
%SYNONYMS=();
@OTHER_ATTRIBUTES=qw();
%DEFAULTS=();
Class::AutoClass::declare(__PACKAGE__);

# constraints = 
#   constraint 
#   constraint separator constraint ...
#   separator = any non-word character or 'and'
sub parse_constraints {
  my($self,$text,$want_tree)=@_;
  my($constraint,$rest);
  my $constraints=[];
  while ($text) {
    ($constraint,$rest)=$self->parse_constraint($text,$want_tree);
    last unless $constraint;
    push(@$constraints,$constraint);
    $rest=~s/^[\s,;]*(AND)*[\s,;]*//is;	# consume separator
    $text=$rest;
  }
  my $result;
  if (@$constraints) {
    $want_tree? $result={match=>$constraints}: $result=$constraints;
  } else {
    $rest=$text;
  }
  wantarray? ($result,$rest): $result;
}

# constraint =
#   constant
#   op constant
#   term constant
#   term op constant
# try longest first. 
sub parse_constraint {
  my($self,$text,$want_tree)=@_;
  my($term,$op,$constant,$rest_term,$rest,$rest);
  ($term,$rest_term)=$self->parse_term($text,$want_tree);
  goto FAIL unless $term;
  # try parsing 'op constant'
  ($op,$rest)=$self->parse_op($rest_term,$want_tree);
  goto SUCCESS if $op=~/exists/i; # no constant needed
  if ($op) {
    ($constant,$rest)=$self->parse_constant($rest,$want_tree);
    if ($constant) {
      goto SUCCESS;
    }
  }
  # try parsing just 'constant'
  ($constant,$rest)=$self->parse_constant($rest_term,$want_tree);
  goto FAIL unless $constant;
  
 SUCCESS:
  my $result={term=>$term,op=>$op,constant=>$constant};
  $result={match=>$result} if $want_tree;
  return wantarray? ($result,$rest): $result;
 FAIL:
  return wantarray? (undef,$text): undef;
}

# joins = 
#   join 
#   join separator join ...
#   separator = any non-word character or 'and'
sub parse_joins {
  my($self,$text,$want_tree)=@_;
  my($join,$rest);
  my $joins=[];
  while ($text) {
    ($join,$rest)=$self->parse_join($text,$want_tree);
    last unless $join;
    push(@$joins,$join);
    $rest=~s/^[\s,;]*(AND)*[\s,;]*//is;	# consume separator
    $text=$rest;
  }
  my $result;
  if (@$joins) {
    $want_tree? $result={match=>$joins}: $result=$joins;
  } else {
    $rest=$text;
  }
  wantarray? ($result,$rest): $result;
}

# join =
#   term = term
sub parse_join {
  my($self,$text,$want_tree)=@_;
  my($term0,$rest)=$self->parse_term($text,$want_tree);
  goto FAIL unless $term0;
  $rest=~s/^\s*=+\s*//is;		# consume separator
  my($term1,$rest)=$self->parse_term($rest,$want_tree);
  goto FAIL unless $term1;
  
 SUCCESS:
  my $result={term0=>$term0,term1=>$term1};
  $result={match=>$result} if $want_tree;
  return wantarray? ($result,$rest): $result;
 FAIL:
  return wantarray? (undef,$text): undef;
}

# aliases = 
#   alias 
#   alias separator alias ...
#   separator = any non-word character
sub parse_aliases {
  my($self,$text,$want_tree)=@_;
  my($alias,$rest);
  my $aliases=[];
  while ($text) {
    ($alias,$rest)=$self->parse_alias($text,$want_tree);
    last unless $alias;
    push(@$aliases,$alias);
    $rest=~s/^[\s,;]*//is;		# consume separator
    $text=$rest;
  }
  my $result;
  if (@$aliases) {
    $want_tree? $result={match=>$aliases}: $result=$aliases;
  } else {
    $rest=$text;
  }
  wantarray? ($result,$rest): $result;
}

# alias =
#   name separator alias
#   separator = any non-word character or AS
sub parse_alias {
  my($self,$text,$want_tree)=@_;
  my($target_name,$rest)=$self->parse_qword($text,$want_tree);
  goto FAIL unless $target_name;
  $rest=~s/^\s*AS\s*|[\s,;]*//is;		# consume separator
  my($alias_name,$rest)=$self->parse_qword($rest,$want_tree);
  goto FAIL unless $alias_name;
  
 SUCCESS:
  my $result={target_name=>$target_name,alias_name=>$alias_name};
  $result={match=>$result} if $want_tree;
  return wantarray? ($result,$rest): $result;
 FAIL:
  return wantarray? (undef,$text): undef;
}

# term = term1 | term1.term1 | term1.term1.term1 
# approximate this by list of any number of term1's
sub parse_term {
  my($self,$text,$want_tree)=@_;
  my($term1,$rest);
  my $term=[];
  while ($text) {
    ($term1,$rest)=$self->parse_term1($text,$want_tree);
    last unless $term1;
    push(@$term,$term1);
    last unless $rest=~s/^\s*\.\s*//s; # done unless separator is '.'
    $text=$rest;
  }
  my $result;
  if (@$term) {
    $result=$want_tree? {match=>$term}: $term;
  } else {
    $rest=$text;
  }
  wantarray? ($result,$rest): $result;
}

# term1='*' | word | quoted_phrase | list
sub parse_term1 {
  my($self,$text,$want_tree)=@_;
  $text.=' ';			# append space because extract_quotelike doesn't 
                                #  handel q() if ) is last character of string
  my($rule,$match,$rest,$prefix,$body,$skip);
  $text=~s/^\s*//s;		# strip leading spaces
  if (($match,$rest)=$text=~/^(\*)(.*)/s) {
    $rule='*';
  } elsif (($match,$rest,$prefix,$skip,$skip,$body)=extract_quotelike($text),$match) {
    $rule='quoted_phrase';
  }  elsif (($match,$rest,$prefix)=extract_bracketed($text,'[(q'),$match) {
    $rule='list';
    ($match)=$match=~/^[\[\(](.*)[\)\]]$/s;
    $match=$self->parse_term_list($match,$want_tree);
  } elsif (($match,$rest)=$text=~/^(\w+)(.*)/s) {
    $rule='word';
  }
  my $result;
  if ($match) {
    $match=$body if defined $body;
    $result=$want_tree? {match=>$match,rule=>$rule}: $match;
  } else {
    $rest=$text;
  }
  wantarray? ($result,$rest): $result;
}
sub parse_term_list {
  my($self,$text,$want_tree)=@_;
  my($term1,$rest);
  my $term=[];
  while ($text) {
    ($term1,$rest)=$self->parse_term1($text,$want_tree);
    last unless $term1;
    push(@$term,$term1);
    $rest=~s/^[\s,;]//s;		# consume separator
    $text=$rest;
  }
  my $result;
  if (@$term) {
    $result=$want_tree? {match=>$term}: $term;
  } else {
    $rest=$text;
  }
  wantarray? ($result,$rest): $result;
}
# term = term1 | term1.term1 | term1.term1.term1 
# approximate this by list of any number of term1's
sub parse_term_value {
  my($self,$text,$want_tree)=@_;
  my($term1,$rest);
  my $term=[];
  while ($text) {
    ($term1,$rest)=$self->parse_term1_value($text,$want_tree);
    last unless $term1;
    push(@$term,$term1);
    $text=$rest;
  }
  my $result;
  if (@$term) {
    $result=$want_tree? {match=>$term}: $term;
  } else {
    $rest=$text;
  }
  wantarray? ($result,$rest): $result;
}

# term1='*' | everything to . | list
sub parse_term1_value {
  my($self,$text,$want_tree)=@_;
  my($rule,$match,$rest,$prefix);
  $text=~s/^\s*//s;		# strip leading spaces
  if (($match,$rest)=$text=~/^(\*)(.*)/s) {
    $rule='*';
  } elsif (($match,$rest,$prefix)=extract_bracketed($text,'[(q'),$match) {
    $rule='list';
    ($match)=$match=~/^[\[\(](.*)[\)\]]$/s;
    $match=$self->parse_term_list($match,$want_tree);
  } elsif (($match,$rest)=$text=~/^(.*?)\.(.*)/s) {
    $match=~s/\s*$//s;		# strip trailing spaces
    $rule='word';
  } else {
    $match=$text;
    $rest='';
    $rule='value';
  }
  my $result;
  if ($match) {
    $result=$want_tree? {match=>$match,rule=>$rule}: $match;
  } else {
    $rest=$text;
  }
  wantarray? ($result,$rest): $result;
}
# op = usual comparison ops | 'in'
sub parse_op {
  my($self,$text,$want_tree)=@_;
  $text=~s/^\s*//s;		# strip leading spaces
  my($match,$rest)=$text=~/^(exists|not\s*in|in|<=|==|!=|>=|<|=|>)(.*)/is; # longest patterns must be first
  $match=uc($match);
  $match='NOT IN' if $match=~/NOT\s*IN/;
  $match='=' if $match eq '==';	# special case == for benefit of Perl programmers
  my $result;
  if ($match) {
    $result=$want_tree? {match=>$match,rule=>'op'}: $match;
  } else {
    $rest=$text;
  }
  wantarray? ($result,$rest): $result;
}

# constant = word | quoted_phrase | list
sub parse_constant {
  my($self,$text,$want_tree)=@_;
  $text.=' ';			# append space because extract_quotelike doesn't 
                                #  handel q() if ) is last character of string
  my($rule,$match,$rest,$prefix,$body,$skip);
  $text=~s/^\s*//s;		# strip leading spaces
  
  if (($match,$rest,$prefix,$skip,$skip,$body)=extract_quotelike($text),$match) {
    $rule='quoted_phrase';
  }  elsif (($match,$rest,$prefix)=extract_bracketed($text,'[(q'),$match) {
    $rule='list';
    ($match)=$match=~/^[\[\(](.*)[\)\]]$/s;
    $match=$self->parse_constant_list($match,$want_tree);
  } elsif (($match,$rest)=$text=~/^([\w\.]+)\W*(.*)/s) {
    $rule='word';
  }
  my $result;
  if ($match) {
    $match=$body if defined $body;
    $result=$want_tree? {match=>$match,rule=>$rule}: $match;
  } else {
    $rest=$text;
  }
  wantarray? ($result,$rest): $result;
}
sub parse_constant_list {
  my($self,$text,$want_tree)=@_;
  my($constant1,$rest);
  my $constants=[];
  while ($text) {
    ($constant1,$rest)=$self->parse_constant($text,$want_tree);
    last unless $constant1;
    push(@$constants,$constant1);
    $text=$rest;
  }
  my $result;
  if (@$constants) {
    $result=$want_tree? {match=>$constants}: $constants;
  } else {
    $rest=$text;
  }
  wantarray? ($result,$rest): $result;
}
# constant_value = entire string | list
sub parse_constant_value {
  my($self,$text,$want_tree)=@_;
  my($rule,$match,$rest,$prefix,$body,$skip);
  if (($match,$rest,$prefix)=extract_bracketed($text,'[(q'),$match) {
    $rule='list';
    ($match)=$match=~/^[\[\(](.*)[\)\]]$/s;
    $match=$self->parse_constant_list($match,$want_tree);
  } else{
    $match=$text;
    $rest='';
    $rule='value';
  }
  my $result;
  if ($match) {
    $result=$want_tree? {match=>$match,rule=>$rule}: $match;
  } else {
    $rest=$text;
  }
  wantarray? ($result,$rest): $result;
}

# outputs = 
#   output 
#   output separator output ...
#   separator = any non-word character
sub parse_outputs {
  my($self,$text,$want_tree)=@_;
  my($output,$rest);
  my $outputs=[];
  while ($text) {
    ($output,$rest)=$self->parse_output($text,$want_tree);
    last unless $output;
    push(@$outputs,$output);
    $rest=~s/^[\s,;]*//is;		# consume separator
    $text=$rest;
  }
  my $result;
  if (@$outputs) {
    $want_tree? $result={match=>$outputs}: $result=$outputs;
  } else {
    $rest=$text;
  }
  wantarray? ($result,$rest): $result;
}

# output =
#   word | word.word, optionally followed by 'AS' name
sub parse_output {
  my($self,$text,$want_tree)=@_;
  my($output1,$rest,$output_name);
  my $output=[];
  while ($text) {
    ($output1,$rest)=$self->parse_qword($text,$want_tree);
    last unless $output1;
    push(@$output,$output1);
    last unless $rest=~s/^\s*\.\s*//s; # done unless separator is '.'
    $text=$rest;
  }
  goto FAIL unless @$output;
  if ($rest=~s/^\W*AS\W*//is) {	# consume separator and
				# parse output_name if separator is 'as'
    ($output_name,$rest)=$self->parse_qword($rest,$want_tree);
    goto FAIL unless $output_name;
  }
 SUCCESS:
  my $result={termlist=>$output,output_name=>$output_name};
  $result={match=>$result} if $want_tree;
  return wantarray? ($result,$rest): $result;
 FAIL:
  return wantarray? (undef,$text): undef;
}

# qword = word | quoted_phrase
sub parse_qword {
  my($self,$text,$want_tree)=@_;
  $text.=' ';			# append space because extract_quotelike doesn't 
                                #  handel q() if ) is last character of string
  my($rule,$match,$rest,$prefix,$body,$skip);
  $text=~s/^\s*//s;		# strip leading spaces
  
  if (($match,$rest,$prefix,$skip,$skip,$body)=extract_quotelike($text),$match) {
    $rule='quoted_phrase';
  }  elsif (($match,$rest)=$text=~/^(\w+)(.*)/s) {
    $rule='word';
  }
  my $result;
  if ($match) {
    $match=$body if defined $body;
    $result=$want_tree? {match=>$match,rule=>$rule}: $match;
  } else {
    $rest=$text;
  }
  wantarray? ($result,$rest): $result;
}


1;

