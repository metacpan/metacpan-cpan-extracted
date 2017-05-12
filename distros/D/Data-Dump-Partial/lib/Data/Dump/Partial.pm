package Data::Dump::Partial;

use 5.010001;
use strict;
use warnings;
use experimental 'smartmatch';
use Data::Dump::Filtered;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(dump_partial dumpp);

our $VERSION = '0.05'; # VERSION

sub _dmp { Data::Dump::Filtered::dump_filtered(@_, undef) }

sub dump_partial {
    my @data = @_;
    die 'Usage: dump_partial(@data, \%opts)'
        if @data > 1 && ref($data[-1]) ne 'HASH';
    my $opts = (@data > 1) ? {%{pop(@data)}} : {};

    $opts->{max_keys}      //=  5;
    $opts->{max_elems}     //=  5;
    $opts->{max_len}       //= 32;
    $opts->{max_total_len} //= 80;

    $opts->{max_keys} = @{$opts->{precious_keys}} if $opts->{precious_keys} &&
        @{ $opts->{precious_keys} } > $opts->{max_keys};

    my $out;

    if ($opts->{_inner}) {
        #print "DEBUG: inner dump, data="._dmp(@data)."\n";
        $out = Data::Dump::dump(@data);
    } else {
        #print "DEBUG: outer dump, data="._dmp(@data)."\n";
        my $filter = sub {
            my ($ctx, $oref) = @_;

            # to avoid deep recursion (dump_partial keeps modifying the hash due
            # to pair_filter or mask_keys_regex)
            my $skip_modify_outermost_hash;
            if ($opts->{_skip_modify_outermost_hash}) {
                #print "DEBUG: Will skip modify outermost hash\n";
                $skip_modify_outermost_hash++;
                $opts->{_skip_modify_outermost_hash}--;
            }

            if ($opts->{max_len} && $ctx->is_scalar && defined($$oref) &&
                    length($$oref) > $opts->{max_len}) {

                #print "DEBUG: truncating scalar\n";
                return { object => substr($$oref, 0, $opts->{max_len}-3)."..." };

            } elsif ($opts->{max_elems} && $ctx->is_array &&
                         @$oref > $opts->{max_elems}) {

                #print "DEBUG: truncating array\n";
                my @ary = @{$oref}[0..($opts->{max_elems}-1)];
                local $opts->{_inner} = 1;
                local $opts->{max_total_len} = 0;
                my $out = dump_partial(\@ary, $opts);
                $out =~ s/(?:, )?]$/, ...]/;
                return { dump => $out };

            } elsif ($ctx->is_hash) {

                my %hash;
                my $modified;

                if ($opts->{pair_filter} && !$skip_modify_outermost_hash) {
                    for (sort keys %$oref) {
                        my @res = $opts->{pair_filter}->($_, $oref->{$_});
                        $modified = "pair_filter" unless @res == 2 &&
                            $res[0] eq $_ && "$res[1]" eq "$oref->{$_}";
                        while (my ($k, $v) = splice @res, 0, 2) {
                            $hash{$k} = $v;
                        }
                    }
                } else {
                    %hash = %$oref;
                }

                if ($opts->{mask_keys_regex} && !$skip_modify_outermost_hash) {
                    for (sort keys %hash) {
                        if (/$opts->{mask_keys_regex}/) {
                            $modified = "mask_keys_regex";
                            $hash{$_} = '***';
                        }
                    }
                }

                my $truncated;
                if ($opts->{max_keys} && keys(%$oref) > $opts->{max_keys}) {
                    my $mk = $opts->{max_keys};
                    {
                        if ($opts->{hide_keys}) {
                            for (sort keys %hash) {
                                delete $hash{$_} if $_ ~~ @{$opts->{hide_keys}};
                            }
                        }
                        last if keys(%hash) <= $mk;
                        if ($opts->{worthless_keys}) {
                            for (sort keys %hash) {
                                last if keys(%hash) <= $mk;
                                delete $hash{$_} if $_ ~~ @{$opts->{worthless_keys}};
                            }
                        }
                        last if keys(%hash) <= $mk;
                        for (reverse sort keys %hash) {
                            delete $hash{$_} if !$opts->{precious_keys} ||
                                !($_ ~~ @{$opts->{precious_keys}});
                            last if keys(%hash) <= $mk;
                        }
                    }
                    $modified = "truncate";
                    $truncated++;
                }

                if ($modified) {
                    #print "DEBUG: modified hash ($modified)\n";
                    local $opts->{_inner} = 1;
                    local $opts->{_skip_modify_outermost_hash} = 1;
                    local $opts->{max_total_len} = 0;
                    my $out = dump_partial(\%hash, $opts);
                    $out =~ s/(?:, )? }$/, ... }/ if $truncated;
                    return { dump => $out };
                }
            }

            if ($opts->{dd_filter}) {
                return $opts->{dd_filter}->($ctx, $oref);
            } else {
                return;
            }
        };
        $out = Data::Dump::Filtered::dump_filtered(@data, $filter);
    }

    for ($out) {
        s/^\s*#.*//mg; # comments
        s/^\s+//mg; # indents
        s/\n+/ /g; # newlines
    }

    if ($opts->{max_total_len} && length($out) > $opts->{max_total_len}) {
        $out = substr($out, 0, $opts->{max_total_len}-3) . "...";
    }

    print STDERR "$out\n" unless defined wantarray;
    $out;
}

