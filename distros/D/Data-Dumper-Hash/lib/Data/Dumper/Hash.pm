package Data::Dumper::Hash;
use strict;
use warnings;
require Exporter;
use vars qw/@ISA @EXPORT @EXPORT_OK/;
our $VERSION = '1.0'; 
@ISA = qw/Exporter/;
@EXPORT = qw/Dump/;
@EXPORT_OK = qw/Dump/;


use Data::Dumper;

sub Dump {
	my @params = @_;
	my @vals = ();
	my @names = ();

    for my $i (0 .. $#params) {
        if (mod($i/2)) {
            push(@vals, $params[$i]);
        }
        else {
            push(@names, $params[$i]);
        }
	}
	return Data::Dumper->Dump(\@vals, \@names);
}
1;
__END__

=head1 NAME

Data::Dumper::Hash

=head1 DESCRIPTION

This is a simple utility module to make dumping data structures easier.
The standard Data::Dumper module has a awkward interface when you want to have sensible names output rather than the default VAR1, VAR2 etc



=head1 SUBROUTINES 

=head2 Dump

The only export from this module to which you pass a hash -
the keys being the names of the variables and the values being the actual value to be dumped
so you use it like this

 print Dump(variable => <value>, anothervariable => <value2>);

 e.g.
 print Dump(data => $data, hash => \%hash);

=head1 Return value

The dumped data structure

=head1 AUTHOR

Tony Edwardson <tony@edwardson.co.uk>

=head1 LICENSE AND COPYRIGHT

 (c) 2015 Tony Edwardson
 All Original Content (c) 2015 Tony Edwardson
 Site Contents/Photography (c) 2015 Tony Edwardson
 All Original Content (c) 2015 Tony Edwardson, All Rights Reserved

=cut

