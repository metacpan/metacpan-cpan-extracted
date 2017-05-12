package Class::DBI::Plugin::Type;

use strict;
use warnings;

our $VERSION = '0.02';

sub import {
    no strict 'refs';
    my $caller = caller();
    #if ($caller->isa("Class::DBI::mysql") and
    #    $caller->can("column_type")) {
    #    return; # My work here is done
    #}

    return if $caller->can("sql_dummy");
    $caller->set_sql(dummy => <<'');
        SELECT *
        FROM __TABLE__
        WHERE 1=0

    $caller->mk_classdata("_types");
    *{$caller."::column_type"} = sub {
        my ($self, $column) = @_;
        if (!$self->_types) {
            my $sth = $self->sql_dummy;
            $sth->execute;
            my %hash;
            @hash{@{$sth->{NAME}}} = 
            map { 
                    my $info = scalar $self->db_Main->type_info($_);
                    if ($info) { $info->{TYPE_NAME} } 
                    else { $_ } # Typeless databases (SQLite)
                }
                @{$sth->{TYPE}};
            $sth->finish;
            $self->_types(\%hash);
        }
        return $self->_types->{$column};
    }   
}

1;
__END__

=head1 NAME

Class::DBI::Plugin::Type - Determine type information for columns

=head1 SYNOPSIS

  package Music::Artist;
  use base 'Class::DBI';
  use Class::DBI::Plugin::Type;
  Music::Artist->table('artist');
  Music::Artist->columns(All => qw/artistid name/);

  print Music::Artist->column_type("artistid"); # integer

=head1 DESCRIPTION

This module allows C<Class::DBI>-based classes to query their columns
for data type information in a database-independent manner. 

=head1 SEE ALSO

L<Class::DBI::AsForm>

=head1 AUTHOR

Simon Cozens, E<lt>simon@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Simon Cozens

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

This module was generously sponsored by the Perl Foundation.

=cut
