use strict;
use Test;
BEGIN { plan tests => 7 }
use Config::Natural;
Config::Natural->options(-quiet => 1);
my $obj = new Config::Natural;

sub remove_comments {
    my $self = shift;
    my $data = shift;
    $data =~ s/\s*#.*$//gom;
    return $data
}

sub xpath_access {
    my $self = shift;
    my $data = shift;
    
    $data =~ s<\$\{([^}]+)\}>
      {
        my @path = split '/', $1;
        not $path[0] and shift @path;
        my($name,$index) = ( (shift @path) =~ /^([^[]+)(?:\[(\d+)\])?$/ );
        my $node = $self->param($name);
        if(ref $node) {
            $node = $node->[$index||0];
            for my $p (@path) {
                ($name,$index) = ( ($p) =~ /^([^[]+)(?:\[(\d+)\])?$/ );
                $node = $node->{$name};
                ref $node and $node = $node->[$index||0];
            }
        }
        $node
      }ge;
    return $data
}

sub varsubst {
    my $self = shift;
    my $data = shift;
    
    $data =~ s<\$(\w\S+)>
      {
        my @path = split '::', $1;
        not $path[0] and shift @path;
        my($name,$index) = ( (shift @path) =~ /^([^[]+)(?:\[(\d+)\])?$/ );
        my $node = $self->param($name);
        if(ref $node) {
            $node = $node->[$index||0];
            for my $p (@path) {
                ($name,$index) = ( ($p) =~ /^([^[]+)(?:\[(\d+)\])?$/ );
                $node = $node->{$name};
                ref $node and $node = $node->[$index||0];
            }
        }
        $node
      }ge;
    return $data
}

## First we check if the remove_comments() filter works
$obj->filter(\&remove_comments);
ok( ref $obj->{'filter'}, 'CODE' );  #01

$obj->read_source(\*DATA);
ok( $obj->param('Eva'), "synthetic human being" );  #02
ok( $obj->param('Magi'), <<'MAGI' );                #03
  Magi is a system made by the interconnection
  of three supercomputers called "brains", each
  one having a different personality.
MAGI
undef $obj;

## Now we check if the xpath_access() filter works
$obj = new Config::Natural { filter => \&xpath_access };
ok( ref $obj->{'filter'}, 'CODE' );  #04
$obj->read_source(File::Spec->catfile('t','about-magi.txt'));
#use Data::Dumper; print Dumper($obj); exit;
ok( $obj->param('about_magi_1'), <<'MAGI' );   #05
  As Ritsuko explains, MAGI is a system made by the interconnection of 
  three genetic supercomputers. They are partially biologic and have a 
  genetically created brain. The theory was conceived by her mother, 
  who also created MAGI. She implanted parts of her own personality in 
  each components of MAGI. The first is named Melchior-1 and has the 
  personality of her as a scientist. The second, named Balthasar-2, is 
  her as a mother. Finally, Casper-3, the third, is her as a woman. 
MAGI
undef $obj;

## Finally we check if the varsubst() filter works
$obj = new Config::Natural { filter => \&varsubst };
ok( ref $obj->{'filter'}, 'CODE' );  #06
$obj->read_source(File::Spec->catfile('t','about-magi.txt'));
ok( $obj->param('about_magi_2'), <<'MAGI' );   #07
  As Ritsuko explains, MAGI is a system made by the interconnection of 
  three genetic supercomputers. They are partially biologic and have a 
  genetically created brain. The theory was conceived by her mother, 
  who also created MAGI. She implanted parts of her own personality in 
  each components of MAGI. Melchior-1 has the personality of her as a 
  scientist . Balthasar-2 is her as a mother and Casper-3 her as a woman . 
MAGI
undef $obj;


__END__

Eva = synthetic human being   # that's how Ritsuko presents it

Magi = -
  Magi is a system made by the interconnection    # that's again how Ritsuko 
  of three supercomputers called "brains", each   # present the things, but it 
  one having a different personality.             # is the truth for once...
.
