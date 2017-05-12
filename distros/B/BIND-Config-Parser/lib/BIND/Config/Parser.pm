package BIND::Config::Parser;

# $Id: Parser.pm 35 2005-06-26 18:58:24Z  $

use warnings;
use strict;

use Parse::RecDescent;

use vars qw( $VERSION );

$VERSION = '0.01';

$::RD_AUTOACTION = q{ $item[1] };

my $grammar = q{

	program:
		  <skip: qr{\s*
		            (?:(?://|\#)[^\n]*\n\s*|/\*(?:[^*]+|\*(?!/))*\*/\s*)*
		           }x> statement(s) eofile { $item[2] }

	statement:
		  simple | nested

	simple:
		  value(s) ';'

	nested:
		  value value(s?) '{' statement(s?) '}' ';'
		  { [ $item[1], $item[2], $item[4] ] }

	value:
		  /[\w.\/=-]+/ | /"[\w.\/ =-]+"/

	eofile:
		  /^\Z/
};

sub new {
	my $class = shift;

	my $self = {
		'_open_block'  => \&_handle_open_block,
		'_close_block' => \&_handle_close_block,
		'_statement'   => \&_handle_statement,
	};

	$self->{ '_parser' } = new Parse::RecDescent( $grammar )
		|| die "Bad grammar\n";

	bless $self, $class;

	return $self;
}

sub parse_file
{
	my $self = shift;

	my $namedconf = shift
		 || die "Missing named.conf argument\n";

	open NAMEDCONF, $namedconf
		|| die "Can't open '$namedconf': $!\n";
	my $text = join( "", <NAMEDCONF> );
	close NAMEDCONF;

	defined( my $tree = $self->{ '_parser' }->program( $text ) )
		|| die "Bad text\n";

	$self->_recurse( $tree );
}

sub open_block_handler
{
	my $self = shift;

	return $self->{ '_open_block' };
}

sub set_open_block_handler
{
	my $self = shift;

	$self->{ '_open_block' } = shift;
}

sub close_block_handler
{
	my $self = shift;

	return $self->{ '_close_block' };
}

sub set_close_block_handler
{
	my $self = shift;

	$self->{ '_close_block' } = shift;
}

sub statement_handler
{
	my $self = shift;

	return $self->{ '_statement' };
}

sub set_statement_handler
{
	my $self = shift;

	$self->{ '_statement' } = shift;
}

sub _recurse
{
	my $self = shift;
	my $tree = shift;

	foreach my $node ( @{ $tree } ) {
		if ( ref( $node->[-1] ) eq 'ARRAY' ) {

			# If the last child of the node is an array then the
			# node must be a nested statement, so handle the
			# opening line, recurse through the contents and
			# close with the curly brace

			$self->open_block_handler->( $node->[0],
						     @{ $node->[1] } );
			$self->_recurse( $node->[-1] );
			$self->close_block_handler->();
		} else {

			# Normal single-line statement

			$self->statement_handler->( @{ $node } );
		}
	}
}

sub _handle_open_block {}
sub _handle_close_block {}
sub _handle_statement {}

1;

__END__

=head1 NAME

BIND::Config::Parser - Parse BIND Config file.

=head1 SYNOPSIS

 use BIND::Config::Parser;

 # Create the parser
 my $parser = new BIND::Config::Parser;

 my $indent = 0;

 # Set up callback handlers
 $parser->set_open_block_handler( sub {
         print "\t" x $indent, join( " ", @_ ), " {\n";
         $indent++;
 } );
 $parser->set_close_block_handler( sub {
         $indent--;
         print "\t" x $indent, "};\n";
 } );
 $parser->set_statement_handler( sub {
         print "\t" x $indent, join( " ", @_ ), ";\n";
 } );

 # Parse the file
 $parser->parse_file( "named.conf" );

=head1 DESCRIPTION

BIND::Config::Parser provides a lightweight parser to the configuration
file syntax of BIND v8 and v9 using a C<Parse::RecDescent> grammar.

It is in a similar vein to C<BIND::Conf_Parser>. However, as it has no
knowledge of the directives, it doesn't need to be kept updated as new
directives are added, it simply knows how to carve up a BIND configuration
file into logical chunks.

=head1 CONSTRUCTOR

=over 4

=item new( );

Create a new C<BIND::Config::Parser> object.

=back

=head1 METHODS

=over 4

=item set_open_block_handler( CODE_REF );

Set the code to be called when a configuration block is opened. At least one
argument will be passed; the name of that block, for example C<options> or
C<zone>, etc. as well as any additional items up to but not including the
opening curly brace.

=item set_close_block_handler( CODE_REF );

Set the code to be called when a configuration block is closed. No arguments
are passed.

=item set_statement_handler( CODE_REF );

Set the code to be called on a single line configuration element. At least one
argument will be passed; the name of that element, as well as any additional
items up to but not including the ending semi-colon.

=item parse_file( FILENAME );

Parse FILENAME, triggering the above defined handlers on the relevant sections.

=back

=head1 TODO

Probably the odd one or two things. I'm fairly sure the grammar is correct.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2005 Matt Dainty.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHORS

Matt Dainty E<lt>matt@bodgit-n-scarper.comE<gt>.

=head1 SEE ALSO

L<perl>, L<Parse::RecDescent>, L<BIND::Conf_Parser>.

=cut
