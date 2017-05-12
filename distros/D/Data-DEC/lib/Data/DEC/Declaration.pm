package Data::DEC::Declaration;

use strict;
use Parse::Highlife::Utils qw(params);
use Data::Dumper;

our $UnnamedCounter = 0;

sub new
{
	my( $class, @args ) = @_;
	my $self = bless {}, $class;
	return $self -> _init( @args );
}

sub _init
{
	# type: identifier | string | number | real | map
	# valuetype: name of the map declaration
	my( $self, $name, $type, $value, $valuetype ) = @_;
	$valuetype = '' unless defined $valuetype;
	if( ! defined $name || ! length $name ) {
		$name = $UnnamedCounter;
		$UnnamedCounter ++;
	}
	$self->{'name'} = $name;
	$self->{'type'} = $type;
	$self->{'value'} = $value;
	$self->{'value-type'} = $valuetype;
	return $self;
}

sub name
{
	my( $self ) = @_;
	return $self->{'name'};
}

sub type
{
	my( $self ) = @_;
	return $self->{'type'};
}

sub value
{
	my( $self ) = @_;
	return $self->{'value'};
}

sub valuetype
{
	my( $self ) = @_;
	return $self->{'value-type'};
}

sub subvalue
{
	my( $self, @args ) = @_;
	return $self->subvalues( @args );
}

sub subvalues
{
	my( $self, $subvalue_key_name ) = @_;
	return () if ref $self->{'value'} ne 'ARRAY';
	my @subvalues;
	foreach my $pair ( @{ $self->{'value'} } ) {
		my( $name, $value ) = @{$pair};
		push @subvalues, $value 
			if ! defined $subvalue_key_name || $name eq $subvalue_key_name;
	}
	return (wantarray() ? @subvalues : shift @subvalues);
}

sub unique_subvalues
{
	my( $self ) = @_;
	return () if ref $self->{'value'} ne 'ARRAY';
	my %subvalues;
	foreach my $pair ( @{ $self->{'value'} } ) {
		my( $name, $value ) = @{$pair};
		$subvalues{ $name } = $value;
	}
	return %subvalues;
}

sub dump
{
	my( $self ) = @_;
	my $w = 16;
	print sprintf('%-'.$w.'s', '#'.$self->{'name'}.' ');
	print $self->{'value-type'}.' ' if length $self->{'value-type'};
	if( $self->{'type'} eq 'map' ) {
		print "{\n";
		map {
			my( $name, $value ) = @{$_};
			print ''.(' ' x $w)."  $name: #".$value->{'name'}."\n";
		} @{$self->{'value'}};
		print ''.(' ' x $w)."}";
	}
	elsif( $self->{'type'} eq 'string' ) {
		my $s = $self->{'value'};
		$s =~ s/\n/\\n/g;
		$s =~ s/\r/\\r/g;
		$s =~ s/"/\\"/g;
		print "\"$s\"";
	}
	else {
		print $self->{'value'};
	}
	print "\n";
}

1;

