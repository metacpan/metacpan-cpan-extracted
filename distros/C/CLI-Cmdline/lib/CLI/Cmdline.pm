#!/usr/bin/perl
package CLI::Cmdline;

use strict;
use warnings;
use 5.010;
use Exporter 'import';

our @EXPORT_OK = qw(parse);
our $VERSION   = '1.22';

=encoding utf8

=head1 NAME

CLI::Cmdline - Minimal command-line parser with short/long options and aliases in pure Perl

=head1 VERSION

1.22

=head1 SYNOPSIS

    use CLI::Cmdline qw(parse);

    my $switches = '-v -q -h|help --dry-run';
    my $options  = 'input --output --config --include';
	
    # only define options which have no default value 0 or '';
    my %opt = (
        v       => 1,          # switch, will be incremented on each occurrence
        include => [],         # multiple values allowed
        config  => '/etc/myapp.conf',
    );

    CLI::Cmdline::parse(\%opt, $switches, $options)
        or die "Usage: $0 [options] <files...>\nTry '$0 --help' for more information.\n";

    # @ARGV now contains only positional arguments
    die " .... "   if $#ARGV < 0 || $ARGV[0] ne 'file.txt';

=head1 DESCRIPTION

Tiny, zero-dependency command-line parser supporting short/long options, aliases,
bundling, repeated switches, array collection, and C<--> termination.

=over 4

=item * Short options: C<-v>, C<-vh>, C<-header>

=item * Long options: C<--verbose>, C<--help>

=item * Long options with argument: C<--output file.txt> or C<--output=file.txt>

=item * Aliases via C<|>

=item * B<Optional> leading C<-> or C<--> in specification strings

=item * Single-letter bundling: C<-vh>, C<-vvv>, C<-vd dir>

=item * Switches counted on repeat

=item * Options collect into array only if default is ARRAY ref

=item * C<--> ends processing

=item * On error: returns 0, restores @ARGV

=item * On success: returns 1

=back

=head1 EXAMPLES

=head2 Minimal example – switches without explicit defaults

You do not need to pre-define every switch with a default value.
Missing switches are automatically initialized to C<0>.

    my %opt;
    parse(\%opt, '-v -h -x')
        or die "usage: $0 [-v] [-h] [-x] files...\n";

    # After parsing ./script.pl -vvvx file.txt
    # %opt will contain: (v => 3, h => 0, x => 1)
    # @ARGV == ('file.txt')

=head2 Required Options

To make an option required, declare it with an empty string default and check afterward:

    my %opt = ( mode => 'normal');
    parse(\%opt, '', '--input --output --mode')
        or die "usage: $0 --input=FILE [--output=FILE] [--mode=TYPE] files...\n";

    die "Error: --input is required\n"   if ($opt{input} eq '');

=head2 Collecting multiple values, no default array needed

If you want multiple occurrences but don't want to pre-set an array:

    my %opt = (
        define => [],        # explicitly an array ref
    );

    parse(\%opt, '', '--define')
        or die "usage: $0 [--define NAME=VAL ...] files...\n";

    # ./script.pl --define DEBUG=1 --define TEST --define PROFILE
    # $opt{define} == ['DEBUG=1', 'TEST', 'PROFILE']

    # Alternative: omit the default entirely (parser will not auto-create array)
    # If you forget the [] default, repeated --define will overwrite the last value.

=head2 Realistic full script with clear usage message

    #!/usr/bin/perl
    use strict;
    use warnings;

    use Data::Dumper $Data::Dumper::Sortkeys = 1;
    use CLI::Cmdline qw(parse);

    my $switches = '-v|verbose -q|quiet --help --dry-run -force|f';
    my $options  = '-input|i -output -mode -tag';
    my %opt      = ( v => 1, mode => 'normal', tag => [] );   # tag = multiple tags allowed

    CLI::Cmdline::parse(\%opt, $switches, $options) 
        	or die "Try '$0 --help' for more information. ARGV = @ARGV\n";

    #  --- check if ARGV is filled or help is required
    Usage()        if $#ARGV < 0 || $opt{help};
    die "Error: --input is required. See $0 --help for usage.\n"   if ($opt{input} eq '');

    my $verbose = $opt{v} - $opt{q};
    print "Starting processing (verbose $verbose)...\n" if $verbose > 0;

    print Dumper(\%opt);
    print "ARG = [".join('] [',@ARGV)."]\n";
    exit 0;

    sub Usage {
        print <<"USAGE";
    Usage  : $0 [options] --input=FILE [files...]
    Options:
      -v|verbose                Increase verbosity (repeatable)
      -q|quiet                  Suppress normal output
      --dry-run                 Show what would be done
      -f|force                  Force operation even if risky
      --input=FILE              Input file (required)
      --output=FILE             Output file (optional)
      --mode=MODE               Processing mode, default: $opt{mode}
      --tag=TAG                 Add a tag (multiple allowed)
      --help                    Show this help message

    Example:
      $0 --input=data.csv -vvv file1.txt
      $0 --input=data.csv --tag=2026 --tag=final -vv file1.txt
      $0 --input=data.csv -quiet  file1.txt
      $0 -input=data.csv -dry-run file1.txt   # not a long tag with =
      $0 -input data.csv -vf file1.txt
      $0 -vfi data.csv file1.txt
      $0 -vif data.csv file1.txt              # option not at the end
      $0 file1.txt                            # missing input error
      $0 --help

    USAGE
        exit 1;
    }

