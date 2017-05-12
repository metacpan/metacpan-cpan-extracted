#!/usr/bin/perl -W
package AI::MicroStructure;
use strict;
use warnings;
use Carp;
use Digest::MD5 qw(md5 md5_hex md5_base64);
use Digest::SHA1  qw(sha1 sha1_hex sha1_base64);
use Try::Tiny;
use File::Basename;
use File::Spec;
use File::Glob;
use Data::Dumper;
use Data::Printer;
use AI::MicroStructure::Util;
use Carp qw(croak);

our $absstructdir = "";
our $structdir = "";
our $VERSION = '0.018';
our $Structure = 'any'; # default structure
our $CODESET = 'utf8';
our $LANG = '';
our %MICRO;
our %MODS;
our %ALIEN;
our $str = "[A-Z]";
our $special = "any";
our $search;
our $data={};
our $item="";
our @items;
our @a=();


our ($init,$new,$drop,$available,$lib,
     $list,$use,$off,$switch,$mirror,
     $version,$help,$write,$verbose)  = (0,0,0,0,0,0,0,0,0,0,0,0,0,0);

eval "\$$_=1; " for @ARGV;



if( grep{/\bnew\b/} @ARGV ){ $new = 1; cleanArgs("new"); }
if( grep{/\bwrite\b/} @ARGV ){ $write = 1; cleanArgs("write");  };
if( grep{/\bdrop\b/} @ARGV ){ $drop = 1; cleanArgs("drop");  };
if( grep{/\bverbose\b/} @ARGV ){ $verbose = 1; cleanArgs("verbose");  };

our $StructureName = $ARGV[0]; # default structure
our $structure = $ARGV[0]; # default structure

our $state  = AI::MicroStructure::Util::config();

our @CWD=();
push @CWD ,  $state->{path}->{"cwd/structures"};
our $config = $state->{cfg};



our $micro = AI::MicroStructure->new($Structure);

$absstructdir = $state->{path}->{"cwd/structures"};



sub cleanArgs{
   my ($key) = @_;
   my @tmp=();
   foreach(@ARGV){
   push @tmp,$_ unless($_=~/$key/);}
   @ARGV=@tmp;
}
# private class method
sub find_structures {
   my ( $class, @dirs ) = @_;
   $ALIEN{"base"} =  [map  @$_,
   map  { [ ( fileparse( $_, qr/\.pm$/ ) )[0] => $_ ] }
   map  { File::Glob::bsd_glob(
   File::Spec->catfile( $_, ($structdir,"*") ) ) } @dirs];

#  $ALIEN{"store"}=[split("\n",`cat @dirs/* | egrep -v "(our|my|use|sub|package)" | data-freq | egrep  -iv "^ [1]:`),
 #                  split("\n",`cat @dirs/* | egrep -v "(our|my|use|sub|package)" | data-freq | egrep -i "^ [1]:`)];

##p %ALIEN;

   return @{$ALIEN{"base"}};
}

# fetch the list of standard structures


sub find_modules {


 my $structures = {};
   foreach(@INC)
   {

   my @set =  grep /($str)/,   map  @$_,
   map  { [ ( fileparse( $_, qr/\.pm$/ ) )[0] => $_ ] }
   map  { File::Glob::bsd_glob(
     File::Spec->catfile( $_, qw( AI MicroStructure *.pm ) ) ) } $_;

   foreach(@set){
   $structures->{$_}=$_;# unless($_=~/(usr\/local|basis)/);
   }
  }
  return %$structures;
}



$MICRO{$_} = 0 for keys %{{__PACKAGE__->find_structures(@CWD)} };
$MODS{$_} = $_ for keys %{{__PACKAGE__->find_modules(@INC)} };
$search = join("|",keys %MICRO);

#p @{[__PACKAGE__->getComponents]};
#die;
#if( grep{/$search/} @ARGV ){ $Structure = $ARGV[0] unless(!$ARGV[0]); }

# fetch the list of standard structures

