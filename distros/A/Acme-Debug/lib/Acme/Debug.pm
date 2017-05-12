#
# $Id: $
#
=head1 Name

Acme::Debug - A handy module to identify lines of code where bugs may be found.

=cut

package Acme::Debug;

use 5.008000;
use Data::Dumper;
use File::Spec;
use strict;
use warnings;

use vars qw($VERSION);
$VERSION = do { my @r = (q$Revision: 1.48 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

=head1 Usage

=over 4

=item perl -d -MAcme::Debug program args

This will report only those lines of code which are buggy as the program
actually executes.

=back

Output goes to C<STDERR> so if you program produces much output on C<STDOUT>
for instance, you might wish to put it somewhere else:

	perl -d -MAcme::Debug program args 1> /dev/null

=cut

require Exporter;
our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw( ) ] ); # use Acme::Debug ':all';
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw( );
our $VERSION = '0.01';

my $debug   = $ENV{Acme_Debug_DEBUG}   || 0;
my $silent  = $ENV{Acme_Debug_SILENT}  || 0;
my $verbose = $ENV{Acme_Debug_VERBOSE} || 0;
my $bug     = $ENV{Acme_Debug_REGEX}   || 'b[^u]*u[^g]*g';

# sub acme_debug = \&DB::DB;

=head1 Environment Variables

These boolean variables may be set to divulge more information.

=over 4

=item Acme_Debug_DUMP

Print the actual buggy lines.

=back

=cut

#=item perl -MAcme::Debug -e 'Acme::Debug->new("program")';

#This will parse every line of the files/s given.

#=cut

sub new { 
	my $proto = shift;
	my $class = ref($proto) ? ref($proto) : $proto;
	my $self  = {};
	bless($self, $class);
	foreach my $f (@_) {
		next unless -f $f;
		my $l = 0;
		if (open(FH, "< $f")) {
			map { DB::DB($f, $l, $_), $l++ } (<FH>);
		} else {
			die("unable to open file $f! $!\n");
		}
	}
	return $self;
}

1;

package DB;
no strict qw(refs);
no warnings;
my $i = my $i_bugs = 0;
my @bugs = ();

sub DB::DB {
	$i++;
	my ($p,$f,$l) = caller;
	if ($f =~ /Acme.Debug.pm/) {
		$f = shift;
		$l = shift;
	}
	my $line = @{"::_<$f"}[$l] || shift;
	my ($v, $d, $x) = File::Spec->splitpath($f);
	# if ($line =~ /b[^u]*u[^g]*g/mi) {
	if ($line =~ /$bug/mi) {
		$i_bugs++;
		unless ($f =~ /perl5db.pl/) {
			push(@bugs, ($debug?"[$i]":'')."  line $l of $x: $line");
		}
	}
}

sub END {
	use Data::Dumper;
	print STDERR "bug free lines:   ".($i-$i_bugs)."\n";
	print STDERR "BUGgy code lines: $i_bugs\n";
	print STDERR @bugs if $verbose;
}

1;

=head1 AUTHOR

Richard Foley, E<lt>acme.debug@rfi.net<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Richard Foley

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
