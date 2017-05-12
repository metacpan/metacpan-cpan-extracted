#!/usr/local/bin/perl

# vim: tw=78: sw=4: ts=4: et: 

# $Id: genbank-parser.pl 9 2008-01-28 20:08:45Z kyclark $

use strict;
use warnings;
use Bio::GenBankParser;
use English qw( -no_match_vars );
use File::Basename;
use Getopt::Long;
use Pod::Usage;
use Readonly;
use YAML qw( Dump );

Readonly my $VERSION => qq$Revision: 9 $ =~ /(\d+)/;

my ( $help, $man_page, $show_version );
GetOptions(
    'help'    => \$help,
    'man'     => \$man_page,
    'version' => \$show_version,
) or pod2usage(2);

if ( $help || $man_page ) {
    pod2usage({
        -exitval => 0,
        -verbose => $man_page ? 2 : 1
    });
}; 

if ( $show_version ) {
    my $prog = basename( $PROGRAM_NAME );
    print "$prog v$VERSION\n";
    exit 0;
}

my @files  = @ARGV or pod2usage('No input files');
my $parser = Bio::GenBankParser->new;

my ( $num_files, $num_seq ) = ( 0, 0 );
for my $file ( @files ) {
    $num_files++;
    $parser->file( $file );

    while ( my $seq = $parser->next_seq ) {
        $num_seq++;
        print Dump( $seq );
    }
}

printf STDERR "Done, processed %s sequence%s in %s file%s.\n",
    $num_seq,
    $num_seq   == 1 ? '' : 's',
    $num_files,
    $num_files == 1 ? '' : 's';

__END__

# ----------------------------------------------------

=pod

=head1 NAME

genbank-parser.pl - parse GenBank records into YAML

=head1 VERSION

This documentation refers to version $Revision: 9 $

=head1 SYNOPSIS

  genbank-parser.pl file1.seq [file2.seq ...]

Options:

  --help        Show brief help and exit
  --man         Show full documentation
  --version     Show version and exit

=head1 DESCRIPTION

This is little more than an example showing a trivial use of 
Bio::GenBankParser.  Here we convert a stream of files into YAML
on STDOUT.

=head1 SEE ALSO

Bio::GenBankParser, YAML.

=head1 AUTHOR

Ken Youens-Clark E<lt>kclark@cpan.orgE<gt>.

=head1 COPYRIGHT

Copyright (c) 2008 Cold Spring Harbor Laboratory

This module is free software; you can redistribute it and/or
modify it under the terms of the GPL (either version 1, or at
your option, any later version) or the Artistic License 2.0.
Refer to LICENSE for the full license text and to DISCLAIMER for
additional warranty disclaimers.

=cut
