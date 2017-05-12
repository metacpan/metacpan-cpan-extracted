package Class::Tiny::Chained;

use strict;
use warnings;
use Class::Tiny ();
our @ISA = 'Class::Tiny';

our $VERSION = '0.004';

sub __gen_sub_body {
  my ($self, $name, $has_default, $default_type) = @_;
  
  if ($has_default && $default_type eq 'CODE') {
    return << "HERE";
sub $name {
  return (
      ( \@_ == 1 )
    ? ( exists \$_[0]{$name} ? \$_[0]{$name} : ( \$_[0]{$name} = \$default->( \$_[0] ) ) )
    : scalar( \$_[0]{$name} = \$_[1], \$_[0] )
  );
}
HERE
  }
  elsif ($has_default) {
    return << "HERE";
sub $name {
  return (
      ( \@_ == 1 )
    ? ( exists \$_[0]{$name} ? \$_[0]{$name} : ( \$_[0]{$name} = \$default ) )
    : scalar( \$_[0]{$name} = \$_[1], \$_[0] )
  );
}
HERE
  }
  else {
    return << "HERE";
sub $name {
  return \@_ == 1 ? \$_[0]{$name} : scalar( \$_[0]{$name} = \$_[1], \$_[0] )
}
HERE
  }
}

1;

=head1 NAME

Class::Tiny::Chained - Minimalist class construction, with chained attributes

=head1 SYNOPSIS

In I<Person.pm>:

 package Person;
 
 use Class::Tiny::Chained qw( name );
 
 1;

In I<Employee.pm>:

 package Employee;
 use parent 'Person';
 
 use Class::Tiny::Chained qw( ssn ), {
   timestamp => sub { time }    # attribute with default
 };
 
 1;

In I<example.pl>:

 use Employee;
 
 my $obj = Employee->new( name => "Larry", ssn => "111-22-3333" );
 
 # attribute setters are chainable
 my $obj = Employee->new->name("Fred")->ssn("444-55-6666");
 my $ts = $obj->name("Bob")->timestamp;

=head1 DESCRIPTION

L<Class::Tiny::Chained> is a wrapper around L<Class::Tiny> which makes the
generated attribute accessors chainable; that is, when setting an attribute
value, the object is returned so that further methods can be called.

=head1 BUGS

Report any issues on the public bugtracker.

=head1 AUTHOR

Dan Book <dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Dan Book.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=head1 SEE ALSO

L<Object::Tap>, L<MooX::ChainedAttributes>
