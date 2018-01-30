package CSS::DOM::PropertyParser;

$VERSION = '0.17';

use warnings; no warnings qw 'utf8 parenthesis';
use strict;

use constant 1.03 (); # multiple
use CSS::DOM'Constants ':primitive', ':value';
use CSS'DOM'Util<unescape unescape_str unescape_url>;

use constant old_perl => $] < 5.01;
{ no strict 'refs'; delete ${__PACKAGE__.'::'}{old_perl} }

# perl 5.10.0 has a bug affecting $^N (perl bug #56194; not the initial
# report, but regressions in 5.10; read the whole ticket for details). We
# have a workaround, but it requires more CPU, so we only enable it for
# this perl version.
use constant naughty_perl => 0+$] eq 5.01;
{ no strict 'refs'; delete ${__PACKAGE__.'::'}{naughty_perl} }

*s2c = *CSS'DOM'Constants'SuffixToConst;
our %s2c;

our %compiled; # compiled formats
our %subcompiled; # compiled sub-formats
# We use ‘our’ instead of ‘my’, because re-evals that are compiled at run
# time can be a bit buggy when they refer to ‘my’ variables.

sub new {
 bless{}, shift
}

sub add_property {
 $_[0]{$_[1]}=$_[2]
}

sub get_property {
 exists $_[0]{$_[1]} ? $_[0]{$_[1]} : ()
}

sub delete_property {
 delete $_[0]{$_[1]} or ()
}

sub property_names {
 sort keys %{$_[0]};
}

sub subproperty_names {
 exists $_[0]{$_[1]} or return;
 my $p = $_[0]{$_[1]};
 my @p = $p->{format} =~ /'([^']+)'/g;
 exists $p->{properties} && $p->{properties} and
    push @p, keys %{$p->{properties}};
 @p;
}

sub clone {
# exists &dclone or require Storable, "Storable"->import('dclone');
# return dclone($_[0]);
 require Clone;
 return Clone'clone($_[0]);
}

#  Declare the variables that the re-evals use. Some nasty hacker went and
# ‘fixed’ run-time re-evals to propagate hints, so now we have to do this
#  as of perl 5.13.8.
our(
 @match,@list,@valtypes,$prepped,$alt_types,@List,%Match,%match,@Match,
 $tokens,$Self,$Fail
);

# The interface for match is documented in a POD comment further down
# (search for the second occurrence of ‘=item match’).
sub match { SUB: {
 my ($self,$property) = (shift,shift);
 return unless exists $self->{$property};

 # Prepare the value
 (my $types, local our ($tokens,$prepped,$alt_types)) = _prep_val(@_);
 # tokens is the actual tokens; $prepped is the tokens unescaped and lc'd
 # if they are ids; $alt_types contains single-char strings indicating pos-
 # sible datum types.
#use DDS; Dump $types if $property =~ /clip/;


 my @subproperties = $self->subproperty_names($property);
 my $shorthand = @subproperties;
 my $spec = $self->{$property};

 # Check for special values
 if(exists $spec->{special_values}
    && $types eq 'i'
    && exists $spec->{special_values}{$prepped->[0]}) {
  @_ = ($self,$property,$spec->{special_values}{$prepped->[0]});
  redo SUB;
 }

 # Check for inherit
 if($types eq 'i' and $prepped->[0] eq 'inherit') {
  my @arg_array = (
   $$tokens[0],'CSS::DOM::Value', type => CSS_INHERIT, css => $$tokens[0]
  );
  if($shorthand) {
   return { map +($_ => \@arg_array), @subproperties };
  }
  else { return @arg_array }
 }

 # Localise other vars used by the hairy regexps
 local our (@Match,%Match,@valtypes,@List);
 local our $Self = $self;

 # Compile the formats of the sub-properties,  something we  can’t  do
 # during the pattern match, as compilation requires regular expressions
 # and perl’s re engine is not reëntrant. This has to come before the for-
 # mat for this property,  in case it relies on  list-style-type.  We  use
 # (??{...}) to pick it up,  but that is too buggy in perl 5.8.x, so, for
 # old perls,  we compile it straight in.  Consequently we also have to
 # ‘un-cache’ any compiled format containing <counter>, in case it is
 #  shared with another parser object with another definition  for
 #  list-style-type.
 my $format = $$spec{format};
 for(
  @subproperties,
  $format =~ '<counter>'
   ? scalar(old_perl && delete $compiled{$format}, 'list-style-type')
   : ()
 ) {
  next unless exists $self->{$_};
  my $format = $self->{$_}{format}; 
  old_perl and $compiled{$format} and delete $compiled{$format};
  $compiled{$format} ||= _compile_format($format)
 }

 # Prepare this property’s format pattern
 my $pattern = $compiled{$format} ||= _compile_format($format);

 # Do the actual pattern matching
 $types =~ /^$pattern\z/ or return;

#use DDS; Dump $types,$tokens,\@valtypes;
#use DDS; Dump \%Match if $property =~ /clip/;
 # Get the values, convert them into CSSValue arg lists and return them
 if($shorthand) {
  my $retval = {%Match};
  my $subprops = exists $spec->{properties} ? $spec->{properties} : undef;

  # We record which captures have been turned into arg lists already,
  # since these are sometimes shared between properties.
  my @arglistified;

  for(@subproperties) {
   if(exists $retval->{$_}) {
    @{ $retval->{$_} } = _make_arg_list( @{ $retval->{$_} } );
   }
   else {
    my $set;
    if($subprops and exists $subprops->{$_}) {
     for my $c( @{ $subprops->{$_} } ) { # capture nums
      # find the first one that matched something
      if( $Match[$c] and length $Match[$c][0] ) {
       @{ $Match[$c] } = _make_arg_list( @{ $Match[$c] } )
        unless $arglistified[$c]++;
       ++$set;
       $retval->{$_} = $Match[$c];
       last;
      }
     }
    }
    if(!$set) {
     # use default value
# ~~~ Should we cache this? (If we do, we need to distinguish between
#    ‘content: Times New Roman’ and ‘font-family: Times New Roman’.)
     my $default = $self->{$_}{default};
     no warnings 'uninitialized';
     $retval->{$_} = length $default
      ? [
         $self->match($_, $default)
        ]
      : ""
    }
   }
  }
  $retval;
 }
 else { # simple
   my $css = join "", @{ (_space_out($types,$tokens))[1] };
#use DDS; Dump \@List  if exists $$spec{list} && $$spec{list};
   return _make_arg_list(
            $types, $tokens, 
            exists $$spec{list} && $$spec{list}
             ? \@List
             : (\@valtypes, $prepped)
          );
 }
}}

