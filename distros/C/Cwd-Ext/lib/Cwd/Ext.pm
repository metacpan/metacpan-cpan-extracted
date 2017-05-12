package Cwd::Ext;
use strict;
use Exporter;
use Carp;
use vars qw(@ISA @EXPORT_OK $VERSION @EXPORT $VERSION $DEBUG %EXPORT_TAGS);
@ISA = qw/Exporter/;
@EXPORT_OK = qw(abs_path_is_in abs_path_is_in_nd abs_path_nd abs_path_matches_into symlinks_supported);
%EXPORT_TAGS = ( all => \@EXPORT_OK );
$VERSION = sprintf "%d.%02d", q$Revision: 1.6 $ =~ /(\d+)/g;


# abs path no dereference
sub abs_path_nd {   
   my $abs_path = shift;
   return $abs_path if $abs_path=~m{^/$};
   
   unless( $abs_path=~/^\// ){
      require Cwd;
      $abs_path = Cwd::cwd()."/$abs_path";
   }
    
    my @elems = split m{/}, $abs_path;
    my $ptr = 1;
    while($ptr <= $#elems){
        if($elems[$ptr] eq ''      ){
            splice @elems, $ptr, 1;
        }

        elsif($elems[$ptr] eq '.'  ){
            splice @elems, $ptr, 1;
        }

        elsif($elems[$ptr] eq '..' ){
            if($ptr < 2){
                splice @elems, $ptr, 1;
            }
            else {
                $ptr--;
                splice @elems, $ptr, 2;
            }
        }
        else {
            $ptr++;
        }
    }

    $#elems ? join q{/}, @elems : q{/};
}


sub abs_path_matches_into {
   my($child,$parent)=@_;
   defined $child  or die('missing child');
   defined $parent or die('missing parent');
   
   if($child eq $parent){
      warn(" - args are the same, returning true") if $DEBUG;
      return $child;
   }

   # WE DON'T WANT /home/hi to match on /home/hithere 
   unless( $child=~/^$parent\// ){
      warn (" -[$child] is not a child of [$parent]") if $DEBUG;
      return 0;
   }
   $child;
}  

# is path a inside filesystem hierarchy b
sub abs_path_is_in {
   my($child,$parent) = @_;
   defined $child  or confess('missing child path argument');
   defined $parent or confess('missing parent path argument');
   
   require Cwd;
   my $_child  = Cwd::abs_path($child)  or warn("cant normalize child [$child]") and return;
   my $_parent = Cwd::abs_path($parent) or warn("cant normalize parent [$parent]") and return;

   abs_path_matches_into($_child,$_parent);
}

# is path a in filesystem hierarchy b, no symlink dereferece
sub abs_path_is_in_nd {
   my($child,$parent) = @_;
   defined $child  or confess('missing child path argument');
   defined $parent or confess('missing parent path argument');

   my $_child  = Cwd::Ext::abs_path_nd($child)  or warn("cant normalize child [$child]") and return;
   my $_parent = Cwd::Ext::abs_path_nd($parent) or warn("cant normalize parent [$parent]") and return;

   abs_path_matches_into($_child,$_parent);
}


sub symlinks_supported { eval { symlink("",""); 1 } }


1;
# lib/Cwd/Ext.pod
