package Apache::DBI::Cache::ImaDBI;

use strict;
use warnings;
use Apache::DBI::Cache ();	# NOTE: do not call import()

our $VERSION = '0.07';

sub _mk_db_closure {
  my ($class, @connection) = @_;
  my $dbh;
  return sub {
    unless( $dbh ) {
      $dbh = DBI->connect(@connection);
      Apache::DBI::Cache::undef_at_request_cleanup(\$dbh);
    }
    return $dbh;
  };
}

sub import {
  my $class=shift;
  my %o=@_;

  if( exists $o{patch} ) {
    $o{patch}=[$o{patch}] unless( ref $o{patch} eq 'ARRAY' );
    foreach my $c (@{$o{patch}}) {
      no strict qw/refs/;
      no warnings qw/redefine/;
      $c='Ima::DBI' if( $c=~/^\d+$/ and  $c!=0 );
      *{$c.'::_mk_db_closure'}=\&_mk_db_closure;
    }
  }
}

1;

__END__

=head1 NAME

Apache::DBI::Cache::ImaDBI - make Apache::DBI::Cache work with Class::DBI

=head1 SYNOPSIS

 In your httpd.conf:
  <Perl>
  use Apache::DBI::Cache ...;
  use Apache::DBI::Cache::ImaDBI patch=>'Ima::DBI';
  </Perl>

 Then use Class::DBI in your modules as usual.

 or

 In your httpd.conf:
  <Perl>
  use Apache::DBI::Cache ...;
  use Apache::DBI::Cache::ImaDBI patch=>'My::Class';
  </Perl>

  package My::Class;
  use base qw/Class::DBI/;

 or

 In your httpd.conf:
  <Perl>
  use Apache::DBI::Cache ...;
  </Perl>

  package My::Class;
  use base qw/Apache::DBI::Cache::ImaDBI Class::DBI/;

=head1 DESCRIPTION

This module provides one method that is designed to override the way
Ima::DBI caches its DBI handle. Normally the handle is connected once
and saved in a closure. With Apache::DBI::Cache::ImaDBI the handle is
cached by means of Apache::DBI::Cache. Once per Apache request cycle
if a class is used for this request a handle is obtained from the cache.

This means:

=over 4

=item *

A classes DBI handle stays the same over an Apache request cycle but may
change between cycles.

=item *

Multiple classes can use the same handle if used in different request
cylces.

=item *

If multiple classes use the same database and these classes are used in
one request cycle then each class gets its own handle.

=back

=head1 USAGE

Normally your classes are designed to work not only with Apache::DBI::Cache.
Hence, your classes don't know also about Apache::DBI::Cache::ImaDBI. But
your classes inherit from Class::DBI and Class::DBI inherits from Ima::DBI.

To get our special method called Apache::DBI::Cache::ImaDBI is used in
one of these ways:

 use Apache::DBI::Cache::ImaDBI patch=>1;

  or

 use Apache::DBI::Cache::ImaDBI patch=>'Ima::DBI';

  or

 use Apache::DBI::Cache::ImaDBI patch=>'Class::DBI';

  or

 use Apache::DBI::Cache::ImaDBI patch=>qw[My::Class1 My::Class2];

The first 2 usages are exactly the same. Our special method is inserted
directly into Ima::DBI. Thus, all classes based on Ima::DBI inherit it.

The 3rd usage inserts our method into Class::DBI. Thus, all classes based
on it inherit our method but classes that are base directly on Ima::DBI do
not.

In the 4th case our method is inserted into individual classes only.

Another way to use Apache::DBI::Cache::ImaDBI is by inheriting from it:

 package My::Class;
 use base qw/Apache::DBI::Cache::ImaDBI Class::DBI/;

  or

 package My::Class;
 use base qw/Apache::DBI::Cache::ImaDBI Ima::DBI/;

Here it is necessary that Apache::DBI::Cache::ImaDBI cames I<before>
Class::DBI or Ima::DBI.

I think that is not the preferred way because it requires source code
modification of your classes.

=head1 SEE ALSO

=over 4

=item L<Apache::DBI::Cache>

=item L<Class::DBI>

=item L<Ima::DBI>

=back

=head1 AUTHOR

Torsten Foertsch, E<lt>torsten.foertsch@gmx.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Torsten Foertsch

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut
