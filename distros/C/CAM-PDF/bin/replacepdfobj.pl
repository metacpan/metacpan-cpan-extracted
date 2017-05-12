#!/usr/bin/perl -w

package main;

use warnings;
use strict;
use CAM::PDF;
use Getopt::Long;
use Pod::Usage;

our $VERSION = '1.60';

my %opts = (
            follow     => 0,
            verbose    => 0,
            order      => 0,
            help       => 0,
            version    => 0,
            );

Getopt::Long::Configure('bundling');
GetOptions('f|follow'     => \$opts{follow},
           'v|verbose'    => \$opts{verbose},
           'o|order'      => \$opts{order},
           'h|help'       => \$opts{help},
           'V|version'    => \$opts{version},
           ) or pod2usage(1);
if ($opts{help})
{
   pod2usage(-exitstatus => 0, -verbose => 2);
}
if ($opts{version})
{
   print "CAM::PDF v$CAM::PDF::VERSION\n";
   exit 0;
}

if (@ARGV < 4)
{
   pod2usage(1);
}

my @files;
my @nums;
my @docs;

push @files, shift;
push @nums, shift;
push @files, shift;
push @nums, shift;
my $outfile = shift || q{-};

foreach my $file (@files)
{
   my $doc = CAM::PDF->new($file) || die "$CAM::PDF::errstr\n";
   push @docs, $doc;
}

if (!$opts{follow})
{
   warn "Warning: if the object from doc2 has references, they may be broken by this process!\n" .
        "Use -f to follow and copy all references\n";
}
if ($nums[0] eq 'a')
{
   my $key = $docs[0]->appendObject($docs[1], $nums[1], $opts{follow});
   warn "Appended as object $key\n";
}
else
{
   $docs[0]->replaceObject($nums[0], $docs[1], $nums[1], $opts{follow});
}
if ($opts{order})
{
   $docs[0]->preserveOrder();
}
if (!$docs[0]->canModify())
{
   die "This PDF forbids modification\n";
}
$docs[0]->cleanoutput($outfile);


__END__

=for stopwords replacepdfobj.pl

=head1 NAME

replacepdfobj.pl - Copy a metadata object from one PDF to another

=head1 SYNOPSIS

 replacepdfobj.pl [options] mainfile.pdf objnum objfile.pdf objnum [outfile.pdf]\n";

 Options:
   -f --follow         copy referenced objects too
   -o --order          preserve the internal PDF ordering for output
   -v --verbose        print diagnostic messages
   -h --help           verbose help message
   -V --version        print CAM::PDF version

=head1 DESCRIPTION

Copy an object (and perhaps it's referenced children) from one PDF to
another.  This is a rather low-level utility that will not be of
interest to most users.

=head1 SEE ALSO

CAM::PDF

=head1 AUTHOR

See L<CAM::PDF>

=cut