=head2 Using -- to pass filenames starting with dash

    my %opt;
    parse(\%opt, '-r')
        or die "usage: $0 [-r] files...\n";

    # Command line:
    ./script.pl -r -- -hidden-file.txt another-file

    # Results:
    # $opt{r} == 1
    # @ARGV == ('-hidden-file.txt', 'another-file')

=head1 AUTHOR
        
Hans Harder <hans@atbas.org>
        
=head1 LICENSE
            
This module is free software.
            
You can redistribute it and/or modify it under the same terms as Perl itself.

See the official Perl licensing terms: https://dev.perl.org/licenses/
        
=cut

sub parse {
    my ($ph, $sw, $opt) = @_;

    my ($psw_lookup,  $psw_alias,  $pasw_missing)  = _process_spec($ph,  $sw // '');
    my ($popt_lookup, $popt_alias, $paopt_missing) = _process_spec($ph, $opt // '');

    @{$ph}{@$pasw_missing}  = (0)  x @$pasw_missing;
    @{$ph}{@$paopt_missing} = ('') x @$paopt_missing;

    while (@ARGV) {
        my $arg = $ARGV[0];

        if ($arg eq '--') {
            shift @ARGV;
            last;
        }

        last if $arg eq '-' || substr($arg, 0, 1) ne '-';
        shift @ARGV;

        my ($name, $attached_val);
        if ($arg =~ /^--([^=]+)=(.*)$/) {
            $name = $1;
            $attached_val = $2;
        } else {
            $name = $arg =~ s/^--?//r;
        }
        # check aliases
        $name = $psw_alias->{$name} // $popt_alias->{$name} // $name;

        my $rc = _check_match($ph, $psw_lookup, $popt_lookup, $name, 1, $attached_val);
        if ($rc == 1) {
            next;
        } elsif ($rc == -1) {
            unshift @ARGV, $arg;
            return 0;
        }

        if ($arg =~ /^-[^-][^=]*$/) {
            my @chars = split //, substr($arg, 1);

            for my $i (0 .. $#chars) {
                my $char = $chars[$i];
                my $is_last = ($i == $#chars);

                $char = $psw_alias->{$char} // $popt_alias->{$char} // $char;

                my $rc = _check_match($ph, $psw_lookup, $popt_lookup, $char, $is_last);
                if ($rc == 1) {
                    last if exists $popt_lookup->{$char};
                } elsif ($rc <= 0) {
                    unshift @ARGV, $arg;
                    return 0;
                }
            }
            next;
        }

        unshift @ARGV, $arg;
        return 0;
    }

    return 1;
}

sub _process_spec {
    my ($ph, $spec_str) = @_;
    my (%lookup, %alias, @missing);
        
    #    return (\%lookup, \%alias, \@missing)  unless $spec_str;

    for my $spec (split /\s+/, $spec_str // '') {
        next unless length $spec;	    
        
        my @names = split /\|/, $spec;
        # Strip optional leading - or -- from ALL names, but remember the first one
        my $canon = $names[0] =~ s/^--?//r;   # remove prefix from first name → canonical
        $lookup{$canon} = 1;
         
        for my $n (@names) {
            my $key = $n =~ s/^--?//r;         # remove prefix from each name
            $alias{$key} = $canon if $key ne $canon;
        }
        push @missing, $canon if (!$ph) || !exists $ph->{$canon};
    }
    return (\%lookup, \%alias, \@missing);
}
            
sub _check_match {
    my ($ph, $sw_ref, $opt_ref, $name, $is_last, $attached_val) = @_;

    if (exists $sw_ref->{$name} && !defined $attached_val) {
        $ph->{$name} = ($ph->{$name} // 0) + 1;
        return 1;
    } elsif (exists $opt_ref->{$name}) {
        return -1 if !$is_last && !defined $attached_val;
        my $val = defined $attached_val ? $attached_val : (shift @ARGV // '');

        # Only error if no value when not attached (i.e., separate arg missing)
        return -1 if $val eq '' && !defined $attached_val;

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
