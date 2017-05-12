#!/usr/bin/perl -w
#!/usr/bin/perl -d:ptkdb -w
#

package Data::Utilities;


use strict;


BEGIN
{
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    $VERSION     = '0.04';
    @ISA         = qw(Exporter);
    #Give a hoot don't pollute, do not export more than needed by default
    @EXPORT      = qw();
    @EXPORT_OK   = qw();
    %EXPORT_TAGS = ();
}


use Data::Comparator;
use Data::Differences;
use Data::Merger;
use Data::Transformator;


sub new
{
    my ($class, %parameters) = @_;

    my $self = bless ({}, ref ($class) || $class);

    return $self;
}


=head1 NAME

Data::Utilities - General utilities for nested perl data structures.

=head1 SYNOPSIS

    use Data::Utilities;

    my $tree
	= {
	   a1 => {
		  a1 => '-a11',
		  a2 => '-a12',
		 },
	   a2 => {
		  a1 => '-a21',
		  a2 => '-a22',
		 },
	  };

    my $expected_data
	= {
	   a1 => {
		  a2 => '-a12',
		 },
	  };

    my $transformation
	= Data::Transformator->new
	    (
	     apply_identity_transformation => {
					       a1 => {
						      a2 => 1,
						     },
					      },
	     contents => $tree,
	     name => 'test_transform5',
	    );

    my $transformed_data = $transformation->transform();

    use Data::Dumper;

    print Dumper($transformed_data);

    my $differences = data_comparator($transformed_data, $expected_data);

    if ($differences->is_empty())
    {
	print "$0: extraction ok\n";
    }
    else
    {
	print "$0: extraction failed\n";
    }


=head1 DESCRIPTION

Data::Utilities contains general tools to transform, merge, compare
nested perl data structures.  See the documentation of the modules in
this package as indicated below.

=head1 USAGE

There are more documentation comments in Data::Transformator, for the
moment I have no time to write better documentation than this.  The
best way to learn how to use it, is to take a look at the test cases.

The Neurospaces project (L<http://www.neurospaces.org/>) makes heavy
use of these utilities.  So you can find some examples overthere to,
especially in the test framework.

=head1 AUTHOR

    Hugo Cornelis
    CPAN ID: CORNELIS
    Neurospaces Project
    hugo.cornelis@gmail.com
    http://www.neurospaces.org/

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

Data::Comparator(3), Data::Merger(3), Data::Transformator(3),
Data::Differences(3).

=cut

#################### main pod documentation end ###################


1;
# The preceding line will help the module return a true value

