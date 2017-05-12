package Apache2::Pod;

=head1 NAME

Apache2::Pod - base class for converting Pod files to prettier forms

=head1 VERSION

Version 0.27

=cut

use vars qw( $VERSION );
use strict;

$VERSION = '0.27';

=head1 SYNOPSIS

The Apache2::Pod::* are mod_perl handlers to easily convert Pod to HTML
or other forms.  You can also emulate F<perldoc>.

=head1 CONFIGURATION

All configuration is done in one of the subclasses.

=head1 TODO

I could envision a day when the user can specify which output format
he'd like from the URL, such as

    http://your.server/perldoc/f/printf?rtf

=head1 FUNCTIONS

No functions are exported.  I don't want to dink around with Exporter
in mod_perl if I don't need to.

=head2 getpodfile( I<$r> )

Returns the filename requested off of the C<$r> request object, or what
Perldoc would find, based on Pod::Find.

=head2 resolve_modname( I<$r> )

Returns a module name based on C<< $r->path_info >>.

=head2 getpodfuncdoc( I<$file>, I<$function_name> )

Given the full filepath of the C<perlfunc> pod file and a function name,
returns the section of that pod document pertaining to the function.  If
the function is not found, returns a pod document phrase stating so.

=cut

use Pod::Find;
use Carp ();

sub getpodfile {
	my $r = shift;

	my $filename;

	if ($r->filename =~ m/\.pod$/i) {
		$filename = $r->filename;
	} 
	else {
		my $module = resolve_modname( $r );
		if ( $module =~ /^f::/ ) {
			$module =~ s/^f:://;
			$filename = "-f<$module>::" . Pod::Find::pod_where( {-inc=>1}, "perlfunc" );
		}
		else {
			$filename = Pod::Find::pod_where( {-inc=>1}, $module );
		}
	}

	return $filename;
}

sub resolve_modname {
	my ( $r ) = @_;
	my $module = $r->path_info;
	$module =~ s|/||;
	$module =~ s|/|::|g;
	$module =~ s|\.html?$||;  # Intermodule links end with .html
	return $module;
}

sub getpodfuncdoc {
	my ( $file, $fun ) = @_;
	# Functions like -r, -e, etc. are listed under `-X'.
	my $search_re = ($fun =~ /^-[rwxoRWXOeszfdlpSbctugkTBMAC]$/)
		? '(?:I<)?-X' : quotemeta($fun) ;
	my $document = '';
	# TODO:  Handle error on open gracefully.
	open(PFUNC, "<$file") || Carp::croak "Can't open $file: $!";
	# Skip introduction
	local $_;
	while ( <PFUNC> ) {
		last if /^=head2 Alphabetical Listing of Perl Functions/;
	}
	
	# Look for our function
	my $found = 0;
	my $inlist = 0;
	while ( <PFUNC> ) {  # "The Mothership Connection is here!"
		if ( m/^=item\s+$search_re\b/ )  {
			$found = 1;
		}
		elsif (/^=item/) {
			last if $found > 1 and not $inlist;
		}
		next unless $found;
		if (/^=over/) {
			++$inlist;
		}
		elsif (/^=back/) {
			--$inlist;
		}
		$document .= "$_";
		++$found if /^\w/;        # found descriptive text
	}
	# TODO:  Handle error on open/close gracefully.
	close PFUNC or Carp::croak "Can't open $file: $!";
	if ( ! $document ) {
		$document = sprintf "=item %s\n\nNo documentation for perl function '%s' found\n", $fun, $fun; # no $fun
	}
	return $document;
}
1;

=head1 SEE ALSO

L<Apache2::Pod::HTML>, 
L<Apache2::Pod::Text>, 

=head1 AUTHOR

Theron Lewis C<< <theron at theronlewis dot com> >>

=head1 HISTORY

Adapteded from Andy Lester's C<< <andy at petdance dot com> >> Apache::Pod
package which was adapted from 
Apache2::Perldoc by Rich Bowen C<< <rbowen@ApacheAdmin.com> >>

=head1 ACKNOWLEDGEMENTS

Thanks also to
Pete Krawczyk,
Kjetil Skotheim,
Kate Yoak
and
Chris Eade
for contributions.

=head1 LICENSE

This package is licensed under the same terms as Perl itself.

=cut
