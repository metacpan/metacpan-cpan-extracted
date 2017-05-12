##-*- Mode: CPerl -*-

##======================================================================
package DDC::PP::Object;
use JSON;
use Carp qw(carp confess);
use strict;

##======================================================================
## debugging & wrapping utilities

## undef = $CLASS->nomethod($method_name)
##  + defines a method $CLASS::$method_name which just throws an error
sub nomethod {
  my ($class,$method_name) = @_;
  my $method = "${class}::${method_name}";
  no strict "refs";
  *$method = sub {
    confess("${method}(): method not implemented");
  };
}

## undef = $CLASS->defprop($property)
##  + defines $CLASS::get$Property and $CLASS::set$Property methods
sub defprop {
  my ($class,$prop)=@_;
  my $getmethod = "${class}::get".ucfirst($prop);
  my $setmethod = "${class}::set".ucfirst($prop);
  no strict 'refs';
  *$getmethod = sub { return $_[0]{$prop}; };
  *$setmethod = sub { return $_[0]{$prop}=$_[1]; };
}

## undef = $CLASS->defalias($propertyFrom,$propertyTo, $doGet=1, $doSet=1)
##  + aliases $CLASS::get$PropertyFrom and $CLASS::set$PropertyFrom methods to $CLASS::get$PropertyTo etc.
sub defalias {
  my ($class,$pfrom,$pto, $doGet,$doSet)=@_;
  my $getmethod = "${class}::get".ucfirst($pfrom);
  my $setmethod = "${class}::set".ucfirst($pfrom);
  no strict 'refs';
  *$getmethod = $class->can('get'.ucfirst($pto)) if (!defined($doGet) || $doGet);
  *$setmethod = $class->can('set'.ucfirst($pto)) if (!defined($doSet) || $doSet);
}

##======================================================================
## xs replacements

sub new {
  my $that = shift;
  return bless { @_ }, ref($that)||$that;
}

__PACKAGE__->nomethod('DumpTree');
__PACKAGE__->nomethod('refcnt');
__PACKAGE__->nomethod('self');
__PACKAGE__->nomethod('free');

#__PACKAGE__->nomethod('Children');
#  + override this if order is important (e.g. for DiaCollo CQWith, CQAnd, etc.)
sub Children {
  return UNIVERSAL::isa($_[0],'HASH') ? [grep {UNIVERSAL::isa($_,'DDC::PP::Object')} values %{$_[0]}] : [];
}

#__PACKAGE__->nomethod('Descendants');
sub Descendants {
  my @stack = (shift);
  my %visited = qw();
  my @kids    = qw();
  my ($obj);
  while (@stack) {
    $obj = shift(@stack);
    next if (exists $visited{$obj});
    push(@kids,$obj);
    $visited{$obj} = undef;
    unshift(@stack, @{$obj->Children}) if (ref($obj));
  }
  return \@kids;
}

#__PACKAGE__->nomethod('DisownChildren');
sub DisownChildren {
  my $obj = shift;
  return if (!ref($obj));
  delete @$obj{$obj->members};
}

#__PACKAGE__->nomethod('toString');
sub toString {
  return "$_[0]";
}

sub toJson {
  return JSON::to_json( $_[0], {utf8=>1,pretty=>0,canonical=>1,allow_blessed=>1,convert_blessed=>1} );
}

##-- json utils
sub jsonClass {
  (my $class = ref($_[0]) || $_[0]) =~ s/^DDC::PP:://;
  return $class;
}


##======================================================================
## Traversal

##--------------------------------------------------------------
## $obj = $obj->mapTraverse(\&CODE)
##  + calls \&CODE on $obj and each DDC::PP::Object descendant in turn
##  + \&CODE is called as \&CODE->($obj), and should return a new value for the corresponding slot
##  + object tree is traversed in depth-first visit-last order
sub mapTraverse {
  my ($obj,$code) = @_;
  return $obj->mapVisit($obj,$code);
}

