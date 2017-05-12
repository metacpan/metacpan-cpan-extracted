package Config::IPFilter::Rule;
{
    use Moose;
    our $MAJOR = 1; our $MINOR = 0; our $DEV = 0; our $VERSION = sprintf('%0d.%02d' . ($DEV ? (($DEV < 0 ? '' : '_') . '%03d') : ('')), $MAJOR, $MINOR, abs $DEV);
    use Config::IPFilter::Types;

    #
    for my $limit (qw[upper lower]) {
        has $limit => (
            isa      => 'Config::IPFilter::Types::Paddr',
            is       => 'ro',
            required => 1,
            coerce   => 1,
            handles  => {
                $limit . '_as_string' => sub {
                    my $s = shift;
                    require Config::IPFilter::Types;
                    Config::IPFilter::Types::paddr2ip($s->{$limit});
                    }
            }
        );
    }
    has description => (isa => 'Str', is => 'ro', required => 1);
    has access_level => (isa      => 'Int',
                         is       => 'ro',
                         required => 1,
                         traits   => ['Counter'],
                         handles  => {
                                     set_access_level      => 'set',
                                     increase_access_level => 'inc',
                                     decrease_access_level => 'dec'
                         }
    );

    sub in_range {
        my ($s, $ip) = @_;
        $ip = Config::IPFilter::Types::ip2paddr($ip);
        return (($s->lower lt $ip && $s->upper gt $ip) ? 1 : 0);
    }

    sub _as_string {
        my $s = shift;
        return sprintf '%s - %s, %d, %s', $s->lower_as_string,
            $s->upper_as_string,
            $s->access_level, $s->description;
    }
    no Moose;
}
1;

=pod

=head1 NAME

Config::IPFilter::Rule - A single block of IP addresses

=head1 Synopsis

    use Config::IPFilter::Rule;
    my $rule =
        Config::IPFilter::Rule->new(access_level => 255,
                                    lower        => '0.0.0.0',
                                    upper        => '255.255.255.255',
                                    description  => 'teh innernetz'
        );

    # Hide in a cave
    $rule->set_access_level(126);

IPv6 is also supported...

    use Config::IPFilter::Rule;
    my $rule = Config::IPFilter::Rule->new(
           access_level => 255,
           upper        => 'ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff',
           lower        => '::',  # ojai
           description  => 'teh innernetz'
    );

    # Hide in a cave
    $rule->set_access_level(126);
    $filter->is_banned('2001:db8::');    # It, and everything else, is banned

=head1 Description

This is a single range of addresses (IPv4 or IPv6) which all share a single
access level.

=head1 my $rule = Config::IPFilter::Rule->B<new>( ... )

This constructs a new object. The following arguments are required:

=over

=item C<access_level>

This is an integer value.

=item C<description>

This is a string. You should put the reason why this range exists here.

=item C<upper>

This is the address at the highest end of this range.

=item C<lower>

This is the address at the lowest end of this range.

=back

=head1 $filter->B<access_level>( )

Returns the access level currently defined for this range. See
L<< Config::IPFilter->is_banned( ... )|Config::IPFilter/"$filter->B<is_banned>( $ip )" >>.

=head1 $filter->B<set_access_level>( $value )

Sets the access level for this range.

=head1 $filter->B<increase_access_level>( [ $inc ] )

Sets the access level for this range C<$inc> degrees higher. The default value
of C<$inc> is C<1>.

=head1 $filter->B<decrease_access_level>( [ $dec ] )

Sets the access level for this range C<$dec> degrees lower. The default value
of C<$dec> is C<1>.

=head1 $filter->B<in_range>( $address )

If the given address is within this rule's range, a true value is returned
otherwise a false value is returned.

=head1 $filter->B<description>( )

This is original string value you passed during construction.

=head1 $filter->B<upper>( )

This returns the address at the highest end of the range.

=head1 $filter->B<lower>( )

This returns the address at the lowest end of the range.

=head1 Author

=begin :html

L<Sanko Robinson|http://sankorobinson.com/>
<L<sanko@cpan.org|mailto://sanko@cpan.org>> -
L<http://sankorobinson.com/|http://sankorobinson.com/>

CPAN ID: L<SANKO|http://search.cpan.org/~sanko>

=end :html

=begin :text

Sanko Robinson <sanko@cpan.org> - http://sankorobinson.com/

CPAN ID: SANKO

=end :text

=head1 License and Legal

Copyright (C) 2010, 2011 by Sanko Robinson <sanko@cpan.org>

This program is free software; you can redistribute it and/or modify it under
the terms of
L<The Artistic License 2.0|http://www.perlfoundation.org/artistic_license_2_0>.
See the F<LICENSE> file included with this distribution or
L<notes on the Artistic License 2.0|http://www.perlfoundation.org/artistic_2_0_notes>
for clarification.

When separated from the distribution, all original POD documentation is
covered by the
L<Creative Commons Attribution-Share Alike 3.0 License|http://creativecommons.org/licenses/by-sa/3.0/us/legalcode>.
See the
L<clarification of the CCA-SA3.0|http://creativecommons.org/licenses/by-sa/3.0/us/>.

Neither this module nor the L<Author|/Author> is affiliated with BitTorrent,
Inc.

=for rcs $Id: Rule.pm 53e0787 2011-02-01 15:34:19Z sanko@cpan.org $

=cut
