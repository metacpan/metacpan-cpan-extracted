package C::DynaLib::Parse;

# common functions for function and struct parsers.
# Using GCC::TranslationUnit (required, but does not work yet)
# and Convert::Binary::C (optional).
# Reini Urban 2010

use strict;
use vars qw(@ISA @EXPORT_OK);
use Exporter;# 'import';
@ISA = qw(Exporter);
@EXPORT_OK = qw(pack_types process_struct process_func
		declare_func declare_struct
	      );

use GCC::TranslationUnit;
use File::Temp;
use Config;
use C::DynaLib;

#sub PTR_TYPE { C::DynaLib::PTR_TYPE }
our @post;
my %records;

# at first GCC::TranslationUnit alone functions
# unused
sub GCC {
  my $is_gcc = $Config{cc} =~ /gcc/i && $Config{gccversion} >= 3;
  if (!$is_gcc and $Config{cc} =~ /^cc/) {
    my $test = `$Config{cc} -dumpversion`;
    $is_gcc = 1 if $test and $test eq $Config{gccversion}."\n";
  }
  warn "Parse needs a gcc with -fdump-translation-unit or gccxml\n"
    unless $is_gcc;

}

sub GCC_prepare { # decl, [gcc]
  # XXX looks like file => c or c++
  my $code = shift;
  my $cc = shift || 'gcc'; # || gcc-xml
  my $tmp = File::Temp->new( TEMPLATE => "tmpXXXXX",
			     SUFFIX => '.c' );
  my $tmpname = $tmp->filename;
  print $tmp "$code\n";
  close $tmp;
  system "$cc -c -fdump-translation-unit $tmpname";
  my @tu = glob "$tmpname.*.tu" or die;
  my $tu = pop @tu;
  my $node = GCC::TranslationUnit::Parser->parsefile($tu)->root;
  $tmpname =~ s/\.c$/.o/;
  unlink $tu, $tmpname;
  $node;
}

# XXX resolve non-basic types, only integer, real, pointer, record.
# boolean?
# on records and pointers we might need to create handy accessors per FFI.
sub type_name {
  my $type = shift;
  #warn $type->qual ? $type->qual." " : "";
  if ($type->name and $type->name->can('name')) {
    return $type->name->name->identifier;
  } elsif (ref $type eq 'GCC::Node::pointer_type') {
    my $node = $type->type;
    if ($node->isa('GCC::Node::record_type')) {
      my $struct = ref($node->name) =~ /type_decl/
	? $node->name->name->identifier : $node->name->identifier;
      # mark struct $name to be dumped later, with decl and fields
      push @C::DynaLib::Parse::post, $node unless $records{$struct};
      # prevent from recursive declarations
      $records{$struct}++;
      return $node->code . " $struct " . $type->thingy . type_name($node);
    }
    return $type->thingy . type_name($node);
  } else {
    ''
  };
}

sub process_func {
  my $node = shift;
  my @parms;
  my $func = $node->name->identifier;
  my $type = $node->type;
  # type => function_type    size: @12      algn: 8        retn: @85  prms: @185
  if ($type->parms) {
    my $parm = $type->parms;
    while ($parm) {
      push @parms, type_name($parm->value);
    } continue {
      $parm = $parm->chain;
    }
  }
  #printf "  size=%s\n", $type->size->type->name->identifier; bit_size_type
  return {name => $func,
	  retn => type_name($type->retn),
	  align => $type->align,
	  retn_align => $type->retn->align,
	  parms => \@parms};
}

sub declare_func {
  my $decl = shift;
  C::DynaLib::DeclareSub($decl->{name},
			 pack_types($decl->{retn}),
			 pack_types($decl->{parms}));
}

sub declare_struct {
  my $decl = shift;
  Define C::DynaLib::Struct($decl->{name},
			    $decl->{packnames},
			    $decl->{names});
}

sub process_struct {
  my $node = shift;
  my (@types, @names, @sizes);
  my $struct = (ref($node->name) =~ /type_decl/)
      ? $node->name->name->identifier
      : $node->name->identifier;
  my $root = $node;
  #printf "\n%s ", $struct;
  #printf " (align=%s)\n",  $node->align;
  #printf "  {\n";
  $node = $node->fields;
  while ($node) {
    # field_decl
    push @types, type_name($node->type);
    push @names, $node->name->identifier;
    push @sizes, $node->align;
    #print "    ",type_name($node->type)," ",$node->name->identifier;
    #printf " (align=%s)\n", $node->align;
  } continue {
    $node = $node->chain;
  }
  #printf "  }\n";
  return {type      => $root->code,
	  name      => $struct,
	  packnames => pack_types(@types),
	  types     => \@types,
	  names     => \@names,
	  sizes     => \@sizes,
	  align     => $root->align,
	 };
}

# common functions for both

sub pack_types {
  my $types =
    {
     ''      => '',
     int     => 'i',
     double  => 'd',
     char    => 'c',
     long    => 'l',
     short   => 's',
     'signed int'     => 'i',
     'signed char'    => 'c',
     'signed long'    => 'l',
     'signed short'   => 's',
     'char*' => 'p',
     'void*' => &C::DynaLib::PTR_TYPE,
     'unsigned int'    => 'I',
     'unsigned char'   => 'C',
     'unsigned long'   => 'L',
     'unsigned short'  => 'S',
     'long long'       => 'q',
     'unsigned long long' => 'Q',
    };
  join "", map {defined $types->{$_} ? $types->{$_} : &C::DynaLib::PTR_TYPE} @_;
}


1;
