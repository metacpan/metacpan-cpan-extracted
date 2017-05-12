use 5.008;
use strict;
use warnings;

package Data::SmartMunge;
BEGIN {
  $Data::SmartMunge::VERSION = '1.101612';
}

# ABSTRACT: Munge scalars, hashes and arrays in flexible ways
use Exporter qw(import);
our %EXPORT_TAGS = (util => [qw(smart_munge delete_matching)],);
our @EXPORT_OK = @{ $EXPORT_TAGS{all} = [ map { @$_ } values %EXPORT_TAGS ] };
my %munger_dispatch = (
    STRING_CODE => sub { $_[1]->($_[0]) },
    ARRAY_CODE  => sub { $_[1]->($_[0]) },
    HASH_CODE   => sub { $_[1]->($_[0]) },
    HASH_HASH   => sub { +{ %{ $_[0] }, %{ $_[1] } } },  # overlay
);

sub smart_munge {
    my ($data, $munger) = @_;

    unless (defined $munger) {
        return $data unless wantarray;
        return @$data if ref $data eq 'ARRAY';
        return %$data if ref $data eq 'HASH';
    }

    my $data_ref   = ref $data   || 'STRING';
    my $munger_ref = ref $munger || 'STRING';
    if (my $handler = $munger_dispatch{ $data_ref . '_' . $munger_ref }) {
        my $result = $handler->($data, $munger);
        return $result unless wantarray;
        return @$result if ref $result eq 'ARRAY';
        return %$result if ref $result eq 'HASH';
    } else {
        die "can't munge $data_ref with $munger_ref";
    }
}

sub delete_matching {
    my ($re, $flags) = @_;
    $flags = '' unless defined $flags;
    return $flags =~ s/g//
        ?  sub { $_[0] =~ s/$re//g; $_[0] }
        :  sub { $_[0] =~ s/$re//; $_[0] };
}


__END__
=pod

=head1 NAME

Data::SmartMunge - Munge scalars, hashes and arrays in flexible ways

=head1 VERSION

version 1.101612

=head1 SYNOPSIS

    use Data::SmartMunge qw(:all);

    my $s  = smart_munge('foo bar baz', sub { uc $_[0] });
    my $s2 = smart_munge('foo bar baz bar baz', delete_matching(qr/bar\s*/, 'g'));

    my $a_ref = smart_munge([ 1 .. 4 ], sub { [ reverse @{ $_[0] } ] });
    my @a = smart_munge([ 1 .. 4 ], sub { [ reverse @{ $_[0] } ] });

    my %h = smart_munge(
        { a => 'foo', b => 'bar' },
        sub {
            +{ map { $_ => uc $_[0]->{$_} } keys %{ $_[0] } };
        },
    );

    my $h_ref = smart_munge(
        { a => 'foo', b => 'bar' },
        { a => undef, c => 'baz' },
    );

=head1 DESCRIPTION

This module provides a generic way to munge scalars, hashes and arrays.

=head1 FUNCTIONS

=head2 smart_munge

Takes as the first argument - the I<data> - either a scalar, an array
reference or a hash reference. Takes as the second argument - the I<munger> -
either a hash or a code reference. It tries to apply the munger to the data.
For example, if the munger is a code reference, that code will be run with the
data as an argument. If both data and munger are hash references, the munger
hash will be overlaid onto the data hash and the result will be returned.

If called in scalar context, any resulting array or hash will be returned as a
reference. In list context, the array or hash will be returned as is.

If the munger is not defined, the data will be returned unchanged, again
respecting context.

=head2 delete_matching

Takes a regular expression as the first argument and flags like C<s///> does
as the optional second argument. Returns a ready-made munger that deletes the
part of the data that matches the regular expression. If the flag argument
contains C<g>, all occurrences will be deleted.

For example:

    smart_munge('foo bar baz bar baz', delete_matching(qr/bar\s*/);
    # returns 'foo baz bar baz'

    smart_munge('foo bar baz bar baz', delete_matching(qr/bar\s*/, 'g');
    # returns 'foo baz baz'

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see
L<http://search.cpan.org/dist/Data-SmartMunge/>.

The development version lives at
L<http://github.com/hanekomu/Data-SmartMunge/>.
Instead of sending patches, please fork this project using the standard git
and github infrastructure.

=head1 AUTHOR

  Marcel Gruenauer <marcel@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