sub _make_arg_list {
 my($types, $tokens) = (shift,shift);
 my($stypes,$stokens) = _space_out($types, $tokens);
 my $css = join "", @$stokens;
 if(@_ == 1) { # list property
  my $list = shift @'_;
  my $sep = @$list <= 1 ? '' : do {
   my $range_start = $$list[0][4];
   my $range_end = $$list[1][4] - length($$list[1][4]) - 1;
   my(undef,$stokens) = _space_out(
    substr($types, $range_start-1, $range_end-$range_start+3),
    [@$tokens[$range_start-1...$range_end+1]]
   );
   join "", @$stokens[1...$#$stokens-1];
  };
  return $css, "CSS::DOM::Value::List",
   separator => $sep, css => $css,
   values => [ map {
    my @args = _make_arg_list(
                   @$_[0...3]
    );
    shift @args, shift @args;
    \@args
   } @$list ];
 }
 else{
  my($valtypes, $prepped) = @_;
  my @valtypes = grep defined, @$valtypes;
  if(@valtypes != 1 and
     $valtypes[0] != CSS_COUNTER || do { # The code in this block is to
      no warnings 'uninitialized';       # distinguish between counter(id,
      my $found;                         # id) (which is a CSS_COUNTER) and
      for(@valtypes[1...$#valtypes-1]) { # counter(id) id (CSS_CUSTOM).
       $_ == -1 and ++$found, last; # -1 is a special marker for the end of
      }                             #  a counter
      $found
     }) {
   return $css => "CSS::DOM::Value", type => CSS_CUSTOM, value => $css;
  }
  my $type = shift @valtypes;
  return $css, "CSS::DOM::Value::Primitive",
   type => $type, css => $css,
   value =>
      $type == CSS_NUMBER || $type == CSS_PERCENTAGE || $type == CSS_EMS ||
      $type == CSS_EXS || $type == CSS_PX || $type == CSS_CM ||
      $type == CSS_MM || $type == CSS_IN || $type == CSS_PT ||
      $type == CSS_PC || $type == CSS_DEG || $type == CSS_RAD ||
      $type == CSS_GRAD || $type == CSS_MS || $type == CSS_S ||
      $type == CSS_HZ || $type == CSS_KHZ
       ? $css
    : $type == CSS_STRING
       ? unescape_str $css
    : $type == CSS_IDENT
       ? unescape $css
    : $type == CSS_URI
       ? unescape_url $css
    : $type == CSS_COUNTER
       ? [
          $$prepped[$types =~ /i/, $-[0]],
          $types =~ /'/ ? $$prepped[$-[0]] : undef,
          $types =~ /i.*?i/ ? $$prepped[$+[0]-1] : undef,
         ]
    : $type == CSS_RGBCOLOR
       ? substr $types, 0, 1, eq '#'
         ? $$prepped[0]
         : do{
            my @vals;
            while($types =~ /([%D1])/g) {
             push @vals, [
              type =>
                 $1 eq '%' ? CSS_PERCENTAGE
               : $1 eq 'D' ? $s2c{unescape do{
                              ($$tokens[$-[1]] =~ '(\D+)')[0]
                             }}
               :             CSS_NUMBER,
              value => $1,
              css => $1,
             ]
            }
            \@vals
           }
    : $type == CSS_ATTR
       ? $$prepped[$types =~ /i/, $-[0]]
    : $type == CSS_RECT
       ? [
          map scalar(
           $types =~ /\G.*?(d?([D1])|i)/g,
           $1 eq 'i'
            ? [type => CSS_IDENT, value => 'auto'] #$$prepped[$-[1]]]
            : [
               type =>
                $2 eq 'D'
                 ? $s2c{unescape do{($$tokens[$-[2]] =~ '(\D+)')[0]}}
                 : CSS_NUMBER,
               value => join "", @$tokens[$-[1]...$+[1]-1]
              ]
          ), 1...4
         ]
    : die __PACKAGE__ . " internal error: unknown type: $type"
 }
}

sub _space_out {
 my($types,$tokens) = @_;
Carp'cluck() if ref $tokens ne 'ARRAY';
 $tokens = [@$tokens];
 my @posses;
 $types =~ s/(?<=[^(f])(?![),]|\z)/
  if($tokens->[-1+pos $types] =~ m=^[+-]\z=) {
   ''
  }
  else {
   push @posses, pos $types; 's'
  }
 /ge;
 splice @$tokens, $_, 0, ' ' for reverse @posses;
 return $types, $tokens;
}

# Defined further down, to keep the hairiness out of the way.
my($colour_names_re, $system_colour_names_re);

sub _prep_val {
 defined &unescape or
  require CSS::DOM::Util, 'CSS::DOM::Util'->import('unescape');
 my($types,$tokens);
 if(@_ > 1) {
  ($types,$tokens)= @_;
 }
 else {
  require CSS::DOM::Parser;
  ($types, $tokens) = CSS::DOM::Parser'tokenise($_[0]);
 }

 # strip out all whitespace tokens
 {
  my @posses;
  $tokens = [@$tokens]; # We have to copy it as it may be referenced
  $types =~ s/s/push @posses,pos$types;''/gem;  #  elsewhere.
  splice@$tokens,$_,1 for reverse @posses;
 }
 
 my @prepped;
 my @alt_type;
 for(0..$#$tokens) {
  my $type = substr $types, $_, 1;
  my $thing;
  if($type =~ /[if#]/) {
   $thing = lc unescape($$tokens[$_]);
   if($type eq 'i') {
    if($thing =~ /^$colour_names_re\z/o) { $alt_type[$_] = 'c' }
    elsif($thing =~ /^$system_colour_names_re\z/o) { $alt_type[$_] = 's' }
   }
   elsif($type eq '#') {
    $thing =~ /^#(?:[0-9a-f]{3}){1,2}\z/ and $alt_type[$_] = 'c';#olour
# ~~~ What about escapes?
   }
  }
  elsif($type eq 'D') { # dimension
    ($thing = $$tokens[$_]) =~ s/^[.0-9]+//;
    $thing = lc unescape($thing);
    if($thing =~ /^(?:deg|g?rad)\z/) { $alt_type[$_] = 'a'}#ngle
    elsif($thing =~ /^(?:e[mx]|p[xtc]|in|[cm]m)\z/) {
     $alt_type[$_] = 'l'#ength
    }
  }
  elsif($type eq '1') { # number
    $thing = 0+$$tokens[$_];  # change 0.000 to 0, etc.
  }
  elsif($type eq 'd') { # delimiter
    $alt_type[$_] = '+' if $$tokens[$_] =~ /^[+-]\z/;
  }
  defined $alt_type[$_] or $alt_type[$_] = '';
  push @prepped, $thing;
 }

 return ($types,$tokens,\@prepped,\@alt_type);
}


# Various bits and pieces for _compile_format’s use

$Fail = qr/(?!)/; # avoid recompiling the same sub-regexp doz-
                      # ens of times

# This optionally matches a sign
my $sign = '(?:d(?(?{$$alt_types[pos()-1]eq"+"})|(?!)))?';

# These $type_ expressions save the current value type in @valtypes.
my $type_is_ # generic one to stick inside (?{...})
 =  '$valtypes[$#valtypes='
              . (naughty_perl ? '$pos[-1]' : 'pos()-length$^N')
  . ']=';
my $type_is_dim_or_number
 = '(?{
     $valtypes[
      $#valtypes=' . (naughty_perl ? '$pos[-1]' : 'pos()-length$^N') . '
     ]
      = $$prepped[pos()-1] ? $s2c{ $$prepped[pos()-1] } : CSS_NUMBER
    })';

# Constants defined in _compile_format and only used there get deleted at
# run time.
{ no strict 'refs'; delete @{__PACKAGE__.'::'}{cap_start=>cap_end=>} }

sub _compile_format {
 my $format = shift;
 my $no_match_stuff = shift; # Leave out the @%match localisation stuff

 # The types of transmogrifications we need to make:

 # Whitespace is ignored.
 #
 # [] is simply (?:).
 #
 # () is itself, except we record the captures manually with (?{}).
 #
 # The chars ? * + | are left as is (except when | is doubled).
 #
 # <...>  thingies are replaced with simple regexps that  match  the  type
 # and then check with a re-eval to see whether the token matches.  Then we
 # have another re-eval that records the type of match in @valtypes,  so we
 # can distinguish between ‘red’ matched by  <ident>  (counter-reset: red),
 # ‘red’ matched by <colour> (color: red) and ‘red’ matched by <str/words>
 # (font-family: red).
 #
 # Identifiers are treated similarly.
 #
 # '...' references are turned into complicated re-evals that look up the
 # format for the other property and add it to the %match hash if
 # it matches.
 # 
 # || causes the innermost enclosing group to be transformed into a per-
 # mutation-matching pattern.  Since at least  one  is  required,  we
 # put question marks after all sub-patterns except the  first  in
 # each alternate. For example, a||b||c (where the letters rep-
 # resent sub-patterns, not actual chars in  the  format)
 # becomes a(?:bc?|cb?)?|b(?:ac?|ca?)?|c(?:ab?|ba?)?.

 # Concerning the [@%][Mm]atch variables:
 #
 # All captures are saved separately  in  an  array  during  matching.  To
 # account for backtracking,  we have to localise every  assignment.  Since
 # the localisations will be undone when the re exits, we have to save them
 # in separate variables. The lc vars are used during matching; the capita-
 # lised variables afterwards.  Since we  may  be  parsing  sub-properties
 # (with their own sets of captures), we need a second localisation mechan-
 # ism that restores the previous set of captured values when a sub-proper-
 # ty’s re exits. (We can’t use Perl’s, because the rest of the outer pat-
 # tern is called recursively  from  within  the  inner  pattern.)  So:
 #
 # @match holds arrays of captures, $match[-1] being the current array.
 # When the re exits, @{ $match[-1] } is copied into @Match. Subpatterns
 # push onto @match upon entry and pop it on exit.
# ~~~ Actually, it seems we don’t currently pop it, but all tests pass. Why
#     is this?
 #
 # @list is similar to @match, but it holds all captured matches in the
 # order they matched, skipping those that did not match. It includes mul-
 # tiple elements for quantified captures (that is,  if they matched multi-
 # ple times).  @match,  on the other hand,  is indexed by capture  number,
 # like @-, et al.  In other words, if we match ‘'rhext' 'scled'’ against
 # ‘(<ident>)? (<string>)+’, we have:
 #   @match:  undef (elem 0 is always undef), undef, 'scled'
 #   @list:  'rhext', 'scled'
 #
 # %match holds named captures (sub-properties) directly (no extra locali-
 # sation necessary), which are then copied to %Match afterwards.
 #
 # In perl 5.10.0 (see the definition of naughty_perl, above).  We work
 # around the unreliability of $^N by pushing the current pos onto  @pos
 # before a sub-pattern or capture,  and popping it afterwards.  We  use
 # $pos[-1] instead of pos()-length$^N (for the beginning of the capture).

 my $pattern = $no_match_stuff
  ? '' : '(?{local @match=(@match,[]); local @list=(@list,[])})(?:';
                        # We add (?: to account for top-level alternations.

 my @group_start = length $pattern; # holds the position within $pattern of
                                    # the last group start
 my @permut_marker = []; # where a || occurs (array of arrays; each group
                         # has its own array on this stack)
 my @capture_nums;
 my $last_capture = 0;

 # For each piece of the format, add to the pattern.
 while(
  $format =~ /(\s+)|(\|\|)|<([^>]+)>|([a-z-]+)|([0-9]+)|'([^']+)'|(.)/g
 ) {
  next if $1;  # ignore whitespace

  # cygwin hack:
  use constant {  # re-evals for before and after captures
   cap_start => naughty_perl ? '(?{local @pos=(@pos,pos)})' : '',
   cap_end   => naughty_perl ? '(?{local @pos=@pos; --$#pos})' : '',
  };

  if($2) { # ||
   push @{ $permut_marker[-1] }, length $pattern;
  }
  elsif($3) { # <...>
   # We have to wrap most of these in (?:...) in case they get quantified.
   # (‘ab’ has to become ‘(?:ab)’ so that ‘ab?’ becomes ‘(?:ab)?’.)
   $pattern .=
     $3 eq 'angle'      ?
      "(?:($sign\[D1])" . cap_start . '(?(?{
        $$alt_types[pos()-1]eq"a"||$$prepped[pos()-1]eq 0
       })|(?!))' . $type_is_dim_or_number . cap_end .")"
   : $3 eq 'attr'       ?
      '(?x:' . cap_start . '(
         f(?(?{$$prepped[pos()-1]eq"attr("})|(?!))i\)
       )' . "(?{ $type_is_ CSS_ATTR })" . cap_end . ")"
   : $3 =~ /^colou?r\z/ ?
      "(?x:" . cap_start . "(?:
        ([i#](?(?{
          \$\$alt_types[pos()-1]eq 'c'||\$\$alt_types[pos()-1]eq 's'
        })|(?!))) (?{ $type_is_ (
                   \$\$alt_types[pos()-1]eq 'c' ? CSS_RGBCOLOR : CSS_IDENT
                  ) })
         |
        (f
          (?:
           (?(?{\$\$prepped[pos()-1]eq 'rgb('})|(?!))
           (?: $sign 1(?:,$sign 1){2} | $sign%(?:,$sign%){2} )
            |
           (?(?{\$\$prepped[pos()-1]eq 'rgba('})|(?!))
           (?: $sign 1(?:,$sign 1){2} | $sign%(?:,$sign%){2} ),$sign 1
          )
        \\)) (?{ $type_is_ CSS_RGBCOLOR })
       )" . cap_end . ")"

   # <counter> represents the following four:
   #  counter(<identifier>)
   #  counter(<identifier>,'list-style-type')
   #  counters(<identifier>,<string>)
   #  counters(<identifier>,<string>,'list-style-type')
   : $3 eq 'counter'    ? do {
      our $Self;
      my $list_style_type = old_perl
       ? exists $$Self{"list-style-type"}
         ? $compiled{$$Self{"list-style-type"}{format}}
            ||= _compile_format($$Self{"list-style-type"}{format})
         : '(?!)'
       : '(??{
             exists $$Self{"list-style-type"}
             ? $compiled{$$Self{"list-style-type"}{format}}
             : $Fail
            })'
      ;
      q*(?x:* . cap_start . q*(f(?{$$prepped[pos()-1]})
          (?(?{$^R eq "counter("})
            i(?:,* . $list_style_type . q*)?
             |
            (?(?{$^R eq "counters("})
              i,'(?:,* . $list_style_type . q*)?
               |
              (?!)
            )
          )
        \))*
        . "(?{ $type_is_ CSS_COUNTER;"
           . ' $valtypes[$#valtypes=pos()-1] = -1})' # -1 is a special
           . cap_end . ')'                           # marker for the end
     }                                               # of a counter
   : $3 eq 'frequency'  ?
      '(?:' . cap_start . '((?:d(?(?{
         $$tokens[pos()-1]eq"+"||$$tokens[-1+pos]eq"-"&&$$tokens[pos]eq 0
       })|(?!)))?[D1](?(?{
        my$p=$$prepped[pos()-1];$p eq"hz"||$p eq"khz"||$p eq 0
       })|(?!)))' . $type_is_dim_or_number . cap_end . ")"
   : $3 eq 'identifier' ?
      "(?:" . cap_start . "(i)(?{ $type_is_ CSS_IDENT })" . cap_end . ")"
   : $3 eq 'integer'    ?
      '(?:' . cap_start . '(1(?(?{index$$tokens[pos()-1],".",==-1})|(?!)))'
      . "(?{ $type_is_ CSS_NUMBER })" . cap_end . ")"
   : $3 eq 'length'     ?
      "(?:" . cap_start . "($sign\[D1])" . '(?(?{
        $$alt_types[pos()-1]eq"l"||$$prepped[pos()-1]eq 0
       })|(?!))' . $type_is_dim_or_number . cap_end . ")"
   : $3 eq 'number'     ?
      "(?:" . cap_start . "(1)(?{ $type_is_ CSS_NUMBER })" . cap_end . ")"
   : $3 eq 'percentage' ?
       "(?:" . cap_start
        . "($sign%)(?{ $type_is_ CSS_PERCENTAGE })"
      . cap_end . ")"
   : $3 eq 'shape'      ?
      q*(?x:* . cap_start . q*(f
          (?(?{$$prepped[pos()-1] eq "rect("})
            (?:
             (?:
              (?:d(?(?{$$alt_types[pos()-1]eq"+"})|(?!)))?[D1](?(?{
               $$alt_types[pos()-1]eq"l"||$$prepped[pos()-1] eq 0
              })|(?!))
               |
              i(?(?{$$prepped[pos()-1]eq"auto"})|(?!))
             ),?
            ){4}
             |
            (?!)
          )
        \))* . "(?{ $type_is_ CSS_RECT })" . cap_end . ")"
   : $3 eq 'string'     ?
      "(?:" . cap_start . "(')(?{ $type_is_ CSS_STRING })" . cap_end . ")"
   : $3 eq 'str/words'  ?
        "(?:" . cap_start
        . "('|i+)(?{ $type_is_ CSS_STRING })"
      . cap_end . ")"
   : $3 eq 'time'       ?
      "(?:" . cap_start . "($sign\[D1])" . '(?(?{
        my$p=$$prepped[pos()-1];$p eq"ms"||$p eq"s"||$p eq 0
       })|(?!))' . $type_is_dim_or_number . cap_end . ")"
   : $3 eq 'url'        ?
      "(?:" . cap_start . "(u)(?{ $type_is_ CSS_URI })" . cap_end . ")"
   : die "Unrecognised data type in property format: <$3>";
  }
  elsif($4) { # identifier
   $pattern .=
     '(?:' . cap_start
       . '(i)(?(?{$$prepped[-1+pos]eq"' . $4 . '"})|(?!))'
       . "(?{ $type_is_ CSS_IDENT })"
    . cap_end . ")";
  }
  elsif($5) { # number
   $pattern .=
     '(?:' . cap_start
             . '(1)(?(?{$$tokens[-1+pos]eq"' . $5 . '"})|(?!))'
             . "(?{ $type_is_ CSS_NUMBER })"
    . cap_end . ")";
  }
  elsif($6) { # '...' reference
   $pattern .=
    '(?:' # again, we use (?: ... ) in case a question mark is added
   .  cap_start
   . '((??{
               exists $$Self{"' . $6 . '"}
               ? $compiled{$$Self{"' . $6 . '"}{format}}
               : $Fail;
      }))'
   . '(?{
       # We have a do-block here because a re-eval’s lexical pad is very
       # buggy and must not be used. (See perl bug #65150.)
       local$match{"'.$6.'"}=do{
         my @range
          = ' . (naughty_perl ? '$pos[-1]' : 'pos()-length$^N') . '
              ...-1+pos;
         [
          '.(
             naughty_perl ? 'substr($_,$pos[-1],pos()-$pos[-1])' : '$^N'
            ).',
           [@$tokens[@range]],[@valtypes[@range]],[@$prepped[@range]]
         ];
       }
      })'
   .  cap_end
   .')'
              
  }
  elsif(do{$7 =~ /^[]|[()]\z/}) { # group or alternation
   # For non-capturing groups, we use (?: ... ).
   # For capturing groups, since they may be quantified, and since we have
   # to put a re-eval after them to capture the value, we use an extra non-
   # capturing group: (?:( ... )(?{...}))
   # Since || is stronger than |, we have to treat | a bit like ][

   if(do{$7 =~ /^[])|]\z/}) { # end of a group
    my $markers = pop @permut_marker;
    if(@$markers) { # Oh no!
     unshift @$markers, $group_start[-1];
     _make_permutations($pattern, $markers);
    }
    pop @group_start;
    $pattern .=
       $7 eq '|' ? '|'
     : $7 eq ']' ? ')'
     : ')(?{
          (
           local $match[-1][' . pop(@capture_nums) . '],
           local $list[-1]
          ) = do {
           my @range
            = '.(naughty_perl ? '$pos[-1]' : 'pos()-length$^N').'...-1+pos;
           my @a = (
            '.(
               naughty_perl
                ? 'substr($_,$pos[-1],pos()-$pos[-1])'
                : '$^N'
              ).',
             [@$tokens[@range]],[@valtypes[@range]],[@$prepped[@range]],
             pos
           );
           \@a, [@{$list[-1]}, \@a]
          }
        })' . cap_end . ')';
     # We have to intertwine these assignments in this convoluted way
     # because of the lexical-in-re-eval bug [perl #65150].
   }
   if(do{$7 =~ /^[[(|]\z/}) { # start of a group
    $pattern
     .= '(?:'
      . (cap_start.'(')
          x ($7 eq '(')
     unless $7 eq '|';
    push @group_start, length $pattern;
    push @permut_marker, [];
    $7 eq '(' and push @capture_nums, ++$last_capture;
   }
  }
  else {
   $pattern .= do{$7 =~ /^[?*+]\z/}   ? $7
             : do{$7 =~ /^[;{},:]\z/} ? quotemeta $7
             :  '(?:d(?(?{$$tokens[-1+pos]eq"' .quotemeta($7) .'"})|(?!)))'
             ;
  }
 }

 # There may be top-level ‘||’ things, so we check for those.
 if(@{$permut_marker[0]}) {
    unshift @{ $permut_marker[0] }, $group_start[0];
    _make_permutations($pattern, $permut_marker[0]);
 }

 # Deal with the match vars
 $pattern .= ')(?{@Match=@{$match[-1]};@List=@{$list[-1]};%Match=%match})'
  unless $no_match_stuff;

 use re 'eval';
 return qr/$pattern/;
}

