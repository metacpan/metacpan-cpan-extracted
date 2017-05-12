# -*- Mode: Perl; tab-width: 2; -*- 
package Biblio::Thesaurus;
use 5.010;
use strict;
use warnings;
require Exporter;
use Storable;
use CGI qw/:standard/;

use Data::Dumper;

# Version
our $VERSION = '0.43';

# Module Stuff
our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw() ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

# We are working with an object oriented interface. This means, we only
# need to export constructors.
#
# The last three variables are used to down-translation sub (downtr)
our @EXPORT = qw(
  &thesaurusLoad
  &thesaurusLoadM
  &thesaurusNew
  &thesaurusRetrieve
  &thesaurusMultiLoad
  @terms $term $rel);

our ($casesen,$rel,@terms,$term);


##
#
#
sub top_name { topName(@_) }

sub topName {
  my ($self, $name) = @_;
  if($name){ $self->{name} = $name;}
  else     { return $self->{name};}
}

sub order {
  my ($self,@names) = @_;
  if(@names){ $self->{order} = [@names] ; }
  else { defined $self->{order} ? (@{$self->{order}}) : () }
}

sub isLanguage{
  my ($self,$l) = @_;
  return defined $self->{languages}{$l}
}

sub languages{
 my ($self,@names) = @_;
 if(@names){ for (@names) { $self->{languages}{$_} = 1; }}
 else { keys (%{$self->{languages}}) }
}

sub baselang {
  my ($self,$name) = @_;
  if($name){ $self->{$name} = $self->{$self->{baselang}};
             delete $self->{$self->{baselang}};
             $self->{baselang} = $name;}
  else {return $self->{baselang};}
}

##
#
#
sub terms {
  my ($self, $term, @rels) = @_;
  my $base = $self->{baselang};
  return () unless $self->isDefined($term);
  $term = $self->_definition($term);

  @rels = map { uc $_ } @rels;

  return (map {
    if (defined($self->{$base}{$term}{$_})) {
      if (ref($self->{$base}{$term}{$_}) eq "ARRAY") {
	@{$self->{$base}{$term}{$_}}
      } else {
	($self->{$base}{$term}{$_})
      }
    } else {
      ()
    }
  } @rels);
}

##
# Parece-me que não está a ser usada.
#
# sub external {
#   my ($self,$term,$external) = @_;
#   $external = uc($external);
#   $term = $self->definition($term);
#   return $self->{$self->{baselang}}{$term}{$external};
# }

###
#
#
sub all_terms { allTerms(@_) }

sub allTerms {
  my $self = shift;
  return sort keys %{$self->{$self->{baselang}}};
}

###
#
#
sub depth_first {
  my ($self,$term,$niveis,@relat) = @_;
  my %st=();

  if ($niveis>=1) {
    for ($self->terms($term,@relat)) {
      $st{$_}=depth_first($self,$_,$niveis-1,@relat);
    }
    \%st; }
  elsif($niveis == 0) {1}
  else {1}
}

###
#
#
sub _default_norelations {
  return {
	  'URL'=> 1,
	  'SN' => 1
	 };
}

###
#
#
sub _default_inversions {
  +{ NT => 'BT', BT => 'NT', RT => 'RT', USE => 'UF', UF => 'USE' };
}

###
#
#
sub _translateTerm {
  my ($self,$term,$lang,$dic) = @_;
  $dic = {} unless $dic;

  $lang = uc($lang);
    # Se foi $lang definido como linguagem
  if (defined($self->{languages}{$lang})) {
      my $trad;
      # Se existe a tradução
      if (defined($trad = $self->{$self->{baselang}}{$term}{$lang})) {
	return $trad;
      } 
  }

  if(defined $dic->{$term})          {return         $dic->{        $term}}
  if(defined $dic->{lcfirst($term)}) {return ucfirst($dic->{lcfirst($term)})}
  if(defined $dic->{lc($term)})      {return      uc($dic->{     lc($term)})}

  return "[$self->{baselang}-$lang:".$self->getdefinition($term)."]";
}


###
#
#
sub appendThesaurus {
    my ($self,$other) = @_;

    # This way we handle full thesaurus objects or simple filename
    unless (ref($other)) {
        $other = thesaurusLoad($other);
    }

    my $new;

    # Check if baselang is the same, or if some of them is undefined
    if ($self->{baselang} eq $other->{baselang}) {
        $new->{baselang} = $self->{baselang}

    } elsif ($self->{baselang} eq "_") {
        $new->{baselang} = $other->{baselang}

    } elsif ($other->{baselang} eq "_") {
        $new->{baselang} = $self->{baselang}

    } else {
        return undef;
    }

    # If some of the top is _top_, the other is choosed. If
    # there are two different tops, use the first ($self) one
    if ($other->{name} eq $self->{name}) {
        $new->{name} = $self->{name}

    } elsif ($other->{name} eq "_top_") {
        $new->{name} = $self->{name}

    } elsif ($self->{name} eq "_top_") {
        $new->{name} = $other->{name}

    } else {
        $new->{name} = $self->{name}
    }

    # VERSION: current module version
    $new->{version} = $VERSION;

    sub _ffjoin {
        # key, hash1ref, hash2ref
        my ($c,$a,$b) = @_;
        if (exists($a->{$c}) && exists($b->{$c})) {
            return {%{$a->{$c}},%{$b->{$c}}};
        } elsif (exists($a->{$c})) {
            return {%{$a->{$c}}}
        } elsif (exists($b->{$c})) {
            return {%{$b->{$c}}}
        } else {
            return {}
        }
    }

    # Inverses: join hash tables... in conflict, $self is used
    $new->{inverses} = _ffjoin("inverses",$other,$self);

    # Descriptions: in conflict, $self is used
    $new->{descriptions} = _ffjoin("descriptions",$other,$self);

    # Externals: union
    $new->{externals} = _ffjoin("externals",$self,$other);

    # Languages: union
    $new->{languages} = _ffjoin("languages",$self,$other);
    # delete($new->{languages}{"_"}) if ($new->{baselang} ne "_");

    # Get terms for the new thesaurus
    my @terms = _set_of(keys  %{$self ->{$self ->{baselang}}},
                        keys  %{$other->{$other->{baselang}}});

    # Para cada termo do thesaurus...
    for my $term (@terms) {

        # existe em ambos...
        if ($self->isDefined($term) && $other->isDefined($term)) {
            my ($a_def,$b_def) = ($self->_definition($term),
                                  $other->_definition($term));
            my $def = $a_def;

            $new->{defined}{lc($def)} = $def;

            my @class = _set_of(keys %{$self ->{$self ->{baselang}}{$a_def}},
                                keys %{$other->{$other->{baselang}}{$b_def}});
            
            # para cada uma das suas relações...
            for my $class (@class) {
                if ($class eq "_NAME_") {

                    #  print STDERR Dumper($new->{$new->{baselang}}{$def});
                    # optar pela forma do thesaurus A
                    $new->{$new->{baselang}}{$def}{_NAME_} = $def;

                } elsif ($new->{externals}{$class}) {
                    if (exists($self->{$self->{baselang}}{$a_def}{$class})) {
                        push @{$new->{$new->{baselang}}{$def}{$class}},
                        @{$self->{$self->{baselang}}{$a_def}{$class}};
                    }
                    if (exists($other->{$other->{baselang}}{$b_def}{$class})) {
                        push @{$new->{$new->{baselang}}{$def}{$class}},
                        @{$other->{$other->{baselang}}{$b_def}{$class}};
                    }

                } elsif ($new->{languages}{$class}) {
                    $new->{$new->{baselang}}{$def}{$class} = "_";

                } else {
                    if (exists($self ->{$self ->{baselang}}{$a_def}{$class}) &&
                        exists($other->{$other->{baselang}}{$b_def}{$class})) {

                        # Join lists
                        my %there;
                        @there{@{$self->{$self->{baselang}}{$a_def}{$class}}} =
                            1 x @{$self->{$self->{baselang}}{$a_def}{$class}};

                        push @{$new->{$new->{baselang}}{$def}{$class}}, keys %there;

                        for (@{$other->{$other->{baselang}}{$b_def}{$class}}) {
                            unless ($there{$_}) {
                                push @{$new->{$new->{baselang}}{$def}{$class}}, $_;
                            }
                            $there{$_} = 1;
                        }

                    } elsif (exists($self->{$self->{baselang}}{$a_def}{$class})) {
                        $new->{$new->{baselang}}{$def}{$class} =
                            $self->{$self->{baselang}}{$a_def}{$class};
                    } else { ## other->b_def->class
                        $new->{$new->{baselang}}{$def}{$class} =
                            $other->{$other->{baselang}}{$b_def}{$class};
                    }
                }
            }

        } elsif ($self->isDefined($term)) {
            $new->{defined}{lc($term)} = $self->_definition($term);
            $new->{$new->{baselang}}{$term} = $self->{$self->{baselang}}{$term};
        } else { ### $other->isDefined($term)
            $new->{defined}{lc($term)} = $other->_definition($term);
            $new->{$new->{baselang}}{$term} = $other->{$other->{baselang}}{$term};
        }
    }

    return bless($new);
}


