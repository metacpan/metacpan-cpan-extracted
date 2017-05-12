use 5.010000;
use warnings;
use strict;
use Perl::MinimumVersion;
use Perl::Version;
use File::Find;
use Test::More;


my $make_minimum;
open my $fh_m, '<', 'Makefile.PL' or die $!;
while ( my $line = <$fh_m> ) {
    if ( $line =~ /^\s*MIN_PERL_VERSION\s*=>\s*'([^']+)',/ ) {
        my $version   = Perl::Version->new( $1 );
        my $numified  = $version->numify;
        $make_minimum  = $numified;
        last;
    }
}
close $fh_m or die $!;


#my $pod1_minimum;
#open my $fh_p1, '<', 'lib/App/DBBrowser.pm' or die $!;
#while ( my $line = <$fh_p1> ) {
#    if ( $line =~ /^=head1\sREQUIREMENTS/ .. $line =~ /^=head1\sAUTHOR/ ) {
#        if ( $line =~ /Perl\sversion\s(5\.\d\d?\.\d+)\s/ ) {
#            my $version    = Perl::Version->new( $1 );
#            my $numified   = $version->numify;
#            $pod1_minimum  = $numified;
#            last;
#        }
#    }
#}
#close $fh_p1 or die $!;


my $pod2_minimum;
open my $fh_p2, '<', 'bin/db-browser' or die $!;
while ( my $line = <$fh_p2> ) {
    if ( $line =~ /^=head2\s+Perl\s+version/ .. $line =~ /^=head2\s+Modules/ ) {
        if ( $line =~ /(5\.\d\d?\.\d+)\s/ ) {
            my $version    = Perl::Version->new( $1 );
            my $numified   = $version->numify;
            $pod2_minimum  = $numified;
            last;
        }
    }
}
close $fh_p2 or die $!;


my @files;
for my $dir ( 'bin', 'lib', 't' ) {
    find( {
        wanted => sub {
            my $file = $File::Find::name;
            return if ! -f $file;
            push @files, $file;
        },
        no_chdir => 1,
    }, $dir );
}
my %explicit_minimum;
for my $file ( @files ) {
    my $object    = Perl::MinimumVersion->new( $file );
    my $min_exp_v = $object->minimum_explicit_version;
    my $version   = Perl::Version->new( $min_exp_v );
    my $numified  = $version->numify;
    $explicit_minimum{$numified}++;
}
my ( $explicit_minimum ) = keys %explicit_minimum;


cmp_ok( $make_minimum, '==', $explicit_minimum,  'perl minimum version in Makefile.PL == explicit perl minimum version' );
#cmp_ok( $make_minimum, '==', $pod1_minimum,      'perl minimum version in Makefile.PL == pod1 perl minimum version' );
cmp_ok( $make_minimum, '==', $pod2_minimum,      'perl minimum version in Makefile.PL == pod2 perl minimum version' );

done_testing;