sub _make_permutations { # args: pattern, \@markers
                         # pattern is modified in-place
 my $markers = pop;
 for my $pattern($_[0]) {
    # Split up the end of the pattern back to the beginning of the inner-
    # most enclosing group, as specified by the markers. Put the separate
    # pieces into @alts.
    my @alts;
    for(reverse @$markers) {
     unshift @alts, substr $pattern, $_, length $pattern, '';
    }
    
    # Do the permutations
    $pattern .= _permute(@alts);
 }
}

sub _permute {
 if(@_ == 2) { return "(?:$_[0]$_[1]?|$_[1]$_[0]?)" }
 else {
  return
     "(?:"
   . join("|", map $_[$_] . _permute(@_[0..$_-1,$_+1...$#_]) . '?', 0..$#_)
   . ")"
 }
}


=begin comment

Colour names:

perl -MRegexp::Assemble -le 'my $ra = new Regexp::Assemble; $ra->add($_) for qw " transparent aliceblue antiquewhite aqua aquamarine azure beige bisque black blanchedalmond blue blueviolet brown burlywood cadetblue chartreuse chocolate coral cornflowerblue cornsilk crimson cyan darkblue darkcyan darkgoldenrod darkgray darkgreen darkgrey darkkhaki darkmagenta darkolivegreen darkorange darkorchid darkred darksalmon darkseagreen darkslateblue darkslategray darkslategrey darkturquoise darkviolet deeppink deepskyblue dimgray dimgrey dodgerblue firebrick floralwhite forestgreen fuchsia gainsboro ghostwhite gold goldenrod gray green greenyellow grey honeydew hotpink indianred indigo ivory khaki lavender lavenderblush lawngreen lemonchiffon lightblue lightcoral lightcyan lightgoldenrodyellow lightgray lightgreen lightgrey lightpink lightsalmon lightseagreen lightskyblue lightslategray lightslategrey lightsteelblue lightyellow lime limegreen linen magenta maroon mediumaquamarine mediumblue mediumorchid mediumpurple mediumseagreen mediumslateblue mediumspringgreen mediumturquoise mediumvioletred midnightblue mintcream mistyrose moccasin navajowhite navy oldlace olive olivedrab orange orangered orchid palegoldenrod palegreen paleturquoise palevioletred papayawhip peachpuff peru pink plum powderblue purple red rosybrown royalblue saddlebrown salmon sandybrown seagreen seashell sienna silver skyblue slateblue slategray slategrey snow springgreen steelblue tan teal thistle tomato turquoise violet wheat white whitesmoke yellow yellowgreen"; print $ra->re '

perl -MRegexp::Assemble -le 'my $ra = new Regexp::Assemble; $ra->add($_) for qw " activeborder activecaption appworkspace background buttonface buttonhighlight buttonshadow buttontext captiontext graytext highlight highlighttext inactiveborder inactivecaption incativecaptiontext infobackground infotext menu menutext scrollbar threeddarkshadow threedface threedhighlight threedlightshadow threedshadow window windowframe windowtext  "; print $ra->re '

=end comment

=cut

$colour_names_re = '(?:d(?:ark(?:s(?:late(?:gr[ae]y|blue)|(?:eagree|almo)n)|g(?:r(?:e(?:en|y)|ay)|oldenrod)|o(?:r(?:ange|chid)|livegreen)|(?:turquois|blu)e|magenta|violet|khaki|cyan|red)|eep(?:skyblue|pink)|imgr[ae]y|odgerblue)|l(?:i(?:ght(?:s(?:(?:eagree|almo)n|(?:teel|ky)blue|lategr[ae]y)|g(?:r(?:e(?:en|y)|ay)|oldenrodyellow)|c(?:oral|yan)|yellow|blue|pink)|me(?:green)?|nen)|a(?:vender(?:blush)?|wngreen)|emonchiffon)|m(?:edium(?:(?:aquamarin|turquois|purpl|blu)e|s(?:(?:pring|ea)green|lateblue)|(?:violetre|orchi)d)|i(?:(?:dnightblu|styros)e|ntcream)|a(?:genta|roon)|occasin)|s(?:(?:a(?:(?:ddle|ndy)brow|lmo)|pringgree)n|late(?:gr[ae]y|blue)|ea(?:green|shell)|(?:teel|ky)blue|i(?:enna|lver)|now)|p(?:a(?:le(?:g(?:oldenrod|reen)|turquoise|violetred)|payawhip)|(?:owderblu|urpl)e|e(?:achpuff|ru)|ink|lum)|c(?:(?:h(?:artreus|ocolat)|adetblu)e|or(?:n(?:flowerblue|silk)|al)|(?:rimso|ya)n)|b(?:l(?:a(?:nchedalmond|ck)|ue(?:violet)?)|(?:isqu|eig)e|urlywood|rown)|g(?:r(?:e(?:en(?:yellow)?|y)|ay)|ol(?:denro)?d|hostwhite|ainsboro)|o(?:l(?:ive(?:drab)?|dlace)|r(?:ange(?:red)?|chid))|a(?:(?:ntiquewhit|liceblu|zur)e|qua(?:marine)?)|t(?:(?:urquois|histl)e|ransparent|omato|eal|an)|f(?:loralwhite|orestgreen|irebrick|uchsia)|r(?:o(?:sybrown|yalblue)|ed)|i(?:ndi(?:anred|go)|vory)|wh(?:it(?:esmok)?e|eat)|ho(?:neydew|tpink)|nav(?:ajowhite|y)|yellow(?:green)?|violet|khaki)';

$system_colour_names_re = '(?:in(?:active(?:caption|border)|fo(?:background|text)|cativecaptiontext)|b(?:utton(?:(?:highligh|tex)t|shadow|face)|ackground)|threed(?:(?:light|dark)?shadow|highlight|face)|(?:(?:caption|gray)tex|highligh(?:ttex)?)t|a(?:ctive(?:caption|border)|ppworkspace)|window(?:frame|text)?|menu(?:text)?|scrollbar)';

=encoding utf8

=head1 NAME

CSS::DOM::PropertyParser - Parser for CSS property values

=head1 VERSION

Version 0.17

=head1 SYNOPSIS

  use CSS::DOM::PropertyParser;
  
  $spec = new CSS::DOM::PropertyParser; # empty
  # OR
  $spec = $CSS::DOM::PropertyParser::Default->clone;
  
  $spec->add_property(
   overflow => {
    format => 'visible|hidden|scroll|auto',
    default => 'visible',
    inherit => 0,
   }
  );
  
  $hashref = $spec->get_property('overflow');
  
  $hashref = $spec->delete_property('overflow');
  
  @names = $spec->property_names;

=head1 DESCRIPTION

Objects of this class provide lists of supported properties for L<CSS::DOM>
style sheets. They also describe the syntax and parsing of those 
properties' values.

Some CSS properties simply have their own values (e.g., overflow); some
are abbreviated forms of several other properties (e.g., font). These are
referred to in this documentation as 'simple' and 'shorthand' properties.

=head1 CONSTRUCTOR

C<$spec = new CSS::DOM::PropertyParser> returns an object that does not
recognise any properties, to which you
can add your own properties.

There are two parser objects that come with this module. These are
C<$CSS::DOM::PropertyParser::CSS21>, which contains all of CSS 2.1, and
C<$CSS::DOM::PropertyParser::Default>, which is currently identical to the
former, but to which parts of CSS 3 which eventually be added.

If one of the default specs will do, you don't need a constructor. Simply
pass it to the L<CSS::DOM> constructor. If you want to modify it, clone it
first, using the C<clone> method (as shown in the L</SYNOPSIS>). It is
often convenient to clone the C<$Default> spec and delete those properties
that are not supported.

=head1 METHODS

=for comment
=head2 Methods for Controlling Property Specifications

=over 4

=item clone

Returns a deep clone of the object. (It's deep so that you can modify the
hashes/arrays inside it without modifying the original.)

=item add_property ( $name, \%spec )

Adds the specification for the named property. See
L</HOW INDIVIDUAL PROPERTIES ARE SPECIFIED>, below.

=item get_property ( $name )

Returns the hashref passed to the previous method.

=item delete_property ( $name )

Deletes the property and returns the hash ref.

=item property_names

Returns a list of the names of supported properties.

=item subproperty_names ( $name )

Returns a list of the names of C<$name>'s sub-properties if it is a
shorthand property.

=item match

Currently for internal use only. See the source code for documentation.
Use at your own risk.

=back

=begin comment

Once I’ve made CSS::DOM::Parser’s tokenise routine public (after a bit of
polishing) (or broken it out into a separate module, CSS::Tokeniser), I’ll
add this to the docs. I also actually have to modify ‘match’ to use this
interface, of course.

=head2 Methods Used by L<CSS::DOM::Style>

If you are thinking of writing a subclass of PropertyParser, you need to be
aware of these methods.

Instead of writing a subclass, you can create your
own class that does not inherit from PropertyParser use that. It will need 
to
implement these methods here. The methods listed above can be omitted.

=over

=item match ( $property, $value )

=item match ( $property, $token_types, \@tokens )

This checks to see whether C<$value> is a valid value for the C<$property>,
parsing it if it is. C<$token_types> and C<@tokens> are the values returned
by C<CSS::DOM::Parser::tokenise>.

Return values are as follows:

If the value doesn't match: empty list.

If the property is a simple one: (0) the CSS 
code for the value (possibly normalised), (1) the class to which a value
object belongs, (2..) arguments to be passed to the constructor.

For a shorthand property, the return value is a single hash ref, the keys
being sub-property names and the values array refs containing what would be
returned for a simple property.

A custom class or subclass can return a L<CSS::DOM::Value> instead of the
class and constructor args, in which case the first return value can
simply be C<undef> (it should return C<(undef, $object)>).

Examples (return value starts on the line following each method call):

 # $prim stands for "CSS::DOM::Value::Primitive"
 # $list stands for "CSS::DOM::Value::List"
 
 $prop_parser->match('background-position','top left');
 'top left', 'CSS::DOM::Value', CSS_CUSTOM, 'top left'
 
 $prop_parser->match('background-position','inherit');
 'inherit', 'CSS::DOM::Value', CSS_INHERIT
 
 $prop_parser->match('top','1em');
 '1em', $prim, type => CSS_EMS, value => 1

 $prop_parser->match('content','"\66oo"');
 '"\66oo"', $prim, type => CSS_STRING, value => foo
 
 $prop_parser->match('clip','rect( 5px, 6px, 7px, 8px )');
 'rect(5px, 6px, 7px, 8px)', $prim,
   type => CSS_RECT,
   value => [ [ type => CSS_PX, value => 5 ],
              [ type => CSS_PX, value => 6 ],
              [ type => CSS_PX, value => 7 ],
              [ type => CSS_PX, value => 8 ] ]
 
 $prop_parser->match('color','#fff');
 '#fff', $prim, type => CSS_RGBCOLOR, value => '#fff'
 
 $prop_parser->match('color','rgba(255,0,0,.5)');
 'rgba(255, 0, 0, .5)', $prim, type => CSS_RGBCOLOR,
   value => [ [ type => CSS_NUMBER, value => 255 ],
              [ type => CSS_NUMBER, value => 0   ],
              [ type => CSS_NUMBER, value => 0   ],
              [ type => CSS_NUMBER, value => .5  ] ]
 
 $prop_parser->match('content','counter(foo,disc)');
 'counter(foo, disc)', $list,
   separator => ' ',
   values => [
    [
     type => CSS_COUNTER,
     value => [
      [ type => CSS_IDENT, value => 'foo' ],
      undef,
      [ type => CSS_IDENT, value => 'disc' ],
     ]
    ],
   ]
 
 $prop_parser->match('font-family','Lucida Grande');
 'Lucida Grande', $list,
   separator => ', ',
   values => [
    [ type => CSS_STRING, value => 'Lucida Grande' ],
   ]

 $prop_parser->match('counter-reset','Lucida Grande');
 'Lucida Grande', $list,
   separator => ' ',
   values => [
    [ type => CSS_IDENT, value => 'Lucida' ],
    [ type => CSS_IDENT, value => 'Grande' ],
   ]
 
 $prop_parser->match('font','bold 13px Lucida Grande');
 {
  'font-style' => [
    'normal', $prim, type => CSS_IDENT, value => 'normal'
   ],
  'font-variant' => [
    'normal', $prim, type => CSS_IDENT, value => 'normal'
   ],
  'font-weight' => [
    'bold', $prim, type => CSS_IDENT, value => 'bold'
   ],
  'font-size' => [ '13px', $prim, type => CSS_PX, value => 13 ],
  'line-height' => [
    'normal', $prim, type => CSS_IDENT, value => 'normal'
   ],
  'font-family' => [ 'Lucida Grande', $list,
    separator => ', ',
    values => [
     [ type => CSS_STRING, value => 'Lucida Grande' ],
    ]
   ]
 }

=item whatever

~~~ 
CSS::DOM::Style currently relies on the internal formatting of the hash
refs. I want to allow custom property parser classes to do away with hash 
refs
altogether, so I will need extra methods here that Style will use instead.

=back

=end comment

=head1 HOW INDIVIDUAL PROPERTIES ARE SPECIFIED

Before you read this the first time, look at the L</Example> below, and
then come back and use this for reference.

The specification for an individual property is a hash ref. There are
several keys that each hash ref can have:

=over

=item format

This is set to a string that describes the format of the property. The
syntax used is based on the CSS 2.1 spec, but is not exactly the same.
Unlike regular expressions, these formats are applied to properties on a
token-by-token basis, not one character at a time. (This means that
C<100|200> cannot be written as C<[1|2]00>, as that would mean
S<C<1 00 | 2 00>>.)

Whitespace is ignored in the format and in the CSS property except as a
token separator.

There are several metachars (in order of precedence):

 [...]      grouping (like (?:...) )
 (...)      capturing group (just like a regexp)
 ?          optional
 *          zero or more
 +          one or more
 ||         alternates that can come in any order and are optional,
            but at least one must be specified  (the order will be
            retained if possible)
 |          alternates, exactly one of which is required

In addition, the following datatypes can be specified in angle brackets:

 <angle>       A number with a 'deg', 'rad' or 'grad' suffix
 <attr>        attr(...)
 <colour>      (You can omit the 'u' if you want to.) One of CSS's
               predefined colour or system colour names, or a #
               followed by 3 or 6 hex digits, or the 'rgb(...)'
               format (rgba is supported, too)
 <counter>     counter(...)
 <frequency>   A unit of Hz or kHz
 <identifier>  An identifier token
 <integer>     An integer (really?!)
 <length>      Number followed by a length unit (em, ex, px, in, cm,
               mm, pt, pc)
 <number>      A number token
 <percentage>  Number followed by %
 <shape>       rect(...)
 <string>      A string token
 <str/words>   A sequence of identifiers or a single string (e.g., a
               font name)
 <time>        A unit of seconds or milliseconds
 <url>         A URL token

The format for a shorthand property can contain the name of a sub-property
in single ASCII quotes.

All other characters are understood verbatim.

It is not necessary to include the word 'inherit' in the format, since
every property supports that.

C<< <counter> >> makes use of the specification for the list-style-type
property. So if you modify the latter, it will affect C<< <counter> >> as
well.

=item default

The default value. This only applies to simple properties.

=item inherit

Whether the property is inherited.

=item special_values

A hash ref of values that are replaced with other values (e.g.,
S<C<< caption => '13px sans-serif' >>>.) The keys
are lowercase identifier names.

This feature only applies to single identifiers. In fact, it exists solely
for the font property's use.

=item list

Set to true if the property is a list of values. The capturing parentheses
in the format determine the individual values of the list.

This applies to simple properties only.

=item properties

For a shorthand property, list the sub-properties here. The keys are the
property names. The values are array refs. The elements within the arrays
are numbers indicating which captures in the format are to be used for the
sub-property's value. They are tried one after the other. Whichever is the
first that matches (null matches not counting) is used.

Sub-properties that are referenced in the C<format> need not be listed 
here.

=item serialise

For shorthand properties only. Set this to a subroutine that serialises the
property. It is called with a hashref of sub-properties as its sole 
argument. The values of the hash are blank for properties that are set to
their initial values. This sub is only called when all sub-properties are
set.

=back

=head2 Example

=cut

0&&q r

=for ;

  our $CSS21 = new CSS::DOM::PropertyParser;
  my %properties = (
    azimuth => {
     format => '<angle> |
                 [ left-side | far-left | left | center-left |
                   center | center-right | right | far-right |
                   right-inside ] || behind
                | leftwards | rightwards',
     default => '0',
     inherit => 1,
    },

   'background-attachment' => {
     format  => 'scroll | fixed',
     default => 'scroll',
     inherit => 0,
    },

   'background-color' => {
     format  => '<colour>',
     default => 'transparent',
     inherit => 0,
    },

   'background-image' => {
     format => '<url> | none',
     default => 'none',
     inherit => 0,
    },
    
   'background-position' => {
     format => '[<percentage>|<length>|left|right]
                 [<percentage>|<length>|top|center|bottom]? |
                [top|bottom] [left|center|right]? |
                center [<percentage>|<length>|left|right|top|bottom|
                        center]?',
     default => '0% 0%',
     inherit => 0,
    },
    
   'background-repeat' => {
     format => 'repeat | repeat-x | repeat-y | no-repeat',
     default => 'repeat',
     inherit => 0,
    },
    
    background => {
     format => "'background-color' || 'background-image' ||
                'background-repeat' || 'background-attachment' ||
                'background-position'",
     serialise => sub {
      my $p = shift;
      my $ret = '';
      for(qw/ background-color background-image background-repeat
              background-attachment background-position /) {
       length $p->{$_} and $ret .= "$p->{$_} ";
      }
      chop $ret;
      length $ret ? $ret : 'none'
     },
    },
    
   'border-collapse' => {
     format => 'collapse | separate',
     inherit => 1,
     default => 'separate',
    },
    
   'border-color' => {
     format => '(<colour>)[(<colour>)[(<colour>)(<colour>)?]?]?',
     properties => {
      'border-top-color' => [1],
      'border-right-color' => [2,1],
      'border-bottom-color' => [3,1],
      'border-left-color' => [4,2,1],
     },
     serialise => sub {
       my $p = shift;
       my @vals = map $p->{"border-$_-color"},
                      qw/top right bottom left/;
       $vals[3] eq $vals[1] and pop @vals,
       $vals[2] eq $vals[0] and pop @vals,
       $vals[1] eq $vals[0] and pop @vals;
       return join " ", @vals;
     },
    },
    
   'border-spacing' => {
     format => '<length> <length>?',
     default => '0',
     inherit => 1,
    },
    
   'border-style' => {
     format => "(none|hidden|dotted|dashed|solid|double|groove|ridge|
                 inset|outset)
                [ (none|hidden|dotted|dashed|solid|double|groove|
                   ridge|inset|outset)
                  [ (none|hidden|dotted|dashed|solid|double|groove|
                     ridge|inset|outset)
                    (none|hidden|dotted|dashed|solid|double|groove|
                     ridge|inset|outset)?
                  ]?
                ]?",
     properties => {
      'border-top-style' => [1],
      'border-right-style' => [2,1],
      'border-bottom-style' => [3,1],
      'border-left-style' => [4,2,1],
     },
     serialise => sub {
       my $p = shift;
       my @vals = map $p->{"border-$_-style"},
                      qw/top right bottom left/;
       $vals[3] eq $vals[1] and pop @vals,
       $vals[2] eq $vals[0] and pop @vals,
       $vals[1] eq $vals[0] and pop @vals;
       return join " ", map $_||'none', @vals;
     },
    },
    
   'border-top' => {
     format => "'border-top-width' || 'border-top-style' ||
                'border-top-color'",
     serialise => sub {
       my $p = shift;
       my $ret = '';
       for(qw/ width style color /) {
         length $p->{"border-top-$_"}
           and $ret .= $p->{"border-top-$_"}." ";
       }
       chop $ret;
       $ret
     },
    },
   'border-right' => {
     format => "'border-right-width' || 'border-right-style' ||
                'border-right-color'",
     serialise => sub {
       my $p = shift;
       my $ret = '';
       for(qw/ width style color /) {
         length $p->{"border-right-$_"}
           and $ret .= $p->{"border-right-$_"}." ";
       }
       chop $ret;
       $ret
     },
    },
   'border-bottom' => {
     format => "'border-bottom-width' || 'border-bottom-style' ||
                'border-bottom-color'",
     serialise => sub {
       my $p = shift;
       my $ret = '';
       for(qw/ width style color /) {
         length $p->{"border-bottom-$_"}
           and $ret .= $p->{"border-bottom-$_"}." ";
       }
       chop $ret;
       $ret
     },
    },
   'border-left' => {
     format => "'border-left-width' || 'border-left-style' ||
                'border-left-color'",
     serialise => sub {
       my $p = shift;
       my $ret = '';
       for(qw/ width style color /) {
         length $p->{"border-left-$_"}
           and $ret .= $p->{"border-left-$_"}." ";
       }
       chop $ret;
       $ret
     },
    },
    
   'border-top-color' => {
     format => '<colour>',
     default => "",
     inherit => 0,
    },
   'border-right-color' => {
     format => '<colour>',
     default => "",
     inherit => 0,
    },
   'border-bottom-color' => {
     format => '<colour>',
     default => "",
     inherit => 0,
    },
   'border-left-color' => {
     format => '<colour>',
     default => "",
     inherit => 0,
    },
    
   'border-top-style' => {
     format => 'none|hidden|dotted|dashed|solid|double|groove|ridge|
                inset|outset',
     default => 'none',
     inherit => 0,
    },
   'border-right-style' => {
     format => 'none|hidden|dotted|dashed|solid|double|groove|ridge|
                inset|outset',
     default => 'none',
     inherit => 0,
    },
   'border-bottom-style' => {
     format => 'none|hidden|dotted|dashed|solid|double|groove|ridge|
                inset|outset',
     default => 'none',
     inherit => 0,
    },
   'border-left-style' => {
     format => 'none|hidden|dotted|dashed|solid|double|groove|ridge|
                inset|outset',
     default => 'none',
     inherit => 0,
    },
    
   'border-top-width' => {
     format => '<length>|thin|thick|medium',
     default => 'medium',
     inherit => 0,
    },
   'border-right-width' => {
     format => '<length>|thin|thick|medium',
     default => 'medium',
     inherit => 0,
    },
   'border-bottom-width' => {
     format => '<length>|thin|thick|medium',
     default => 'medium',
     inherit => 0,
    },
   'border-left-width' => {
     format => '<length>|thin|thick|medium',
     default => 'medium',
     inherit => 0,
    },
    
   'border-width' => {
     format => "(<length>|thin|thick|medium)
                [ (<length>|thin|thick|medium)
                  [ (<length>|thin|thick|medium)
                    (<length>|thin|thick|medium)?
                  ]?
                ]?",
     properties => {
      'border-top-width' => [1],
      'border-right-width' => [2,1],
      'border-bottom-width' => [3,1],
      'border-left-width' => [4,2,1],
     },
     serialise => sub {
       my $p = shift;
       my @vals = map $p->{"border-$_-width"},
                      qw/top right bottom left/;
       $vals[3] eq $vals[1] and pop @vals,
       $vals[2] eq $vals[0] and pop @vals,
       $vals[1] eq $vals[0] and pop @vals;
       return join " ", map length $_ ? $_ : 'medium', @vals;
     },
    },
    
    border => {
     format => "(<length>|thin|thick|medium) ||
                (none|hidden|dotted|dashed|solid|double|groove|ridge|
                 inset|outset) || (<colour>)",
     properties => {
      'border-top-width' => [1],
      'border-right-width' => [1],
      'border-bottom-width' => [1],
      'border-left-width' => [1],
      'border-top-style' => [2],
      'border-right-style' => [2],
      'border-bottom-style' => [2],
      'border-left-style' => [2],
      'border-top-color' => [3],
      'border-right-color' => [3],
      'border-bottom-color' => [3],
      'border-left-color' => [3],
     },
     serialise => sub {
       my $p = shift;
       my $ret = '';
       for(qw/ width style color /) {
         my $temp = $p->{"border-top-$_"};
         for my $side(qw/ right bottom left /) {
           $temp eq $p->{"border-$side-$_"} or return "";
         }
         length $temp and $ret .= "$temp ";
       }
       chop $ret;
       $ret
     },
    },
    
    bottom => {
     format => '<length>|<percentage>|auto',
     default => 'auto',
     inherit => 0,
    },
    
   'caption-side' => {
     format => 'top|bottom',
     default => 'top',
     inherit => 1,
    },
    
    clear => {
     format => 'none|left|right|both',
     default => 'none',
     inherit => 0,
    },
    
    clip => {
     format => '<shape>|auto',
     default => 'auto',
     inherit => 0,
    },
    
    color => {
     format => '<colour>',
     default => 'rgba(0,0,0,1)',
     inherit => 1,
    },
    
    content => {
     format => '( normal|none|open-quote|close-quote|no-open-quote|
                  no-close-quote|<string>|<url>|<counter>|<attr> )+',
     default => 'normal',
     inherit => 0,
     list => 1,
    },
    
   'counter-increment' => {
     format => '[(<identifier>) (<integer>)? ]+ | none',
     default => 'none',
     inherit => 0,
     list => 1,
    },
   'counter-reset' => {
     format => '[(<identifier>) (<integer>)? ]+ | none',
     default => 'none',
     inherit => 0,
     list => 1,
    },
    
   'cue-after' => {
     format => '<url>|none',
     default => 'none',
     inherit => 0,
    },
   'cue-before' => {
     format => '<url>|none',
     default => 'none',
     inherit => 0,
    },
    
    cue =>{
     format => '(<url>|none) (<url>|none)?',
     properties => {
      'cue-before' => [1],
      'cue-after' => [2,1],
     },
     serialise => sub {
       my $p = shift;
       my @vals = @$p{"cue-before", "cue-after"};
       $vals[1] eq $vals[0] and pop @vals;
       return join " ", map length $_ ? $_ : 'none', @vals;
     },
    },
    
    cursor => {
     format => '[(<url>) ,]* 
                (auto|crosshair|default|pointer|move|e-resize|
                 ne-resize|nw-resize|n-resize|se-resize|sw-resize|
                 s-resize|w-resize|text|wait|help|progress)',
     default => 'auto',
     inherit => 1,
     list => 1,
    },
    
    direction => {
     format => 'ltr|rtl',
     default => 'ltr',
     inherit => 1,
    },
    
    display => {
     format => 'inline|block|list-item|run-in|inline-block|table|
                inline-table|table-row-group|table-header-group|
                table-footer-group|table-row|table-column-group|
                table-column|table-cell|table-caption|none',
     default => 'inline',
     inherit => 0,
    },
    
    elevation => {
     format => '<angle>|below|level|above|higher|lower',
     default => '0',
     inherit => 1,
    },
    
   'empty-cells' => {
     format => 'show|hide',
     default => 'show',
     inherit => 1,
    },
    
    float => {
     format => 'left|right|none',
     default => 'none',
     inherit => 0,
    },
    
   'font-family' => { # aka typeface
     format => '(serif|sans-serif|cursive|fantasy|monospace|
                 <str/words>)
                [,(serif|sans-serif|cursive|fantasy|monospace|
                   <str/words>)]*',
     default => 'Times, serif',
     inherit => 1,
     list => 1,
    },
    
   'font-size' => {
     format => 'xx-small|x-small|small|medium|large|x-large|xx-large|
                larger|smaller|<length>|<percentage>',
     default => 'medium',
     inherit => 1,
    },
    
   'font-style' => {
     format => 'normal|italic|oblique',
     default => 'normal',
     inherit => 1,
    },
    
   'font-variant' => {
     format => 'normal | small-caps',
     default => 'normal',
     inherit => 1,
    },
    
   'font-weight' => {
     format => 'normal|bold|bolder|lighter|
                100|200|300|400|500|600|700|800|900',
     default => 'normal',
     inherit => 1,
    },
    
    font => {
     format => "[ 'font-style' || 'font-variant' || 'font-weight' ]?
                'font-size' [ / 'line-height' ]? 'font-family'",
     special_values => {
       caption => '13px Lucida Grande, sans-serif',
       icon => '13px Lucida Grande, sans-serif',
       menu => '13px Lucida Grande, sans-serif',
      'message-box' => '13px Lucida Grande, sans-serif',
      'small-caption' => '11px Lucida Grande, sans-serif',
      'status-bar' => '10px Lucida Grande, sans-serif',
     },
     serialise => sub {
       my $p = shift;
       my $ret = '';
       for(qw/ style variant weight /) {
         length $p->{"font-$_"}
           and $ret .= $p->{"font-$_"}." ";
       }
       $ret .= length $p->{'font-size'}
               ? $p->{'font-size'}
               : 'medium';
       $ret .= "/$p->{'line-height'}" if length $p->{'line-height'};
       $ret .= " " . ($p->{'font-family'} || "Times, serif");
       $ret
     },
    },
    
    height => {
     format => '<length>|<percentage>|auto',
     default => 'auto',
     inherit => 0,
    },
    
    left => {
     format => '<length>|<percentage>|auto',
     default => 'auto',
     inherit => 0,
    },
    
   'letter-spacing' => { # aka tracking
     format => 'normal|<length>',
     default => 'normal',
     inherit => 1,
    },
    
   'line-height' => { # aka leading
     format => 'normal|<number>|<length>|<percentage>',
     default => "normal",
     inherit => 1,
    },
    
   'list-style-image' => {
     format => '<url>|none',
     default => 'none',
     inherit => 1,
    },
    
   'list-style-position' => {
     format => 'inside|outside',
     default => 'outside',
     inherit => 1,
    },
    
   'list-style-type' => {
     format => 'disc|circle|square|decimal|decimal-leading-zero|
                lower-roman|upper-roman|lower-greek|lower-latin|
                upper-latin|armenian|georgian|lower-alpha|
                upper-alpha',
     default => 'disc',
     inherit => 1,
    },
    
   'list-style' => {
     format => "'list-style-type'||'list-style-position'||
                'list-style-image'",
     serialise => sub {
       my $p = shift;
       my $ret = '';
       for(qw/ type position image /) {
         $p->{"list-style-$_"}
           and $ret .= $p->{"list-style-$_"}." ";
       }
       chop $ret;
       $ret || 'disc'
     },
    },
    
   'margin-right' => {
     format => '<length>|<percentage>|auto',
     default => '0',
     inherit => 0,
    },
   'margin-left' => {
     format => '<length>|<percentage>|auto',
     default => '0',
     inherit => 0,
    },
   'margin-top' => {
     format => '<length>|<percentage>|auto',
     default => '0',
     inherit => 0,
    },
   'margin-bottom' => {
     format => '<length>|<percentage>|auto',
     default => '0',
     inherit => 0,
    },
    
    margin => {
     format => "(<length>|<percentage>|auto)
                [ (<length>|<percentage>|auto)
                  [ (<length>|<percentage>|auto)
                    (<length>|<percentage>|auto)?
                  ]?
                ]?",
     properties => {
      'margin-top' => [1],
      'margin-right' => [2,1],
      'margin-bottom' => [3,1],
      'margin-left' => [4,2,1],
     },
     serialise => sub {
       my $p = shift;
       my @vals = map $p->{"margin-$_"},
                      qw/top right bottom left/;
       $vals[3] eq $vals[1] and pop @vals,
       $vals[2] eq $vals[0] and pop @vals,
       $vals[1] eq $vals[0] and pop @vals;
       return join " ", map $_ || 0, @vals;
     },
    },
    
   'max-height' => {
     format => '<length>|<percentage>|none',
     default => 'none',
     inherit => 0,
    },
   'max-width' => {
     format => '<length>|<percentage>|none',
     default => 'none',
     inherit => 0,
    },
   'min-height' => {
     format => '<length>|<percentage>|none',
     default => 'none',
     inherit => 0,
    },
   'min-width' => {
     format => '<length>|<percentage>|none',
     default => 'none',
     inherit => 0,
    },
    
    orphans => {
     format => '<integer>',
     default => 2,
     inherit => 1,
    },
    
   'outline-color' => {
     format => '<colour>|invert',
     default => 'invert',
     inherit => 0,
    },
    
   'outline-style' => {
     format => 'none|hidden|dotted|dashed|solid|double|groove|ridge|
                inset|outset',
     default => 'none',
     inherit => 0,
    },
    
   'outline-width' => {
     format => '<length>|thin|thick|medium',
     default => 'medium',
     inherit => 0,
    },
    
    outline => {
     format => "'outline-color'||'outline-style'||'outline-width'",
     serialise => sub {
       my $p = shift;
       my $ret = '';
       for(qw/ color style width /) {
         length $p->{"outline-$_"}
           and $ret .= $p->{"outline-$_"}." ";
       }
       chop $ret;
       length $ret ? $ret : 'invert';
     },
    },
    
    overflow => {
     format => 'visible|hidden|scroll|auto',
     default => 'visible',
     inherit => 0,
    },
    
   'padding-top' => {
     format => '<length>|<percentage>',
     default => 0,
     inherit => 0,
    },
   'padding-right' => {
     format => '<length>|<percentage>',
     default => 0,
     inherit => 0,
    },
   'padding-bottom' => {
     format => '<length>|<percentage>',
     default => 0,
     inherit => 0,
    },
   'padding-left' => {
     format => '<length>|<percentage>',
     default => 0,
     inherit => 0,
    },
    
    padding => {
     format => "(<length>|<percentage>)
                [ (<length>|<percentage>)
                  [ (<length>|<percentage>)
                    (<length>|<percentage>)?
                  ]?
                ]?",
     properties => {
      'padding-top' => [1],
      'padding-right' => [2,1],
      'padding-bottom' => [3,1],
      'padding-left' => [4,2,1],
     },
     serialise => sub {
       my $p = shift;
       my @vals = map $p->{"padding-$_"},
                      qw/top right bottom left/;
       $vals[3] eq $vals[1] and pop @vals,
       $vals[2] eq $vals[0] and pop @vals,
       $vals[1] eq $vals[0] and pop @vals;
       return join " ", map $_ || 0, @vals;
     },
    },
    
   'page-break-after' => {
     format => 'auto|always|avoid|left|right',
     default => 'auto',
     inherit => 0,
    },
   'page-break-before' => {
     format => 'auto|always|avoid|left|right',
     default => 'auto',
     inherit => 0,
    },
    
   'page-break-inside' => {
     format => 'avoid|auto',
     default => 'auto',
     inherit => 1,
    },
    
   'pause-after' => {
      format => '<time>|<percentage>',
      default => 0,
      inherit => 0,
    },
   'pause-before' => {
      format => '<time>|<percentage>',
      default => 0,
      inherit => 0,
    },
    
    pause => {
     format => '(<time>|<percentage>)(<time>|<percentage>)?',
     properties => {
      'pause-before' => [1],
      'pause-after' => [2,1],
     }
    },
    
   'pitch-range' => {
     format => '<number>',
     default => 50,
     inherit => 1,
    },
    
    pitch => {
     format => '<frequency>|x-low|low|medium|high|x-high',
     default => 'medium',
     inherit => 1,
    },
    
   'play-during' => {
      format => '<url> [ mix || repeat ]? | auto | none',
      default => 'auto',
      inherit => 0,
    },
    
    position => {
     format => 'static|relative|absolute|fixed',
     default => 'relative',
     inherit => 0,
    },
    
    quotes => {
     format => '[(<string>)(<string>)]+|none',
     default => 'none',
     inherit => 1,
     list => 1,
    },
    
    richness => {
     format => '<number>',
     default => 50,
     inherit => 1,
    },
    
    right => {
     format => '<length>|<percentage>|auto',
     default => 'auto',
     inherit => 0,
    },
    
   'speak-header' => {
     format => 'once|always',
     default => 'once',
     inherit => 1,
    },
    
   'speak-numeral' => {
     format => 'digits|continuous',
     default => 'continuous',
     inherit => 1,
    },
    
   'speak-punctuation' => {
     format => 'code|none',
     default => 'none',
     inherit => 1,
    },
    
    speak => {
     format => 'normal|none|spell-out',
     default => 'normal',
     inherit => 1,
    },
    
   'speech-rate' => {
     format => '<number>|x-slow|slow|medium|fast|x-fast|faster|slower',
     default => 'medium',
     inherit => 1,
    },
    
    stress => {
     format => '<number>',
     default => 50,
     inherit => 1,
    },
    
   'table-layout' => {
     format => 'auto|fixed',
     default => 'auto',
     inherit => 0,
    },
    
   'text-align' => {
     format => 'left|right|center|justify|auto',
     default => 'auto',
     inherit => 1,
    },
    
   'text-decoration' => {
     format => 'none | underline||overline||line-through||blink ',
     default => 'none',
     inherit => 0,
    },
    
   'text-indent' => {
     format => '<length>|<percentage>',
     default => 0,
     inherit => 1,
    },
    
   'text-transform' => {
     format => 'capitalize|uppercase|lowercase|none',
     default => 'none',
     inherit => 1,
    },
    
    top => {
     format => '<length>|<percentage>|auto',
     default => 'auto',
     inherit => 0,
    },
    
   'unicode-bidi' => {
     format => 'normal|embed|bidi-override',
     default => 'normal',
     inherit => 0,
    },
    
   'vertical-align' => {
     format => 'baseline|sub|super|top|text-top|middle|bottom|
                text-bottom|<percentage>|<length>',
     default => 'baseline',
     inherit => 0,
    },
    
    visibility => {
     format => 'visible|hidden|collapse',
     default => 'visible',
     inherit => 1,
    },
    
   'voice-family' => {
     format => '(male|female|child|<str/words>)
                [, (male|female|child|<str/words>) ]*',
     default => '',
     inherit => 1,
     list => 1,
    },
    
    volume => {
     format => '<number>|<percentage>|silent|x-soft|soft|medium|loud|
                x-loud',
     default => 'medium',
     inherit => 1,
    },
    
   'white-space' =>   {
     format => 'normal|pre|nowrap|pre-wrap|pre-line',
     default => 'normal',
     inherit => 1,
    },
    
    widows => {
     format => '<integer>',
     default => 2,
     inherit => 1,
    },
    
    width => {
     format => '<length>|<percentage>|auto',
     default => 'auto',
     inherit => 0,
    },
    
   'word-spacing' => {
     format => 'normal|<length>',
     default => 'normal',
     inherit => 1,
    },
    
   'z-index' => {
     format => 'auto|<integer>',
     default => 'auto',
     inherit => 0,
    },
  );
  $CSS21->add_property( $_ => $properties{$_} ) for keys %properties;

=pod

=cut

our $Default = $CSS21;

=head1 SEE ALSO

L<CSS::DOM>
