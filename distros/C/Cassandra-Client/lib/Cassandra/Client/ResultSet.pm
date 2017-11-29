package Cassandra::Client::ResultSet;
our $AUTHORITY = 'cpan:TVDW';
$Cassandra::Client::ResultSet::VERSION = '0.14';
use 5.010;
use strict;
use warnings;


sub new {
    my ($class, $raw_data, $decoder, $next_page)= @_;

    return bless {
        raw_data => $raw_data,
        decoder => $decoder,
        next_page => $next_page,
    }, $class;
}


sub rows {
    return $_[0]{rows} ||= $_[0]{decoder}->decode(${$_[0]{raw_data}}, 0);
}


sub row_hashes {
    return $_[0]{row_hashes} ||= $_[0]{decoder}->decode(${$_[0]{raw_data}}, 1);
}


sub column_names {
    $_[0]{decoder}->column_names
}


sub next_page {
    $_[0]{next_page}
}


1;

__END__

=pod

=head1 NAME

Cassandra::Client::ResultSet

=head1 VERSION

version 0.14

=head1 METHODS

=over

=item $result->rows()

Returns an arrayref of all rows in the ResultSet. Each row will be represented as an arrayref with cells. To find column names, see C<column_names>.

=item $result->row_hashes()

Returns an arrayref of all rows in the ResultSet. Each row will be represented as a hashref with cells.

=item $result->column_names()

Returns an arrayref with the names of the columns in the result set, to be used with rows returned from C<rows()>.

=item $result->next_page()

Returns a string pointing to the next Cassandra result page, if any. Used internally by C<< $client->each_page() >>, but can be used to implement custom pagination logic.

=back

=head1 AUTHOR

Tom van der Woerdt <tvdw@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Tom van der Woerdt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
