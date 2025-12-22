#!/usr/bin/env perl
use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test::DescribeMe qw(extended);
use Test::Most;
use File::Temp qw(tempdir);

# Load the module
BEGIN {
	use_ok('App::Test::Generator::SchemaExtractor');
}
# Tests for Modern Perl Features Support

# Helper to create a temporary Perl module file
sub create_test_module {
	my $content = $_[0];
	my $dir = tempdir(CLEANUP => 1);
	my $file = File::Spec->catfile($dir, 'TestModule.pm');
	open my $fh, '>', $file or die "Cannot create $file: $!";
	print $fh $content;
	close $fh;
	return $file;
}

# Helper to create an extractor for testing
sub create_extractor {
	my $module_content = $_[0];
	my $module_file = create_test_module($module_content);
	return App::Test::Generator::SchemaExtractor->new(
		input_file => $module_file,
		output_dir => tempdir(CLEANUP => 1),
		verbose	=> $ENV{'TEST_VERBOSE'} ? 1 : 0,
	);
}

subtest 'Modern Signatures (Perl 5.20+)' => sub {
    my $module = <<'END_MODULE';
package Test::ModernSignatures;
use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

=head2 connect

Connect to database with modern signature.

=cut

sub connect($self, $host, $port = 3306, $database = undef) {
    return "Connected to $host:$port";
}

=head2 process_data

Process with slurpy parameters.

=cut

sub process_data($self, $file, %options) {
    return keys %options;
}

=head2 simple_calc

Simple function without $self.

=cut

sub simple_calc($x, $y = 0) {
    return $x + $y;
}

END_MODULE

    my $extractor = create_extractor($module);
    my $schemas = $extractor->extract_all();

    # Test connect method
    my $connect = $schemas->{connect};
    ok($connect, 'Found connect method');

    is($connect->{input}{host}{position}, 0, 'host is first parameter');
    is($connect->{input}{host}{optional}, 0, 'host is required');

    is($connect->{input}{port}{position}, 1, 'port is second parameter');
    is($connect->{input}{port}{optional}, 1, 'port is optional');
    is($connect->{input}{port}{default}, 3306, 'port default is 3306');

    is($connect->{input}{database}{position}, 2, 'database is third parameter');
    is($connect->{input}{database}{optional}, 1, 'database is optional');
    is($connect->{input}{database}{default}, undef, 'database default is undef');

    # Test process_data with slurpy hash
    my $process = $schemas->{process_data};
    is($process->{input}{file}{position}, 0, 'file is first parameter');
    is($process->{input}{options}{type}, 'hash', 'options is hash type');
    ok($process->{input}{options}{slurpy}, 'options is slurpy parameter');
    ok($process->{input}{options}{optional}, 'slurpy parameters are optional');

    # Test simple function without $self
    my $calc = $schemas->{simple_calc};
    is($calc->{input}{x}{position}, 0, 'x is first parameter');
    is($calc->{input}{y}{optional}, 1, 'y is optional');
    is($calc->{input}{y}{default}, 0, 'y default is 0');

    done_testing();
};

subtest 'Type Constraints in Signatures (Perl 5.36+)' => sub {
    my $module = <<'END_MODULE';
package Test::TypeConstraints;
use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

sub calculate($x :Int, $y :Num, $name :Str = "result") {
    return $x + $y;
}

sub validate($flag :Bool, $items :ArrayRef) {
    return $flag;
}

sub process_user($user :UserClass) {
    return $user->name;
}

END_MODULE

    my $extractor = create_extractor($module);
    my $schemas = $extractor->extract_all();

    my $calc = $schemas->{calculate};
    is($calc->{input}{x}{type}, 'integer', 'x has integer type from :Int');
    is($calc->{input}{y}{type}, 'number', 'y has number type from :Num');
    is($calc->{input}{name}{type}, 'string', 'name has string type from :Str');
    is($calc->{input}{name}{default}, 'result', 'name has default value');

    my $validate = $schemas->{validate};
    is($validate->{input}{flag}{type}, 'boolean', 'flag has boolean type');
    is($validate->{input}{items}{type}, 'arrayref', 'items has arrayref type');

    my $process = $schemas->{process_user};
    is($process->{input}{user}{type}, 'object', 'user has object type');
    is($process->{input}{user}{isa}, 'UserClass', 'user has UserClass constraint');

    done_testing();
};

