# ABSTRACT: ArangoDB Cursor object
package Arango::DB::Cursor;
$Arango::DB::Cursor::VERSION = '0.003';
use warnings;
use strict;

use Data::Dumper;

sub new {
    my ($class, %opts) = @_;
    my $self = { arango => $opts{arango}, database => $opts{database} };

    delete $opts{arango};

    my $ans = $self->{arango}->_api('create_cursor', \%opts);
    $self->{results} = $ans;

    return bless $self => $class;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Arango::DB::Cursor - ArangoDB Cursor object

=head1 VERSION

version 0.003

=head1 USAGE

This class should not be created directly. The L<Arango::DB> module is responsible for
creating instances of this object.

C<Arango::DB::Cursor> answers to the following methods:

=head1 AUTHOR

Alberto Simões <ambs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Alberto Simões.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
