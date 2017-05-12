package Class::OOorNO;
use strict;
use vars qw( $VERSION   @ISA   @EXPORT_OK   %EXPORT_TAGS );
use Exporter;
$VERSION     = 0.01_1; # 2/30/02, 1:50 am
@ISA         = qw( Exporter );
@EXPORT_OK   = qw( OOorNO   myargs   myself   coerce_array   shave_opts );
%EXPORT_TAGS = ( 'all' => [ @EXPORT_OK ] );

# --------------------------------------------------------
# Constructor
# --------------------------------------------------------
sub new { bless({ }, shift(@_)) }


# --------------------------------------------------------
# Class::OOorNO::Class::OOorNO()
# --------------------------------------------------------
sub OOorNO { return($_[0]) if UNIVERSAL::isa($_[0],'UNIVERSAL') }


# --------------------------------------------------------
# Class::OOorNO::myargs()
# --------------------------------------------------------
sub myargs { shift(@_) if UNIVERSAL::isa($_[0], (caller(0))[0]); @_ }


# --------------------------------------------------------
# Class::OOorNO::myself()
# --------------------------------------------------------
sub myself { UNIVERSAL::isa($_[0], (caller(0))[0]) ? $_[0] : undef }


# --------------------------------------------------------
# Class::OOorNO::shave_opts()
# --------------------------------------------------------
sub shave_opts {

   my($mamma) = myargs(@_);

   return undef unless UNIVERSAL::isa($mamma,'ARRAY');

   my(@maid)   = @$mamma; @$mamma = ();
   my($opts)   = {};

   while (@maid) {

      my($o) = shift(@maid)||'';

      if (substr($o,0,2) eq '--') {

         $opts->{[split(/=/o,$o)]->[0]} = [split(/=/o,$o)]->[1] || $o;
      }
      else {

         push(@$mamma, $o);
      }
   }

   return($opts);
}


# --------------------------------------------------------
# Class::OOorNO::coerce_array()
# --------------------------------------------------------
sub coerce_array {

   my($hashref)   = {};
   my($i)         = 0;
   my(@shadow)    = myargs(@_);

   while (@shadow) {

      my($name,$val) = splice(@shadow,0,2);

      if (defined($name)) {

         $hashref->{$name} = (defined($val)) ? $val : '';
      }
      else {

         ++$i;

         $hashref->{qq[un-named key no. $i]} = (defined($val)) ? $val : '';
      }
   }

   return($hashref);
}

1;

