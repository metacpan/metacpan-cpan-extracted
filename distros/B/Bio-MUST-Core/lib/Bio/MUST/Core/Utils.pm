package Bio::MUST::Core::Utils;
# ABSTRACT: Utility functions for enabling multiple file processing
$Bio::MUST::Core::Utils::VERSION = '0.251810';
use strict;
use warnings;
use autodie;

use File::Basename;
use Path::Class qw(file);
use Test::Files;
use Test::Most;

# TODO: use :filenames in some binaries

use Exporter::Easy (
    OK   => [ qw(secure_outfile :filenames :tests) ],
    TAGS => [
        filenames => [ qw(insert_suffix change_suffix append_suffix) ],
        tests     => [ qw(cmp_store cmp_float) ],
    ],
);


sub secure_outfile {
    my $infile = shift;
    my $suffix = shift;

    return insert_suffix($infile, $suffix) if defined $suffix;

    rename $infile, append_suffix($infile, '.bak') if -e $infile;
    return $infile;
}


sub insert_suffix {
    my $infile = shift;
    my $string = shift;

    my ($filename, $directories, $suffix) = fileparse($infile, qr{\.[^.]*}xms);
    return $directories . $filename . $string . $suffix;
}


sub change_suffix {
    my $infile = shift;
    my $suffix = shift;

    my ($filename, $directories) = fileparse($infile, qr{\.[^.]*}xms);
    return $directories . $filename . $suffix;
}


sub append_suffix {
    my $infile = shift;
    my $suffix = shift;

    my ($filename, $directories) = fileparse($infile);
    return $directories . $filename . $suffix;
}


sub cmp_store {
    my %args = @_;
    my ($obj, $method, $file, $test, $args, $filter)
        = @args{ qw(obj method file test args filter) };

    $args //= {};               # optional hash reference

    # named output file
    my $outfile;
    unless ($method =~ m/\A temp_/xms) {
        $outfile = file('test', "my_$file");
        ( file($outfile) )->remove if -e $outfile;
        $obj->$method($outfile, $args);
    }

    # anonymous temporary file
    $outfile //= $obj->$method($args);

    # compare file contents
    compare_ok(       $outfile, file('test', $file),          "$test: $file")
        unless $filter;
    compare_filter_ok($outfile, file('test', $file), $filter, "$test: $file")
        if     $filter;

    return;
}


sub cmp_float {
    my ($got, $expect, $epsilon, $test) = @_;

    # compare got and expect to epsilon precision
    cmp_ok abs($got - $expect), '<', $epsilon, $test;

    return;
}

1;

__END__

=pod

=head1 NAME

Bio::MUST::Core::Utils - Utility functions for enabling multiple file processing

=head1 VERSION

version 0.251810

=head1 SYNOPSIS

    # TODO

=head1 DESCRIPTION

    # TODO

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
