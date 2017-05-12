package Data::Phrasebook::Debug;
use strict;
use warnings FATAL => 'all';
use Carp qw( croak );

use vars qw($VERSION);
$VERSION = '0.35';

=head1 NAME

Data::Phrasebook::Debug - Phrasebook debugging.

=head1 SYNOPSIS

    use Data::Phrasebook;

    my $q = Data::Phrasebook->new(
        class  => 'Plain',
        loader => 'Text',
        file   => 'phrases.txt',
        debug  => 2,
    );

    my $r = Phrasebook->new( file  => 'phrases.txt', debug => 3 );

    $r->debug(4);
    $r->store(3,"Start");
    my @log = $r->retrieve(2);
    $r->clear();

=head1 DESCRIPTION

This module enables debug logging for phrasebook classes. It simply stores
all interaction with the phrasebook, which can then be interrogated. Do not
call directly, but via the class object.

There is a single storage for all levels of the Data::Phrasebook heirarchy.
This then enables storage and retrieval to be performed by the user. There
are several different levels of debugging, detailed as follows:

  1 - Errors
  2 - Warnings
  3 - Information
  4 - Variable Debugging

The first three are simple strings that are recorded during the processing.
However, the latter is specifically for dumping the contents of significant
variables.

Through the use of the debug() method, the debugging can be switched on and
off at significant points. The clear() method will clear the current trail of
debugging information.

=cut

my @debug;
my $debug = 0;

=head1 METHODS

=head2 debug

Accessor to debugging flag.

=cut

sub debug {
    my $self = shift;
    return @_ ? $debug = shift : $debug;
}

=head2 clear

Clear the currently stored debugging information.

=cut

sub clear {
    return @debug = ();
}

=head2 store

Store debugging information.

=cut

sub store {
    return  unless($debug);

    my ($self, $id, @args) = @_;
    return  if(!$id || $debug < $id);

    push @debug, [$id, join(' ',@args)];
	return;
}

=head2 retrieve

Retrieve debugging information.

=cut

sub retrieve {
    my $self = shift;
    my $id   = shift || 1;

    return grep {$_->[0] <= $id} @debug;
}

=head2 dumper

Uses 'on demand' call to Data::Dumper::Dumper().

=cut

sub dumper {
    my $self = shift;
    my $dump = 'Data::Dumper';
    if(eval { require $dump }) {
        $dump->import;
		return Dumper(@_);
	}
	return '';
}

1;

__END__

=head1 SEE ALSO

L<Data::Phrasebook>.

=head1 SUPPORT

Please see the README file.

=head1 AUTHOR

  Barbie, <barbie@cpan.org>
  for Miss Barbell Productions <http://www.missbarbell.co.uk>.

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2004-2013 Barbie for Miss Barbell Productions.

  This distribution is free software; you can redistribute it and/or
  modify it under the Artistic License v2.

=cut
