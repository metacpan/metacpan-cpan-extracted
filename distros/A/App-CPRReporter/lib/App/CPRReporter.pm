use strict;
use warnings;

package App::CPRReporter 0.02;
$App::CPRReporter::VERSION = '0.03';
use Moose;
use namespace::autoclean;
use 5.012;
use autodie;

use Carp qw/croak carp/;
use Text::ResusciAnneparser;
use Spreadsheet::XLSX;
use Text::Iconv;
use Data::Dumper;
use Text::Fuzzy::PP;

has employees => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has certificates => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has course => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

# Actions that need to be run after the constructor
sub BUILD {
    my $self = shift;

    # Add stuff here

    my $certparser =
      Text::ResusciAnneparser->new( infile => $self->{certificates} );
    $self->{_certificates} = $certparser->certified();
    $self->{_training}     = $certparser->in_training();

    $self->_parse_employees;

    # Make an array of employees that will be used for fuzzy matching
    foreach my $employee ( keys %{$self->{_employees}} ) {
        push( @{ $self->{_employee_array} }, $employee );
    }

    #print Dumper($self->{_employee_array});

# Only parse the course info after the array is created, the array is used in matching
    $self->_parse_course;

}

# Run the application, merging the info of the certificates and the employees
sub run {
    my $self = shift;

    # Certificates are here
    my $certificate_count = 0;
    my $certs             = $self->{_certificates};
    foreach my $date ( sort keys %{$certs} ) {
        foreach my $certuser ( @{ $certs->{$date} } ) {
            my $fullname = $self->_resolve_name( $certuser->{familyname},
                $certuser->{givenname} );

            #say "Certificate found for $fullname";
            $certificate_count++;

# TODO Check if certificate date is already filled in and of is it keep the most recent one.
# Might not be required because we sort the date keys.
            if ( defined $self->{_employees}->{$fullname} ) {

                # Fill in certificate
                $self->{_employees}->{$fullname}->{cert} = $date;
            } else {

            # Oops: user not found in personel database
            #carp "Warning: employee '$fullname' not found in employee database"
                if ( ref($fullname) ) {
                    carp "Fullname is reference, this should not be the case!";
                }
                push( @{ $self->{_not_in_hr}->{cert} }, $fullname );

            }
        }
    }

    say "$certificate_count certificates found";

    my $training_count = 0;
    my $training       = $self->{_training};
    foreach my $traininguser ( @{$training} ) {
        my $fullname = $self->_resolve_name( $traininguser->{familyname},
            $traininguser->{givenname} );

        #say "Training found for $fullname";
        # TODO deduplicate this code with a local function, see above
        if ( defined $self->{_employees}->{$fullname} ) {

            # Fill in training if there is no certificate yet, otherwise notify!
            if ( !defined $self->{_employees}->{$fullname}->{cert} ) {
                $self->{_employees}->{$fullname}->{cert} = 'training';
                $training_count++;
            } else {

#carp "Warning: employee '$fullname' is both in training and has a certificate from $self->{_employees}->{$fullname}->{cert}";
            }
        } else {

           # Oops: user not found in personel database
           #carp "Warning: employee '$fullname' not found in employee database";
            push( @{ $self->{_not_in_hr}->{training} }, $fullname );
            $training_count++;
        }
    }

    say "$training_count people are in training";

    # Check people who are in training and that have a certificate
    # now run the stats, for every dienst separately report
    my $stats;
    foreach my $employee ( keys %{$self->{_employees}} ) {
        my $dienst = $self->{_employees}->{$employee}->{dienst};
        my $cert   = $self->{_employees}->{$employee}->{cert} || 'none';
        my $course = $self->{_employees}->{$employee}->{course} || 'none';

        $stats->{employee_count} += 1;

        if ( $cert eq 'none' ) {
            $stats->{$dienst}->{'not_started'}->{count} += 1;
            push( @{ $stats->{$dienst}->{'not_started'}->{list} }, $employee );
        } elsif ( $cert eq 'training' ) {
            $stats->{$dienst}->{'training'}->{count} += 1;
            push( @{ $stats->{$dienst}->{'training'}->{list} }, $employee );
        } else {
            $stats->{$dienst}->{'certified'}->{count} += 1;
            push( @{ $stats->{$dienst}->{'certified'}->{list} }, $employee );
        }

        if ( !( $course eq 'none' ) ) {
            $stats->{$dienst}->{'course'}->{count} += 1;

        }
    }

    #print Dumper($stats);

    # Display the results
    say "Dienst;Certificaat;Training;Niet gestart;Theorie";

    foreach my $dienst ( sort keys %{$stats} ) {
        next if ( $dienst eq 'employee_count' );

        if ( !defined $stats->{$dienst}->{certified}->{count} ) {
            $stats->{$dienst}->{certified}->{count} = 0;
        }
        if ( !defined $stats->{$dienst}->{training}->{count} ) {
            $stats->{$dienst}->{training}->{count} = 0;
        }
        if ( !defined $stats->{$dienst}->{not_started}->{count} ) {
            $stats->{$dienst}->{not_started}->{count} = 0;
        }
        if ( !defined $stats->{$dienst}->{course}->{count} ) {
            $stats->{$dienst}->{course}->{count} = 0;
        }
        say "$dienst;"
          . $stats->{$dienst}->{certified}->{count} . ";"
          . $stats->{$dienst}->{training}->{count} . ";"
          . $stats->{$dienst}->{not_started}->{count} . ";"
          . $stats->{$dienst}->{course}->{count};

    }

    if ( defined $self->{_not_in_hr}->{cert} ) {
        say "";
        say "Not found in the HR database while parsing certificates: "
          . scalar( @{ $self->{_not_in_hr}->{cert} } );
        foreach ( @{ $self->{_not_in_hr}->{cert} } ) {
            say;
        }
    }

    if ( defined $self->{_not_in_hr}->{training} ) {
        say "Not found in the HR database while parsing in training: "
          . scalar( @{ $self->{_not_in_hr}->{training} } );
        foreach ( @{ $self->{_not_in_hr}->{training} } ) {
            say;
        }
    }

    if ( defined $self->{_not_in_hr}->{theory} ) {
        say "Not found in the HR database while parsing theory: "
          . scalar( @{ $self->{_not_in_hr}->{theory} } );
        foreach ( @{ $self->{_not_in_hr}->{theory} } ) {
            say;
        }
    }

    #say "";
    #say "Resolved names";
    #print Dumper($self->{_resolve});
}

