package Bio::PhyloTastic;
use strict;
use warnings;
use Pod::Usage 'pod2usage';
use Getopt::Long;
use Data::Dumper;
use Bio::Phylo::Factory;
use Bio::Phylo::Util::Logger;
use Bio::Phylo::IO qw'parse unparse';
use Bio::Phylo::Util::Exceptions 'throw';

=head1 NAME

Bio::PhyloTastic - Perl clients for PhyloTastic

=head1 DESCRIPTION

PhyloTastic (L<http://phylotastic.org>) is community effort to develop
interoperable tools for pruning and annotating phylogenetic megatrees. This
package contributes to that effort by providing simple client access to web
services that perform steps in the pipeline. The functionality of these clients
readily available using the C<phylotastic> command line utility that comes with
this distribution.

The basic usage is:

 $ phylotastic ModuleName <args>

Where C<ModuleName> is the last part of the package name of one of the client
classes (e.g. C<BabelPhysh>). The command line arguments of these classes are
somewhat variable, though they typically take one or more C<--infile=filename>
arguments and an C<--outfile=filename> argument. For the other arguments you
can consult the usage message for each module as follows:

 $ phylotastic ModuleName --help

The full documentation for each module (such as it is), can be viewed like this:

 $ phylotastic ModuleName --man

For more verbose output during the execution of a module, provide the
C<--verbose> flag with a numerical argument (0 = only fatal message, 1 = error,
2 = warn, 3 = info, 4 = debug).

 $ phylotastic ModuleName --verbose=4 <args>

=head1 SEE ALSO

The following client classes are currently available.

=over

=item L<Bio::PhyloTastic::BabelPhysh>

File translation.

=item L<Bio::PhyloTastic::DateLife>

Divergence date estimation.

=item L<Bio::PhyloTastic::PhyleMerge>

File merging.

=item L<Bio::PhyloTastic::PruneOMatic>

Tree pruning.

=item L<Bio::PhyloTastic::TaxTractor>

Extracts taxon labels from files.

=item L<Bio::PhyloTastic::TNRS>

Taxonomic name resolution service.

=item L<Bio::Phylo::IO>

Reading and writing of all data is done using L<Bio::Phylo::IO>, which uses
the deserializers in the Bio::Phylo::Parsers namespace and the serializers in
the Bio::Phylo::Unparsers namespace. Consequently, the input formats that are
available are the ones that Bio::Phylo supports.

=back

In addition, work is under way to develop Galaxy config files that wrap these
classes so they are available from within Galaxy (L<http://usegalaxy.org>).
These config files can be found here:
L<https://github.com/phylotastic/arch-galaxy/tree/master/galaxy>

=cut

# release number
our $VERSION = '0.2';

# Bio::Phylo::Util::Logger
my $log;
sub _log { $log }

# instantiate factory
my $fac = Bio::Phylo::Factory->new;
sub _fac { $fac };

# returns a hash for Getopt::Long
my @infile;
my @deserializer;
my ( $outfile, $serializer, $verbose, $help, $man );
sub _get_default_args {	
	return (
		'infile=s'       => \@infile,
		'deserializer=s' => \@deserializer,
		'serializer=s'   => \$serializer,
		'outfile=s'      => \$outfile,
		'verbose=i'      => \$verbose,
		'help+'          => \$help,
		'man+'           => \$man,
	);
}

# gets child class arguments
sub _get_args {
	my $class = shift;
	$log->info(ref($class). ' did not specify additional arguments');
	return ();
}

# runs the child class, receives list of projects, returns project
sub _run {
	throw 'NotImplemented' => "Not implemented!";
}

sub _pod2usage {
	my ( $class, $man ) = @_;
	my $inc = $class;
	$inc =~ s/::/\//g;
	$inc .= '.pm';
	my $fullpath = $INC{$inc};
	pod2usage({
		'-exitval' => 1,
		'-verbose' => $man ? 2 : 1,
		'-input'   => $fullpath,
	});
}

=head1 METHODS

This distribution can actually also be used within scripts or modules. The
basic idea is to invoke C<run> on a service package name, with named arguments
(i.e. key value pairs) that match those as required on the command line.
The following example of this behaviour writes the input NeXML file $infile
as NEXUS to $outfile:

 Bio::PhyloTastic::BabelPhysh->run(
	'-infile'       => $infile,
	'-deserializer' => 'nexml',
	'-outfile'      => $outfile,
	'-serializer'   => 'nexus',
 );

=over

=item run

The C<run> method is a static method, i.e. called on the package, like so:

 Bio::PhyloTastic::ModuleName->run(%args);

The implementation in this superclass does argument checking and input file
parsing before it dispatches the parsed data to an implementing method in the
child class called C<_run>. That implementing method returns a
L<Bio::Phylo::Project> object that is subsequently serialized here.

=back

=cut

sub run {
	my $class = shift;
	my %args = ( $class->_get_default_args, $class->_get_args );
	push @ARGV, @_;
	
	# process arguments
	GetOptions(%args);
	
	# print help?
	$class->_pod2usage($man) if $help or $man;
	
	# instantiate logger
	$log = Bio::Phylo::Util::Logger->new(
		'-level' => $verbose,
		'-class' => $class,
	);
	$log->VERBOSE( '-level' => $verbose, '-class' => __PACKAGE__ );
	my $file = __FILE__;
	$file =~ s/Bio\/PhyloTastic\.pm$//;
	$log->PREFIX($file);
	$log->debug("instantiated logger");
	
	# parse projects
	my @projects;
	for my $i ( 0 .. $#{ $args{'infile=s'} } ) {
		push @projects, parse(
			'-format'     => $args{'deserializer=s'}->[$i],
			'-file'       => $args{'infile=s'}->[$i],
			'-as_project' => 1,
		);
	}
	
	# run child class
	$log->debug("going to run $class->_run");
	my $project = $class->_run(@projects);
	
	# client wants stringified
	if ( ${ $args{'outfile=s'} } ) {
		my $string = unparse(
			'-format' => ${ $args{'serializer=s'} },
			'-phylo'  => $project,
		);
		
		# to standard out
		if ( ${ $args{'outfile=s'} } eq '-' ) {
			print $string;
		}
		
		# to file
		else {
			open my $fh, '>', ${ $args{'outfile=s'} } or die $!;
			print $fh $string;
		}
	}
	else {
		return $project;
	}
}

1;