package App::perlrdf::FileSpec::OutputBindings;

use 5.010;
use autodie;
use strict;
use warnings;
use utf8;

BEGIN {
	$App::perlrdf::FileSpec::OutputBindings::AUTHORITY = 'cpan:TOBYINK';
	$App::perlrdf::FileSpec::OutputBindings::VERSION   = '0.004';
}

use Any::Moose;
use File::Temp qw(tempfile);
use JSON qw(from_json);
use RDF::Trine;
use Spreadsheet::Wright;
use YAML::XS qw(Dump);

use namespace::clean;

extends 'App::perlrdf::FileSpec::OutputFile';

sub _build_format
{
	my $self = shift;
	return 'YAML'    if $self->uri =~ /\.ya?ml/i;
	return 'XML'     if $self->uri =~ /\.xml/i;
	return 'JSON'    if $self->uri =~ /\.json/i;
	return 'CSV'     if $self->uri =~ /\.csv/i;
	return 'XLS'     if $self->uri =~ /\.xls/i;
	return 'HTML'    if $self->uri =~ /\.html?/i;
	return 'XHTML'   if $self->uri =~ /\.xhtml/i;
	return 'ODS'     if $self->uri =~ /\.ods/i;
	return 'Text';
}

sub serialize_iterator
{
	my ($self, $iter) = @_;

	if ($self->format =~ /json/i)
	{
		$self->handle->print($iter->as_json);
	}
	elsif ($self->format =~ /yaml/i)
	{
		$self->handle->print(Dump from_json($iter->as_json));
	}
	elsif ($self->format =~ /xml/i)
	{
		$iter->print_xml($self->handle);
	}
	elsif ($self->format =~ /te?xt/i)
	{
		$self->handle->print($iter->as_string);
	}
	else
	{
		my ($dummyfh, $filename) = tempfile();
		$dummyfh->close;
		my $s = Spreadsheet::Wright->new(
			filename   => $filename,
			format     => $self->format,
		);
		$s->addrow(map {+{
			font_weight => 'bold',
			font_style  => 'italic',
			content     => $_,
		}} $iter->binding_names);
		while (my $row = $iter->next)
		{
			my %row = %$row;
			$s->addrow(map
			{
				if ($_->is_resource)
				{
					+{
						color       => 'blue',
						content     => $_->as_ntriples,
					}
				}
				elsif ($_->is_literal)
				{
					+{
						color       => 'black',
						content     => $_->as_ntriples,
					}
				}
				elsif (defined $_)
				{
					+{
						color       => 'green',
						content     => $_->as_ntriples,
					}
				}
				else
				{
					+{
						color       => 'black',
						content     => q(),
					}
				}
			}
			@row{ $iter->binding_names });
		}
		$s->close;
		
		local @ARGV = $filename;
		while (<>)
		{
			$self->handle->print($_);
		}
	}
	
	$self->handle->close;
}
	
1;