# Parse the employee database to extract the names and the group they are in
sub _parse_employees {

    my $self = shift;

    #my $converter = Text::Iconv -> new ("utf-8", "windows-1251");
    my $excel = Spreadsheet::XLSX->new( $self->{employees} );

    my $sheet = @{ $excel->{Worksheet} }[0];
    $sheet->{MaxRow} ||= $sheet->{MinRow};

    # Go over the rows in the sheet and extract employee info, skip first row
    foreach my $row ( $sheet->{MinRow} + 1 .. $sheet->{MaxRow} ) {
        my $dienst     = $sheet->{Cells}[$row][0]->{Val} || next;
        my $familyname = uc( $sheet->{Cells}[$row][2]->{Val} ) || "NotDefined_employee_$row";
        my $givenname  = uc( $sheet->{Cells}[$row][3]->{Val} ) || "NotDefined_employee_$row";

        my $name = "$familyname $givenname";
        $self->{_employees}->{$name} = { dienst => $dienst };

    }

}

# Parse the course database to see when the theoretical course was followed
sub _parse_course {
    my $self = shift;

    my $excel = Spreadsheet::XLSX->new( $self->{course} );

    my $sheet = @{ $excel->{Worksheet} }[0];
    $sheet->{MaxRow} ||= $sheet->{MinRow};

    # Go over the rows in the sheet and extract employee info, skip first row
    foreach my $row ( $sheet->{MinRow} + 1 .. $sheet->{MaxRow} ) {
        my $familyname = $sheet->{Cells}[$row][1]->{Val} || "NotDefined_course_$row";
        my $givenname  = $sheet->{Cells}[$row][2]->{Val} || "NotDefined_course_$row";
        $familyname = uc($familyname) || $row;
        $givenname  = uc($givenname)  || $row;

        # Ensure no leading/trailing spaces are in the name
        $familyname =~ s/^\s+//;    # strip white space from the beginning
        $familyname =~ s/\s+$//;    # strip white space from the end
        $givenname  =~ s/^\s+//;    # strip white space from the beginning
        $givenname  =~ s/\s+$//;    # strip white space from the end
        my $date = $sheet->{Cells}[$row][7]->{Val};

        # If the date is not filled in then date will be undefined.
        next if ( !defined($date) );

        my $name = $self->_resolve_name( $familyname, $givenname );

# Extract the formatted value from the cell, we can only call this function once we know the cell has a value
        $date = $sheet->{Cells}[$row][7]->value();

        # If the employee already exists: OK, go ahead and insert training
        if ( defined $self->{_employees}->{$name} ) {
            $self->{_employees}->{$name}->{course} = $date;
        } else {

#carp "Oops: employee '$name' not found in employee database while parsing the theoretical training list";
            push( @{ $self->{_not_in_hr}->{theory} }, $name );

        }
    }

}

