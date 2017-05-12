#! /usr/bin/env perl

use lib "../lib";

use strict;
use 5.012;
use App::CPRReporter;
use Getopt::Long;
use Pod::Usage;

my ( $employees, $certificates, $course, $help, $man );

GetOptions(
    'people=s' => \$employees,
    'certs=s'  => \$certificates,
    'course=s' => \$course,
    'help|?|h' => \$help,
    'man'      => \$man,
) or pod2usage(2);
pod2usage(1)
  if ( $help || !defined($certificates) || $course eq "" || $employees eq "" );
pod2usage( -exitstatus => 0, -verbose => 2 ) if ($man);

my $reporter = App::CPRReporter->new(
    employees    => $employees,
    certificates => $certificates,
    course       => $course
);
$reporter->run();

# PODNAME: cpr_report.pl
# ABSTRACT: Generate an overview of the status of people enrolled for CPR training.

__END__

=pod

=encoding UTF-8

=head1 NAME

cpr_report.pl - Generate an overview of the status of people enrolled for CPR training.

=head1 VERSION

version 0.03

=head1 SYNOPSIS

cpr_report.pl --people <file1.xlsx> --certs <file2.xml> --course <file3.xlsx>

=head1 DESCRIPTION

Application to merge information from various datasets to generate an overview of who followed the practical and theoretical CPR training.

The expected format of the various input files is documented in the module App::CPRReporter.

=head1 AUTHOR

Lieven Hollevoet <hollie@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Lieven Hollevoet.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
