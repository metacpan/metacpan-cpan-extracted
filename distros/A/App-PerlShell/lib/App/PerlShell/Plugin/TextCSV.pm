package App::PerlShell::Plugin::TextCSV;

########################################################
# AUTHOR = Michael Vincent
# www.VinsWorld.com
########################################################

use strict;
use warnings;
use Pod::Usage;
use Pod::Find qw( pod_where );

eval "use Text::CSV";
if ($@) {
    print "Text::CSV required.\n";
    return 1;
}

use Exporter;

our @EXPORT = qw(
  TextCSV
  textcsv
);

our @ISA = qw ( Exporter );

sub TextCSV {
    pod2usage(
        -verbose => 2,
        -exitval => "NOEXIT",
        -input   => pod_where( {-inc => 1}, __PACKAGE__ )
    );
}

########################################################

sub textcsv {
    my ( $file, $params ) = @_;

    if ( not defined $file ) {
        print "file required\n";
        return;
    }
    if ( not defined $params ) {
        $params = {};    
    }

    my $csv = Text::CSV->new( $params )
      or die Text::CSV->error_diag;

    open my $fh, "<", $file
      or die "$!";

    my @rets;
    my $retType = wantarray;
    my ( $line, $skip ) = ( 0, 0 );
    while ( my $row = $csv->getline($fh) ) {
        $line++;       # for error message if needed
        push @rets, $row;
    }
    if ( not $csv->eof ) {
        my ( $cde, $str, $pos ) = $csv->error_diag;
        print "$line,$pos: ($cde) $str\n";
    }

    close $fh;

    if ( not defined($retType) ) {
        for ( @rets ) {
            print join $csv->sep_char, @{$_};
            print "\n";
        }
        return
    } elsif ($retType) {
        return @rets;
    } else {
        return \@rets;
    }
}

1;

__END__

=head1 NAME

TextCSV - Read file with Text::CSV

=head1 SYNOPSIS

 use App::PerlShell::Plugin::TextCSV;

=head1 DESCRIPTION

This module implements easy reading of comma separated value files 
with B<Text::CSV>.

=head1 COMMANDS

=head2 TextCSV - provide help

Provides help.

=head1 METHODS

=head2 textcsv - read CSV file

 [@csv =] textcsv file [Text::CSV OPTIONS];

Given B<file>, read in as CSV and return fields to screen or in optional 
array.  B<File> must be first argument, see B<Text::CSV> for additional 
options and syntax.

=head1 EXAMPLES

  use App::PerlShell::Plugin::TextCSV;
  @csv = textcsv 'file.csv', {binary => 1};
  print Dumper \@csv;
  
  print $csv[0]->[1]; # print value at first column, second row

=head1 SEE ALSO

L<Text::CSV>

=head1 LICENSE

This software is released under the same terms as Perl itself.
If you don't know what that means visit L<http://perl.com/>.

=head1 AUTHOR

Copyright (c) 2017 Michael Vincent

L<http://www.VinsWorld.com>

All rights reserved

=cut
