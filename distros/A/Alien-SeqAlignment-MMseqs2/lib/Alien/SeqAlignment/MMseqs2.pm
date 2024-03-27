use strict;
use warnings;
package Alien::SeqAlignment::MMseqs2;
$Alien::SeqAlignment::MMseqs2::VERSION = '0.02';
use parent qw( Alien::Base );
use Carp;
our $AUTOLOAD;

sub AUTOLOAD {
    my ($self) = @_;
    our $AUTOLOAD;
    $AUTOLOAD =~ s/.*::(\w+)$//;
    my $method = $1;
    unless ( exists $self->runtime_prop->{command}->{$method} ) {
        croak "Method $method not found";
    }
    else {
        no strict 'refs';
        *$AUTOLOAD = sub {
            shift->runtime_prop->{command}->{$method};
        };
    }
    use strict 'refs';
    goto &$AUTOLOAD;
}

=head1 NAME

Alien::SeqAlignment::MMseqs2 - find, build and install the mmseqs2 tools

=head1 VERSION

version 0.02

=head1 SYNOPSIS

To execute the MMseqs2 set of tools, you can use the following code:

 use Alien::SeqAlignment::MMseqs2;
 use Env qw( @PATH );
 unshift @PATH, Alien::SeqAlignment::MMseqs2->bin_dir;

Now you can run the mmseqs2 tools as:
  Alien::SeqAlignment::MMseqs2->mmseqs <command> [<args>]

 
=head1 DESCRIPTION

This distribution provides MMseqs2 so that it can be used by other
Perl distributions that are on CPAN.  The source code will be downloaded
from the MMseqs2 website, if it is not found in the system path.
The program will then be built and installed in a private share location.
The build provides the various CLI tools in the MMseqs2 suite.


=head1 METHODS : MMseqs2 SUITE

=head2 mmseqs

  system Alien::SeqAlignment::MMseqs2->mmseqs <command> [<args>]

Returns the command name for running the CLI version of the mmseqs2 suite.
The command is the name of the MMseqs workflow that you want to run.


=head1 SEE ALSO

=over 4

=item * L<MMseqs2|https://github.com/soedinglab/MMseqs2>

MMseqs2: ultra fast and sensitive sequence search and clustering suite


MMseqs2 (Many-against-Many sequence searching) is a software suite to 
search and cluster huge protein and nucleotide sequence sets. MMseqs2 is 
open source GPL-licensed software implemented in C++ for Linux, MacOS, and 
(as beta version, via cygwin) Windows. The software is designed to run on 
multiple cores and servers and exhibits very good scalability. MMseqs2 can 
run 10000 times faster than BLAST. At 100 times its speed it achieves a
lmost the same sensitivity. It can perform profile searches with the same s
ensitivity as PSI-BLAST at over 400 times its speed.


=item * L<Alien>

Documentation on the Alien concept itself.

=item * L<Alien::Base|https://metacpan.org/pod/Alien::Base>

The base class for this Alien. The methods in that class allow you to use
the static and the dynamic edlib library in your code. 

=item * L<Alien::Build::Manual::AlienUser|https://metacpan.org/dist/Alien-Build/view/lib/Alien/Build/Manual/AlienUser.pod>

Detailed manual for users of Alien classes.

=item * L<Bio::SeqAlignment|https://metacpan.org/pod/Bio::SeqAlignment>

A collection of tools and libraries for aligning biological sequences 
from within Perl. 

=back

=head1 AUTHOR

Christos Argyropoulos <chrisarg@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Christos Argyropoulos.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

1;
