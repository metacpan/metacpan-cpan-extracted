#-----------------------------------------------------------------
# Class::Data::TIN
#-----------------------------------------------------------------
# Copyright Thomas Klausner / ZSI 2001, 2002
# You may use and distribute this module according to the same terms
# that Perl is distributed under.
#
# Thomas Klausner domm@zsi.at http://domm.zsi.at
#
# $Author: domm $
# $Date: 2002/01/29 22:03:35 $
# $Revision: 1.9 $
#-----------------------------------------------------------------
# Class::Data::TIN - T_ranslucent I_nheritable N_onpolluting
#-----------------------------------------------------------------
package Class::Data::TIN;

use 5.006;
use strict;
use warnings;

require Exporter;

use Carp;
use Data::Dumper;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(get get_classdata set set_classdata append append_classdata);
our $VERSION = '0.02';

# not exported, has to be called explicitly with Class::Data::TIN->new()
sub new {
   shift;  # remove own ClassName 'Class::Data::TIN'
   my $org_package=shift;  # get name of package to store vars in
   my $data;

   if (@_ == 1) {  # one param passed
     my $param=shift;
     if (ref($param) eq 'HASH') {  # is it a HASH ref ?
       $data=$param;
     } elsif (-e $param) {  # or is it a file ?
       $data=do $param; # TODO some error checking
     } else {  # then something is wrong
       croak("param is neither HASH REF nor file ...");
     }
   } else {  # more params passed, treat as HASH
     $data={@_};
   }

   croak("data structure must be a hashref") if ($data && ref($data) ne "HASH");

   my $tin_package=__PACKAGE__."::".$org_package;

   ### put data into TIN
   # start eval-string
   my $install="package $tin_package;";

   # add ISA's
   my @isa=eval "@".$org_package."::ISA";
   my @isa_tin;
   foreach (@isa) {
      push(@isa_tin,__PACKAGE__."::".$_);
   }
   $install.='our @ISA=(qw ('."@isa_tin".'));' if @isa_tin;

   $install.='our $_tin;';
   $install.='$_tin=$data;' if $data;
   eval $install;
   croak $@ if $@;

   # generate accessor methods in $tin_package
   for my $key (keys %$data) {
      _make_accessor($tin_package,$key);
   }

   # return empty fake pseudo obj, to make calling get/set/append easier
   # this is /not/ blessed, in fact, its just an alias to __PACKAGE__
   return $org_package;
}

# not exported
sub _make_accessor {
   my ($pkg,$key)=@_;

   # to enable black symbol table magic
   no strict "refs";

   my $accessor=$pkg."::".$key;
   return if *$accessor{CODE}; # there is allready an accessor

   my $r_tin=eval '$'."$pkg".'::_tin';

   *$accessor = sub {
      my $self=shift;
      $r_tin->{$key} = shift if @_;
      return $r_tin->{$key};
   }
}

# exported, has to be called on object or class, NOT on Class::Data::TIN
sub get_classdata {
   my ($self,$key)=@_;

   my $package=ref($self) || $self;
   my $tin=__PACKAGE__."::".$package;
   if ($tin->can($key)) {
      return $tin->$key();
   }
   return;
}

# alias
*get=*get_classdata;

# exported, has to be called on object or class, NOT on Class::Data::TIN
sub set_classdata {
   my $self=shift;
   my $package=ref($self) || $self;

   croak "object not allowed to modify class data" if (ref($self));

   my $tin=__PACKAGE__."::".$package;
   my ($key,$val)=@_;

   # copy on write:
   _make_accessor($tin,$key);

   return $tin->$key($val);
}

# alias
*set=*set_classdata;


# exported, has to be called on object or class, NOT on Class::Data::TIN
sub append_classdata {
   my $self=shift;
   my $package=ref($self) || $self;

   croak "object not allowed to modify class data" if (ref($self));

   my $tin=__PACKAGE__."::".$package;

   my $key=shift;

   # if this key is not here, there's no use appending, so use set()
   unless ($tin->can($key)) {
      return set($self,$key,@_);
   }

   # get old value
   my $val=$tin->$key;

   if (!ref($val)) {
      $val.=shift;
   } elsif (ref($val) eq "HASH") {
      eval Data::Dumper->Dump([$val],['val']);
      $val={%$val,@_};
   } elsif (ref($val) eq "ARRAY") {
      eval Data::Dumper->Dump([$val],['val']);
      push(@$val,@_);
   } elsif (ref($val) eq "CODE") {
      croak("cannot modify code ref");
   }

   # copy on write:
   _make_accessor($tin,$key);

   $tin->$key($val);
}

# alias
*append=*append_classdata;




1;
__END__

=head1 NAME

Class::Data::TIN - Translucent Inheritable Nonpolluting Class Data