###
#
#
sub thesaurusMultiLoad {
  my @files = @_;

  my $self = thesaurusLoad(shift @files);
  while(@files) {
    $self->appendThesaurus(shift @files);
  }

  return $self;
}

###
#
#
sub top {
  my $self = shift;
  my $script = shift;
  return "<ul>".join("\n",
		     map {"<li><a href=\"$script?t=$_\">$_</a></li>"}
		     @{$self->{$self->{baselang}}->{$self->{name}}->{NT}}). "</ul>";
}

###
#
#
sub _default_descriptions {
  return {
	  'RT'  => q/Related term/,
	  'TT'  => q/Top term/,
	  'NT'  => q/Narrower term/,
	  'BT'  => q/Broader term/,
	  'USE' => q/Synonym/,
	  'UF'  => q/Quasi synonym/,
	  'SN'  => q/Scope note/,
	 };
}

sub setExternal {
  my ($self,@rels) = @_;
  for (@rels) {
    $self->{externals}{uc($_)} = 1;
  }
  return $self;
}

sub isExternal {
  my ($self,$ext) = @_;
  return (defined($self->{externals}{uc($ext)}) &&
	  defined($self->{externals}{uc($ext)}) == 1);
}

###
#
#
sub thesaurusNew {
  my $obj = {
	     # thesaurus => {},
	     inverses     => _default_inversions(),
	     descriptions => _default_descriptions(),
	     externals    => _default_norelations(),
	     name => '_top_',
	     baselang => '?',
	     languages => {},
	     version => $VERSION,
	     prefix => "",
	    };

  # bless and return it! Amen!
  return bless($obj);
}

###
#
#
sub storeOn {
  store(@_);
}

###
#
#
sub thesaurusRetrieve {
  my $file = shift;
  my $obj = retrieve($file);
  if (defined($obj->{version})) {
    return $obj;
  } else {
    die("Rebuild your thesaurus with a recent Biblio::Thesaurus version");
  }
}

###
#
#
sub _trurl {
  my $t = shift;
  $t =~ s/\s/+/g;
  return $t;
}

###
#
#
sub getHTMLTop {
  my $self = shift;
  my $script = shift || $ENV{SCRIPT_NAME};
  my $t = "<ul>";
  $t.=join("\n",
	   map { "<li><a href=\"$script?t=" ._trurl($_). "\">$_</a></li>" }
	   @{$self->{$self->{baselang}}->{$self->{name}}->{NT}});
  $t .= "</ul>";
  return $t;
}

