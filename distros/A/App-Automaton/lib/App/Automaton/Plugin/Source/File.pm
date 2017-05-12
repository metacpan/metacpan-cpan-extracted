package App::Automaton::Plugin::Source::File;

# ABSTRACT: File input module

use strict;
use warnings;
use Moo;

sub go {
    my $self = shift;
    my $in = shift;
	
	my $d = $in->{debug};

    my $file = $in->{path};
	_logger($d, "Processing file: $file");
    open(my $fh, "<", $in->{path}) || return 1;
    my @lines = <$fh>;
    close($fh);
	
	if ($in->{empty}) {
		_logger($d, "emptying the file: $file");
		open(my $fh, '>', $in->{path});
		print $fh '';
		close($fh);
	}
	
	if ($in->{delete}) {
		_logger($d, "deleting file: $file");
		unlink $file;
	}
	
    chomp(@lines);

    return(@lines);
}

sub _logger {
	my $level = shift;
	my $message = shift;
	print "$message\n" if $level;
	return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Automaton::Plugin::Source::File - File input module

=head1 VERSION

version 0.150912

=head1 SYNOPSIS

This module is intended to be used from within the App::Automaton application.

It retrieves lines from a file and adds them to the queue to be processed.

=head1 METHODS

=over 4

=item go

Executes the plugin. Expects input: conf as hashref

=back

=head1 SEE ALSO

L<App::Automaton>

=head1 AUTHOR

Michael LaGrasta <michael@lagrasta.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Michael LaGrasta.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