#print Dumper keys %MICRO;
sub getComponents{


  my $x= {};


        $x->{"all_structures"} = [keys %MICRO];
        $x->{"count_struct"} = sprintf(keys %MICRO);
        $x->{"structures"} = {};
        $x->{"structures"}->{"json"} = sprintf(`ls  /home/santex/repos/KnowledgeInterDisciplinary/data/json | egrep -i "($structure)";`);


           foreach my $con (@{$x->{"all_structures"}}){
            next unless($con!~/any/);
            my @in = split("\n",eval{`cat $state->{path}->{"cwd/structures"}/$con.pm`;});

#            my $conc=join("|",@{$x->{"nsubcon"}->{$state->{path}->{"cwd/structures"}}->{$con}->{all}});

$x->{"structures"}->{$state->{path}->{"cwd/structures"}}->{$con}->{name} = [grep{$_}grep {!/(our|my|use|sub|use|package|#|__|1)/}split("\n",`cat $state->{path}->{"cwd/structures"}/$con.pm`)];#,
#split("\n",grep{$con}@{$x->{"structures"}->{"json"}})];
$x->{"structures"}->{$state->{path}->{"cwd/structures"}}->{$con}->{files}  =  [split("\n",`ls -R  /home/santex/repos/KnowledgeInterDisciplinary/data/json | egrep -i "($con)";`)];
          }

#$x->{"nsubcon"}->{$state->{path}->{"cwd/structures"}}->{$con}->{n} = grep{$_}grep {!/(our|my|use|sub|use|package|#|__|1)/}split("\n",`cat $state->{path}->{"cwd/structures"}/$con.pm`) ;

#
        $x->{"structures"}->{"json"} = [];
#p @{[$x]};

# $x->{"structures"}->{json}=[];
        #my @got = [values  %{$x->{"structures"}}];

         # p @got;
  #      foreach(@got){
 #         if(!$#_ && 0){
#$x->{"structures"}->{$_} = [grep{$_}ssplit("^*\n",`cat '$state->{path}->{"cwd/structures"}/$_.pm'`)];
#die();
  #        }
  #}

 #       if(!@{$x->{"structures"}->{$_}}){

#    $x->{"structures"}->{$_} =   [split("^*\n",`cat $state->{path}->{"cwd/structures"}/$_.pm |  | egrep -i "($_)\$"`)] for( @{$x->{"all structures"}});

#          "glue"=>split("\n",`cat  $CWD[0]/* | egrep -v "(our|my|use|sub|package)"  | egrep -i "($structure)$"  | data-freq | egrep  -v "^ [1]:"`)};
#
 return $x;
}




sub import {
    my $class = shift;

    my @structures = ( grep { $_ eq ':all' } @_ )
      ? ( 'foo', grep { !/^(?:foo|:all)$/ } keys %MICRO  ) # 'foo' is still first
      : @_;

    $Structure = $structures[0] if @structures;
    $micro = AI::MicroStructure->new( $Structure );

    # export the microname() function
    no strict 'refs';
    my $callpkg = caller;
    *{"$callpkg\::microname"} = \&microname;    # standard theme

    # load the classes in @structures
    for my $structure( @structures ) {
        eval "require AI::MicroStructure::$structure; import AI::MicroStructure::$structure;";
        croak $@ if $@;
        *{"$callpkg\::micro$structure"} = sub { $micro->name( $structure, @_ ) };
    }
}

sub new {
    my ( $class, @args ) = ( @_ );
    my $structure;
    $structure = shift @args if @args % 2;
    $structure = $Structure unless $structure; # same default everywhere

    # defer croaking until name() is actually called
    bless { structure => $structure, args => { @args }, micro => {} ,state=>$state}, $class;
}




sub _rearrange{
   my $self = shift;
   $self->{'payload'} = shift if @_;
   return %$self;
}

# CLASS METHODS
sub add_structure {
   my $class  = shift;
   my %structures = @_;

   for my $structure ( keys %structures ) {
   croak "The structure $structure already exists!" if exists $MICRO{$structure};
   my @badnames = grep { !/^[a-z_]\w*$/i } @{$structures{$structure}};
   croak "Invalid names (@badnames) for structure $structure"
   if @badnames;

   my $code = << "EOC";
package AI::MicroStructure::$structure;
use strict;
use AI::MicroStructure::List;
our \@ISA = qw( AI::MicroStructure::List );
our \@List = qw( @{$structures{$structure}} );
__PACKAGE__->init();
1;
EOC
   eval $code;
   $MICRO{$structure} = 1; # loaded

   # export the microstructure() function
   no strict 'refs';
   my $callpkg = caller;
   *{"$callpkg\::micro$structure"} = sub { $micro->name( $structure, @_ ) };
   }
}





# load the content of __DATA__ into a structure
# this class method is used by the other AI::MicroStructure classes
sub load_data {
   my ($class, $structure ) = @_;
   $data = {};

   my $fh;
   { no strict 'refs'; $fh = *{"$structure\::DATA"}{IO}; }

   my $item;
   my @items;
   $$item = "";

   {
   if(defined($fh)){
   local $_;
   while (<$fh>) {
   /^#\s*(\w+.*)$/ && do {
   push @items, $item;
   $item = $data;
   my $last;
   my @keys = split m!\s+|\s*/\s*!, $1;
   $last = $item, $item = $item->{$_} ||= {} for @keys;
   $item = \( $last->{ $keys[-1] } = "" );
   next;
   };
   $$item .= $_;
   }
   }
}
   # clean up the items
   for( @items, $item ) {
   $$_ =~ s/\A\s*//;
   $$_ =~ s/\s*\z//;
   $$_ =~ s/\s+/ /g;
   }


   return $data;
}


#fitnes

sub fitnes {

    my $self = shift;
    return sha1_hex($self->structures());
   ##my ($config,$structure, $config ) = (shift,[$self->structures()]); FIXME

}

# main function
sub microname { $micro->name( @_ ) };



sub shitname {
    my $self = shift;
    my ( $structure, $count ) = ("any",1);

    if (@_) {
        ( $structure, $count ) = @_;
        ( $structure, $count ) = ( $self->{structure}, $structure )
          if $structure =~ /^(?:0|[1-9]\d*)$/;
    }
    else {
        ( $structure, $count ) = ( $self->{structure}, 1 );
    }

    if( ! exists $self->{micro}{$structure} ) {
        my ( $structure, $category ) = split /\//, $structure, 2;
        if( ! $MICRO{$structure}  ) {
            try{

#            `micro new $structure`;

            eval "require '$absstructdir/$structure.pm';";
            $MICRO{$structure} = 1; # loaded
            $self->{micro}{$structure}  = AI::MicroStructure->new($structure,category => $category);
            print $self->{micro}{$structure}->name( $count );
            return;
            }  catch{

            }
        }

    }



}

# corresponding method
sub name {
   my $self = shift;
   my ( $structure, $count ) = ("any",1);

   if (@_) {
   ( $structure, $count ) = @_;
   ( $structure, $count ) = ( $self->{structure}, $structure )
   if defined($structure) && $structure =~ /^(?:0|[1-9]\d*)$/;
   }
   else {
   ( $structure, $count ) = ( $self->{structure}, 1 );
   }

   if( ! exists $self->{micro}{$structure} ) {
   if( ! $MICRO{$structure} ) {
   eval "require '$absstructdir/$structure.pm';";
   croak "MicroStructure list $structure does not exist!" if $@;
   $MICRO{$structure} = 1; # loaded
   }
   $self->{micro}{$structure} =
   "AI::MicroStructure::$structure"->new( %{ $self->{args} } );
   }

   $self->{micro}{$structure}->name( $count );
}

# corresponding method
sub namex {
   my $self = shift;
   my ( $structure, $count ) = ("any",1);

   if (@_) {
   ( $structure, $count ) = @_;
   ( $structure, $count ) = ( $self->{structure}, $structure )
   if defined($structure) && $structure =~ /^(?:0|[1-9]\d*)$/;
   }
   else {
   ( $structure, $count ) = ( $self->{structure}, 1 );
   }

   if( ! exists $self->{micro}{$structure} ) {
   if( ! $MICRO{$structure} ) {
    try {
   eval "require '$absstructdir/$structure.pm';";
   $MICRO{$structure} = 1; # loaded
   croak "MicroStructure list $structure does not exist!" if $@;

    }catch{

      }
   }
   $self->{micro}{$structure} =
   "AI::MicroStructure::$structure"->new( %{ $self->{args} } );







   }

   $self->{micro}{$structure}->name( $count );
}






# other methods
sub structures { wantarray ? ( sort keys %MICRO ) : scalar keys %MICRO }
sub has_structure { $_[1] ? exists $MICRO{$_[1]} : 0 }
sub configure_driver { $_[1] ? exists $MICRO{$_[1]} : 0 }
sub count {
   my $self = shift;
   my ( $structure, $count );

   if (@_) {
   ( $structure, $count ) = @_;
   ( $structure, $count ) = ( $self->{structure}, $structure )
   if $structure =~ /^(?:0|[1-9]\d*)$/;
   }


   if( ! exists $self->{micro}{$structure} ) {
   return scalar ($self->{micro}{$structure}->new);
   }

   return 0;
}


sub trim
{
   my $self = shift;
   my $string = shift;
   $string =  "" unless  $string;
   $string =~ s/^\s+//;
   $string =~ s/\s+$//;
   $string =~ s/\t//;
   $string =~ s/^\s//;
   return $string;
}


sub getBundle {

   my $self = shift;



my @structures = grep { !/^(?:any)/ } AI::MicroStructure->structures;
my @micros;
my @search=[];
for my $structure (@structures) {
   no strict 'refs';
   eval "require '$absstructdir/$structure.pm';";

   my %isa = map { $_ => 1 } @{"AI::MicroStructure::$structure\::ISA"};
   if( exists $isa{'AI::MicroStructure::Locale'} ) {
   for my $lang ( "AI::MicroStructure::$structure"->languages() ) {
   push @micros,
   ["AI::MicroStructure::$structure"->new( lang => $lang ),$lang];


   }
   }
   elsif( exists $isa{'AI::MicroStructure::MultiList'} ) {
   for my $cat ( "AI::MicroStructure::$structure"->categories(), ':all' ) {
   push @micros,
   [ "AI::MicroStructure::$structure"->new( category => $cat ),$cat];
   }
   }
   else {
   push @micros, ["AI::MicroStructure::$structure"->new(),''];
   }
}

my  $all ={};

for my $test (@micros) {
   my $micro = $test->[0];
   my %items;
   my $items = $micro->name(0);
   $items{$_}++ for $micro->name(0);
   my $key=sprintf("%s",$micro->structure);
   $all->{$key}=[$test->[1],$micro->name($items)];

}


 return $all;

}


sub save_cat {

  my $self = shift;
  my $data = shift;
  my $dat;
  my $ret = "";


  foreach my $key(sort keys %{$data} ) {
   next unless($_);
   #ref $hash->{$_} eq "HASH"
   if(ref $data->{$key} eq "HASH"){
   $ret .= "\n".$self->save_cat($data->{$key});
   }else{
   $dat = $data->{$key};
   $dat =~ s/^|,/\n/g;
   $dat =~ s/\n\n/\n/g;
   $dat =~ s/->\n|[0-9]\n//g;

   $ret .= "# ".($key=~/names|default|[a-z]/?$key:"names ".$key);
   $ret .= "\n ".$dat."\n";
   }

  }

  return $ret;

}

sub save_default {

  my $self = shift;
  my $data = shift;
  my $line = shift;
  my $dat = {};
  my @in = ();
  my $active=0;
  $line = $Structure unless($line);

  foreach(@{$data->{rows}->{"coordinate"}}){

   if($_ eq $line){ $active=1; }

   if(1+$line eq $_){ $active=0; }

   if($active==1){
   $_=~s/,//g;
   $_ = $self->trim($_);
   $dat->{names}->{$_}=$_ unless(defined($dat->{names}->{$_}));
   }

}

foreach(@{$data->{rows}->{"search"}}){

   if($_ eq $line){  $active=1; }


   if(1+$line eq $_){ $active=0; }

   if($active==1){
   $_=~s/,//g;
   $_ = $self->trim($_);
   $dat->{names}->{$_}=$_ unless(defined($dat->{names}->{$_}));


   }

}

push @in , keys %{$dat->{names}};
push @in , values %{$data->{names}};
$dat->{names} = join(" ",@in);
$dat->{names} =~ s/$line(.*?)\-\>(.*?) [1-9] /$1 $2/g;
$dat->{names} =~ s/  / /g;
my @file = grep{/$Structure/}map{File::Glob::bsd_glob(
 File::Spec->catfile( $_, ($structdir,"*.pm") ) )}@CWD;


  if(@file){
  open(SELF,"+<$file[0]") || die $!;

  while(<SELF>){last if /^__DATA__/}

   truncate(SELF,tell SELF);

   print SELF $self->save_cat($dat);

   truncate(SELF,tell SELF);
   close SELF;
  }

}

sub openData{

my $self = shift;

my @datax = ();

if(<DATA>){

@datax = <DATA>;

while(@datax){
  chomp;
  if($_=~/^#\s*(\w+.*)$/) {
   @a=split(" ",$1);
   if($#a){
   $data->{$a[0]}->{$a[1]}="";
   }else{
   $data->{$1}="";
   }
   $item=$1 unless($#a);

  }else{

   my @keys = split m!\s+|\s*/\s*!,$_;
   foreach(sort @keys){
   if($#a){
   $data->{$a[0]}->{$a[1]} .= " $_" unless($_ eq "");
   }else{
   $data->{$item} .= " $_" unless($_ eq "");
   }
   }

  };

}
}
return $data;


}

sub getBlank {

  my $self = shift;
  my $structure = shift;
  my $data = shift;



my $usage = "";

$usage = "#!/usr/bin/perl -W\n";
$usage .= << "EOC";
package AI::MicroStructure::$structure;
use strict;
use AI::MicroStructure::List;
our \@ISA = qw( AI::MicroStructure::List );
our \@List = qw( \@{\$structures{\$structure}} );
__PACKAGE__->init();
1;
EOC



my $new = {};
foreach my $k
(grep{!/^[0-9]/}map{$_=$self->trim($_)}@{$data->{rows}->{"search"}}){

   $k =~ s/[ ]/_/g;
   $k =~ s/[\(]|[\)]//g;
   next if($k=~/synonyms|hypernyms/);
   print $k;
   $new->{$k}=[map{$_=[map{$_=$self->trim($_)}split("\n|, ",$_)]}
      grep{!/synonyms|hypernyms/}split("sense~~~~~~~~~",
                                      lc `micro-wnet $k`)];
   next unless(@{$new->{$k}});
#   $new->{$k}=~s/Sense*\n(.*?)\n\n/$1/g;
#   @{$new->{$k}} = [split("\n|,",$new->{$k})];
   $data->{rows}->{"ident"}->{md5_base64($new->{$k})} = $new->{$k};

}


my $list = join("\n",sort keys %$new);


#   $list =~ s/_//g;

$usage .= "
__DATA__
# names
".$list;




}

sub save_new {

my $self = shift;
my $StructureName = shift;
my $data = shift;

    if($StructureName){
    #$StructureName = lc $self->trim(`micro`) unless($StructureName);
    my $file = "$absstructdir/$StructureName.pm";

    print `mkdir -p $absstructdir` unless(-d $absstructdir);
    my $fh;

    open($fh,">$file") || warn @{[$file,$!]};

    print $fh $self->getBlank($StructureName,$data);

    close $fh;
    $Structure = $StructureName;
    push @CWD,$file;
    return 1;
  }
}



sub drop {

my $self = shift;
my $StructureName = shift;

my @file = grep{/$StructureName.pm/}map{File::Glob::bsd_glob(
File::Spec->catfile( $_, ($structdir,"*.pm") ) )}@CWD;
my $fh = shift @file;
if(`ls $fh`)
{

print  `rm $fh`;
}
  #push @CWD,$file[1];

  return 1;
}


sub help{

}



END{

if($init){}
if($available){}
if($lib){}
if($list){
p @{[__PACKAGE__->getComponents]};

  }
if($use){}
if($off){}
if($switch){}
if($mirror){}
if($version){
    printf($VERSION);
    exit(0);
}



if($help) {
    printf(__PACKAGE__->help());
    exit(0);

}





if($drop == 1) {
   __PACKAGE__->drop($StructureName);
   exit 0;
}

if($new==1){

  use Term::ReadKey;
  use JSON;

  my $data = decode_json(lc`micro-sense $StructureName words`);



  my $char;
  my $line;
  my $senses=@{$data->{"senses"}};
   $senses= 0 unless($senses);
 if(!$verbose){

  printf("\n
  \033[0;34m
  %s
  Type: the number you choose 1..$senses
  \033[0m",__PACKAGE__->usage($StructureName,$senses,$data));
 }
  $line = 1 unless($senses != 1);
  if($verbose){
    $line=1;
  }
  chomp($line = <STDIN>) unless($line);

  my $d = join("#",@{$data->{rows}->{search}});

  my  @d = grep{/^$line#/}split("sense~~~~~~~~~",$d);
  @{$data->{rows}->{"search"}}=split("#",join("",@d));

  if($line>0){
   __PACKAGE__->save_new($StructureName,$data,$line);
   exit 0;
  }else{

   printf "your logic is today impaired !!!\n";
   exit 0;

  }



  }

  if($write == 1) {
   __PACKAGE__->save_default();
  }
}





sub usage {

 my $self = shift;


 my $search = shift;
 my $senseNr = shift;
 my $data = shift;


my $usage = << 'EOT';

               .--'"""""--.>_
            .-'  o\\b.\o._o.`-.
         .-'.- )  \d888888888888b.
        /.'   b  Y8888888888888888b.
      .-'. 8888888888888888888888888b
     / o888 Y Y8888888888888888888888b
     / d888P/ /| Y"Y8888888888888888888b
   J d8888/| Y .o._. "Y8888888888888Y" \
   |d Y888b|obd88888bo. """Y88888Y' .od8
   Fdd 8888888888888888888bo._'|| d88888|
   Fd d 88\ Y8888Y "Y888888888b, d888888P
   d-b 8888b Y88P'     """""Y888b8888P"|
  J  8\88888888P    `m.        """""   |
  || `8888888P'       "Ymm._          _J
  |\\  Y8888P  '     .mmm.YM)     .mMF"'
  | \\  Y888J     ' < (@)>.- `   /MFm. |
  J   \  `YY           ""'   ::  MM @)>F
   L  /)  88                  :  |  ""\|
   | ( (   Yb .            '  .  |     L
   \   bo  8b    .            .  J     |        <0>_
    \      "' .      .    .    .  L   F         <1>_
     o._.:.    .        .  \mm,__J/  /          <2>_
     Y8::'|.            /     `Y8P  J           <3>_
     `|'  J:   . .     '   .  .   | F           <4>_
      |    L          ' .    _:    |            <5>_
      |    `:        . .:oood8bdb. |            1>_
      F     `:.          "-._   `" F            2>_
     /       `::.           """'  /             3>_
    /         `::.          ""   /              4>_
_.-d(          `:::.            F               5>_
-888b.          `::::.     .  J                 6>_
Y888888b.          `::::::::::'                 7>_
Y88888888bo.        `::::::d                    8>_
`"Y8888888888boo.._   `"dd88b.                  9>_





"""""""""""""""""""""""""""""""""""""""""""""""

EOT


$usage =~ s/<0>_/\033[0;32mThe word $search\033[255;34m/g;
$usage =~ s/<1>_/\033[0;32mhas $senseNr concept's\033[255;34m/g;
$usage =~ s/<2>_/\033[0;32mwe need to find out the which one\033[255;34m/g;
$usage =~ s/<3>_/\033[0;32mto use for our new,\033[255;34m/g;
$usage =~ s/<4>_/\033[0;32mmicro-structure,\033[255;34m/g;
$usage =~ s/<5>_//g;
my @row = ();
my $ii=0;
foreach my $sensnrx (sort keys %{$data->{"rows"}->{"senses"}})
{



   my $row = $data->{"rows"}->{"senses"}->{$sensnrx};
   my $txt="";

   foreach(@{$row->{"basics"}}[1..2]){
   next unless($_);
   $txt .= sprintf("\033[0;31m %s\033[255;34m",$_);
   }

   $txt .= sprintf("",$_);
   $usage =~ s/$sensnrx>_/($sensnrx):$txt/g;
   if($sensnrx>9){
   $usage .= sprintf("\n(%d):%s",$sensnrx,$txt);

   }
}

  foreach my $ii (0..16){
   $usage =~ s/$ii>_//g;
  }


return $usage;
}

1;

__END__

1;

__END__


#print Dumper $micro;

# ABSTRACT: AI::MicroStructure   Creates Concepts for words

=head1 NAME

  AI::MicroStructure

=head1 DESCRIPTION

  Creates Concepts for words

=head1 SYNOPSIS

  ~$ micro new world

  ~$ micro structures

  ~$ micro any 2

  ~$ micro drop world

  ~$ micro

=head1 AUTHOR

  Hagen Geissler <santex@cpan.org>

=head1 COPYRIGHT AND LICENCE

  Hagen Geissler <santex@cpan.org>

=head1 SUPPORT AND DOCUMENTATION

 [sample using concepts](http://quantup.com)

 [PDF info on my works](https://github.com/santex)


=head1 SEE ALSO

  AI-MicroStructure
  AI-MicroStructure-Cache
  AI-MicroStructure-Deamon
  AI-MicroStructure-Relations
  AI-MicroStructure-Concept
  AI-MicroStructure-Data
  AI-MicroStructure-Driver
  AI-MicroStructure-Plugin-Pdf
  AI-MicroStructure-Plugin-Twitter
  AI-MicroStructure-Plugin-Wiki



__DATA__



our $VERSION = '0.014';
our $Structure = 'any'; # default structure
our $CODESET = 'utf8';
our $LANG = '';
our %MICRO;
our %MODS;
our %ALIEN;
our $str = "[A-Z]";
our $special = "any";
our $search;
our $data={};
our $item="";
our @items;
our @a=();





our ($new, $write,$drop) =(0,0,0);

my $state = AI::MicroStructure::util::load_config(); my @CWD=$state->{cwd}; my $config=$state->{cfg};
our $structdir = "structures";
our $absstructdir = "$CWD[0]/$structdir";

if( grep{/\bnew\b/} @ARGV ){ $new = 1; cleanArgs("new"); }
if( grep{/\bwrite\b/} @ARGV ){ $write = 1; cleanArgs("write");  };
if( grep{/\bdrop\b/} @ARGV ){ $drop = 1; cleanArgs("drop");  };

our $StructureName = $ARGV[0]; # default structure
our $structure = $ARGV[0]; # default structure

##########################################################################
cat  $dir/* | egrep -v "(our|my|use|sub|package)"  | egrep -i "(instance|animal|whale|mammal|sea)$" | egrep  "^ [1]:"
 1: andaman_sea
 1: swansea
 1: domesticanimal
 1: fictionalanimal
 1: marineanimal



cat  $dir/* | egrep -v "(our|my|use|sub|package)"  | egrep -i "(instance|animal|whale|mammal|sea)$"  | data-freq | egrep  -v "^ [1]:"
84: animal
26: mammal
25: eutherian_mammal
25: placental_mammal
12: domesticated_animal
11: domestic_animal
 6: predatory_animal
 6: sea_animal
 5: fictional_animal
 5: marine_animal
 5: range_animal
 5: work_animal
 5: hoofed_mammal
 3: artiodactyl_mammal
 2: perissodactyl_mammal
 2: instance
 2: moss_animal
 2: anglesea
 2: female_mammal
 2: fossorial_mammal
 2: mediterranean_sea
 2: aquatic_mammal
 2: cetacean_mammal
 2: toothed_whale
 2: whale
