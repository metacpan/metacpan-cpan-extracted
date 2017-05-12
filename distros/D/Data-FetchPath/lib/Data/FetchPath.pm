package Data::FetchPath;

use strict;
use warnings;
no warnings 'uninitialized';
use base 'Exporter';
our @EXPORT_OK = ('path');

=head1 NAME

Data::FetchPath - "eval"able paths to your complex data values

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

Quick summary of what the module does.

    use Data::FetchPath 'path';
    use Test::Most;

    my $data = {
        foo => 3,
        bar => [qw/ this that 3 /],
        3   => undef,
        baz => {
            trois  => 3,
            quatre => [qw/ 1 2 3 4 /],
        }
    };
    my $target_value = 3;
    ok $paths = path( $data, $target_value ), 'Fetching paths for matching data should succeed';
    my @expected = sort qw(
      {bar}[2]
      {baz}{trois}
      {baz}{quatre}[2]
      {foo}
    );
    eq_or_diff $path, \@expected,
        '... and it should return all paths to data values found';
    for ( 0 .. $#expected ) {
        my $found_value = eval "\$data->$expected[$_]";
        is $found_value, $target_value,
            '... and all values should match the value you looked for';
        }
    }

=head1 EXPORT

=head1 FUNCTIONS

=head2 C<path>

Exported on demand via:

 use Data::FetchPath 'path';
 my $paths = path($data_structure, $value);
 my $paths = path($data_structure, $regex);

Passed a data structure and either a scalar value or a regex
(C<qr/foo.*bar/>), this function will return an array reference to the paths
to said value.  Each path is suitable for using C<eval> against said data
structure:

 my %data = (
     one   => 'uno',
     two   => 'dos',
     three => 'tres',
 );
 # find values with the letter 'o' in them
 my $paths = path(\%data, qr/o/);
 foreach my $path (@$data) {
     print eval "\$data$path\n";
 }
 __END__
 uno
 dos

Currently the data structure must be an array or hash reference.  The value
must be a scalar or a regular expression.

=cut

use Scalar::Util 'reftype';

my %path = (
    ARRAY => \&_array_path,
    HASH  => \&_hash_path,
);

sub path {
    my ( $data, $search_term ) = @_;
    my $type       = reftype $data;
    my $find_paths = $path{$type};
    return $find_paths->( $data, $search_term, { $data => 1 } );
}

sub _array_path {
    my ( $data, $search_term, $seen ) = @_;
    my @paths;
    foreach my $i ( 0 .. $#$data ) {
        my $item          = $data->[$i];
        my $type          = reftype $item;
        my $current_index = "[$i]";
        my $ref           = ref $search_term;
        if ( !$type ) {
            if ( !$ref && $item eq $search_term ) {    # XXX
                push @paths => $current_index;
            }
            elsif ( 'Regexp' eq $ref && $item =~ $search_term ) {
                push @paths => $current_index;
            }
        }
        elsif ( my $find_paths = $path{$type} ) {
            unless ( $seen->{$item} ) {
                $seen->{$item} = 1;
                my @current_paths =
                  map { "$current_index$_" }
                  @{ $find_paths->( $item, $search_term, $seen ) };
                push @paths => @current_paths;
            }
        }
    }
    return \@paths;
}

sub _hash_path {
    my ( $data, $search_term, $seen ) = @_;
    my @paths;
    foreach my $key ( keys %$data ) {
        my $item        = $data->{$key};
        my $type        = reftype $item;
        my $current_key = "{$key}";
        my $ref         = ref $search_term;
        if ( !$type ) {
            if ( !$ref && $item eq $search_term ) {    # XXX
                push @paths => $current_key;
            }
            elsif ( 'Regexp' eq $ref && $item =~ $search_term ) {
                push @paths => $current_key;
            }
        }
        elsif ( my $find_paths = $path{$type} ) {
            unless ( $seen->{$item} ) {
                $seen->{$item} = 1;
                my @current_paths =
                  map { "$current_key$_" }
                  @{ $find_paths->( $item, $search_term, $seen ) };
                push @paths => @current_paths;
            }
        }
    }
    return \@paths;
}

=head1 AUTHOR

Curtis "Ovid" Poe, C<< <ovid at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-data-fetchpath at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-FetchPath>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::FetchPath


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-FetchPath>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Data-FetchPath>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Data-FetchPath>

=item * Search CPAN

L<http://search.cpan.org/dist/Data-FetchPath>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 Curtis "Ovid" Poe, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1;    # End of Data::FetchPath
