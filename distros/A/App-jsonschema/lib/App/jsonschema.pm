use strict;
use warnings;
package App::jsonschema;
{
  $App::jsonschema::VERSION = '0.03';
}
use JSON::Schema;
use JSON qw/from_json/;
use autodie;
use Moo;
use feature qw/say/;
use Data::Dump qw/dump/;


# ABSTRACT: Command-line utility to validate JSON using JSON Schema


has schema_file => ( 
	is 			=> 'rw', 
	required 	=> 1,
	isa 		=> sub { die "Could not find file '$_[0]'!" unless -f $_[0] }
);
has schema		=> ( is => 'lazy' );
has validator	=> ( is => 'lazy' );

sub _build_validator  {
	my $self = shift;
	return JSON::Schema->new($self->schema);
}

sub _build_schema {
	my $self = shift;
	my $schema;
	{
		local $/;
		open my $fh, '<', $self->schema_file;
		$schema = <$fh>;
		close $fh;
	}
	return $schema;
}



sub validate {
	my ($self,@files) = @_;
	my $result;
	my $status = 0;
	for my $file (@files){
		my $json;
		{
			local $/;
			open my $fh, '<', $file;
			$json = <$fh>;
			close $fh;
		}
		$result = $self->validator->validate(from_json($json));
		unless($result->valid){
			$self->_report_errors($result,$file);
			$status++;
		}
	}
	exit $status;
}

sub _report_errors {
	my ($self,$result,$json_file) = @_;
	print STDERR "Cannot validate '$json_file' against schema '".$self->schema_file."':\n";
	foreach ($result->errors){
		print STDERR "  ".$_->{property}.":\t".$_->{message}."\n";
	}
}


1;

__END__

=pod

=encoding utf-8

=head1 NAME

App::jsonschema - Command-line utility to validate JSON using JSON Schema

=head1 VERSION

version 0.03

=head1 SYNOPSIS

    jsonschema.pl schema.json file1.json [file2.json ...]

=head1 DESCRIPTION

jsonschema.pl is a script to validate JSON documents agains a JSON
Schema. It is a simple command-line wrapper around L<JSON::Schema>.

=head1 SEE ALSO

L<JSON>, L<JSON::Schema>

=head2 validate

    Validates a set of JSON files passed as argument.

=head1 AUTHOR

Andre Santos <andrefs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Andre Santos.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
