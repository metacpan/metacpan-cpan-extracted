#!/usr/bin/perl -w

use strict;

use lib '../lib';
use Getopt::Long;
use LWP::Simple;
use Pod::Usage;
use GraphViz;
use XML::XPath;

sub depends {
	my ($xp, $os, $pkg) = @_;
	$os = lc $os;
	my $nodeset = $xp->find("/REPOSITORYSUMMARY/SOFTPKG[\@NAME='$pkg']/IMPLEMENTATION/DEPENDENCY[../OS/\@NAME='$os']/\@NAME");
	return map { $xp->findvalue('.', $_) } $nodeset->get_nodelist;

}

sub process {
	my $xp   = shift;
	my $os   = shift;
	my $deps = shift;
	for my $pkg (@_) {
		next if $deps->{$pkg};  # check here since it might have been done in a recursive call
		my @deps = depends($xp, $os, $pkg);
		$deps->{$pkg} = [ @deps ];
		process($xp, $os, $deps, @deps);
	}
	return $deps;
}

our $VERSION='0.01';

my %opts = (
    help     => 0,
    man      => 0,
    verbose  => 0,
    os       => '',
    pkg      => '',
);

GetOptions(\%opts, qw(
    help
    man
    verbose
    os=s
    pkg=s
)) || pod2usage(2);

pod2usage(1) if     $opts{help};
pod2usage(-exitstatus => 0, -verbose => 2) if $opts{man};
pod2usage(1) unless $opts{pkg};
$opts{os}  ||= 'linux';
$opts{pkg} =~ s/::/-/g;

mirror("http://www.activestate.com/PPMPackages/5.6plus/package.lst", "package.lst") unless -f "package.lst";
my $xp = XML::XPath->new(filename => 'package.lst');
my $deps = process($xp, $opts{os}, {}, $opts{pkg});

my $g = GraphViz->new();

for my $pkg (keys %$deps) {
	$g->add_node($pkg);
	for my $dep (@{ $deps->{$pkg} }) {
		$g->add_edge($pkg => $dep);
	}
}

print $g->as_png;

__END__

=head1 NAME

ppmgraph.pl - graph CPAN tarball dependencies

=head1 SYNOPSIS

ppmgraph.pl -os=linux -pkg=Class-DBI >class-dbi.png

=head1 DESCRIPTION

This program takes Activestate's package list (download it from
http://www.activestate.com/PPMPackages/5.6plus/package.lst), which is in
XML format, and uses it to determine dependencies between packages. It
then hands over those dependencies to GraphViz. The resulting graph is
output in PNG format on STDOUT.

Note that this means that dependencies of modules within the tarballs
can't be determined this way, only dependencies between the tarballs
themselves. For these purposes, there will be programs to graph
dependencies between installed modules and the runtime @ISA hierarchy.

=head1 OPTIONS

This section describes the supported command line options. Minimum
matching is supported.

=over 4

=item B<--pkg>

Mandatory option to specify which package to graph the dependency
for. This can be either the name of the module (e.g. C<Class::DBI>)
or the name of the tarball sans version number (e.g. C<Class-DBI>). In
any case, the graph will display tarball names as the node labels,
since that's what's contained in the XML file.

=item B<--os>

Which Operating System to graph the dependency for. At the moment,
ActiveState defines "linux", "solaris" and "MSWin32". If not given,
this option defaults to "linux".

=item B<--help>

Print a brief help message and exit.

=item B<--man>

Print the manual page and exit.

=item B<--verbose>

Print information messages as we go along.

=back

=head1 BUGS

Some. Possibly. I haven't fully tested it. Also, a performance
problem. The package XML file is over a meg, and performance suffers. At
the moment, this is of no concern, but I might switch over to PerlSAX
later. I'm using XPath at the moment since I'm familiar with it.

=head1 AUTHOR

Marcel GrE<uuml>nauer E<lt>marcel@codewerk.comE<gt>

=head1 COPYRIGHT

Copyright 2000 Marcel GrE<uuml>nauer. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

GraphViz(3pm)

=cut
