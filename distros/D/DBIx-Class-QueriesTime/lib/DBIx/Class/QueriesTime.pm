package DBIx::Class::QueriesTime;

use strict;
use warnings;
use vars qw( $VERSION );

$VERSION = '0.01';

package DBIx::Class::Storage::DBI;
use Carp::Clan qw/DBIx::Class/;

use Time::HiRes qw( tv_interval gettimeofday );
no warnings 'redefine';
sub _execute {
    my ($self, $op, $extra_bind, $ident, @args) = @_;
    my ($sql, @bind) = $self->sql_maker->$op($ident, @args);
    unshift(@bind, @$extra_bind) if $extra_bind;
    if ($self->debug) {
        my @debug_bind = map { defined $_ ? $_ : 'NULL' } @bind;
        $self->debugfh->print("$sql: @debug_bind\n");
    }
    my $sth = $self->sth($sql,$op);
    croak "no sth generated via sql: $sql" unless $sth;
    @bind = map { ref $_ ? ''.$_ : $_ } @bind; # stringify args
    my $rv;
    if ($sth) {
        my $befor_query = [gettimeofday] if $self->debug;
        $rv = $sth->execute(@bind);
        $self->debugfh->print('->Query Time: ',tv_interval($befor_query),"\n")
          if $self->debug;
    } else {
        croak "'$sql' did not generate a statement.";
    }
    return (wantarray ? ($rv, $sth, @bind) : $rv);
}

1;

=head1 NAME

DBIx::Class::QueriesTime - Get your query's time.

=head1 VERSION

This documentation refers to DBIx::Class::QueriesTime version 0.01

=head1 SYNOPSIS

  package YourDB;
  
  use strict;
  use warnings;
  use base 'DBIx::Class';
  
  __PACKAGE__->load_components(qw/Core DB QueriesTime/);

and your script

  #! /usr/bin/perl
  
  use strict;
  use warnings;
  use YourDB;

  YourDB->storage->debug(1);
  YourDB->storage->debugfh(IO::File->new('/tmp/trace.out', '>>'));

your query and query's time output trace file:

  SELECT me.id, me.name FROM Authors me WHERE ( name = ? ): nekokak
  ->Query Time: 0.287087

=head1 DESCRIPTION

DBIx::Class::QueriesTime is Extension to DBIx::Class.
DBIx::Class::QueriesTime get your query's time.
DBIx::Class::QueriesTime is redefine DBIx::Class::Storage::DBI::_execute.

=head1 DEPENDENCIES

L<DBIx::Class>

L<Time::HiRes>

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.
Please report problems to Atsushi Kobayashi (E<lt>nekokak@cpan.orgE<gt>)
Patches are welcome.

=head1 SEE ALSO

L<DBIx::Class>

L<Time::HiRes>

=head1 AUTHOR

Atsushi Kobayashi, E<lt>nekokak@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Atsushi Kobayashi (E<lt>nekokak@cpan.orgE<gt>). All rights reserved.

This library is free software; you can redistribute it and/or modify it
 under the same terms as Perl itself. See L<perlartistic>.

=cut