subtest 'Subroutine Attributes' => sub {
    my $module = <<'END_MODULE';
package Test::Attributes;
use strict;
use warnings;

sub get_value :lvalue {
    my $self = shift;
    return $self->{value};
}

sub calculate :Returns(Int) :method {
    my ($self, $x, $y) = @_;
    return $x + $y;
}

sub custom_attr :MyAttr(some_value) {
    my $self = shift;
    return 1;
}

END_MODULE

    my $extractor = create_extractor($module);
    my $schemas = $extractor->extract_all();

    my $get_value = $schemas->{get_value};
    ok($get_value->{_attributes}, 'get_value has attributes');
    ok($get_value->{_attributes}{lvalue}, 'Has :lvalue attribute');

    my $calculate = $schemas->{calculate};
    ok($calculate->{_attributes}{Returns}, 'Has :Returns attribute');
    is($calculate->{_attributes}{Returns}, 'Int', 'Returns Int');
    ok($calculate->{_attributes}{method}, 'Has :method attribute');

    my $custom = $schemas->{custom_attr};
    is($custom->{_attributes}{MyAttr}, 'some_value', 'Custom attribute value captured');

    done_testing();
};

subtest 'Postfix Dereferencing (Perl 5.20+)' => sub {
    my $module = <<'END_MODULE';
package Test::PostfixDeref;
use strict;
use warnings;
use feature 'postderef';
no warnings 'experimental::postderef';

sub process_array {
    my ($self, $arrayref) = @_;

    my @array = $arrayref->@*;
    my $first = $arrayref->[0];
    my @slice = $arrayref->@[1,3,5];

    return scalar @array;
}

sub process_hash {
    my ($self, $hashref) = @_;

    my %hash = $hashref->%*;
    my @keys = keys $hashref->%*;
    my %slice = $hashref->%{qw(key1 key2)};

    return scalar keys %hash;
}

sub mixed_derefs {
    my ($self, $coderef, $scalarref) = @_;

    $coderef->&*;
    my $value = $scalarref->$*;

    return $value;
}

END_MODULE

    my $extractor = create_extractor($module);
    my $schemas = $extractor->extract_all();

    my $array_proc = $schemas->{process_array};
    ok($array_proc->{_modern_features}, 'Has modern features tracking');
    ok($array_proc->{_modern_features}{postfix_dereferencing}{array_deref},
       'Uses array postfix dereference');
    ok($array_proc->{_modern_features}{postfix_dereferencing}{array_slice},
       'Uses array slice postfix');

    my $hash_proc = $schemas->{process_hash};
    ok($hash_proc->{_modern_features}{postfix_dereferencing}{hash_deref},
       'Uses hash postfix dereference');
    ok($hash_proc->{_modern_features}{postfix_dereferencing}{hash_slice},
       'Uses hash slice postfix');

    my $mixed = $schemas->{mixed_derefs};
    ok($mixed->{_modern_features}{postfix_dereferencing}{code_deref},
       'Uses code postfix dereference');
    ok($mixed->{_modern_features}{postfix_dereferencing}{scalar_deref},
       'Uses scalar postfix dereference');

    done_testing();
};

