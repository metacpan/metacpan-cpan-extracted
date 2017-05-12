package App::Siesh::Batch;

use strict;
use warnings;

sub ReadLine { return __PACKAGE__ };

sub new {
	my ($class,$fh) = @_;
	return bless { handle => $fh }, $class;
}

sub readline {
	my $self = shift;
        my $fh = $self->{handle};
	if ($fh->eof()) {
		return "quit";
	} else {
		chomp(my $line = $fh->getline());
		return $line;
	}
	return;
}

sub history_expand { }
sub MinLine { }
sub Attribs { }
sub OUT { }
sub IN { }
sub ornaments { }
sub addhistory { }

1;

__END__

=head1 NAME

App::Siesh::Batch

=head1 SYNOPSIS

  my $readline = App::Siesh::Batch(\*STDIN)
  my $term = Term::ShellUI->new( term => $readline );

=head1 DESCRIPTION

Implements a very simple fake readline module. It expects a file handle
as single argument to new(), and returns a new line from that filehandle
upon readline() till it is exhausted. All other methods you would expect
in a readline module are just subs and won't do anything. To prevent
Term::ShellUI to print a spurious newline after the last command we
return quit on eof.

=head1 SEE ALSO

L<siesh>, L<Net::ManageSieve::Siesh>, L<Net::ManageSieve>

=head1 AUTHOR

Mario Domgoergen <dom@math.uni-bonn.de>

=head1 COPYRIGHT & LICENSE

Copyright 2008 Mario Domgoergen, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