# Try to resolve a name in case it is not found in the personel database
sub _resolve_name {
    my ( $self, $fname, $gname ) = @_;

    my $name;

    # Cleanup leading/trailing spaces

    # Straight match
    $name = uc($fname) . " " . uc($gname);
    if ( exists $self->{_employees}->{$name} ) {
        $self->{_resolve}->{straight} += 1;
        return $name;
    }

    # First try, maybe they switched familyname and givenname?
    my $orig = $name;
    $name = uc($gname) . " " . uc($fname);
    if ( exists $self->{_employees}->{$name} ) {
        $self->_fixlog( 'switcharoo', $orig, $name );
        return $name;
    }

    # Exact match but missing parts?
    $name = uc($fname) . " " . uc($gname);
    foreach my $employee ( @{ $self->{_employee_array} } ) {
        if ( $employee =~ /.*$name.*/ ) {
            $self->_fixlog( 'partial', $name, $employee );
            return $employee;
        }

        # And the reverse could also occur
        if ( $name =~ /.*$employee.*/ ) {
            $self->_fixlog( 'partial', $name, $employee );
            return $employee;
        }
    }

    # Check if we can find a match with fuzzy matching
    $name = uc($fname) . " " . uc($gname);
    my $tf = Text::Fuzzy::PP->new($name);
    $tf->set_max_distance(3);
    my $index = $tf->nearest( $self->{_employee_array} ) || -1;
    if ( $index > 0 ) {
        my $fixed = $self->{_employee_array}->[$index];
        $self->_fixlog( 'fuzzy', $name, $fixed );
        return $fixed;
    }

    # People with double given name might shorten it
    # Marie-Christine -> M.-Christine
    if ( $gname =~ /^(\w)\w+(\-\w+)$/ ) {
        $name = uc( $fname . " " . $1 . "." . "$2" );

        # Check if we can find a match with fuzzy matching
        $tf = Text::Fuzzy::PP->new($name);
        $tf->set_max_distance(3);
        my $index = $tf->nearest( $self->{_employee_array} ) || -1;
        if ( $index > 0 ) {
            my $fixed = $self->{_employee_array}->[$index];
            $self->_fixlog( 'fuzzy_short', $name, $fixed );
            return $fixed;
        }
    }

    # Or maybe they left of the 'Marie-' part of their given name,
    # try to fuzzy match after adding it
    $name = uc( $fname . " Marie-" . $gname );
    $tf   = Text::Fuzzy::PP->new($name);
    $tf->set_max_distance(3);
    $index = $tf->nearest( $self->{_employee_array} ) || -1;
    if ( $index > 0 ) {
        my $fixed = $self->{_employee_array}->[$index];
        $self->_fixlog( 'fuzzy_-marie', $name, $fixed );
        return $fixed;
    }

    # People with long given name might shorten it
    # Match those by family name (exact match) and regexp on given name
    foreach my $employee ( @{ $self->{_employee_array} } ) {
        my $f_fname = uc($fname);
        my $f_gname = uc($gname);
        $name = $f_fname . " " . $f_gname;

        if ( $employee =~ /(\w+)\s(\w+)/ ) {
            my $e_fname = $1;
            my $e_gname = $2;

            if ( $e_fname =~ /$f_fname/ && $e_gname =~ /$f_gname/ ) {
                $self->_fixlog( 'partial', $name, $employee );
                return $employee;
            }
        }
    }

    # Report no match found
    #say "No match in employee database for '$name'";
    $self->{_resolve}->{nomatch} += 1;
    return $name;

}

