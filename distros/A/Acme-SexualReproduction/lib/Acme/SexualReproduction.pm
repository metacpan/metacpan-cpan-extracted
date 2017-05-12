package Acme::SexualReproduction;

use 5.006;
use strict;
use warnings;
use Carp qw(carp croak);
use IPC::Shareable ':lock';

our @EXPORT_OK = qw(male female);
use Exporter 'import';

=head1 NAME

Acme::SexualReproduction - beacuse fork() is for unicellular ones.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

This module allows you to improve the chances of your program kind to survive by mixing genes of their processes when creating a child process. Especially if your program is a K-strategic one.

In a "female" process:

    use Acme::SexualReproduction 'female';
    my $pid = female('unique ID', \%chromosomes);
    ...

In a "male" process:

    use Acme::SexualReproduction 'male';
    male('unique ID', \%chromosomes);

The child is spawned then from the female process.

=head1 EXPORT

Only two functions are exported: one for insemination (a "male" process) and one for allocating a shared hash of chromosomes and spawning a child (a "female" process).

=head2 male($id, \%chromosomes);

Tries to write the chromosomes to the shared memory of the female process with unique SHM $id. Sadly, does not return the child's PID.

=cut

=for comment
This subroutine was written first just because it was easier. I strongly disclaim any sexual discrimination from my side. It's written just for fun anyways.
=cut

sub male {
	my ($id, $chromosomes) = @_;
	croak "\$chromosomes must be a HASH reference" unless ref $chromosomes eq 'HASH';
	croak "Male process is sterile" unless keys %$chromosomes;
	tie my $sperm, 'IPC::Shareable', { key => $id } || croak "Couldn't copulate with female process, SHM ID $id: $!";
	(tied $sperm)->shlock;
	@{$sperm}{keys %$chromosomes} = values %$chromosomes;
	(tied $sperm)->shunlock;
	return 1;
}

=head2 $pid = female($id, \%chromosomes)

Shares a hash for the male process' chromosomes, waits for the insemination, mixes the genes and spawns the child process. \%chromosomes hash reference is changed in the child process.

=cut

sub female {	
	my ($id, $chromosomes) = @_;
	croak "\$chromosomes must be a HASH reference" unless ref $chromosomes eq 'HASH';
	tie my $sperm, 'IPC::Shareable', {key => $id, create => 1 } or carp("Couldn't copulate with male process: $!"), return;
	sleep 0.5 while !keys %$sperm; # foreplay
	keys %$sperm eq keys %$chromosomes or carp("Chromosome mismatch"), return;
	my %child_chromosomes = map { $_, int rand 2 ? $chromosomes->{$_} : $sperm->{$_} } keys %$chromosomes;
	my $pid = fork;
	carp("Couldn't spawn a child: $!"), return unless defined $pid;
	%$chromosomes = %child_chromosomes if $pid == 0;
	return $pid;
}

=head1 AUTHOR

Ivan Krylov, C<< <krylov.r00t at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-acme-sexualreproduction at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Acme-SexualReproduction>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Acme::SexualReproduction


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Acme-SexualReproduction>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Acme-SexualReproduction>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Acme-SexualReproduction>

=item * Search CPAN

L<http://search.cpan.org/dist/Acme-SexualReproduction/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Ivan Krylov.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

no warnings 'void';
"fork() is for unicellar organisms!";
