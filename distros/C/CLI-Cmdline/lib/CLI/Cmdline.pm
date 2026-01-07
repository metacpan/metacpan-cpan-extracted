#!/usr/bin/perl
package CLI::Cmdline;

use strict;
use warnings;
use 5.010;
use Exporter 'import';
use Carp;

our @EXPORT_OK = qw(parse);
our $VERSION   = '1.18';

=encoding utf8

=head1 NAME

CLI::Cmdline - Minimal command-line parser with short and long options in pure Perl

=head1 VERSION

1.18

=head1 SYNOPSIS

    use CLI::Cmdline;

    my $switches = '-v -h -x -verbose -quiet';
    my $options  = '-dir -file -header';

    my %PARAM = (
        header  => [],  # array, so allowed mutiple entries
        dir     => 'default.d',
        x       => 5,
    );

    CLI::Cmdline::parse(\%PARAM, $switches, $options)
        or die "Invalid option or missing argument: @ARGV\n";

    # @ARGV now contains only positional arguments

=head1 DESCRIPTION

Tiny, zero-dependency cmdline parser supporting:

=over 4

=item * Short options: C<-v>, C<-vh>, C<-header>

=item * Long options: C<--verbose>, C<--help>

=item * Long options with argument: C<--output file.txt> or C<--output=file.txt>

=item * Single-letter bundling: C<-vh>, C<-vvv>, C<-vd dir>

=item * Switches counted on repeat

=item * Options collect into array only if default is ARRAY ref

=item * C<--> ends processing

=item * On error: returns 0, restores @ARGV

=item * On success: returns 1

=back

Use with:

    parse(...) or die "Bad options";

=head1 AUTHOR

Hans Harder <hans@atbas.org>

=head1 LICENSE

This module is free software.

You can redistribute it and/or modify it under the same terms as Perl itself.

See the official Perl licensing terms: https://dev.perl.org/licenses/

=cut

sub parse {
    my ($ph, $sw, $opt) = @_;

    my %sw_lookup  = map { s/^--?//r => 1 } split /\s+/, $sw  // '';
    my %opt_lookup = map { s/^--?//r => 1 } split /\s+/, $opt // '';

    my @sw_missing  = grep { !exists $ph->{$_} } keys %sw_lookup;
    my @opt_missing = grep { !exists $ph->{$_} } keys %opt_lookup;

    @{$ph}{@sw_missing}  = (0)  x @sw_missing;
    @{$ph}{@opt_missing} = ('') x @opt_missing;

    while (@ARGV) {
        my $arg = $ARGV[0];

        if ($arg eq '--') {
            shift @ARGV;
            last;
        }

        # Stop at non-options or lone '-'
        last if $arg eq '-' || substr($arg, 0, 1) ne '-';
        shift @ARGV;

        # Handle --key=value form for long options
        my $name = $arg;
        my $attached_val = undef;
        if ($arg =~ /^--([^=]+)=(.*)$/) {
            $name = $1;
            $attached_val = $2;
        } else {
            $name =~ s/^--?//;
        }

        # Full match (multi-char or single after prefix strip)
        if (length($name) > 0) {
            my $rc = _check_match($ph, \%sw_lookup, \%opt_lookup, $name, 1, $attached_val);
            if ($rc == 1) {
                next;
            } elsif ($rc == -1) {
                unshift @ARGV, $arg;
                return 0;
            }
            # rc == 0 : not full match = try bundling (only if short form)
        }

        # Only try bundling if it looks like short bundle
        if ($arg =~ /^-[^-][^=]*$/) {  # -abc, no =
            my @chars = split //, substr($arg, 1);

            for my $i (0 .. $#chars) {
                my $nm   = $chars[$i];
                my $last = ($i == $#chars) ? 1 : 0;

                my $rc = _check_match($ph, \%sw_lookup, \%opt_lookup, $nm, $last);
                if ($rc == 1) {
                    last if exists $opt_lookup{$nm};
                } elsif ($rc == -1 || $rc == 0) {
                    unshift @ARGV, $arg;
                    return 0;
                }
            }
        } else {
            # Was not a valid full match and not bundleable → restore
            unshift @ARGV, $arg;
            return 0;
        }
    }

    return 1;
}

# internal sub, Returns: 1 = matched and processed, 0 = not found, -1 = error
sub _check_match {
    my ($ph, $sw_ref, $opt_ref, $name, $is_last, $attached_val) = @_;

    if (exists $sw_ref->{$name} && not $attached_val) {
        $ph->{$name} = exists $ph->{$name} ? $ph->{$name} + 1 : 1;
        return 1;
    }
    elsif (exists $opt_ref->{$name}) {
        return -1 if !$is_last && !defined $attached_val;

        my $val = defined $attached_val ? $attached_val : shift @ARGV;
        return -1 unless defined $val || defined $attached_val;

        if (ref $ph->{$name} eq 'ARRAY') {
            push @{$ph->{$name}}, $val;
        } else {
            $ph->{$name} = $val;
        }
        return 1;
    }

    return 0;
}

1;

__END__
