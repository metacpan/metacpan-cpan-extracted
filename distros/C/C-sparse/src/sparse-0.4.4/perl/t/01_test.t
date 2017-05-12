#!/usr/bin/perl -w
use Data::Dump;
use C::sparse qw(:all);
use Test::More tests => 2;

#pp(\%INC);

#$s0 = C::sparse::sparse("t/test_ptrs.c");
$s0 = C::sparse::sparse("-It/tcg", "-It/tcg/tci", "-It/.", "-It/.", "-It/include", "-It/target-arm", "-DOS_OBJECT_USE_OBJC=0",  "-D_GNU_SOURCE", "-D_FILE_OFFSET_BITS=64", "-D_LARGEFILE_SOURCE",  "-fno-strict-aliasing",   "-I/Users/eiselekd/src/qemu-1.7.0/pixman/pixman", "-I/Users/eiselekd/src/qemu-1.7.0/pixman/pixman", "-I/Users/eiselekd/src/qemu-1.7.0/dtc/libfdt",  "-It/target-arm", "-DNEED_CPU_H", "-It/include", "-D_REENTRANT", "-I/usr/local/Cellar/glib/2.38.0/include/glib-2.0", "-I/usr/local/Cellar/glib/2.38.0/lib/glib-2.0/include", "-I/usr/local/opt/gettext/include",  "-g",  "-c", "-o", "t/target-arm/translate.o",  "t/target-arm/translate.c");

#$s0 = C::sparse::sparse("-It/tcg", "-It/tcg/tci", "-It/.", "-I/usr/include/i386-linux-gnu/", "-It/include", "-It/target-arm", "-DOS_OBJECT_USE_OBJC=0",  "-D_GNU_SOURCE", "-D_FILE_OFFSET_BITS=64", "-D_LARGEFILE_SOURCE",  "-fno-strict-aliasing",   "-I/Users/eiselekd/src/qemu-1.7.0/pixman/pixman", "-I/usr/include/pixman-1", "-I/home/eiselekd/Downloads/qemu-1.7.0/dtc/libfdt",  "-Itarget-arm", "-DNEED_CPU_H", "-Iinclude", "-D_REENTRANT", "-I/usr/include/glib-2.0", "-I/usr/lib/i386-linux-gnu/glib-2.0/include", "-I/usr/local/opt/gettext/include",  "-g",  "-c", "-o", "t/target-arm/translate.o",  "t/target-arm/translate.c");


#gcc "-Itcg" "-Itcg/tci" "-I." "-I." "-Iinclude" "-Itarget-arm" "-Itarget-arm" "-DOS_OBJECT_USE_OBJC=0"  "-D_GNU_SOURCE" "-D_FILE_OFFSET_BITS=64" "-D_LARGEFILE_SOURCE"  "-fno-strict-aliasing"   "-I/Users/eiselekd/src/qemu-1.7.0/pixman/pixman" "-I/usr/include/pixman-1" "-I/home/eiselekd/Downloads/qemu-1.7.0/dtc/libfdt"  "-Itarget-arm" "-DNEED_CPU_H" "-Iinclude" "-D_REENTRANT" "-I/usr/include/glib-2.0" "-I/usr/lib/i386-linux-gnu/glib-2.0/include" "-I/usr/local/opt/gettext/include"  "-g"  "-c" "-o" "target-arm/translate.o"  "target-arm/translate.c"





my @typedefs = $s0->symbols($typ = (C::sparse::NS_STRUCT));
my $idx = 0;
print("typ: $typ\n");
foreach my $t (@typedefs) {
  my $struct = $t->totype;
  print ($idx.":".$struct->n.":".$struct."\n");
  foreach my $l ($struct->l) {
      my @p = $l->p;
      print (' ' x scalar(@p));
      print (" l:".$l->n.":".$l."\n");
  }
  
  $idx++;
}

#exit(0);

my @s = $s0->symbols();
print ("Number of symbols:".scalar(@s)."\n");
foreach my $s (@s) {
  print("symbol: ".$s.":".$C::sparse::sym::typ_n{$s->type}."\n");
  #print(" ".$s->symbol_list);
  my $fn = $s->totype;
  print ("Fn: ".$fn.":isa:".$fn->isa('C::sparse::type::fn')."\n");
  if ($fn->isa('C::sparse::type::fn')) {
    print ("Function:".$fn->n."\n");
    my $idx = 0;
    foreach my $a ($fn->args) {
      print (" $idx:".$a->n.":".$a."\n"); $idx++;
    }
    
    foreach my $c ($fn->c) {
      print (" c:".$c."\n");
    }
    foreach my $l ($fn->l) {
#	print("$fn:$l\n");
      my @p = $l->p;
      print (' ' x scalar(@p));
      print (" l:".$l);
      if ($l->isa('C::sparse::stmt::expr')) {
	print(" => expr");
      }
      print ("\n");
    }
  }
  print("\n");
}

#print ("SYM_PTR:".C::sparse::SYM_PTR);
