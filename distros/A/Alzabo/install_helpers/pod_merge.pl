#!/usr/bin/perl -w

use strict;

use File::Basename;
use File::Copy;
use File::Path;
use File::Spec;

my ($sourcedir, $libdir, $verbose) = @ARGV;

foreach ($sourcedir, $libdir) { s,/$,,; }

foreach ( qw( Schema Table Column ColumnDefinition Index ForeignKey ) )
{
    my $from = File::Spec->catfile( $sourcedir, 'Alzabo', "$_.pm" );

    foreach my $class ( qw( Create Runtime ) )
    {
	my $merge = File::Spec->catfile( $sourcedir, 'Alzabo', $class, "$_.pm" );
	my $to = File::Spec->catfile( $libdir, 'Alzabo', $class, "$_.pm" );
	merge( $from, $merge, $to, $class );
    }
}

merge( File::Spec->catfile( $sourcedir, 'Alzabo.pm' ),
       File::Spec->catfile( $sourcedir, 'Alzabo', 'QuickRef.pod' ),
       File::Spec->catfile( $libdir, 'Alzabo', 'QuickRef.pod' ),
     );

sub merge
{
    my ($file, $t_in, $t_out, $class) = @_;

    local (*FROM, *TO);
    open FROM, $file or die "Can't read '$file': $!";
    open TO, $t_in or die "Can't read '$t_in': $!";

    my $from = join '', <FROM>;
    my $to = join '', <TO>;

    close FROM or die "Can't close '$file': $!";
    close TO or die "Can't close '$t_in': $!";

    $to =~ s/\r//g;
    $to =~ s/\n
             =for\ pod_merge   # find this string at the beginning of a line
             (?:
              \s+
              (\w+)            # say what POD marker to merge from
             )
             (?:
              \ +
              (\w+)            # optionally, say what POD marker to merge until (i.e. =head3)
             )?
             .*?               # what we're going to merge (and replace)
             \n+
             (?=
              \n=              # next =foo marker, skipping all spaces.  This just makes matching stop here
             )
             /
              find_chunk($file, $from, $class, $1, $2)
             /gxie;

    mkpath( dirname($t_out) ) unless -d dirname($t_out);

    if (-e $t_out)
    {
	chmod 0644, $t_out or die "Can't chmod '$t_out' to 644: $!";
    }
    open TO, ">$t_out" or die "Can't write to '$t_out': $!";
    print TO $to or die "Can't write to '$t_out': $!";
    close TO or die "Can't write to '$t_out': $!";
    chmod 0644, $t_out or die "Can't chmod '$t_out' to 444: $!";

    for ( $file, $t_out ) { s,^.*(?=Alzabo),,; s/\.pm$//; s,[\\/],::,g; }

    print "merged $file docs into $t_out\n" if $verbose;
}

sub find_chunk
{
    my ($file, $from, $class, $title, $until) = @_;

    my $chunk;
    if ($title eq 'merged')
    {
	$chunk = "\n\nNote: all relevant documentation from the superclass has been merged into this document.\n";
    }
    else
    {
        if ( my ($l) = $from =~ /\n=head([1234]) +$title.*?\n/ )
	{
	    my $levels = join '', (1..$l);
	    my $until_re = $until ? qr/$until/ : qr/(?:head[$levels]|cut)/;
	    my $re = qr/(\n=head$l +$title.*?)\n=$until_re/s;
	    ($chunk) = $from =~ /$re/;
	}
    }

    if (defined $class)
    {
	$chunk =~ s/Alzabo::(Column|ColumnDefinition|ForeignKey|Index|Schema|Table)/Alzabo::$class\::$1/g;
    }

    die "Can't find =headX $title in $file\n" unless $chunk;
    return $chunk;
}
