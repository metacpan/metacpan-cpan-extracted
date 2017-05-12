package Class::DBI::Plugin::QueriesTime;

use strict;
use warnings;
use Time::HiRes qw( tv_interval gettimeofday );
use vars qw($VERSION);
$VERSION = '0.01';

sub import {
    my $class = shift;
    my $pkg   = caller(0);
    my $befor_query;

    no strict 'refs';
    no warnings 'redefine';
    *{"$pkg\::sth_to_objects"} = sub {
        my ($class, $sth, $args) = @_;
        $class->_croak("sth_to_objects needs a statement handle") unless $sth;
        unless (UNIVERSAL::isa($sth => "DBI::st")) {
            my $meth = "sql_$sth";
            $sth = $class->$meth();
        }
        my (%data, @rows);
        eval {
            $befor_query = [gettimeofday];
            $sth->execute(@$args) unless $sth->{Active};
            $sth->bind_columns(\(@data{ @{ $sth->{NAME_lc} } }));
            warn "Query Time: ",tv_interval ( $befor_query );
            push @rows, {%data} while $sth->fetch;
        };
        return $class->_croak("$class can't $sth->{Statement}: $@", err => $@)
            if $@;
        return $class->_ids_to_objects(\@rows);
    };
}
1;

=head1 NAME

Class::DBI::Plugin::QueriesTime - Get your query's time.

=head1 VERSION

This documentation refers to Class::DBI::Plugin::QueriesTime version 0.01

=head1 SYNOPSIS

  package YourDB;
  use base qw/Class::DBI/;
  use Class::DBI::Plugin::QueriesTime;

=head1 DESCRIPTION

Class::DBI::Plugin::QueriesTime is Extension to Class::DBI.
Class::DBI::Plugin::QueriesTime get your query's time.
Class::DBI::Plugin::QueriesTime is redefine Class::DBI::sth_to_objects.

=head1 DEPENDENCIES

L<Class::DBI>

L<Time::HiRes>

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.
Please report problems to Atsushi Kobayashi (E<lt>nekokak@cpan.orgE<gt>)
Patches are welcome.

=head1 SEE ALSO

L<Class::DBI>

L<Time::HiRes>

=head1 AUTHOR

Atsushi Kobayashi, E<lt>nekokak@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Atsushi Kobayashi (E<lt>nekokak@cpan.orgE<gt>). All rights reserved.

This library is free software; you can redistribute it and/or modify it
 under the same terms as Perl itself. See L<perlartistic>.

=cut
