package Bosch::RCPPlus::Response;
use strict;

use XML::LibXML;
use Carp qw(croak);

sub new
{
	my ($proto, $content, $args, $format) = @_;
	my $class = ref($proto) || $proto;

	my $self = {
		content => $content,
		xml => XML::LibXML->load_xml(string => $content),
		args => $args,
		format => $format,
	};

	bless ($self, $class);
	return $self;
}

sub type
{
	my ($proto) = @_;
	return $proto->{xml}->findvalue('/rcp/type');
}

sub error
{
	my ($proto) = @_;

	return $proto->{xml}->findvalue('/rcp/result/error');
}

# RCPParser.parseXMLAnswer
sub result
{
	my ($proto) = @_;
	my $ret;

	switch: for ($proto->type) {
		/^F_FLAG$/ && do {
			$ret = !!int($proto->{xml}->findvalue('/rcp/result/dec'));
			last;
		};

		/^P_UNICODE$/ && do {
			my $content = $proto->{xml}->findvalue('/rcp/result/str');
			my @chars = split ' ', $content;
			my $text = '';

			foreach my $char (@chars) {
				$text = $text . chr(hex($char)) if ($char);
			}

			$ret = $text;
			last;
		};

		/^P_OCTET$/ && do {
			my $content = $proto->{xml}->findvalue('/rcp/result/str');
			my @chars = split ' ', $content;
			my @data;

			foreach my $char (@chars) {
				push @data, hex($char) if ($char);
			}

			$ret = \@data;
			last;
		};

		/^T_DWORD$/ && do {
			$ret = int($proto->{xml}->findvalue('/rcp/result/dec'));
		};

		croak("Unknown type $_");
		last;
	}

	$ret = $proto->{format}->($ret) if ($proto->{format});
	return $ret;
}

1;
