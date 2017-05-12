package Config::IPFilter;
{
    use Moose;
    our $MAJOR = 1; our $MINOR = 00; our $DEV = 0; our $VERSION = sprintf('%0d.%02d' . ($DEV ? (($DEV < 0 ? '' : '_') . '%03d') : ('')), $MAJOR, $MINOR, abs $DEV);
    use Config::IPFilter::Types;

    #
    has rules => (isa      => 'ArrayRef[Config::IPFilter::Rule]',
                  is       => 'ro',
                  traits   => ['Array'],
                  init_arg => undef, # XXX - In the future, allow this
                  default  => sub { [] },
                  handles  => {
                              add_rule            => 'push',
                              count_rules         => 'count',
                              is_empty            => 'is_empty',
                              get_rule            => 'get',
                              first_rule          => 'first',
                              grep_rules          => 'grep',
                              map_rules           => 'map',
                              sort_rules          => 'sort',
                              sort_rules_in_place => 'sort_in_place',
                              shuffle_rules       => 'shuffle',
                              clear_rules         => 'clear',
                              insert_rule         => 'insert',
                              delete_rule         => 'delete',
                              push_rule           => 'push',
                              pop_rule            => 'pop'
                  }
    );
    around add_rule => sub {
        my ($c, $s, $l, $u, $a, $d) = @_;
        $l = blessed $l? $l : sub {
            require Config::IPFilter::Rule;
            Config::IPFilter::Rule->new(lower        => $l,
                                        upper        => $u,
                                        access_level => $a,
                                        description  => $d
            );
            }
            ->();
        return $c->($s, $l) ? $l : ();
    };

    sub load {
        my ($s, $path) = @_;
        open(my $IPFilter, '<', $path) || return;
        for my $line (<$IPFilter>) {
            next if $line =~ m[(?:^#|^$)];
            my ($range, $access_level, $desc) =
                ($line =~ m[^(.+-.+)\s*,\s*(\d+)\s*,\s*(.+)\s*$]);
            next if !$range;
            my ($start, $end) = ($range =~ m[^(.+)\s*-\s*(.+)\s*$]);
            $_ =~ s[\s][]g for $start, $end;
            $s->add_rule($start, $end, $access_level, $desc);
        }
        1;
    }

    sub save {
        my ($s, $path) = @_;
        open(my $IPFilter, '>', $path) || return;
        for my $rule (
            $s->sort_rules(
                sub {
                    $_[0]->lower cmp $_[1]->lower
                        || $_[0]->upper cmp $_[1]->upper;
                }
            )
            )
        {   syswrite $IPFilter, $rule->_as_string . "\n";
        }
        return close $IPFilter;
    }

    sub is_banned {
        my ($s, $ip) = @_;
        return $s->first_rule(
            sub {
                $_->in_range($ip) && $_->access_level < 127;
            }
        ) || ();
    }

    #
    no Moose;
}
1;

=pod

=head1 NAME

Config::IPFilter - Simple, rule-based IP filter

=head1 Synopsis

    use Config::IPFilter;
    my $filter = Config::IPFilter->new;
    my $rule   = $filter->add_rule('89.238.128.0', '89.238.191.255', 127,
                                 'Example range');

    # A list of example IPv4 addresses. IPv6 works too.
    my @ipv4 = qw[89.238.156.165 89.238.156.169 89.238.156.170 89.238.167.84
        89.238.167.86 89.238.167.99];

    # Check a list of ips
    say sprintf '%15s is %sbanned', $_, $filter->is_banned($_) ? '' : 'not '
        for @ipv4;

    # Lower the acces level by one pushes it below our ban threshold
    $rule->decrease_access_level;

    # Check a list of ips
    say sprintf '%15s is %sbanned', $_,
        $filter->is_banned($_) ? 'now ' : 'still not '
        for @ipv4;

You could also load rules directly from an C<ipfilter.dat> file.

=head1 Description

    # Example of a "ipfilter.dat" file
    #
    # All entered IP ranges will be blocked in both directions. Be careful
    # what you enter here. Wrong entries may totally block access to the
    # network.
    #
    # Format:
    # IP-Range , Access Level , Description
    #
    # Access Levels:
    # 127 blocked
    # >=127 permitted

    064.094.089.000 - 064.094.089.255 , 000 , Gator.com

This entry will block the IPs from 064.094.089.000 to 064.094.089.255, i.e.
your code should not connect to any IP in this range.

At the moment only one, read-only access level is implemented; a value at or
below C<127> means that addresses in that range are banned.

=head1 Methods

Here's a list of 'em...

=head2 my $filter = Config::IPFilter->B<new>( )

This builds a new, empty object. There are currently no expected arguments.

=head2 $filter->B<add_rule>( $rule )

This method adds a new L<range|Config::IPFilter::Rule> to the in-memory
ipfilter.

=head2 $filter->B<add_rule>( $lower, $upper, $access_level, $description )

This method coerces the arguments into a new L<rule|Config::IPFilter::Rule>
which is then added to the in-memory ipfilter.

=head2 $filter->B<count_rules>( )

Returns a tally of all loaded L<rule|Config::IPFilter::Rule>s.

=head2 $filter->B<is_empty>( )

Returns a boolean value indicating whether or not there are any
L<rule|Config::IPFilter::Rule>s loaded in the ipfilter.

=head2 $filter->B<clear_rules>( )

Deletes all L<rule|Config::IPFilter::Rule>s from the ipfilter.

=head2 $filter->B<load>( $path )

Slurps an C<ipfilter.dat>-like file and adds the
L<rule|Config::IPFilter::Rule>s found inside to the ipfilter.

=head2 $filter->B<save>( $path )

Stores the in-memory ipfilter to disk.

=head2 $filter->B<is_banned>( $ip )

If C<$ip> is banned, the first L<rule|Config::IPFilter::Rule> in which it was
found below the threshold is returned.

If not, a false value is returned. Currently, rules with an
L<< access_level|Config::IPFilter::Rule/"$filter->B<access_level>( )" >> at or
below C<127> are considered banned.

=head1 IPv6 Support

The standard ipfilter.dat only supports IPv4 addresses but
L<Net::BitTorrent>'s current implementation supports IPv6 as well. Keep this
in mind when L<storing|/save> an ipfilter.dat file to disk.

=head1 Notes

This is a very good example of code which should not require L<Moose|Moose>.
In a future version, I hope to switch to L<Moo|Moo>. ...when C<coerce> works
to some degree.

=head1 See Also

L<Emule Project's ipfilter.dat documentation|http://www.emule-project.net/home/perl/help.cgi?l=1&topic_id=142&rm=show_topic>

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

=for rcs $Id: IPFilter.pm 53e0787 2011-02-01 15:34:19Z sanko@cpan.org $

=cut