## $oldval = CLASS->mapVisit($curval, \$code)
sub mapVisit {
  my ($that,$nod,$code) = @_;
  if (#UNIVERSAL::isa($nod,'DDC::PP::Object') ##-- breaks DDC::Any
      ref($nod) && UNIVERSAL::can($nod,'members')
     ) {
    my ($oldval,$newval);
    foreach my $slot (grep {$nod->can("get$_")} $nod->members) {
      $oldval = $nod->can("get${slot}")->($nod);
      $newval = $that->mapVisit($oldval, $code);
      $nod->can("set${slot}")->($nod,$newval) if ((defined($newval) && defined($oldval) && $newval ne $oldval)
						  || defined($newval)
						  || defined($oldval));
    }
    return $code->($nod);
  }
  elsif (ref($nod) && UNIVERSAL::isa($nod,'ARRAY')) {
    my $newval = [grep {defined($_)} map {$that->mapVisit($_,$code)} @$nod];
    return ref($newval) eq 'ARRAY' ? $newval : bless($newval, ref($nod));
  }
  elsif (ref($nod) && UNIVERSAL::isa($nod,'HASH')) {
    my $newval = {map {($_=>$that->mapVisit($nod->{$_},$code))} keys %$nod};
    return ref($newval) eq 'HASH' ? $newval : bless($newval, ref($nod));
  }
  return $nod;
}


##======================================================================
## C->Perl

##--------------------------------------------------------------
## \%hash = $obj->toHash(%opts)
##  + %opts:
##    (
##     trimClassNames => $bool,  ##-- auto-trim class-names?
##     json => $bool,            ##-- for JSON-ification?
##    )
##  + returns an object as a (nested) perl hash
##  + pure-perl variant just returns object
sub toHash {
  my ($obj,%opts) = @_;
  return $obj if (!defined($obj) && !ref($obj));
  my $class = ref($obj);
  $class =~ s/^DDC::(?:XS|PP|Any)::// if ($opts{trimClassNames} || $opts{json}); ##-- use toJson()-style class names
  return {
	  (map {
	    ( $_ => $obj->valToPerl($obj->can("get$_")->($obj),%opts) )
	  } grep {
	    $obj->can("get$_")
	  }  $obj->members),
	  class => $class,
	 };
}

##--------------------------------------------------------------
## $perlval = $CLASS_OR_OBJECT->valToPerl($cval,%opts)
##  + %opts: as for toHash()
##  + returns a perl-encoded representation of $cval
sub valToPerl {
  my ($that,$cval,%opts) = @_;
  if (!ref($cval)) {
    return $cval;
  } elsif (UNIVERSAL::can($cval,'toHash')) {
    return $cval->toHash(%opts);
  } elsif (UNIVERSAL::isa($cval,'HASH')) {
    return {(map {($_=>$that->valToPerl($cval->{$_},%opts))} keys %$cval)};
  } elsif (UNIVERSAL::isa($cval,'ARRAY')) {
    return [map {$that->valToPerl($_,%opts)} @$cval];
  }
  return $cval; ##-- CODE- or GLOB-ref?
}


##--------------------------------------------------------------
## @classes = $CLASS_OR_OBJ->inherits()
##  + returns a list of all classes from which $CLASS_OR_OBJ inherits
##  + called by toHash()
sub inherits {
  no strict 'refs';
  my $that = shift;
  my $class = ref($that) || $that;
  return ($class, map {inherits($_)} @{"${class}::ISA"});
}

##--------------------------------------------------------------
## @keys = $CLASS_OR_OBJ->members()
##  + returns a list of all members with a "set${Key}" method supported by $CLASS_OR_OBJ or any superclasss
##  + called by toHash()
sub members {
  no strict 'refs';
  my $that = shift;
  my ($class,$symtab,%keys);
  foreach $class ($that->inherits) {
    $symtab = \%{"${class}::"};
    @keys{(
	   grep {exists $symtab->{"set$_"}}
	   map { /^get([[:upper:]].*)$/ ? $1 : qw() }
	   keys %$symtab
	  )} = qw();
  }
  return keys %keys;
}

##======================================================================
## Perl->C-like

##--------------------------------------------------------------
## $obj = CLASS->newFromHash(\%hash)
##  + creates a C++-like object from a (nested) perl hash
sub newFromHash {
  my ($that,$hash) = @_;
  my $class = ref($that) || $that;
  return $hash if (!defined($hash) || UNIVERSAL::isa($hash,$class));
  confess(__PACKAGE__ , "::newFromHash(): argument '$hash' is neither undef, a HASH-ref, nor an object of class $class")
    if (!UNIVERSAL::isa($hash,'HASH'));

  $class = $hash->{class} if (defined($hash->{class}));
  $class = "DDC::PP::$class" if ($class !~ /:/); ##-- honor toJson()-style class names
  my $obj = $class->new()
    or confess(__PACKAGE__, "::newFromHash(): $class->new() failed");

  my ($key,$val,$valobj, $setsub);
  while (($key,$val) = each %$hash) {
    next if ($key eq 'class');

    if ( !($setsub = $obj->can("set".ucfirst($key))) ) {
      warn(__PACKAGE__, "::newFromHash(): ignoring key '$key' for object of class '$class'");
      next;
    }
    $valobj = $that->valFromPerl($val);
    $setsub->($obj,$valobj);
  }

  return $obj;
}

