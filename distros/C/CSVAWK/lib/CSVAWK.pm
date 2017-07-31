package CSVAWK; # git description: 0.0.1-2-g2eeca26

use strict;
use warnings;

use autodie;
use charnames qw(:full);
use English qw(-no_match_vars);
use File::Basename;
use File::Temp qw(tempdir tempfile);
use Readonly;
use Text::CSV_XS;

use base 'Exporter';
our @EXPORT_OK = qw(csvawk);

our $VERSION = '0.1';

Readonly my $HIDE_FS                  => "\N{INFORMATION SEPARATOR ONE}";
Readonly my $HIDE_RS                  => "\N{INFORMATION SEPARATOR TWO}";
Readonly my %SWITCHES_WITH_PARAMETERS => map { $_ => 1 } qw(
  -f --file
  -F --field-separator
  -v --assign
  -m
  -e --source
  -E --exec
  -i --include
  -l --load
  -W
);
Readonly my $IS_PROGRAM_SWITCH => qr/^-[ef]/mxs;

sub convert_to_identifier {
    my ($str) = @_;
    $str =~ s/\W+/_/mxsg;
    if ( $str !~ m/^[[:alpha:]_]/mxs ) {
        $str = "_$str";
    }
    return $str;
}

sub get_csv_parser {
    my $csv = Text::CSV_XS->new(
        {
            binary    => 1,
            auto_diag => 1,
            eol       => "\n",
        }
    );

    return $csv;
}

sub hide_separators {
    my ($str) = @_;
    $str =~ s/,/$HIDE_FS/mxsg;
    $str =~ s/\n/$HIDE_RS/mxsg;
    return $str;
}

sub restore_separators {
    my ($str) = @_;
    $str =~ s/$HIDE_FS/,/mxsg;
    $str =~ s/$HIDE_RS/\n/mxsg;
    return $str;
}

sub split_arguments {
    my (@args) = @_;
    my ( @files, $has_program_switch );

  ARGUMENT: for my $arg ( reverse @args ) {
        if ( $arg =~ m/^-/mxs ) {
            if ( exists $SWITCHES_WITH_PARAMETERS{$arg} ) {
                pop @files;
            }
            last ARGUMENT;
        }
        push @files, $arg;
    }

    my @other_args = @args[ 0 .. $#args - $#files - 1 ];
  OTHER_ARGUMENT: for my $arg (@other_args) {
        if ( $arg =~ $IS_PROGRAM_SWITCH ) {
            $has_program_switch = 1;
            last OTHER_ARGUMENT;
        }
    }
    if ( !$has_program_switch ) {
        push @other_args, '-e', pop @files;
    }
    return \@other_args, [ reverse @files ];
}

sub get_variables {
    my ($files) = @_;

    my %results;
    my $csv = get_csv_parser();

    for my $file ( @{$files} ) {
        open my $fh, '<', $file;
        my $headers = $csv->getline($fh);
        $results{$file} = [ map { convert_to_identifier($_) } @{$headers} ];
        close $fh;
    }

    return \%results;
}

sub quote_files {
    my ($in_files) = @_;

    my %file_map;
    my $dir = tempdir();
    my $csv = get_csv_parser();

    for my $in_file ( @{$in_files} ) {
        my ( $out, $out_file ) =
          tempfile( basename($in_file) . '.XXXXXXXX', DIR => $dir );
        $file_map{$in_file} = $out_file;
        open my $in, '<', $in_file;
        while ( my $row = $csv->getline($in) ) {
            for my $field ( @{$row} ) {
                $field = hide_separators($field);
            }
            $csv->print( $out, $row );
        }

        close $in;
        close $out;
    }

    return \%file_map;
}

sub build_library {
    my ( $files, $file_map, $variables ) = @_;
    my ( $fh, $filename ) = tempfile( SUFFIX => '.awk' );

    print { *{$fh} } <<'END_AWK';
BEGIN {
    FS = ","
    OFS = ","
}
FNR == 1 {
END_AWK

    for my $file ( @{$files} ) {
        my $tempfile = $file_map->{$file};
        print { *{$fh} } qq(  if (FILENAME == "$tempfile") {\n);
        my $i = 1;
        for my $variable ( @{ $variables->{$file} } ) {
            print { *{$fh} } "    $variable = $i\n";
            $i++;
        }
        print { *{$fh} } "  }\n";
    }
    print { *{$fh} } "}\n";
    close $fh;

    return $filename;
}

sub csvawk {
    my (@args) = @_;
    my $dirname = dirname(__FILE__);
    my ( $other_args, $files ) = split_arguments(@args);
    my $file_map  = quote_files($files);
    my $variables = get_variables($files);
    my $library   = build_library( $files, $file_map, $variables );

    #<<<
    my @command = (
        'awk',
        '-f',
        $library,
        @{$other_args},
        map { $file_map->{$_} } @{$files},
    );
    #>>>

    open my $output, q(-|), @command;
    while ( my $row = <$output> ) {
        print restore_separators($row);
    }
    close $output;

    return 0;
}

1;

__END__

=pod

=head1 NAME

CSVAWK - Pass CSV files to AWK.


=head1 SYNOPSIS

Given a CSV file that can't be parsed naively

  a,b,"c,d",e
  1,2,3,"4
  5"
  6,7,8,9

the command

  csvawk '$a == 1 { print $b, $c_d }' quux.csv

will return

  2,3


=head1 DESCRIPTION

CSVAWK allows processing CSV files to AWK via a (relatively) thin Perl wrapper.


=head1 AUTHOR

Bryan McKelvey <bryan.mckelvey@gmail.com>


=head1 COPYRIGHT

Copyright (c) 2017 Bryan McKelvey.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module

=cut
