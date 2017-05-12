package App::KV2JSON;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.02";

use Encode;
use JSON::PP;

sub run {
    my ($class, @argv) = @_;

    if ($argv[0] =~ /^--?h(?:elp)?$/) {
        print_usage();
    }

    my @key_values = (_kv_from_pipe(), @argv);

    my $hash = kv2hash(@key_values);

    my $coder = JSON::PP->new->ascii(1);
    $coder->encode($hash) . "\n";
}

sub kv2hash {
    my @key_values = @_;

    my $hash = {};
    for my $kv (@key_values) {
        my ($key, $value) = split /=/, $kv, 2;
        $value = decode_utf8 $value;

        if ($key =~ s/\[\]$//) {
            $value = [split /,/, $value];
        }

        my @keys;
        while ($key =~ s/\[([^\[]*)\]$//) {
            unshift @keys, $1;
        }
        unshift @keys, $key;

        my $target = $hash;
        while (@keys) {
            my $key = shift @keys;
            my $is_number = $key =~ s/#$//;
            if (!@keys) {
                if ($is_number) {
                    if (ref $value) {
                        $value = [map { $_ += 0 } @$value]
                    }
                    else {
                        $value += 0;
                    }
                }
                $target->{$key} = $value;
                last;
            }
            $target->{$key} = {} unless exists $target->{$key};
            $target = $target->{$key};
        }
    }
    $hash;
}

sub print_usage {
    print <<'...';
Usage:
    % kv2json var=baz fruits[]=apple,orange aa[bb]=cc
    {"fruits":["apple","orange"],"var":"baz","aa":{"bb":"cc"}}
...
    exit;
}

sub _kv_from_pipe {
    my @key_values;
    if (-p STDIN) {
        my $continue;
        my $kv = '';
        while (my $line = <STDIN>) {
            chomp $line;
            $kv .= $line;
            $continue = $kv =~ s/\\$// ? 1 : 0;
            if (!$continue) {
                push @key_values, $kv;
                $kv = '';
            }
        }
    }
    @key_values;
}

1;
__END__
=for stopwords kv2json

=encoding utf-8

=head1 NAME

App::KV2JSON - backend class of kv2json

=head1 SYNOPSIS

    use App::KV2JSON;

=head1 DESCRIPTION

App::KV2JSON is backend module of L<kv2json>.

=head1 LICENSE

Copyright (C) Songmu.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Songmu E<lt>y.songmu@gmail.comE<gt>

=cut

