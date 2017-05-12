package t::Object::Synopsis;
use strict;
 
 use Class::InsideOut ':std'; # public, private, register and id

 public     name => my %name;       # accessor: name()
 private    ssn  => my %ssn;        # no accessor
 
 public     age  => my %age, {
    set_hook => sub { /^\d+$/ or die "must be an integer" }
 };
 
 public     initials => my %initials, {
    set_hook => sub { $_ = uc $_ }
 };
 
 sub new { 
   register( bless \(my $s), shift ); 
 }
 
 sub greeting {
   my $self = shift;
   return "Hello, my name is $name{ id $self }";
 }

1;
