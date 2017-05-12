package Data::DEC;

use 5.014002;
use strict;
use warnings;

use Parse::Highlife;
use Parse::Highlife::Utils qw(dump_ast);
use Data::DEC::Declaration;
#use Data::Dump qw(dump);

# require Exporter;
# 
# our @ISA = qw(Exporter);
# 
# # Items to export into callers namespace by default. Note: do not export
# # names by default without a very good reason. Use EXPORT_OK instead.
# # Do not simply export all your public functions/methods/constants.
# 
# # This allows declaration	use Data::DEC ':all';
# # If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# # will save memory.
# our %EXPORT_TAGS = ( 'all' => [ qw(
# 	
# ) ] );
# 
# our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
# 
# our @EXPORT = qw(
# 		
# );

our $VERSION = '0.03';

our $Grammar = q{

	space ignored: /\s\n\r\t+/;

	multiline-comment ignored: "/*" .. "*/";

	singleline-comment ignored: /\#[^\n\r]*/;

	file: { declaration 0..* };
	
		declaration: [ "@" identifier ] literal;
		
			literal: < map string real number identifier >;
			
				map: [ symbol ] "[" { pair 0..* } "]";
				
					pair: [ symbol ":" ] declaration;
				
				string: < double-quoted-string single-quoted-string >;
				
					double-quoted-string: '"' .. '"';
				
					single-quoted-string: "'" .. "'";
					
				real: /\d+\.\d+/;
				
				number: /\d+/;
				
				identifier: symbol { "." symbol 0..* };

					symbol: /[\w\d]+(\-[\w\d]+)*/;
						
};

sub new
{
	my( $class, @args ) = @_;
	my $self = bless {}, $class;
	return $self->_init( @args );	
}

sub _init
{
	my( $self, @filenames ) = @_;

	# raw DEC content
	$self->{'filenames'} = [ @filenames ];
	
	# the parsed declarations
	$self->{'declarations'} = [];
	
	# setup compiler
	my $compiler = Parse::Highlife -> Compiler;
	$compiler->grammar( $Grammar );
	$compiler->toprule( -name => 'file' );
	$compiler->transformer( 
		-rule => 'declaration', 
		-fn => sub { _declaration_from_ast( $self->{'declarations'}, @_ ) },
	);
	$self->{'dec-compiler'} = $compiler;

	# compile document
	$compiler -> compile( @{$self->{'filenames'}} );
	$self->_delete_temporary_references();
	
	return $self;
}

sub validate
{
	my( $self, $decs ) = @_;
	warn "Data::DEC::validate() is not implemented, yet.\n";
	# ...
	return 1;
}

sub dump
{
	my( $self ) = @_;
	map{ $_->dump() } @{$self->{'declarations'}};
}

sub declarations
{
	my( $self ) = @_;
	return @{$self->{'declarations'}};
}

# identifier declarations can only resolved after all declarations
# are parsed, but then all indirect references to declarations
# can be turned into direct ones (eliminating unesessary declarations)
sub _delete_temporary_references
{
	my( $self ) = @_;
	while( $self->_has_temporary_references() )
	{
		my @ids_to_delete;
		map {
			if( $_->{'type'} eq 'map' ) {
				# check all keys
				foreach my $e (0..scalar(@{$_->{'value'}})-1) {
					my $entry = $_->{'value'}->[$e];
					my( $name, $value ) = @{$entry};
					if( $value->{'type'} eq 'identifier' ) {
						$_->{'value'}->[$e]->[1] = $self->find_declaration_by_name( $value->{'value'} );
						push @ids_to_delete, $value->{name};
					}
				}
			}
		}
		@{$self->{'declarations'}};
		
		# filter out the ones that are unecessary
		$self->{'declarations'} = [
			grep {
				my $d = $_;
				scalar(grep { $_ eq $d->{'name'} } @ids_to_delete) == 0;
			}
			@{$self->{'declarations'}}
		];
	}
}

# returns 1 if a declaration exists that is an identifier
sub _has_temporary_references
{
	my( $self ) = @_;
	map {
		return 1 if $_->{'type'} eq 'identifier';
	}
	@{$self->{'declarations'}};
	return 0;
}

sub find_declaration_by_name
{
	my( $self, $name ) = @_;
	map {
		if( $_->{'name'} eq $name ) {
			return $_;
		}
	}
	@{$self->{'declarations'}};
	return undef;
}

sub _declaration_from_ast
{
	my( $declarations_result, $transformer, $ast ) = @_;

	my $name = '';
	if( $ast->first_child()->has_ancestor('symbol') ) {
		$name = join '.', map { $_->value() } $ast->first_child()->ancestors('symbol');
	}

	my $type = '';
	my $valuetype = '';
	my $value = '';
	if( $ast->ancestor('literal')->has_ancestor('map') ) {
		$type = 'map';
		$valuetype = $ast->ancestor('literal')->first_child('symbol')->value();	
			$valuetype = '' if $valuetype eq '['; # unnamed map declaration!
		$value = [];
		my $unnamed_counter = 0;
		foreach my $pair (@{$ast->ancestor('literal')->ancestor('map')->third_child()->{'children'}}) {
			my $entry_name;
			if( $pair->first_child()->has_ancestor('symbol') ) {
				$entry_name = $pair->first_child()->ancestor('symbol')->value();
			}
			else {
				$entry_name = $unnamed_counter;
				$unnamed_counter ++;
			}
			my $entry_value = _declaration_from_ast( $declarations_result, $transformer, $pair->second_child() );	
			push @{$value}, [ $entry_name, $entry_value ];
		}
	}
	elsif( $ast->ancestor('literal')->has_ancestor('identifier') ) {
		$type = 'identifier';
		$value = $ast->ancestor('literal')->ancestor('identifier')->value();
	}
	elsif( $ast->ancestor('literal')->has_ancestor('number') ) {
		$type = 'number';
		$value = $ast->ancestor('literal')->ancestor('number')->value();
	}
	elsif( $ast->ancestor('literal')->has_ancestor('real') ) {
		$type = 'real';
		$value = $ast->ancestor('literal')->ancestor('real')->value();
	}
	elsif( $ast->ancestor('literal')->has_ancestor('string') ) {
		$type = 'string';
		$value = $ast->ancestor('literal')->ancestor('string')->value();
	}
	
	my $decl = Data::DEC::Declaration->new( $name, $type, $value, $valuetype );

	push @{$declarations_result}, $decl;
	return $decl;
}

1;
__END__

=head1 NAME

Data::DEC - Perl extension for parsing and validation of DEC and DECS formatted data

=head1 SYNOPSIS

  use Data::DEC;
  my $decs = Data::DEC->new( $decs_content );
  my $dec = Data::DEC->new( $dec_content );
  print "is valid: ".$dec->validate($decs)."\n";
  foreach my $d ($dec->toplevel_declarations()) {
  	# d is a Data::DEC::Declaration instance
  	print "name: ".$d->name."\n"
  	# ...
  }

=head1 DESCRIPTION

Data::DEC is a module that can parse DEC formatted data and
validate it against a given DECS document to validate its structure.
The DEC format is specified at http://www.tkirchner.com/d/dec/DEC-1.0.html

=head2 EXPORT

None by default.

=head1 SEE ALSO

None.

=head1 AUTHOR

Tom Kirchner, E<lt>tom@kirchner.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Tom Kirchner

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