###
#
#
sub thesaurusLoad {

  my %opt =();
  # completed => 1
  if(ref($_[0]) eq "HASH") {%opt = (%opt , %{shift(@_)}) } ;

  my ($file,$self) = @_;
  my %thesaurus;

  unless($self){
    $self->{inverses}     = _default_inversions();
    $self->{descriptions} = _default_descriptions();
    $self->{externals}    = _default_norelations();
    $self->{name}         = "_top_";
    $self->{baselang}     = "_";
    $self->{languages}    = {};
    $self->{defined}      = {};
    $self->{version}      = $VERSION; }
  else {
    $self->{defined}      = {};
  }

  # Open the thesaurus file to load
  open ISO, $file or die (q/Can't open thesaurus file/);
	###  binmode(ISO,"$opt{encoding}:") if($opt{encoding});

  # While we have commands or comments or empty lines, continue...
  while(($_ = <ISO>)=~/(^(%|#))|(^\s*$)/) {
    chomp;

    if (/^%\s*inv(?:erse)?\s+(\S+)\s+(\S+)/) {

      # Treat the inv*erse command
      $self->{inverses}{uc($1)} = uc($2);
      $self->{inverses}{uc($2)} = uc($1);

    } elsif (/^%\s*enc(oding)?\s+(\S+)/) {

      $self->{encoding} = lc $2;
      $self->{encoding} =~ s/_/-/g;
      binmode ISO, ":encoding($self->{encoding})";

    } elsif (/^%\s*tit(le)?\s+(.+)/) {
      $self->{title} = $2;

    } elsif (/^%\s*aut(hor)?\s+(.+)/) {
      $self->{author} = $2;

    } elsif (/^%\s*desc(ription)?\[(\S+)\]\s+(\S+)\s+(.*)$/) {

      # Treat the desc*cription [lang] command....  'RT EN'
      $self->{descriptions}{uc($3)." ".uc($2)} = $3;

    } elsif (/^%\s*desc(ription)?\s+(\S+)\s+(.*)$/) {

      # Treat the desc*cription command
      $self->{descriptions}{uc($2)} = $3;

    } elsif (/^%\s*ext(ernals?)?\s+(.*)$/) {

      # Treat the ext*ernals command
      chomp(my $classes = uc($2));
      for (split /\s+/, $classes) {
				$self->{externals}{$_} = 1;
      }

    } elsif (/^%\s*lang(uages?)?\s+(.*)$/) {

      # Treat the lang*uages command
      chomp(my $classes = uc($2));
      for (split /\s+/, $classes) {
				$self->{languages}{$_} = 1;
      }

    } elsif (/^%\s*top\s+(.*)$/) {

      $self->{name} = $1;

    } elsif (/^%\s*baselang(uage)?\s+(\S+)/) {

      $self->{baselang} = uc($2);

    } elsif (/^%/) {

      print STDERR "Unknown command: '$_'\n\n";

    } else {
      # It's a comment or an empty line: do nothing
    }
  }

  # Redefine the record separator
  my $old_sep = $/;
  $/ = "";

  # The last line wasn't a comment, a command or an empty line, so use it!
  $_ .= <ISO>;

  my $ncommands = $.-1;

  # While there are definitions...
  do {
    # define local variables
    my ($class,$term,$relations);

    ## Concat lines that continue back in one
    s/\n[ \t]+/ /g;  # Can't use \s because "\n" =~ m!\s!

    # The first line contains the term to be defined
    /(.+)(?:\n((.|\n)+)|\n?$)/;
    $term = $1;
    $relations = $2 || "";

    # If the term is all spaces, go back...
    if ($term =~ /^\s+$/) {
      print STDERR "Term with only spaces ignored at block term ",$.-$ncommands,"\n\n";
      $term = '#zbr'; # This makes the next loop think this is a comment and ignore it
    }

    # Let's see if the term is commented...
    unless ($term =~ /^#/) {
      $term = _term_normalize($term);

      $term = $self->{defined}{lc($term)} if ($self->{defined}{lc($term)});
      $thesaurus{$term}{_NAME_} = $term;
      $self->{defined}{lc($term)} = $term;

      # The remaining are relations
      $_ = $relations;

      # OK! The term is *not* commented...
      # For each definition line...
      $_.="\n" unless /\n$/;
      while (/((([^#\s]+)|#)[ \t]*(.*)\n)/g) {
		next unless $4;
		# Is it commented?
		unless ($2 eq "#") {
	  		# it seems not... set the relation class
	  		$class = uc($2); # || $class;... now multiline are handled before this

          print STDERR "** WARNING **: '$1'\n" unless $class;

	  # See if $class has a description
	  $self->{descriptions}{$class} = ucfirst(lc($class)) unless defined $self->{descriptions}{$class};
	  ## $descs->{$class}= ucfirst(lc($class))  unless(defined($descs->{$class}));

	  # divide the relation terms by comma unless it is a language or extern relation
	  if ( exists($self->{externals}{$class}) && defined($self->{externals}{$class}) ) {
	    ## $thesaurus{$term}{$class}.= ($2?"$4":" $4");
	    ## $thesaurus{$term}{$class}.= ($thesaurus{$term}{$class}?" $4":"$4");
            push @{$thesaurus{$term}{$class}}, $4;
	  } elsif (exists($self->{languages}{$class}) && defined($self->{languages}{$class})) {
	    # $translations->{$class}->{_term_normalize($4)}.=$term;
	    $self->{$class}{$4}.=$term;
	    $self->{defined}{_term_normalize(lc($4))} = $term;
	    $thesaurus{$term}{$class} = $4;
	  } else {
	    push(@{$thesaurus{$term}{$class}}, map {
	      _term_normalize($_)
	    } split(/\s*,\s*/, $4));
	  }
	}
      }
    }
  } while(<ISO>);

  # Close the ISO thesaurus file
  close ISO;

  # revert to the old record separator. Not needed, but beautifer.
  $/ = $old_sep;

  $self->{$self->{baselang}} = \%thesaurus;
  $self->{languages}{$self->{baselang}} = 1;

  # bless and return the thesaurus! Amen!
  if (exists($opt{completed}) && $opt{completed}) {
    return bless($self);
  } else {
    return complete(bless($self));
  }
}

sub _lc{
 if($casesen){$_[0]}
 else {lc($_[0])}
}

sub thesaurusLoadM {
  my $file   = shift;
  my ($t,$rs)= _treatMetas1(thesaurusLoad($file));
  if(@$rs){
    undef $t->{$t->{baselang}};
    undef $t->{defined};
    _treatMetas2(thesaurusLoad($file,$t),$rs);}
  else{$t}
}

sub _treatMetas1 {
 my $t = shift;
 my @ts=();
 my %r=();

 if(@ts=$t->terms("_order_","NT"))   { $t->order(@ts); 
          @r{@ts,"_order_"}=(@ts,1) }
 if(@ts=$t->terms("_external_","NT")){ $t->setExternal(@ts);
          @r{@ts,"_external_"}=(@ts,1) }
 if(@ts=$t->terms("_top_","NT"))     { $t->topName($ts[0]);
          $r{"_top_"}=1 }
 if(@ts=$t->terms("baselang_","NT")){ $t->baselang($ts[0]);
          @r{@ts,"baselang_"}=(@ts,1) }
 if(@ts=$t->terms("_language_","NT")){ $t->languages(@ts); 
          @r{@ts,"_language_"}=(@ts,1) }
 if(@ts=$t->terms("_symmetric_","NT")){ for(@ts){ $t->addInverse($_,$_);}
          @r{@ts,"_symmetric_"}=(@ts,1) }

# for each new relation describe it, add Invers and remove it as Term
 if(@ts=$t->terms("_relation_","NT")){
   $r{"_relation_"}=1 ;
   $t->downtr(
     { SN        => sub{ $t->describe({rel => $term, desc=>$terms[0]}) }, ## FALTA A LINGUA
       INV       => sub{ $t->addInverse($term,$terms[0])},
       RANG      => sub{ $t->setExternal($term)},
       -order    => ["SN","INV"],
       -eachTerm => sub{ $r{$term}=$term },
     }, @ts);
 }
 ($t,[(keys %r)]);
}

sub _treatMetas2{
 my ($t,$rs)=  @_;
 for (@$rs){  $t->deleteTerm($_)}
 $t;
}

###
#
#
sub getDescription {
  my ($obj, $rel, $lang) = @_;
  if (defined($lang)) {
    my $x = uc($rel)." ".uc($lang);
    return exists($obj->{descriptions}->{$x})?$obj->{descriptions}->{$x}:"...";
  } else {
    my $x = uc($rel)." ".uc($obj->{baselang});
    if (exists($obj->{descriptions}->{$x})) {
      return $obj->{descriptions}->{$x};
    } elsif (exists($obj->{descriptions}->{$rel})) {
      return $obj->{descriptions}->{$rel};
    } else {
      return "...";
      }
  }
}

###
#
#
sub describe {
  my ($obj, $conf) = @_;
  my ($class, $desc, $lang);
  return unless ($class = uc($conf->{rel}));
  return unless ($desc = $conf->{desc});
  if ($conf->{lang}) {
    $lang = " ".uc($conf->{lang});
  } else {
    $lang = "";
  }

  $obj->{descriptions}->{$class.$lang}=$desc;
}

###
#
#
sub addInverse {
  my ($obj,$a,$b) = @_;
  $a = uc($a);
  $b = uc($b);
  $obj->{descriptions}{$a}="..." unless(defined($obj->{descriptions}{$a}));
  $obj->{descriptions}{$b}="..." unless(defined($obj->{descriptions}{$b}));

  for (keys %{$obj->{inverses}}) {
    delete($obj->{inverses}{$_}) if (($obj->{inverses}{$_} eq $a) ||
				       ($obj->{inverses}{$_} eq $b));
  }
  $obj->{inverses}{$a}=$b;
  $obj->{inverses}{$b}=$a;
}

###
#
#
sub meta2str {
  my $obj = shift;
  my $term;
  my %inverses = %{$obj->{inverses}};
  my %descs = %{$obj->{descriptions}};

  my $t = "";

  # Save the 'encoding' command
  #
  $t.="\%encoding $obj->{encoding}\n\n" if defined $obj->{encoding} ;

  # Save the 'title' command
  #
  $t.="\%title $obj->{title}\n\n" if defined $obj->{title};

  # Save the 'author' command
  #
  $t.="\%author $obj->{author}\n\n" if defined $obj->{author};

  # Save the externals commands
  #
  $t.= "\%externals " . join(" ",keys %{$obj->{externals}});
  $t.="\n\n";

  # Save the languages commands
  #
  $t.= "\%languages " . join(" ",keys %{$obj->{languages}});
  $t.="\n\n";

  # Save the 'top' command
  #
  $t.="\%top $obj->{name}\n\n" if $obj->{name} ne "_top_";

  # Save the 'baselanguage' command
  #
  $t.="\%baselanguage $obj->{baselang}\n\n" if $obj->{baselang} ne "_";

  # Save the inverses commands
  #
  for $term (keys %inverses) {
    $t.= "\%inverse $term $inverses{$term}\n";
  }
  $t.="\n\n";

  # Save the descriptions commands
  #
  for $term (keys %descs) {
    if ( $term =~ /^(\w+)\s+(\w+)$/ ) {
      $t.= "\%description[$2] $1 $descs{$term}\n";
    } else {
      $t.= "\%description $term $descs{$term}\n";
    }
  }
  $t.="\n\n";
  $t;
}

##
#
#
sub save {
  my $obj = shift;
  my $file = shift;
  my ($term,$class);
  my %thesaurus = %{$obj->{$obj->{baselang}}};
  my $t = meta2str($obj); #save the metadata

  # Save the thesaurus
  #
  for $term (keys %thesaurus) {
    $t.= "\n$thesaurus{$term}{_NAME_}\n";
    for $class ( keys %{$thesaurus{$term}} ) {
      next if $class eq "_NAME_";
      if(defined $obj->{languages}{$class}) {
	$t.= "$class\t$thesaurus{$term}->{$class}\n";
      } else {
        # if save_compact, juntar por ',' as relacoes nao external
        $t.= "$class\t$_\n" for (@{$thesaurus{$term}{$class}});
      }
    }
  }

  open F, ">$file" or return 0;
  if (defined $obj->{encoding}) {
      $obj->{encoding} = lc($obj->{encoding});
      $obj->{encoding} =~ s/_/-/g;
      binmode(F,":encoding($obj->{encoding})") ;
  }
  print F $t;
  close F;
  return 1;
}

###
#
#
sub navigate {
  # The first element is the object reference
  my $obj = shift;
  # This is the script name
  my $script = $ENV{SCRIPT_NAME} || "";

  # Get the configuration hash
  my $conf = {};
  if (ref($_[0])) { $conf = shift }

  my $expander = $conf->{expand} || [];
  my @tmp = map {$obj->{inverses}{$_}} @$expander;
  my $language = $conf->{lang} || undef;
  my $second_level_limit = $conf->{level2size} || 0;
  my $hide_on_first_level = $conf->{level1hide} || [];
  my $hide_on_second_level = $conf->{level2hide} || \@tmp;
  my $capitalize = $conf->{capitalize} || 0;
  my $topic = $conf->{topic_name} || "t";

  my %hide;
  @hide{@$hide_on_first_level} = @$hide_on_first_level;

  $script = $conf->{scriptname} if (exists($conf->{scriptname}));
  my %param = @_;

  my $term;
  my $show_title = 1;
  if (exists($param{$topic})) {
    $param{$topic} =~ s/\+/ /g;
    $term = $obj->getdefinition($param{$topic});
  } else {
    $show_title = 0 if exists($conf->{title}) && $conf->{title} eq "no";
    if ($obj->isDefined($obj->{name})) {
      $term = $obj->{defined}{lc($obj->{name})};
    } else {
      $term = '_top_';
    }
  }

  my (@terms,$html);

  # If we don't have the term, return only the title
  return h2($term) unless ($obj->isDefined($term));

  # Make the page title
  $html = h2(capitalize($capitalize, $obj->_translateTerm($term,$language))) if $show_title;

  # Get the external relations
  my %norel = %{$obj->{externals}};

  # Now print the relations
  my $rel;
  for $rel (keys %{$obj->{$obj->{baselang}}{$term}}) {
    # next iteraction if the relation is the _NAME_
    next if ($rel eq "_NAME_");

    # Next if we want to hide it
    next if exists $hide{$rel};

    # This block jumps if it is an expansion relation
    next if grep {$_ eq uc($rel)} @{$expander};

    # The externs exceptions...
    if (exists($norel{$rel})) {
      # It's an external, so...
      #
      # Its description is "..."?
      my $desc = $obj->getDescription($rel, $language);

      $html .= join("<br/>\n", map { b($desc)." $_" } @{$obj->{$obj->{baselang}}{$term}{$rel}});
      $html .= " ".br;
    } elsif (exists($obj->{languages}{$rel})) {
      ## This empty block is used for languages translations

    } else {
      ## OK! It's a simple relation

      # There is a translation for the *relation* description?
      my $desc = $obj->getDescription($rel, $language);
      if ($desc eq "...") {
	$html .= b($rel)." ";
      } else {
	$html.= b($desc)." ";
      }

      # Now, write each term with a thesaurus link
      $html.= join(", ", map {
	my $term = $_;
	my $link = $term;
	$link =~ s/\s/+/g;
	$term = $obj->_translateTerm($term, $language);
	a({ href=>"$script?$topic=$link"},$term)
      } sort {lc($a)cmp lc($b)} @{$obj->{$obj->{baselang}}{$term}{$rel}});

      $html.= br;
    }
  }

  # Now, treat the expansion relations
  for $rel (@{$expander}) {
    $rel = uc($rel);
    if (exists($obj->{$obj->{baselang}}{$term}{$rel})) {
      @terms = sort {lc($a)cmp lc($b)} @{$obj->{$obj->{baselang}}{$term}{$rel}};
      $html.= ul(li([map {
	_thesaurusGetHTMLTerm($_, $obj, $script, $language,
			     $second_level_limit, $hide_on_second_level);
      } @terms])) if (@terms);
    }
  }
  return $html;
}

###
#
#
sub toTex{
  my $self = shift;
  my $_corres = shift || {};
  my $mydt = shift || {};
#  my $a;

  my %descs = %{$self->{descriptions}};

  my $procgr= sub {
      my $r="";# my $a;
      my $auxrel = $descs{$rel} || $rel;
      $auxrel =~ s/_/ /g;
      $auxrel = ucfirst(lc($auxrel));
      my $ki =  $_corres->{$rel}->[0] || "\\\\\\emph{$auxrel} -- " ;
      my $kf = $_corres->{$rel}->[1] || "\n";
      $r = "\\item[$ki]" . 
           join(' $\diamondsuit$ ',(sort {lc($a) cmp lc($b)} @terms)) if @terms;
      };

 $self->downtr(
    { '-default'  => $procgr,
      '-end'      => sub{s/_/\\_/g; 
                         "\\begin{description}\n$_\\end{description}\n"},
      '-eachTerm' => 
          sub{"\n\\item[$term]~\\begin{description}\n$_\\end{description}\n"},
      (defined $self->{order}?(-order => $self->{order}):()),
      (%$mydt) }
 );
}

sub toXml{
  my $self = shift;
  my $_corres = shift || {};
  my $mydt = shift || {};
  my $a;

  my $proc= sub {
      my $r=""; my $a;
      my $ki = $_corres->{$rel}->[0] || "$rel" ;
      my $kf = $_corres->{$rel}->[1] || "/$rel";
      for $a (@terms){ $r .= "    <$ki>$a<$kf>\n";};
      $r;
      };

   $self->downtr({
          '-default'  => $proc,
          '-eachTerm' => 
     sub{"  <term>\n    <$self->{baselang}>$term</$self->{baselang}>\n$_  </term>\n"},
          '-end'      => sub{"<thesaurus>\n$_</theasurus>\n"},
          (%$mydt)
        });
}

###
#
#
sub dumpHTML {
  my $obj = shift;
  my %thesaurus = %{$obj->{$obj->{baselang}}};
  my $t = "";
  for (keys %thesaurus) {
    $t.=_thesaurusGetHTMLTerm($_,$obj,"",$obj->{baselang});
  }
  return $t;
}

###
#
#
sub relations {
  my ($self,$term) = @_;

  return sort grep { $_ !~ /^_/ } keys %{$self->{$self->{baselang}}->{$term}}
}


###
#
# Given a term, return it's information (second level for navigate)
sub _thesaurusGetHTMLTerm {
  my ($term,$obj,$script,$language,$limit,$hide) = @_;

  my @rels2hide = map {uc} (defined($hide))?@$hide:();
  my %rels2hide;
  @rels2hide{@rels2hide}=1;

  # Put thesaurus and descriptions on handy variables
  my %thesaurus = %{$obj->{$obj->{baselang}}};
  my %descs = %{$obj->{descriptions}};

  # Check if the term exists in the thesaurus
  if ($obj->isDefined($term)) {
    $term = $obj->{defined}{lc($term)};
    my ($c,$t,$tterm);
    my $link = $term;

    $link =~ s/\s/+/g;
    $tterm = $obj->_translateTerm($term,$language);
    $t = b(a({href=>"$script?t=$link"},$tterm)). br . "<small><dl><dd>\n";

    for $c (sort keys %{$thesaurus{$term}}) {
      $c = uc($c);
      next if exists($rels2hide{$c});
      # jump if it is the name relation :)
      next if ($c eq "_NAME_");

      if (exists($obj->{externals}{$c})) {
 	# put an external relation
	my $desc = $obj->getDescription($c,$language);
        if ($desc eq "...") {
          $t .= join("<br/>\n", map { div($_) } @{$thesaurus{$term}{$c}});
        } else {
          $t .= join("<br/>\n", map { b($desc)." $_" } @{$thesaurus{$term}{$c}});
        }
      } elsif (exists($obj->{languages}{$c})) {
 	# Jump the language relations
      } else {
	my $desc = $obj->getDescription($c,$language);
	if ($desc eq "...") {
	  $t.= b($c)." ";
	} else {
	  $t.= b($desc)." ";
	}
	my @termos = sort {lc($a)cmp lc($b)} ( @{$thesaurus{$term}{$c}} );
	if (defined($limit) && $limit!=0 && @termos > $limit) {
 	  while(@termos > $limit) { pop @termos; }
 	  push @termos, "...";
 	}
 	if (defined($script)) {
 	  @termos = map {my $link = $_;
 			 if ($link eq "...") {
 			   $link
 			 } else {
 			   $_ = $obj->_translateTerm($_,$language) || $_;
 			   $link =~s/\s/+/g;
 			   a({href=>"$script?t=$link"},$_)
 			 }
 		       } @termos;
 	}
 	$t.= join(", ", @termos) . br."\n";
      }
    }
    $t.= "</dd></dl></small>\n";
    return $t;
  } else {
    print STDERR "Can't find term '$term'\n";
    return qq/Term $term is not defined\n/;
  }
}

sub getdefinition { getDefinition(@_) }
sub getDefinition {
  my $self = shift;
  my $term = _term_normalize(lc(shift));
  if ($self->isDefined($term)) {
  	return $self->{defined}{$term};
  } else {
	return $term;
  }
}

###
#
#
sub isDefined {
  my $obj = shift;
  my $term = _term_normalize(lc(shift));
  return defined($obj->{defined}{$term});
}

###
#
#
sub _definition {
  my ($self,$term) = @_;
  return $self->{defined}{_term_normalize(lc($term))};
}

###
#
#
sub complete {
  my $obj = shift;
  my $thesaurus = $obj->{$obj->{baselang}};
  my %inverses = %{$obj->{inverses}};
  my ($termo,$classe);

  # para cada termo
  for $termo (keys %$thesaurus) {
    # $obj->{defined}{lc($termo)} = $termo;
    # e para cada classe,
    for $classe (keys %{$thesaurus->{$termo}}) {
      # verificar se existem duplicados...
      if (ref($thesaurus->{$termo}{$classe}) eq "ARRAY") {
	my %h;
	@h{@{$thesaurus->{$termo}{$classe}}} = @{$thesaurus->{$termo}{$classe}};
	$thesaurus->{$termo}{$classe} = [ keys %h ];

	# se tiver inverso,
	if (defined($inverses{$classe})) {
	  # completar cada um dos termos relacionados
	  for (@{$thesaurus->{$termo}{$classe}}) {
	    # %thesaurus = _completa($obj,$_,$inverses{$classe},$termo,%thesaurus);
	    _completa($obj,$_,$inverses{$classe},$termo,$thesaurus);
	  }
	}
      }
    }
  }

  $obj -> {$obj->{baselang}} = $thesaurus;

  return $obj;
}

###
#
#
sub _completa {
  ## Yeah, obj and thesaurus can be redundanct, but it's better this way...
  my ($obj,$palavra,$classe,$termo,$thesaurus) = @_;
  my $t;

  # Ver se existe a palavra e a classe no thesaurus
  if ($obj->isDefined($palavra)) {
    $t = $obj->{defined}{lc($palavra)};
    if (defined($thesaurus->{$t}{$classe})) {
      # se existe, o array palavras fica com os termos (para ver se ja' existe)
      my @palavras = @{$thesaurus->{$t}{$classe}};
      # ver se ja' existe
      for (@palavras) {
	return $thesaurus if (lc eq lc($termo));
      }
    }
    # nao existe: aumentar
    push @{$thesaurus->{$t}{$classe}}, $obj->{defined}{lc($termo)};
  } else {
    # nao existe: aumentar
    $thesaurus->{$palavra}{_NAME_} = $palavra unless
      defined($thesaurus->{$palavra}) && defined($thesaurus->{$palavra}{_NAME_});
    $obj->{defined}{lc($palavra)} = $palavra;
    push @{$thesaurus->{$palavra}{$classe}}, $obj->{defined}{lc($termo)};
  }
  return $thesaurus;
}

###
#
#
sub addTerm {
  my $obj = shift;
  my $term = _term_normalize(shift);

  $obj->{$obj->{baselang}}{$term}{_NAME_} = $term;
  $obj->{defined}{lc($term)} = $term;
}

sub hasRelation {
	my ($obj, $term, $rel, $rterm) = @_;
	$rel = uc($rel);

	return 0 unless $obj->isDefined($term); # Check if term exists
	$term = $obj->_definition($term);

	my $has = 0;
	if ($rterm) {
		if (exists($obj->{externals}{$rel})) {
		 	$has = 1 if (grep { $_ eq $rterm } @{$obj->{$obj->{baselang}}{$term}{$rel}});
		} else {
			$rterm = _term_normalize($rterm);
			$has = 1 if (grep { $_ eq $rterm} @{$obj->{$obj->{baselang}}{$term}{$rel}});
		}
	} else {
		$has = 1 if exists($obj->{$obj->{baselang}}{$term}{$rel});
	}
	return $has;
}

###
#
#
sub addRelation {
  my ($obj, $term, $rel, @terms) = @_;
  $rel = uc($rel);

  $obj->{descriptions}{$rel} = "..." 
    unless defined($obj->{descriptions}{$rel});

  unless ($obj->isDefined($term)) {
    $obj->{defined}{lc(_term_normalize($term))} = _term_normalize($term);
  }

  $term = $obj->_definition($term);

  if (exists($obj->{externals}{$rel})) {
    push @{$obj->{$obj->{baselang}}{$term}{$rel}}, @terms;

  } else {
    push @{$obj->{$obj->{baselang}}{$term}{$rel}},
      map {_term_normalize($_)} @terms;
    for (@terms) {
      $obj->addTerm($_) unless $obj->isDefined($_);
    }
  }

}

###
#
#
sub deleteRelation {
  my ($self, $term, $rel, @terms) = @_;
  $rel = uc($rel);

	if (@terms) {
		for my $oterm (@terms) {
			$self->_deleteRelation($term, $rel, $oterm);
			## Se existe inversa, do the same shit
			if (exists $self->{inverses}{$rel}) {
				$self->_deleteRelation($oterm, $self->{inverses}{$rel}, $term);
			}
		}
	} else {
		if (exists($self->{externals}{$rel})) {
			$self->_deleteRelation($term, $rel);
		} else {
			@terms = $self->terms($term,$rel);
			return unless @terms;
			$self->deleteRelation($term, $rel, @terms);
		}
	}
}

###
#
#
sub _deleteRelation {
	my ($obj, $term, $rel, $oterm) = @_;

	# return if the term is not defined
  return unless $obj->isDefined($term);

	$term = $obj->_definition($term);	
	if ($oterm) {
		# if we have a full relation (term,rel,term), then it is not an external relation
		return if exists($obj->{externals}{$rel});
		
		$oterm = _term_normalize($oterm);
		$obj->{$obj->{baselang}}{$term}{$rel} = [ grep { $_ ne $oterm } @{$obj->{$obj->{baselang}}{$term}{$rel}}];		
	} else {
		delete($obj->{$obj->{baselang}}{$term}{$rel});
	}
}

###
#
#
sub deleteTerm {
  my $obj = shift;
  my $term = _term_normalize(shift);
  my $t2=$term;
  $term = $obj->_definition($term);
  my ($t,$c);

  warn("'$t2' => '$term'\n") && return unless defined($term);

  if (defined($obj->{$obj->{baselang}}{$term})){
    delete($obj->{$obj->{baselang}}{$term});
    delete($obj->{defined}{lc($term)});
  } 
  else {warn ("'$term' not found...\n");}

  foreach $t (keys %{$obj->{$obj->{baselang}}}) {
    foreach $c (keys %{$obj->{$obj->{baselang}}{$t}}) {
      my @a = ();
      if ( ref($obj->{$obj->{baselang}}{$t}{$c}) eq "ARRAY") {
      	foreach (@{$obj->{$obj->{baselang}}{$t}{$c}}) {
		push(@a,$_) unless($_ eq $term);
      	}
      	$obj->{$obj->{baselang}}{$t}{$c}=\@a;
      }
    }
  }
}

###
#
#
sub downtr {
  my $self = shift;
  my $handler = shift;
  die("bad use of downtr method; args should be: hashRef, termlist") 
    unless(ref($handler) eq "HASH");
  my @tl = @_ ; #lc(shift);
  @tl = (sort 
           {lc($a) cmp lc($b)} 
           keys %{$self->{$self->{baselang}}}) unless (@tl);
  my $r2 = ""; #final result 
  my $c;
  for my $t (@tl){
    my $r = "";
    $term = $t;
    if (defined( $handler->{"_NAME_"})){
      $r .=  &{$handler->{"_NAME_"}};
    }

    my @rels = (keys %{$self->{$self->{baselang}}->{$t}});
    my %rels = ();
    @rels{@rels} = @rels;
    my $order = defined $handler->{-order} ? $handler->{-order} :
                ( defined $self->{order} ? $self->{order} : []);
    delete(@rels{@$order});
    @rels = ( @{$order}, (sort keys(%rels) )); 

    for $c (@rels) {
      next unless $self->{$self->{baselang}}{$t}{$c};
      next if ($c eq "_NAME_");

      # Set environment variables to downtr function
      #
      # rel...
      #
      $rel = $c;
      #
      # List of terms...
      #
      if ($self->{languages}->{$rel}) {
        @terms = ( $self->{$self->{baselang}}{$t}{$rel} );
      } else {
        @terms = @{$self->{$self->{baselang}}{$t}{$rel}};
      }

      #
      # Current term...
      #
      $term = $t;

      if (exists($handler->{$rel})) {
          $r .=  &{$handler->{$rel}} // "";
      } elsif (exists($handler->{-default})) {
          $r .=  &{$handler->{-default}} // "";
      } else  {
          $r .=  "\n$rel\t".join(", ",@terms);
      }
    }
    for($r){
      if (exists($handler->{'-eachTerm'})) {
        my $ans = &{$handler->{'-eachTerm'}};
        $r2 .= ($ans)?$ans:"";
      } else {
        $r2 .= $_;
      }
    }
  }
  if (defined($handler->{-end})) { 
    for($r2){
      $_ = &{$handler->{'-end'}}
    }
  }
  $r2;
}

###
#
#
sub tc{
  my ($self,$term,@relations) = @_;
  my %x = _tc_aux($self, $term, {}, @relations);
  return (keys %x);
}


###
#
#
sub toHash {
    my ($self, $rel) = @_;
    $rel //= "NT";
    $rel = [$rel] unless ref($rel);
    my $top = $self->topName;
    return +{ $top => $self->_toHash($top, $rel, [$top]) };
}

sub _toHash {
    my ($self, $term, $rel, $stack) = @_;
    my $h = $self->depth_first($term, 1, @$rel);
    if (keys %$h) {
        for (keys %$h) {
            $h->{$_} = $self->_toHash($_, $rel, [@$stack, $_]);
        }
    } else {
        $h = join("::", @$stack);
    }
    return $h;
}

##
#
#
sub toJson {
    my ($self, $rel) = @_;
    $rel //= "NT";
    $rel = [$rel] unless ref($rel);
    my $top = $self->topName;
    $self->_toJson($top, $rel);
}

sub _toJson {
    my ($self, $term, $rel) = @_;
    my $h = $self->depth_first($term, 1, @$rel);
    my $json = "{ \"data\": \"$term\", \"attr\":{id:\"$term\"}";
    if (keys %$h) {
        $json .= ", \"children\": [";
        $json .= join(", ", map { $self->_toJson($_, $rel) } keys %$h);
        $json .= "]"
    }
    $json .= "}";
}

###
#
#
sub _tc_aux {
  my ($self,$term,$vis,@relat) = @_;
  $term = $self->getdefinition($term);
  my %r = ( $term => 1 );
  for ($self->terms($term,@relat)) {
    next if exists $vis->{$_};
    $vis->{$_}++;
    %r = (%r, $_ => 1,  _tc_aux($self,$_,@relat)) unless $r{$_};
  }
  return %r;
}

###
#
#
sub _term_normalize {
  my $t = shift;
  $t =~ s/^\s*(.*?)\s*$/$1/;
  $t =~ s/\s\s+/ /g;
  return $t;
}

sub capitalize {
  my $op = shift;
  my $text = shift;
  if ($op) {
    $text = join(" ",map {ucfirst} split /\s+/, $text);
  }
  return $text;
}

# remove duplicados de uma lista
sub _set_of {
  my %set = ();
  $set{$_} = 1 for @_;
  return keys %set;
}

1;
__END__

=encoding UTF-8

=head1 NAME

Biblio::Thesaurus - Perl extension for managing ISO thesaurus

=head1 SYNOPSIS

  use Biblio::Thesaurus;

  $obj = thesaurusNew();
  $obj = thesaurusLoad('iso-file');
  $obj = thesaurusRetrieve('storable-file');
  $obj = thesaurusMultiLoad('iso-file1','iso-file2',...);

  $obj->save('iso-file');
  $obj->storeOn('storable-file');

  $obj->addTerm('term');
  $obj->addRelation('term','relation','term1',...,'termn');
  $obj->deleteTerm('term');

  $obj->isDefined('term');

  $obj->describe( { rel='NT', desc="Narrow Term", lang=>"UK" } );

  $obj->addInverse('Relation1','Relation2');

  $obj->order('rela1', 'rel2', ....);
  @order = $obj->order();

  $obj->languages('l1', 'l2', ....);
  @langs = $obj->languages();

  $obj->baselang('l');
  $lang = $obj->baselang();

  $obj->topName('term');
  $term = $obj->topName();

  $html = $obj->navigate(+{configuration},%parameters);

  $html = $obj->getHTMLTop();

  $output = $obj->downtr(\%handler);
  $output = $obj->downtr(\%handler,'term', ... );

  $obj->appendThesaurus("iso-file");
  $obj->appendThesaurus($tobj);

  $obj->tc('term', 'relation1', 'relation2');
  $obj->depth_first('term', 2, "NT", "UF")

  $latex = $obj->toTex( ...)
  $xml   = $obj->toXml( ...)

=head1 ABSTRACT

This module provides transparent methods to maintain Thesaurus files.
The module uses a subset from ISO 2788 which defines some standard
features to be found on thesaurus files. The module also supports
multilingual thesaurus and some extensions to the ISOs standard.

=head1 DESCRIPTION

A Thesaurus is a classification structure. We can see it as a graph
where nodes are terms and the vertices are relations between terms.

This module provides transparent methods to maintain Thesaurus files.
The module uses a subset from ISO 2788 which defines some standard
features to be found on thesaurus files. This ISO includes a set of
relations that can be seen as standard but, this program can use user
defined ones.  So, it can be used on ISO or not ISO thesaurus files.

=head1 File Structure

Thesaurus used with this module are standard ASCII documents. This
file can contain processing instructions, comments or term
definitions. The instructions area is used to define new relations and
mathematical properties between them.

We can see the file with this structure:

   ______________
  |              |
  |    HEADER    | --> Can contain, only, processing instructions,
  |______________|     comment or empty lines.
  |              |
  |  Def Term 1  | --> Each term definition should be separated
  |              |     from each other with an empty line.
  |  Def Term 2  |
  |              |
  |     .....    |
  |              |
  |  Def Term n  |
  |______________|

Comments can appear on any line. Meanwhile, the comment character
(B<#>) should be the first character on the line (with no spaces
before).  Comments line span to the end of the line (until the first
carriage return).

Processing instructions lines, like comments, should start with the
percent sign (B<%>). We describe these instructions later on this
document.

Terms definitions can't contain any empty line because they are used
to separate definitions from each other. On the first line of term
definition record should appear the defined term. Next lines defines
relations with other terms. The first characters should be an
abbreviation of the relation (on upper case) and spaces. Then, should
appear a comma separated list of terms.

There can be more than one line with the same relation. Thesaurus module will
concatenate the lists. If you want to continue a list on the next line you
can repeat the relation term of leave some spaces between the start of the line
and the terms list.

Here is an example:

  Animal
  NT cat, dog, cow
     fish, ant
  NT camel
  BT Life being

  cat
  BT Animal
  SN domestic animal to be kicked when
     anything bad occurs.

There can be defined a special term (C<_top_>). It should be
used when you want a top tree for thesaurus navigation. So,
we normally define the C<_top_> term with the more interesting
terms to be navigated.

The B<ISO> subset used are:

=over 4

=item B<TT> - Top Term

The broadest term we can define about the current term.

=item B<NT> - Narrower Term

Terms more specific than current term.

=item B<BT> - Broader Term

More generic terms than current term.

=item B<USE> - Synonym

Another chances when finding a Synonym.

=item B<UF> - Quasi-Synonym

Terms that are no synonyms of current term but can be used,
sometimes with that meaning.

=item B<RT> - Related Term

Related term that can't be inserted on any other category.

=item B<SN> - Scope Note

Text. Note of context of the current term. Use for definitions or
comments about the scope you are using that term.

=back

=head2 Processing Instructions

Processing instructions, as said before, are written on a line starting
with the percent sign. Current commands are:

=over 4

=item B<top>

When presenting a thesaurus, we need a term, to know where to start.
Normally, we want the thesaurus to have some kind of top level, where
to start navigating. This command specifies that term, the term that
should be used when no term is specified.

Example:

  %top Contents

  Contents
  NT Biography ...
  RT ...

=item B<enc>oding

This command defines the encoding used in the thesaurus file.

Example:

 %enc utf8

=item B<inv>erse

This command defines the mathematic inverse of the relation. That
is, if you define C<inverse A B> and you know that C<foo> is
related by C<A> with C<bar>, then, C<bar> is related by C<B>
with C<foo>.

Example:

  %inv BT NT
  %inverse UF USE

=item B<desc>ription

This command defines a description for some relation class. These
descriptions are used when outputting thesaurus on HTML.

Example:

  %desc SN Note of Scope
  %description IOF Instance of

If you are constructing a multilingual thesaurus, you will want to translate
the relation class description. To do this, you should use the C<description>
command with the language in from of it:

  %desc[PT] SN Nota de Contexto
  %description[PT] IOF Instancia de

=item B<ext>ernals

This defines classes that does not relate terms but, instead, relate a term
with some text (a scope note, an url, etc.). This can be used like this:

  %ext SN URL
  %externals SN URL

Note that you can specify more than one relation type per line.

=item B<lang>uages

This other command permits the construction of a multilingual thesaurus. TO
specify languages classifiers (like PT, EN, FR, and so on) you can use one
of these lines:

  %lang PT EN FR
  %languages PT EN FR

To describe (legend) the language names, you should use the B<description>
command, so, you could append:

  %description PT Portuguese
  %description EN English
  %description FR French

=item B<baselang>uage

This one makes it possible to explicitly name the base language for the
thesaurus. This command should be used with the C<description> one, to
describe the language name. Here is a simple example:

  %baselang PT
  %languages EN FR

  %description PT Portuguese
  %description EN English
  %description FR French

=back

=head2 I18N

Internationalization functions, C<languages> and C<setLanguage> should
be used before any other function or constructor. Note that when
loading a saved thesaurus, descriptions defined on that file will be
not translated.  That's important!

  interfaceLanguages()

This function returns a list of languages that can be used on the current
Thesaurus version.

  interfaceSetLanguage( <lang-name> )

This function turns on the language specified. So, it is the first
function you should call when using this module. By default, it uses
Portuguese. Future version can change this, so you should call it any
way.

=head1 API

This module uses a perl object oriented model programming, so you must
create an object with one of the C<thesaurusNew>, C<thesaurusLoad> or
C<thesaurusRetrieve> commands. Next commands should be called using
the B<OO> fashion.

=head1 Constructors

=head2 thesaurusNew

To create an empty thesaurus object. The returned newly created object
contains the inversion properties from the ISO classes and some stub
descriptions for the same classes.

=head2 thesaurusLoad

To use the C<thesaurusLoad> function, you must supply a file name.
This file name should correspond to the ISO ASCII file as defined on
earlier sections. It returns the object with the contents of the
file. If the file does not defined relations and descriptions about
the ISO classes, they are added.

Also,

  $obj = thesaurusLoad({ completed => 1}, 'iso-file');

can be used to say that the thesaurus needs  B<not> to be complete after load.

=head2 thesaurusMultiLoad

You can join different thesaurus ISO files using this function:

  $obj = thesaurusMultiLoad('iso-file1','iso-file2',...);

=head2 appendThesaurus

You can also append a thesaurus ISO (or another thesaurus object) to a
loaded thesaurus. For that, use one of:

  $obj->appendThesaurus("iso-file");
  $obj->appendThesaurus( $other_thesaurus_object );

=head2 thesaurusLoadM

This method is used to load a thesaurus on the meta-thesaurus
format. This is still under development.

=head2 thesaurusRetrieve

Everybody knows that text access and parsing of files is not
efficient. So, this module can save and load thesaurus from Storable
files. This function should receive a file name from a file which was
saved using the C<storeOn> function.

=head1 Methods

=head2 save

This method dumps the object on an ISO ASCII file. Note that the
sequence C<thesaurusLoad>, C<save> is not the identity
function. Comments are removed and processing instructions can be
added. To use it, you should supply a file name.

Note: if the process fails, this method will return 0. Any other
method die when failing to save on a file.

=head2 meta2str

This method returns the ISO ascii description of the metadata.

=head2 storeOn

This method saves the thesaurus object in Storable format. You should
use it when you want to load with the C<thesaurusRetrieve> function.

=head2 addTerm

You can add terms definitions using the perl API. This method adds a
term on the thesaurus. Note that if that term already exists, all its
relations will be deleted.

=head2 all_terms

Returns an array with all terms for the thesaurus base language.
NOTE: this function is deprecated. Use allTerms instead.

=head2 allTerms

Returns an array with all terms for the thesaurus base language.

=head2 topName

Returns the term in the top of the thesaurus, or defined a new one if
called with an argument.

=head2 top_name

Deprecated. See C<<topName>>;

=head2 addRelation

To add relations to a term, use this method. It can be called again
and again. Previous inserted relations will not be deleted.  This
method can be used with a list of terms for the relation like:

  $obj->addRelation('Animal','NT','cat','dog','cow','camel');

Note: After you add a big amount of relations, autocomplete the
thesaurus using the $obj->complete() method. Completing after each
relation addiction is time and cpu consuming.

=head2 hasRelation

Checks if a specific relation exists in the Thesaurus:

  if ($obj->hasRelation('Animal','NT','cat')) { ... }

You can check if a term has a relation "X" with anything:

  if ($obj->hasRelation('Animal','SN')) { ... }

=head2 deleteRelation

  $obj->deleteRelation('Animal','NT','cat','dog','cow','camel');

=head2 deleteTerm

Use this method to remove all references of the term supplied. Note
that B<all> references will be deleted.

=head2 describe

You can use this method to describe some relation class. You can use
it to change the description of an existing class (like the ISO ones)
or to define a new class.

=head2 isDefined

Use this method to check if a term exists in the thesaurus.

=head2 setExternal

Use this method to define that a relation is "extern". 

=head2 isExternal

Use this method to check if a relation is "extern". 

=head2 isLanguage

Use this method to check if a relation is a Language.

=head2 getdefinition

Deprecated. Use C<<getDefinition>

=head2 getDefinition

Returns the definition for a term. The definition is a feature
structure containing the term information.

=head2 getDescription

Given a relation name and a language (or the default will be used), it
returns the description for that relation.

=head2 relations

Call this method with a term, and it returns a list of the relations
defined for that term.


=head2 addInverse

This method should be used to describe the inversion property to
relation classes. Note that if there is some previous property about
any of the relations, it will de deleted. If any of the relations does
not exist, it will be added.

=head2 order

With this method you can define (and access) the order of
classes. This order is used whenever you call a dump function, or the
navigation CGI.

=head2 navigate

This function is a some what type of CGI included on a object
method. You must supply an associative array of CGI parameters. This
method prints an HTML thesaurus for Web Navigation.

The typical thesaurus navigation CGI is:

  #!/usr/bin/perl -w

  use CGI qw/:standard/;
  use Biblio::Thesaurus;

  print header;
  for (param()) { $arg{$_} = param($_) }
  $thesaurus = thesaurusLoad("thesaurus_file");
  print $thesaurus->navigate(%arg);

This method can receive, as first argument, a reference to an
associative array with some configuration variables like what
relations to be expanded and what language to be used by default.

So, in the last example we could write

  $thesaurus->navigate(+{expand=>['NT', 'USE'],
                         lang  =>'EN'})

meaning that the structure should show two levels of 'NT' and 'USE'
relations, and that it should use the English language.

These options include:

=over 4

=item capitalize

try to capitalize terms when they are the title of the page.

=item expand

a reference to a list of relations that should be expanded at first
level; Defaults to the empty list.

=item title

can be C<yes> or C<no>. If it is C<no>, the current term will not be
shown as a title; Defaults to C<yes>.

=item scriptname

the name of the script the links should point on. Defaults to current
page name.

=item level1hide

a reference to a list of relations to do not show on the first level.
Defaults to the empty list. Useful to hide the 'LEN' relation when
using Library::Simple.

=item level2size

the number of terms to be shown on each second level relation;
Defaults to 0 (all terms).

=item level2hide

a reference to a list of relations to do not show on the second
level. Defaults to the empty list.

=item topic_name

the name of the topic CGI parameter (default: "t")

=back


=head2 dumpHTML

This method returns a big string containing all the thesaurus in
HTML. It is mainly used for debug.

=head2 getHTMLTop

This method returns the HTML needed for the top level of the browsing
thesaurus. It can be useful when putting a top level on the first page
of a portal.

=head2 complete

This function completes the thesaurus based on the invertibility
properties. This operation is only needed when adding terms and
relations by this API. Whenever the system loads a thesaurus ISO file,
it is completed.

=head2 baselang

Use this method to set or retrieve the base language of the thesaurus.
If no baselang is provided, the value "_" is returned

=head2 downtr

The C<downtr> method is used to produce something from a set of terms.
When no term is given, the all thesaurus is taken.
It should be passed as argument a term and an associative array (handler) with
anonymous subroutines that process each relation. These functions can use
the pre-instantiated variables C<$term>, C<$rel>, C<@terms>.
The handler can have three special functions:
C<-default> (default handler for relations that don't have a defined function 
in the handler),
C<-eachTerm> executed with each term output (received as C<$_>), and
C<-end> executed over the output of the the other functions (received as C<$_>),

If a C<-order> array reference is provided, the correspondent order of the
relations will be used.

Example:

   $the->downtr( { NT       => sub{ ""},    #Do nothing with NT relations
                   -default => sub{ print "$rel", join(",",@terms) }
                 },
                 "frog" );

   print $thesaurus->downtr(
     {-default  => sub { "\n$rel \t".join("\n\t",@terms)},
      -eachTerm => sub { "\n______________ $term $_"},
      -end      => sub { "Thesaurus :\n $_ \nFIM\n"},
      -order    => ["BT","NT","RT"],
     });


Both functions return a output value: the concatenation of the internal values
(but functions can also work with side effects)


=head2 depth_first

The C<depth_first> method is used to get the list of terms (in fact the 
tree of terms) related with C<$term> by relations C<@r> up to the level C<$lev>

  $hashref = $the->depth_first($term ,$lev, @r)

  $hashref = $the->depth_first("frog", 2, "NT","UF")

C<$lev> should be an integer greater then 0.

=head2 tc transitive closure

The C<tc> method is used to eval the transitive closure of the relations
C<@r> starting from a term C<$term>

  $the->tc($term , @r)

  $the->tc("frog", "NT","UF")

=head2 terms

The C<terms> method is used to get all the terms related by relations C<@r>
with C<$term>

  $the->terms($term , @r);

  $the->terms("frog", "NT", "UF");

=head2 toTex

Writes a thesaurus in LaTeX format...
The first argument is used to pass a tag substitution hash.
It uses downtr function to make the translation; a downtr handler can be given
to tune some transformations details...

  print $thesaurus->toTex(
         {EN=>["\\\\\\emph{Ingles} -- ",""]},
         {FR => sub{""}})

=head2 toXml

This method writes a thesaurus in XML format...
The first argument is used fo pass a tag substitution hash.
It uses downtr function to make the translation; a downtr handler can be given
to tune some transformations details...

  print $thesaurus->toXml();

=head2 toJson

Returns a JSON tree based on NT relation. Other relation can be
supplied as an argument. Future versions might include language
selection.

  print $thesaurus->toJson();


=head2 toHash

Returns a Hash reference with a tree based on NT relation. Other
relation can be supplied as an argument. Future versions might include
language selection.

  print $thesaurus->toHash();

=head1 AUTHOR

Alberto Simoes, <albie@alfarrabio.di.uminho.pt>

José Joao Almeida, <jj@di.uminho.pt>

Sara Correia,  <sara.correia@portugalmail.com>

This module is included in the Natura project. You can visit it at
http://natura.di.uminho.pt, and access the SVN tree.

=head1 COPYRIGHT & LICENSE

Copyright 2000-2012 Project Natura.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

The example thesaurus file (C<examples/thesaurus>),

Manpages:

  Biblio::WebPortal(3)
  Biblio::Catalog(3)
  Biblio::Catalog::Bibtex(3)
  perl(1) manpages.

=cut

__DATA__
=head2 loading from Iso 2788
=head2 building a thesaurus with internal constructors
=head2 writing a thesaurus in another format