# Log resolved names so that they can be used for later reference
sub _fixlog {
    my ( $self, $type, $original, $fixed ) = @_;

    #say "$type match for '$original', replaced by '$fixed'";
    $self->{_resolve}->{$type} += 1;
    push(
        @{ $self->{_resolve_list} },
        { $original => { fixed => $fixed, type => $type } }
    );

}

# Speed up the Moose object construction
__PACKAGE__->meta->make_immutable;
no Moose;
1;

# ABSTRACT: Application to merge various datasets info an overview of who followed CPR training (cardiopulmonary resuscitation, the use of rescue breathing and chest compressions to help a person whose breathing and heartbeat have stopped)

__END__

=pod

=encoding UTF-8

=head1 NAME

App::CPRReporter - Application to merge various datasets info an overview of who followed CPR training (cardiopulmonary resuscitation, the use of rescue breathing and chest compressions to help a person whose breathing and heartbeat have stopped)

=head1 VERSION

version 0.03

=head1 SYNOPSIS

my $object = App::CPRReporter->new(parameter => 'text.txt');

=head1 DESCRIPTION

This application parses various datasets and fuses the information to generate an overview of
who followed the theoretical part and the practical part of a course on CPR (cardiopulmonary
resuscitation, the use of rescue breathing and chest compressions to help a person whose
breathing and heartbeat have stopped).

More specifically, this application was written to take into account the following information:

=over

=item An Excel document of the employee database, containing familyname (column C), given name (column D) and group (column A)

=item An XML document extracted from the training station software (see Text::ResusciAnneparser)

=item An Ecxel document of the people who followed training, containing familyname (column B), given name (column D) and course date (column H)

=back

This application solves two problems, firstly it automates the task of generating an overview of what people in what group already followed training and who not.
Secondly, the application also automates name resolving. The two Excel documents are generated by the personel department and hence should have to correct
names. However, the XML document is filled with user-typed input. Hence the name matching between all datasets needs do be done taking into account typos, inverse input, shortened names, ...

=head1 METHODS

=head2 C<new(%parameters)>

This constructor returns a new App::CPRReporter object. Supported parameters are listed below

=over

=item employees

The filename of the Excel document (Office 2007 format) with a full list of people that should follow the course.

=item certificates

The filename of the XML document extracted from the training software.

=item course

The filename of the Excel document (Office 2007 format) with an overview of people that followed the theoretical trainging.

=back

=head2 C<run()>

Run the application and print out the result.

=head2 BUILD

Helper function to run custome code after the object has been created by Moose.

=head1 TODO

Currently, the application prints output to STDOUT in a CSV format. Future versions could write to Excel immediately.

=head1 AUTHOR

Lieven Hollevoet <hollie@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Lieven Hollevoet.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
