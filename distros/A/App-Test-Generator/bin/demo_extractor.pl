#!/usr/bin/env perl

=head1 NAME

demo_extractor.pl - Demonstrate the schema extractor

=head1 DESCRIPTION

This script demonstrates the schema extractor by:
1. Creating a temporary sample module
2. Running the extractor on it
3. Showing the generated schemas
4. Comparing them to expected results

=cut

use strict;
use warnings;
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use File::Spec;
use FindBin;
use lib "$FindBin::Bin/../lib";

use App::Test::Generator::SchemaExtractor;

print "=" x 70 . "\n";
print "Schema Extractor Demonstration\n";
print "=" x 70 . "\n\n";

# Create temporary directory for our test
my $tempdir = tempdir(CLEANUP => 1);
my $lib_dir = File::Spec->catdir($tempdir, 'lib');
my $schema_dir = File::Spec->catdir($tempdir, 'schemas');

make_path($lib_dir);

print "Setup:\n";
print "  Temp directory: $tempdir\n";
print "  Library directory: $lib_dir\n";
print "  Schema directory: $schema_dir\n\n";

# Create sample module file
my $sample_module = File::Spec->catfile($lib_dir, 'Sample.pm');

open my $fh, '>', $sample_module or die "Can't create sample module: $!";
print $fh <<'END_MODULE';
package Sample;

use strict;
use warnings;
use Carp qw(croak);

=head1 NAME

Sample - Example module for testing

=head2 validate_email($email)

Validates an email address.

Parameters:
  $email - string (5-254 chars), email address

Returns: 1 if valid

=cut

sub validate_email {
    my ($self, $email) = @_;

    croak "Email required" unless defined $email;
    croak "Email too short" unless length($email) >= 5;
    croak "Email too long" unless length($email) <= 254;
    croak "Invalid format" unless $email =~ /^[^@]+@[^@]+\.[^@]+$/;

    return 1;
}

=head2 calculate_age($birth_year)

Calculate age from birth year.

Parameters:
  $birth_year - integer (1900-2024), year of birth

Returns: age in years

=cut

sub calculate_age {
    my ($self, $birth_year) = @_;

    croak "Birth year required" unless defined $birth_year;
    croak "Invalid year" unless $birth_year >= 1900 && $birth_year <= 2024;

    return 2024 - $birth_year;
}

=head2 greet($name, $greeting)

Generate greeting.

Parameters:
  $name - string (1-50 chars), person's name
  $greeting - string (optional), custom greeting

Returns: greeting string

=cut

sub greet {
    my ($self, $name, $greeting) = @_;

    croak "Name required" unless defined $name;
    croak "Name too long" unless length($name) <= 50;

    $greeting ||= "Hello";
    return "$greeting, $name!";
}

=head2 mystery($x)

Does something mysterious.

=cut

sub mystery {
    my ($self, $x) = @_;
    return $x * 2;
}

1;
END_MODULE

close $fh;

print "Created sample module: $sample_module\n\n";

# Run the extractor
print "Running Schema Extractor...\n";
print "-" x 70 . "\n\n";

my $extractor = App::Test::Generator::SchemaExtractor->new(
    input_file => $sample_module,
    output_dir => $schema_dir,
    verbose    => 1,
);

my $schemas = $extractor->extract_all();

print "\n" . "=" x 70 . "\n";
print "RESULTS\n";
print "=" x 70 . "\n\n";

# Display each schema
foreach my $method (sort keys %$schemas) {
    my $schema = $schemas->{$method};

    print "Method: $method\n";
    print "  Confidence: " . uc($schema->{_confidence}) . "\n";

    if ($schema->{new}) {
        print "  Requires: $schema->{new}->new()\n";
    }

    print "  Parameters:\n";

    if (keys %{$schema->{input}}) {
        foreach my $param (sort keys %{$schema->{input}}) {
            my $p = $schema->{input}{$param};
            print "    $param:\n";
            print "      type: " . ($p->{type} || 'unknown') . "\n";
            print "      min: $p->{min}\n" if defined $p->{min};
            print "      max: $p->{max}\n" if defined $p->{max};
            print "      optional: " . ($p->{optional} ? 'yes' : 'no') . "\n"
                if defined $p->{optional};
            print "      matches: $p->{matches}\n" if $p->{matches};
        }
    } else {
        print "    (none detected)\n";
    }

    if ($schema->{_notes} && @{$schema->{_notes}}) {
        print "  Notes:\n";
        foreach my $note (@{$schema->{_notes}}) {
            print "    - $note\n";
        }
    }

    print "\n";
}

