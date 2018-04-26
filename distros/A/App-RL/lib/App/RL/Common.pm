package App::RL::Common;
use strict;
use warnings;
use autodie;

use 5.010001;

use Carp qw();
use IO::Zlib;
use List::Util qw();
use Path::Tiny qw();
use Set::Scalar;
use Tie::IxHash;
use YAML::Syck qw();

use AlignDB::IntSpan;

# The only entrance for AlignDB::IntSpan or AlignDB::IntSpanXS
#@returns AlignDB::IntSpan
sub new_set {
    return AlignDB::IntSpan->new;
}

sub read_lines {
    my $infile = shift;

    my $in_fh;
    if ( lc $infile eq "stdin" ) {
        $in_fh = *STDIN{IO};
    }
    else {
        $in_fh = IO::Zlib->new( $infile, "rb" );
    }

    my @lines;
    while ( my $line = $in_fh->getline ) {
        chomp $line;
        push @lines, $line;
    }
    close $in_fh;

    return @lines;
}

sub read_sizes {
    my $fn         = shift;
    my $remove_chr = shift;

    my @lines = read_lines($fn);
    my %length_of;
    for (@lines) {
        my ( $key, $value ) = split /\t/;
        $key =~ s/chr0?//i if $remove_chr;
        $length_of{$key} = $value;
    }

    return \%length_of;
}

sub read_names {
    my $fn = shift;

    my @lines = read_lines($fn);

    return \@lines;
}

sub runlist2set {
    my $runlist_of = shift;
    my $remove_chr = shift;

    my $set_of = {};

    for my $chr ( sort keys %{$runlist_of} ) {
        my $new_chr = $chr;
        $new_chr =~ s/chr0?//i if $remove_chr;
        my $set = new_set();
        $set->add( $runlist_of->{$chr} );
        $set_of->{$new_chr} = $set;
    }

    return $set_of;
}

sub decode_header {
    my $header = shift;

    tie my %info, "Tie::IxHash";

    # S288.chrI(+):27070-29557|species=S288C
    my $head_qr = qr{
        (?:(?P<name>[\w_]+)\.)?
        (?P<chr>[\w-]+)
        (?:\((?P<strand>.+)\))?
        [\:]                    # spacer
        (?P<start>\d+)
        [\_\-]?                 # spacer
        (?P<end>\d+)?
    }xi;

    $header =~ $head_qr;
    my $chr_name  = $2;
    my $chr_start = $4;
    my $chr_end   = $5;

    if ( defined $chr_name and defined $chr_start ) {
        if ( !defined $chr_end ) {
            $chr_end = $chr_start;
        }
        %info = (
            name   => $1,
            chr    => $chr_name,
            strand => $3,
            start  => $chr_start,
            end    => $chr_end,
        );
        if ( defined $info{strand} ) {
            if ( $info{strand} eq '1' ) {
                $info{strand} = '+';
            }
            elsif ( $info{strand} eq '-1' ) {
                $info{strand} = '-';
            }
        }
    }
    else {
        $header =~ /^(\S+)/;
        my $chr = $1;
        %info = (
            name   => undef,
            chr    => $chr,
            strand => undef,
            start  => undef,
            end    => undef,
        );
    }

    # additional keys
    if ( $header =~ /\|(.+)/ ) {
        my @parts = grep {defined} split /;/, $1;
        for my $part (@parts) {
            my ( $key, $value ) = split /=/, $part;
            if ( defined $key and defined $value ) {
                $info{$key} = $value;
            }
        }
    }

    return \%info;
}

sub info_is_valid {
    my $info = shift;

    if ( ref $info eq "HASH" ) {
        if ( exists $info->{chr} and exists $info->{start} ) {
            if ( defined $info->{chr} and defined $info->{start} ) {
                return 1;
            }
        }
    }

    return 0;
}

sub encode_header {
    my $info           = shift;
    my $only_essential = shift;

    my $header;
    if ( defined $info->{name} ) {
        if ( defined $info->{chr} ) {
            $header .= $info->{name};
            $header .= "." . $info->{chr};
        }
        else {
            $header .= $info->{name};
        }
    }
    elsif ( defined $info->{chr} ) {
        $header .= $info->{chr};
    }

    if ( defined $info->{strand} ) {
        $header .= "(" . $info->{strand} . ")";
    }
    if ( defined $info->{start} ) {
        $header .= ":" . $info->{start};
        if ( $info->{end} != $info->{start} ) {
            $header .= "-" . $info->{end};
        }
    }

    # additional keys
    if ( !$only_essential ) {
        my %essential = map { $_ => 1 } qw{name chr strand start end seq full_seq};
        my @parts;
        for my $key ( sort keys %{$info} ) {
            if ( !$essential{$key} ) {
                push @parts, $key . "=" . $info->{$key};
            }
        }
        if (@parts) {
            my $additional = join ";", @parts;
            $header .= "|" . $additional;
        }
    }

    return $header;
}

1;
