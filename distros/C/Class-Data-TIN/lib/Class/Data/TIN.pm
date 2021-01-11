package Class::Data::TIN;

# ABSTRACT: DEPRECATED - Translucent, Inheritable, Nonpolluting class data
our $VERSION = '0.03'; # VERSION

use 5.006;
use strict;
use warnings;

warn __PACKAGE__ .' is DEPRECATED, please do not use this module anymore';

use Class::DispatchToAll qw(dispatch_to_all);

require Exporter;

use Carp;
use Data::Dumper;

our @ISA = qw(Exporter);
our @EXPORT_OK = ('get_classdata','set_classdata','append_classdata','merge_classdata');

our $stop="_tinstop";

# not exported, has to be called explicitly with Class::Data::TIN->new()
sub new {
   shift;  # remove own ClassName 'Class::Data::TIN'
   my $org_package=shift;  # get name of package to store vars in
   my $data=_import_data(@_);

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

#   $install.='$'.__PACKAGE__.'::_tin=$data;';
   $install.='our $_tin=$data;';

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
sub _import_data {
    my $data;
    if (@_ == 1) {  # one param passed
	my $param=shift;
	if (ref($param) eq 'HASH') {  # is it a HASH ref ?
	    $data=$param;
	} elsif (-e $param) {  # or is it a file ?
	    $data=do $param;
	    unless ($data) {
		croak("couldn't parse $param: $@") if $@;
                croak("couldn't do $param: $!") unless defined $data;
	    }
	} else {  # then something is wrong
	    croak("param is neither HASH REF nor file ...");
	}
    } else {  # more params passed, treat as HASH
	$data={@_};
    }
   return $data;
}

sub _save_val {
    my ($pkg,$key,$val,$stopper)=@_;

#    if (ref($val) eq "ARRAY" && $val->[0] eq $stop) {
#	$val=$val->[1];
#    }

    if ($stopper && $stopper>0) {
	$val=[$stop,$val];
    }

    my $install='$'.$pkg.'::_tin->{$key}=$val';
    eval $install;
    croak($@) if $@;

    _make_accessor($pkg,$key);

    return;
}

sub _make_accessor {
    my ($pkg,$key)=@_;
    no strict "refs";
    my $accessor=$pkg."::".$key;
    return if *$accessor{CODE}; # there is allready an accessor

    my $r_tin=eval '$'."$pkg".'::_tin';
    croak($@) if $@;

    *$accessor = sub {
	my $self=shift;
	$r_tin->{$key} = shift if @_;
	return $r_tin->{$key};
    };
    return;
}

# ueberschreibt den aktuellen Wert in der package mit dem neuen
# geht mit einem wert
sub set_classdata {
    my ($self,$key,$val,$stopper)=@_;
    my $package=ref($self) || $self;

    my $tin=__PACKAGE__."::".$package;
    _save_val($tin,$key,$val,$stopper);
    return $tin->$key();
}

# haengt daten an die daten in der aktuellen package dran
# geht mit einem wert
# copy on write
sub append_classdata {
    my ($self,$key,$val,$stopper)=@_;
    return unless $val;
    my $package=ref($self) || $self;

    # aktuellen wert hohlen
    no strict 'refs';
    my $tin=__PACKAGE__."::".$package;
    my $rtin=$tin."::_tin";
    my $oldval=$$rtin->{$key};

    # neuen wert dranhaengen
    if ($oldval) {
	($val,$stopper)=_merge($oldval,$val,$stopper);
    }

    _save_val($tin,$key,$val,$stopper);
    return;
}

# wie append, nur mit mehreren vals auf einmal
sub merge_classdata {
    my $self=shift;
    my $package=ref($self) || $self;
    my $data=_import_data(@_);

    no strict 'refs';
    my $tin=__PACKAGE__."::".$package;
    my $rtin=$tin."::_tin";

    while (my ($key,$val)=each %$data) {
	my $stopper;
	my $oldval=$$rtin->{$key};
	if ($oldval && $val) {
	    ($val,$stopper)=_merge($oldval,$val);
	}
	_save_val($tin,$key,$val,$stopper);
    }
    return;
}

sub _merge {
    my ($oldval,$newval,$stopper)=@_;

    my $ref=ref($oldval);
    my $refnew=ref($newval);

    if ($ref eq "ARRAY" && $oldval->[0] eq $stop) {
	$oldval=$oldval->[1];
	$ref=ref($oldval);
	$stopper++;
    }

    if ($refnew eq "ARRAY" && $newval->[0] eq $stop) {
	$newval=$newval->[1];
	$refnew=ref($newval);
	$stopper++;
    }

    if (!$ref || $ref eq "SCALAR") {
	if ($refnew eq "SCALAR") {
	    $oldval=$newval;
	} else {
	    if ($ref eq "SCALAR") {
		my $v=$$oldval;
		$v.=$newval;
		$oldval=\$v;
	    } else {
		$oldval.=$newval;
	    }
	}
    } elsif ($ref eq "HASH") {
	if (!$refnew) {
	    $oldval={%$oldval,$newval};
	} elsif ($refnew eq "HASH") {
	    $oldval={%$oldval,%$newval};
	} else {
	    croak("type mismatch!");
	}
    } elsif ($ref eq "ARRAY") {
	if (!$refnew) {
	    push(@$oldval,$newval);
	} elsif ($refnew eq "ARRAY") {
	    push(@$oldval,@$newval);
	} else {
	    croak("type mismatch!");
	}
    } elsif ($ref eq "CODE") {
	croak("cannot append/merge code ref");
    }

    return ($oldval,$stopper);
}


sub get_classdata {
    my ($self,$key)=@_;
    my $package=ref($self) || $self;
    my $tin=__PACKAGE__."::".$package;

    my @vals=dispatch_to_all($tin,$key);
    return unless @vals;

    # peek at first val of @vals to decide data type
    my $ref=ref($vals[0]);

    # check if stoptin caused wrong ref
    if ($ref eq "ARRAY" && $vals[0]->[0] eq $stop) {
	$ref=ref($vals[0]->[1]);
    }

    $ref||="SCALAR";

    my $get='_get_'.$ref;
    my $return;
    no strict 'refs';
    foreach my $v (reverse @vals) {
	next unless $v;
	if (ref($v) eq "ARRAY" && $v->[0] eq $stop) {
	    $return=$get->(undef,$v->[1]);
#	    my $overwrite=$v->[1];
#	    if ($ref eq "ARRAY") {
#		$return=[];
#		push(@$return,@$overwrite);
#	    } else {
#		$return=$overwrite;
#	    }
	} else {
	    $return=$get->($return,$v);
	}
    }
    return $return;
}


sub _get_SCALAR {
    my ($ret,$val)=@_;
    my $r=ref($val);
    if (!$r) {
	$ret.=$val;
    } elsif ($r eq "SCALAR") {
	$ret=$$val;
    }
    return $ret;
}

sub _get_ARRAY {
    my ($ret,$val)=@_;
    push(@$ret,@$val);
    return $ret;
}

sub _get_HASH {
    my ($ret,$val)=@_;
    if (! defined $ret) {
	$ret=$val;
    } else {
	$ret={%$ret,%$val};
    }
    return $ret;
}

sub _get_CODE {
    my ($ret,$val)=@_;
    return $val;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Class::Data::TIN - DEPRECATED - Translucent, Inheritable, Nonpolluting class data

=head1 VERSION

version 0.03

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

THIS MODULE IS DEPRECATED! I used it the last time ~20 years ago, and if I needed a similar functionality now, I would use Moose and/or some meta programming.

But here are the old docs, anyway:

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

Thomas Klausner <domm@plix.at>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2001 - 2002 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
