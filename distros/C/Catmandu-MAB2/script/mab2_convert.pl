#!/usr/bin/perl

# PODNAME: mab2_convert.pl
our $VERSION = '0.11';

use utf8;
use warnings;

use Getopt::Long;
use MAB2::Parser::Disk;
use MAB2::Parser::RAW;
use MAB2::Parser::XML;
use MAB2::Writer::Disk;
use MAB2::Writer::RAW;
use MAB2::Writer::XML;

my ($in, $out, $from, $to);

my $options_ok = GetOptions (
    'i=s'     => \$in,
    'o=s'     => \$out,
    'f=s'     => \$from,
    't=s'     => \$to,
    'help'    => sub { cli_usage() },
    'usage'   => sub { cli_usage() },
);

cli_usage() if !$options_ok or !$in or !$out or !$from or !$to;

my $formats = qr{^(Disk|RAW|XML)$};
die "Not a valid input format \"$from\"" if $from !~ m/$formats/;
die "Not a valid output format \"$to\"" if $to !~ m/$formats/;

convert($in, $out, $from, $to);

sub cli_usage {
    
    my $usage = <<END;

Usage: mab2_convert.pl -i mab2raw.dat -o mab2xml.xml -f RAW -t XML

Description: Convert records from one MAB2 format to an other.

Options:
    -i        Specify input file.
    -o        Specify output file.
    -f        Specify input format (Disk|RAW|XML).
    -t        Specify output format (Disk|RAW|XML).
    
    --help    Print this documentation
END
    
    print "Unknown option: @_\n" if ( @_ );
    print "$usage\n";
    exit;
}

sub convert {
    my ($in, $out, $from, $to) = @_;
    print "START\n";
    my $parser = "MAB2::Parser::$from"->new( $in );
    my $writer;
    if ($to eq 'XML') {
        $writer = MAB2::Writer::XML->new( file => $out, xml_declaration => 1, collection => 1 );
        $writer->start();
    }
    else{
        $writer = "MAB2::Writer::$to"->new( file => $out );
    
    }
    while ( my $record = $parser->next() ) {
        $writer->write($record);        
    }
    $writer->end() if $to eq 'XML';
    print "DONE\n";
}

__END__

=pod

=encoding UTF-8

=head1 NAME

mab2_convert.pl - converter for MAB2 formats

=head1 SYNOPSIS

    Usage: mab2_convert.pl -i mab2raw.dat -o mab2xml.xml -f RAW -t XML

    Description: Convert records from one MAB2 format to an other.

    Options:
        -i        Specify input file.
        -o        Specify output file.
        -f        Specify input format (Disk|RAW|XML).
        -t        Specify output format (Disk|RAW|XML).
        
        --help    Print this documentation

=head1 AUTHOR

Johann Rolschewski <jorol@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Johann Rolschewski.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
