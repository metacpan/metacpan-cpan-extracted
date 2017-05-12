package CPAN::Dashboard::Distribution::CPANTesters;
$CPAN::Dashboard::Distribution::CPANTesters::VERSION = '0.02';
use 5.006;
use Moo;

has passes   => (is => 'ro');
has fails    => (is => 'ro');
has unknowns => (is => 'ro');
has na       => (is => 'ro');

1;

=head1 NAME

CPAN::Dashboard::Distribution::CPANTesters - Package to manage the CPAN Testers for CPAN Dashboard.

=head1 DESCRIPTION

B<FOR INTERNAL USE ONLY>

=head1 REPOSITORY

L<https://github.com/neilbowers/CPAN-Dashboard>

=head1 AUTHOR

Neil Bowers E<lt>neilb@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Neil Bowers <neilb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
