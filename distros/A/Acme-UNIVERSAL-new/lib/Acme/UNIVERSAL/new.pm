package Acme::UNIVERSAL::new;

use strict;
use warnings;

use vars '$VERSION';
$VERSION = '0.01';

sub UNIVERSAL::new
{
	my $class = get_class();
	my $ref   = get_ref();
	bless $ref, $class;
}

sub get_class
{
	my ($root, $prefix) = @_;

	unless ($root)
	{
		$root   = \%main::;
		$prefix = '';
	}

	my %symbols = get_symbols( $root );

	my @candidates;

	while ( my ($namespace, $name) = each %symbols )
	{
		next if $namespace eq 'main::';
		next if $namespace eq '<none>::';
		my $fullname = $prefix . $name;
		push @candidates, $fullname if has_constructor( $fullname );
		push @candidates, get_class( $root->{ $namespace }, $fullname . '::' );
	}

	return $candidates[ rand( @candidates ) ] unless $prefix;
	return @candidates;
}

sub has_constructor
{
	my $symbol              = shift;
	return unless $symbol && $symbol =~ /^[A-Za-z]/;
	return unless my $ctor  = $symbol->can( 'new' );
	return if        $ctor == \&UNIVERSAL::new;
	return 1;
}

sub get_symbols
{
	my $table = shift;
	return map  { my $name = $_; s/::$//; $name => $_ }
	       grep { /::$/ }
		   keys %$table;
}

sub get_ref
{
	my @refs = ( \(my $foo), {}, [], sub {}, do { local *FOO; \*FOO } );
	return $refs[ rand( @refs ) ];
}

1; # End of Acme::UNIVERSAL::new

__END__

=head1 NAME

Acme::UNIVERSAL::new - the only constructor you ever need

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

C<Acme::UNIVERSAL::new> provides C<UNIVERSAL::new()>, the only constructor you
will ever need:

    use Acme::UNIVERSAL::new;

    my $q   = UNIVERSAL::new( 'CGI' );
	my $dbh = UNIVERSAL::new( 'dbi:Pg:dbname=my_db', '', '', {} );

    # ...

Just call C<UNIVERSAL::new()> as a function, passing whatever arguments you
want, and you will receive an appropriate object.

=head1 FUNCTIONS

This module provides only one useful function:

=head2 C<UNIVERSAL::new>

The universal constructor.  Pass in arguments.  Get back an object.  What could
be easier?

There are a few other functions:

=head2 C<get_class( $symbol_table, $name_prefix )>

Returns a random class name, after finding everything that looks like a class
beneath the given C<$symbol_table> reference named C<$name_prefix>.  If you
pass neither argument, this starts in the main symbol table.

=head2 C<get_ref()>

Returns a random blessable reference.

=head2 C<has_constructor( $class_name )>

Returns true if the given class has a constructor named C<new()> that is I<not>
C<UNIVERSAL::new()>.

=head2 C<get_symbols( $symbol_table )>

Returns a hash of symbol tables and their plain names.

=head1 AUTHOR and COPYRIGHT

Copyright 2006 chromatic, C<< chromatic at wgz dot org >>

=head1 BUGS

None.  Seriously.  Don't file any.

=head1 LICENSE

You may use, modify, and distribute this module under the same terms as Perl
itself.

=cut