##--------------------------------------------------------------
## $cval = $CLASS_OR_OBJECT->valFromPerl($perlval)
##  + returns a c-like representation of $perlval
sub valFromPerl {
  my ($that,$pval) = @_;
  if (!ref($pval)) {
    return $pval;
  } elsif (UNIVERSAL::isa($pval,'HASH') && $pval->{class}) {
    return $that->newFromHash($pval);
  } elsif (UNIVERSAL::isa($pval,'HASH')) {
    return {(map {($_=>$that->valFromPerl($pval->{$_}))} keys %$pval)};
  } elsif (UNIVERSAL::isa($pval,'ARRAY')) {
    return [map {$that->valFromPerl($_)} @$pval];
  }
  return $pval; ##-- CODE- or GLOB-ref?
}


##======================================================================
## Clone

## $obj2 = $obj->clone()
sub clone {
  return $_[0]->newFromHash($_[0]->toHash);
}

##======================================================================
## JSON

##--------------------------------------------------------------
## $obj = CLASS->newFromJson($json_string,%json_opts)
##  + creates a C++ object from a json string
sub newFromJson {
  my ($that,$json,%opts) = @_;
  my $hash = JSON::from_json($json, { utf8=>!utf8::is_utf8($json), relaxed=>1, allow_nonref=>1, %opts });
  return $that->newFromHash($hash);
}

## $json = $obj->TO_JSON
sub TO_JSON {
  return $_[0]->toHash(json=>1);
}


1; ##-- be happy

=pod

=head1 NAME

DDC::PP::Object - common perl base class for DDC::PP objects

=head1 SYNOPSIS

 #-- Preliminaries
 use DDC::PP;
 $CLASS = 'DDC::PP::Object';
 
 ##---------------------------------------------------------------------
 ## C -> Perl
 $q    = DDC::PP->parse("foo && bar");
 $qs   = $q->toString;                  ##-- $qs is "('foo' && 'bar')"
 $hash = $q->toHash();                  ##-- query encoded as perl hash-ref
 
 #... the perl object can be manipulated directly (perl refcounting applies)
 $hash->{Dtr1} = {class=>'CQTokExact',Value=>'baz'};    ##-- NO memory leak!
 
 ##---------------------------------------------------------------------
 ## Perl->C
 $q2   = $CLASS->newFromHash($hash);    ##-- $q2 needs explicit free()
 $qs2  = $q2->toString();               ##-- $qs2 is "(@'baz' && 'bar')
 
 ##---------------------------------------------------------------------
 ## Deep copy & Traversal
 
 $q3 = $q->clone();                     ##-- wraps newFromHash($q->toHash)
 $q  = $q->mapTraverse(\&CODE);         ##-- recursively tweak sub-objects
 
 ##---------------------------------------------------------------------
 ## JSON utilities
 $json = $q->toJson();                  ##-- ddc-internal json-ification
 $json = $q->TO_JSON();                 ##-- wraps toHash() for the JSON module
 $obj  = $CLASS->newFromJson($str);     ##-- wraps newFromHash(from_json($str))
 
 ##---------------------------------------------------------------------
 ## Debugging
 $obj->DumpTree();                      ##-- dumps substructure to STDERR
 $obj->free();                          ##-- expplicit deep destruction, use at your own risk
 \@kids = $obj->Children();             ##-- ARRAY-ref of direct children
 \@desc = $obj->Descendants();          ##-- ARRAY-ref of descendants
 undef  = $obj->DisownChildren();       ##-- prevent deep destruction (dummy method; you should never need this)
 $cnt   = $obj->refcnt();               ##-- get internal reference count (dummy method)



=head1 DESCRIPTION

The DDC::PP::Object class is a pure-perl fork of the L<DDC::XS::Object|DDC::XS::Object> class, which see.


=head1 SEE ALSO

perl(1),
DDC::PP(3perl),
DDC::PP::CQuery(3perl),
DDC::PP::CQCount(3perl),
DDC::PP::CQFilter(3perl),
DDC::PP::CQueryOptions(3perl),
DDC::PP::CQueryCompiler(3perl).

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 by Bryan Jurish

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