subtest 'Field Declarations (Perl 5.38+)' => sub {
    my $module = <<'END_MODULE';
package Test::Fields;
use strict;
use warnings;
use feature 'class';

class DatabaseConnection {
    field $host :param = 'localhost';
    field $port :param = 3306;
    field $username :param(user);
    field $password :param;
    field $dbh;
    field $logger :param :isa(Log::Any);

    method connect() {
        $dbh = DBI->connect("dbi:mysql:host=$host;port=$port", $username, $password);
        return $dbh;
    }
}

END_MODULE

    my $extractor = create_extractor($module);
    my $schemas = $extractor->extract_all();

    my $connect = $schemas->{connect};
    ok($connect->{_fields}, 'Found field declarations');

    # Check field -> parameter mapping
    ok($connect->{_fields}{host}, 'host field found');
    ok($connect->{_fields}{host}{is_param}, 'host is a parameter');
    is($connect->{_fields}{host}{default}, 'localhost', 'host default is localhost');

    ok($connect->{_fields}{port}, 'port field found');
    is($connect->{_fields}{port}{default}, 3306, 'port default is 3306');

    # Check renamed parameter
    is($connect->{_fields}{username}{param_name}, 'user',
       'username maps to user parameter');

    # Check type constraint
    is($connect->{_fields}{logger}{isa}, 'Log::Any',
       'logger has type constraint');

    # Check merged parameter info
    is($connect->{input}{host}{default}, 'localhost',
       'Field default merged into parameter');
    is($connect->{input}{host}{optional}, 1,
       'Parameter with default is optional');

    is($connect->{input}{user}{field_name}, 'username',
       'Parameter tracks original field name');

    done_testing();
};

subtest 'Mixed Traditional and Modern Syntax' => sub {
    my $module = <<'END_MODULE';
package Test::Mixed;
use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

# Modern signature
sub modern($self, $x, $y = 5) {
    return $x + $y;
}

# Traditional with defaults in code
sub traditional {
    my ($self, $x, $y) = @_;
    $y //= 5;
    return $x + $y;
}

# Hybrid: signature + additional processing
sub hybrid($self, $data) {
    my $processed = $data->@* if ref $data;
    return $processed;
}

END_MODULE

    my $extractor = create_extractor($module);
    my $schemas = $extractor->extract_all();

    my $modern = $schemas->{modern};
    is($modern->{input}{x}{optional}, 0, 'Modern: x is required');
    is($modern->{input}{y}{optional}, 1, 'Modern: y is optional');
    is($modern->{input}{y}{default}, 5, 'Modern: y default is 5');

    my $trad = $schemas->{traditional};
    is($trad->{input}{y}{optional}, 1, 'Traditional: y has default in code');
    is($trad->{input}{y}{default}, 5, 'Traditional: default extracted from code');

    my $hybrid = $schemas->{hybrid};
    is($hybrid->{input}{data}{position}, 0, 'Hybrid: parameter from signature');
    ok($hybrid->{_modern_features}{postfix_dereferencing}{array_deref},
       'Hybrid: uses postfix deref in body');

    done_testing();
};

subtest 'Complex Signatures with Multiple Features' => sub {
    my $module = <<'END_MODULE';
package Test::Complex;
use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

sub complex_method :Returns(HashRef) (
    $self,
    $required :Str,
    $optional :Int = 10,
    $nullable :Num = undef,
    @extra
) {
    my %result = (
        required => $required,
        optional => $optional,
        extra => \@extra
    );

    return \%result;
}

END_MODULE

    my $extractor = create_extractor($module);
    my $schemas = $extractor->extract_all();

    my $complex = $schemas->{complex_method};

    # Check attributes
    ok($complex->{_attributes}{Returns}, 'Has return type attribute');
    is($complex->{_attributes}{Returns}, 'HashRef', 'Returns HashRef');

    # Check required parameter with type
    is($complex->{input}{required}{type}, 'string', 'required has string type');
    is($complex->{input}{required}{optional}, 0, 'required is not optional');

    # Check optional with default
    is($complex->{input}{optional}{type}, 'integer', 'optional has integer type');
    is($complex->{input}{optional}{default}, 10, 'optional default is 10');

    # Check nullable with undef default
    is($complex->{input}{nullable}{type}, 'number', 'nullable has number type');
    is($complex->{input}{nullable}{default}, undef, 'nullable default is undef');

    # Check slurpy array
    is($complex->{input}{extra}{type}, 'array', 'extra is array');
    ok($complex->{input}{extra}{slurpy}, 'extra is slurpy');

    done_testing();
};

done_testing();
