use 5.008001;
use strict;
use warnings;

package Data::Fake::Company;
# ABSTRACT: Fake company and job data generators

our $VERSION = '0.003';

use Exporter 5.57 qw/import/;

our @EXPORT = qw(
  fake_company
  fake_title
);

use Data::Fake::Core  ();
use Data::Fake::Names ();

my ( @job_titles,     $job_title_count );
my ( @company_suffix, $company_suffix_count );

sub _job_title      { return $job_titles[ int( rand($job_title_count) ) ] }
sub _company_suffix { return $company_suffix[ int( rand($company_suffix_count) ) ] }

#pod =func fake_company
#pod
#pod     $generator = fake_company();
#pod
#pod Takes no arguments and returns a generator that returns a randomly generated
#pod fake company name.
#pod
#pod =cut

sub fake_company {
    my $fake_surname = Data::Fake::Names::fake_surname();
    return Data::Fake::Core::fake_pick(
        Data::Fake::Core::fake_template( "%s, %s", $fake_surname, \&_company_suffix ),
        Data::Fake::Core::fake_template( "%s-%s",         ($fake_surname) x 2 ),
        Data::Fake::Core::fake_template( "%s, %s and %s", ($fake_surname) x 3 ),
    );
}

#pod =func fake_title
#pod
#pod     $generator = fake_title();
#pod
#pod Takes no arguments and returns a generator that returns a randomly generated
#pod job title (drawn from a corpus of ~90 common titles sources from Glassdoor).
#pod
#pod =cut

sub fake_title {
    return sub { _job_title() }
}

# list of most common job titles from glassdoor.com with some edits and
# amendments
@job_titles = (
    'Account Executive',
    'Account Manager',
    'Accountant',
    'Actuary',
    'Administrative Assistant',
    'Analyst',
    'Applications Engineer',
    'Architect',
    'Art Director',
    'Assistant Manager',
    'Assistant Store Manager',
    'Assistant Vice President',
    'Associate',
    'Associate Consultant',
    'Associate Director',
    'Attorney',
    'Audit Associate',
    'Branch Manager',
    'Business Analyst',
    'Business Development Manager',
    'Cashier',
    'Civil Engineer',
    'Consultant',
    'Customer Service',
    'Customer Service Representative',
    'Data Analyst',
    'Design Engineer',
    'Developer',
    'Director',
    'Editor',
    'Electrical Engineer',
    'Engineer',
    'Engineering Manager',
    'Executive Assistant',
    'Finance Manager',
    'Financial Advisor',
    'Financial Analyst',
    'Financial Representative',
    'Flight Attendant',
    'General Manager',
    'Graduate Research Assistant',
    'Graphic Designer',
    'Hardware Engineer',
    'Human Resources Manager',
    'Investment Banking Analyst',
    'IT Analyst',
    'It Manager',
    'IT Specialist',
    'Law Clerk',
    'Management Trainee',
    'Manager',
    'Marketing Assistant',
    'Marketing Director',
    'Marketing Manager',
    'Mechanical Engineer',
    'Member of Technical Staff',
    'Network Engineer',
    'Office Manager',
    'Operations Analyst',
    'Operations Manager',
    'Personal Banker',
    'Pharmacist',
    'Principal Consultant',
    'Principal Engineer',
    'Principal Software Engineer',
    'Process Engineer',
    'Product Manager',
    'Program Manager',
    'Programmer',
    'Programmer Analyst',
    'Project Engineer',
    'Project Manager',
    'Public Relations',
    'QA Engineer',
    'Recruiter',
    'Registered Nurse',
    'Research Analyst',
    'Research Assistant',
    'Research Associate',
    'Sales',
    'Sales Associate',
    'Sales Engineer',
    'Sales Manager',
    'Sales Representative',
    'Senior Accountant',
    'Senior Analyst',
    'Senior Associate',
    'Senior Business Analyst',
    'Senior Consultant',
    'Senior Director',
    'Senior Engineer',
    'Senior Financial Analyst',
);

@company_suffix = qw( Inc. Corp. LP LLP LLC );

$job_title_count      = @job_titles;
$company_suffix_count = @company_suffix;


# vim: ts=4 sts=4 sw=4 et tw=75:

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Fake::Company - Fake company and job data generators

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    use Data::Fake::Company;

    $fake_company = fake_company()->();
    $fake_title   = fake_title()->();

=head1 DESCRIPTION

This module provides fake data generators for company names and job titles.

All functions are exported by default.

=head1 FUNCTIONS

=head2 fake_company

    $generator = fake_company();

Takes no arguments and returns a generator that returns a randomly generated
fake company name.

=head2 fake_title

    $generator = fake_title();

Takes no arguments and returns a generator that returns a randomly generated
job title (drawn from a corpus of ~90 common titles sources from Glassdoor).

=for Pod::Coverage BUILD

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