# Verify accuracy
print "=" x 70 . "\n";
print "ACCURACY CHECK\n";
print "=" x 70 . "\n\n";

my %expected = (
    validate_email => {
        confidence => 'high',
        params => {
            email => {
                type => 'string',
                min => 5,
                max => 254,
                has_regex => 1,
            }
        }
    },
    calculate_age => {
        confidence => 'high',
        params => {
            birth_year => {
                type => 'integer',
                min => 1900,
                max => 2024,
            }
        }
    },
    greet => {
        confidence => 'high',
        params => {
            name => {
                type => 'string',
                max => 50,
            },
            greeting => {
                type => 'string',
                optional => 1,
            }
        }
    },
    mystery => {
        confidence => 'low',
        params => {
            x => {
                type => 'unknown',
            }
        }
    },
);

my $passed = 0;
my $failed = 0;

foreach my $method (sort keys %expected) {
    print "Testing $method:\n";

    my $schema = $schemas->{$method};
    my $expect = $expected{$method};

    # Check confidence
    if ($schema->{_confidence} eq $expect->{confidence}) {
        print "  ✓ Confidence: $schema->{_confidence}\n";
        $passed++;
    } else {
        print "  ✗ Confidence: expected $expect->{confidence}, got $schema->{_confidence}\n";
        $failed++;
    }

    # Check parameters
    foreach my $param (keys %{$expect->{params}}) {
        my $got = $schema->{input}{$param};
        my $exp = $expect->{params}{$param};

        if ($got) {
            if ($exp->{type} ne 'unknown' && $got->{type} eq $exp->{type}) {
                print "  ✓ $param type: $got->{type}\n";
                $passed++;
            } elsif ($exp->{type} eq 'unknown' && !$got->{type}) {
                print "  ✓ $param type: unknown (as expected)\n";
                $passed++;
            } else {
                print "  ✗ $param type: expected $exp->{type}, got " .
                      ($got->{type} || 'none') . "\n";
                $failed++;
            }

            if (defined $exp->{min}) {
                if (defined $got->{min} && $got->{min} == $exp->{min}) {
                    print "  ✓ $param min: $got->{min}\n";
                    $passed++;
                } else {
                    print "  ✗ $param min: expected $exp->{min}, got " .
                          ($got->{min} || 'none') . "\n";
                    $failed++;
                }
            }

            if (defined $exp->{max}) {
                if (defined $got->{max} && $got->{max} == $exp->{max}) {
                    print "  ✓ $param max: $got->{max}\n";
                    $passed++;
                } else {
                    print "  ✗ $param max: expected $exp->{max}, got " .
                          ($got->{max} || 'none') . "\n";
                    $failed++;
                }
            }

            if ($exp->{has_regex}) {
                if ($got->{matches}) {
                    print "  ✓ $param has regex pattern\n";
                    $passed++;
                } else {
                    print "  ✗ $param missing regex pattern\n";
                    $failed++;
                }
            }
        } else {
            print "  ✗ $param not detected\n";
            $failed++;
        }
    }

    print "\n";
}

print "=" x 70 . "\n";
print "SUMMARY\n";
print "=" x 70 . "\n\n";

print "Total checks: " . ($passed + $failed) . "\n";
print "Passed: $passed\n";
print "Failed: $failed\n";

my $success_rate = $passed / ($passed + $failed) * 100;
printf "Success rate: %.1f%%\n\n", $success_rate;

if ($success_rate >= 80) {
    print "✓ EXCELLENT - Extractor is working well!\n";
} elsif ($success_rate >= 60) {
    print "✓ GOOD - Extractor is functional with room for improvement\n";
} else {
    print "✗ NEEDS WORK - Extractor needs debugging\n";
}

print "\n" . "=" x 70 . "\n";
print "Generated schema files in: $schema_dir/\n";
print "You can inspect them manually for more details.\n";
print "=" x 70 . "\n";

__END__
