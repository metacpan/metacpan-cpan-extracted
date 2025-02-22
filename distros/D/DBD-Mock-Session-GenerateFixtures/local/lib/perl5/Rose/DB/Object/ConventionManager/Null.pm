package Rose::DB::Object::ConventionManager::Null;

use strict;

use Rose::DB::Object::ConventionManager;
our @ISA = qw(Rose::DB::Object::ConventionManager);

our $VERSION = '0.73';

our $Instance;

# This class is a singleton
sub new
{
  my($class) = shift;
  return $Instance ||= $class->SUPER::new(@_);
}

sub class_to_table_singular { }
sub class_suffix { }
sub class_to_table_plural { }
sub table_to_class_plural  { }
sub table_to_class { }
sub class_prefix { }
sub related_table_to_class { }
sub auto_table_name { }
sub auto_primary_key_column_names { }
sub singular_to_plural { }
sub plural_to_singular { }
sub auto_foreign_key_name { }
sub auto_foreign_key { }
sub auto_relationship { }

1;

__END__

=head1 NAME

Rose::DB::Object::ConventionManager::Null - A singleton convention manager that does nothing.

=head1 SYNOPSIS

  package My::Product;

  use Rose::DB::Object;
  our @ISA = qw(Rose::DB::Object);

  # This really sets the convention manager to a
  # Rose::DB::Object::ConventionManager::Null object
  __PACKAGE__->meta->convention_manager(undef);
  ...

=head1 DESCRIPTION

L<Rose::DB::Object::ConventionManager::Null> is a subclass of L<Rose::DB::Object::ConventionManager> that does nothing.  That is, it overrides every method with no-ops that always return undef or an empty list, depending on calling context.  This class is a singleton.

When a piece of L<metadata|Rose::DB::Object::Metadata> is missing, the convention manager is asked to provide it.  This "null" convention manager class is useful if you do not want the convention manager to provide any information.  In other words, use this convention manager class if you want to force all L<metadata|Rose::DB::Object::Metadata> to be explicitly specified.

See the L<Rose::DB::Object::ConventionManager> documentation for more information on convention managers.

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same terms
as Perl itself.