sub dumpp { dump_partial(@_) }

1;
# ABSTRACT: Dump data structure compactly and potentially partially

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Dump::Partial - Dump data structure compactly and potentially partially

=head1 VERSION

version 0.05

=head1 SYNOPSIS

 use Data::Dump::Partial qw(dump_partial dumpp);

 dump_partial([1, "some long string", 3, 4, 5, 6, 7]);
 # prints something like: [1, "some long st...", 3, 4, 5, ...]

 # specify options
 dumpp($data, $more_data, {max_total_len => 50, max_keys => 4});

 # mask passwords specified in hash key values
 dumpp({auth_info=>{user=>"steven", password=>"secret"}, foo=>1, bar=>2},
       {mask_keys_regex=>qr/\Apass\z|passw(or)?d/i});
 # prints something like:
 # {auth_info=>{user=>"steven", password=>"***"}, foo=>1, bar=>2}

=head1 DESCRIPTION

=head1 FUNCTIONS

=head2 dump_partial(..., $opts)

Dump one more data structures compactly and potentially partially. Uses
L<Data::Dump::Filtered> as the backend.

By compactly, it means all indents and comments and newlines are removed, so the
output all fits in one line.

By partially, it means only up to a certain amount of data are dumped/shown:
string longer than a certain length will be truncated (with "..." appended in
the end), array more than a certain number of elements will be truncated, and
hash containing more than a certain number of pairs will be truncated. The total
length of dump is also limited. When truncating hash you can specify which keys
to discard/preserve first. You can also mask certain hash key values (for
example, to avoid exposing passwords in dumps).

$opts is a hashref, optional only when there is one data to dump, with the
following known keys:

=over 4

=item * max_total_len => NUM

Total length of output before it gets truncated with an ellipsis. Default is 80.

=item * max_len => NUM

Maximum length of a scalar (string, etc) to show before the rest get truncated
with an ellipsis. Default is 32.

=item * max_keys => NUM

Number of key pairs of a hash to show before the rest get truncated with an
ellipsis. Default is 5.

=item * max_elems => NUM

Number of elements of an array to show before the rest get truncated with an
ellipsis. Default is 5.

=item * precious_keys => [KEY, ...]

Never truncate these keys (even if it results in max_keys limit being exceeded).

=item * worthless_keys => [KEY, ...]

When needing to truncate hash keys, search for these first.

=item * hide_keys => [KEY, ...]

Always truncate these hash keys, no matter what. This is actually also
implemented by Data::Dump::Filtered.

=item * mask_keys_regex => REGEX

When encountering keys that match certain regex, mask the values with '***'.
This can be useful if you want to mask passwords, e.g.: mask_keys_regex =>
qr/\Apass\z|passw(or)?d/i. If you want more general masking, you can use
pair_filter.

=item * pair_filter => CODE

CODE will be called for each hash key/value pair encountered in the data. It
will be given ($key, $value) as argument and is expected to return a list of
zero or more of keys and values. The example below implements something similar
to what mask_keys_regex accomplishes:

 # mask each password character with '*'
 hash_pair_filter => sub {
     my ($k, $v) = @_;
     if ($k =~ /\Apass\z|passw(or)?d/i) {
         $v =~ s/./*/g;
     }
     ($k, $v);
 }

=item * dd_filter => \&sub

If you have other Data::Dump::Filtered filter you want to execute, you can pass
it here.

=back

=head2 dumpp

An alias for dump_filtered().

=head1 FAQ

=head2 What is the point/purpose of this module?

Sometimes you want to dump a data structure, but need it to be short, more than
need it to be complete, for example when logging to log files or database.

=head2 Is the dump result eval()-able? Will the dump result eval() to produce the original data?

Sometimes it is/will, sometimes it does/will not if it gets truncated.

=head1 SEE ALSO

L<Data::Dump::Filtered>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Dump-Partial>.

=head1 SOURCE

Source repository is at L<https://github.com/sharyanto/perl-Data-Dump-Partial>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Dump-Partial>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