=head1 SYNOPSIS

  use Class::Data::TIN qw(get_classdata set_classdata append_classdata);
  # or
  # use Class::Data::TIN qw(get set append);
  # but I prefer the first option, because of a less likly
  # namespace clashing

  # generate class data in your PACAKGE
  package My::Stuff;
  use Class::Data::TIN;

  our @ISA=(qw (Our::Stuff));

  my $tin=Class::Data::TIN->new(__PACKAGE__,
		      {
		       string=>"a string",
		       string2=>"another string",
		       array=>['foo','bar'],
		       hash=>{
			      foo=>'bar',
			      jaja=>'neinein',
			     },
		       code=>sub{return "bla"}
		      });


   print $tin->get_classdata('string');
   # or
   # print My::Stuff->get_classdata('string');
   # prints "a string"

   print $tin->get_classdata('newstring');
   # prints nothing, as newstring is not defined

   $tin->set_classdata('newstring','now I am here');
   print $self->get_classdata('newstring');
   # prints "now I am here"

   $tin->append_classdata('newstring',', or am I?');
   print $tin->get_classdata('newstring');
   # prints "now I am here, or am I?"


=head1 DESCRIPTION

Class::Data::TIN implements Translucent Inheritable Nonpolluting Class Data.

The thing I don't like with Class::Data::Inheritable or the implementations suggested in perltootc is that you end up with lots of accessor routines in your namespace.

Class::Data::TIN works around this "problem" by storing the Class Data in its own namespace (mirroring the namespace and @ISA hierarchies of the modules using it) and supplying the using packages with (at this time) three meta-accessors called C<get_classdata> (or just C<get>), C<set_classdata> (C<set>) and C<append_classdata> (C<append>). It achieves this with some black magic (namespace munging & evaling).

=head2 new ($package,$datastruct)

new takes the package name of the package needing ClassData, and a data structrure passed as a hashref, a hash or a path to a file returning a hashref if called with C<do>. It then installs a new package by appending "Class::Data::TIN::" to C<$package>, copying C<$package>s @ISA to the new package and saving C<$data> in the var C<$_tin>

Then for every key in C<$data> accessor methods are generated in the new namespace.

new() returns the name of the original package as a string (B<not> as a blessed reference!), so that the calling package may use the return value to modifiy the Class Data. This is done because I have to discern between B<object> invocation and B<class> invocation of the Class Data manipulating methods. Ideally, if an object modifies the Class Data, this changes are only visible to this object. B<NOTE:> But this is not implemented yet. You can only modify Class Data when calling directly with ClassName->set, or with the return value of new() (which is, for example, nothing but the string "ClassName").

B<Example:>

  package My::Stuff;
  use Class::Data::TIN;
  our @ISA=('Other::Stuff');
  my $tin=Class::Data::TIN->new(__PACKAGE__,
		      {
		       string=>"a string",
                      });

In new(), the following code is eval'ed:

  package Class::Data::TIN::My::Stuff;
  our @ISA=(qw (Class::Data::TIN::Other::Stuff));
  our $_tin;
  $_tin=$data;

and accesors are generated, that look sort of like this:

  sub string {
      my $self=shift;
      $_tin->{'string'} = shift if @_;
      return $_tin->{'string'};
   }

The point is that C<string> and all other accessors are generate in a Namespace in Class::Data::TIN::My::Stuff, and B<not> in My::Stuff, thus keeping My::Stuff neat and tidy.

look at the test script (test.pl) for a more complex example.

=head2 get_classdata ($key)

returns the value of the given key.

=head2 set_classdata ($key,$val)

set the key to the given value.

Translucency is implemented here by making a new accessor in the pseudo-class. (copy on write)

=head2 append_classdata ($key,$value [,$value2,..])

appends some values to a key. sets a new key if the key wasn't there. Does copy on write. You can also use append to override the value of a HASH in a parent class (simply append the value you'd like to override to the HASH)

=head2 _make_accessor

internal method, don't call it!

_make_accessor checks if there allready exists an accessor for the given key. If not, it dumps one into the appropriate symbol table.

=head2 TODO

A Lot:

=over 4

=item * implement object translucency

=item * test different kinds to call new

=item * let user decide wheter object is allowed to modify class data

=back 4

=head2 EXPORT

None by default.

get get_classdata set set_classdata append append_classdata, if you ask for it

=head1 SEE ALSO

perltootc, Class::Data::Inheritable

=head1 AUTHOR

Thomas Klausner, domm@zsi.at, http://domm.zsi.at

=head1 COPYRIGHT

Class::Data::TIN is Copyright (c) 2002 Thomas Klausner, ZSI.
All rights reserved.

You may use and distribute this module according to the same terms
that Perl is distributed under

=cut
