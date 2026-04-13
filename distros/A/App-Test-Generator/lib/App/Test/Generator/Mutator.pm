package App::Test::Generator::Mutator;

use strict;
use warnings;

use File::Temp qw(tempdir);
use File::Copy::Recursive qw(dircopy);
use File::Copy qw(copy);
use File::Path;
use File::Spec;
use PPI;

use App::Test::Generator::Mutation::BooleanNegation;
use App::Test::Generator::Mutation::ReturnUndef;
use App::Test::Generator::Mutation::NumericBoundary;
use App::Test::Generator::Mutation::ConditionalInversion;

=head1 NAME

App::Test::Generator::Mutator - Generate mutation tests

=head1 VERSION

Version 0.32

=head1 DESCRIPTION

B<App::Test::Generator::Mutator> is a mutation engine that programmatically alters Perl source files to evaluate the effectiveness of a project's test suite.
It analyzes modules, generates systematic code mutations (such as conditional inversions,
logical operator changes,
and other behavioral tweaks),
and applies them within an isolated workspace so tests can be executed safely against each modified variant.
By tracking which mutants are "killed" (cause tests to fail) versus those that "survive" (tests still pass),
the module enables calculation of a mutation score,
providing a quantitative measure of how well the test suite detects unintended behavioral changes.

=cut

sub new {
	my ($class, %args) = @_;

	die 'file required' unless $args{file};

	my $self = bless {
		file => $args{file},
		lib_dir => $args{lib_dir} || 'lib',
		mutation_level => $args{mutation_level} || 'full',	# full or fast
		mutations => [
			App::Test::Generator::Mutation::BooleanNegation->new(),
			App::Test::Generator::Mutation::ReturnUndef->new(),
			App::Test::Generator::Mutation::NumericBoundary->new(),
			App::Test::Generator::Mutation::ConditionalInversion->new()
		],
	}, $class;

	return $self;
}

sub generate_mutants {
	my $self = $_[0];

	my $doc = PPI::Document->new($self->{file}) or die "Unable to parse $self->{file}";

	my @mutants;

	for my $mutation (@{$self->{mutations}}) {
		push @mutants, $mutation->mutate($doc);
	}

	if($self->{mutation_level} eq 'fast') {
		return @{_dedup_mutants(\@mutants)};
	}
	return @mutants;
}

sub apply_mutant {
	my ($self, $mutant) = @_;

	my $workspace = $self->{workspace} or die 'Workspace not prepared';

	my $relative = $self->{relative} or die 'Relative path not set';

	my $target = File::Spec->catfile(
		$workspace,
		$self->{lib_dir},
		$relative,
	);

	my $doc = PPI::Document->new($target) or die "Failed to parse $target";

	$mutant->{transform}->($doc);

	$doc->save($target);
}

sub revert {
	my $self = $_[0];

	copy("$self->{file}.bak", $self->{file}) or die 'Restore failed';
}

sub run_tests {
	my $self = $_[0];

	return system($^X, '-Mblib', '$(which prove)', '-l', 't/') == 0;
}

=head2 prepare_workspace

Prepares an isolated temporary workspace for a single mutation test run.

The entire C<lib/> tree is copied into the workspace so that all module
dependencies resolve correctly when the test suite runs against the mutant.
Only after this copy is complete is the single target file overwritten by
C<apply_mutant>.

=head3 Arguments

Takes no arguments beyond the invocant.

=head3 Returns

A string containing the absolute path to the temporary directory that was created.
The directory is automatically removed when the
C<App::Test::Generator::Mutator> object goes out of scope (via
L<File::Temp>'s C<CLEANUP =E<gt> 1> behaviour).

=head3 Side Effects

=over 4

=item *

Creates a temporary directory under the system's default temp location.

=item *

Recursively copies the entire C<lib_dir> tree (default C<lib/>) into the
workspace using C<File::Copy::Recursive::dircopy>.

=item *

Sets C<< $self->{workspace} >> to the absolute path of the temporary directory.

=item *

Sets C<< $self->{relative} >> to the path of the target file relative to
C<lib_dir>, for use by C<apply_mutant>.

=back

=head3 Notes

The workspace is only valid for a single file's mutation run.  Call
C<prepare_workspace> once per file, then call C<apply_mutant> once per
mutant within that file.  Because C<CLEANUP =E<gt> 1> is set, the workspace
is silently removed when the tempdir handle is garbage collected - do not
store the path beyond the lifetime of the enclosing scope.

=head3 Example

    my $mutator = App::Test::Generator::Mutator->new(
        file    => 'lib/My/Module.pm',
        lib_dir => 'lib',
    );

    my @mutants = $mutator->generate_mutants();

    for my $mutant (@mutants) {
        my $workspace = $mutator->prepare_workspace();

        $mutator->apply_mutant($mutant);

        local $ENV{PERL5LIB} = "$workspace/lib";
        my $survived = (system('prove', 't') == 0);

        # workspace cleaned up automatically when $workspace goes out of scope
    }

=head3 API Specification

=head4 Input

    # Params::Validate::Strict schema
    {
        # No named parameters - invocant only.
        # Required state (validated by new()):
        #   file    => { type => SCALAR, callbacks => { 'file exists' => sub { -f $_[0] } } }
        #   lib_dir => { type => SCALAR, default => 'lib' }
    }

=head4 Output

    # Return::Set schema
    {
        type        => SCALAR,
        description => 'Absolute path to the temporary workspace directory',
        callbacks   => {
            'is absolute path' => sub { File::Spec->file_name_is_absolute($_[0]) },
            'directory exists' => sub { -d $_[0] },
        },
    }

=cut

sub prepare_workspace {
	my $self = $_[0];

	my $tmp = tempdir(CLEANUP => 1);

	my $src = $self->{file};

	# Derive relative path automatically
	my $relative = $src;
	$relative =~ s/^\Q$self->{lib_dir}\E\/?//;

	# Copy the entire lib tree so dependencies resolve correctly
	dircopy($self->{lib_dir}, File::Spec->catfile($tmp, $self->{lib_dir}))
		or die "dircopy failed: $!";

	$self->{workspace} = $tmp;
	$self->{relative}  = $relative;

	return $tmp;
}

sub _dedup_mutants
{
	my $mutants = $_[0];
	my @rc;
	my %seen;

	for my $m (@{$mutants}) {
		my $key = join '|',
			$m->{line},
			$m->{original},
			$m->{transform};

		next if $seen{$key}++;

		next if _is_redundant_mutation($m);

		push @rc, $m;
	}

	return \@rc;
}

sub _is_redundant_mutation {
	my $m = $_[0];

	my $orig = $m->{original} // '';
	my $new = $m->{transform} // '';

	# Exact same code (safety guard)
	return 1 if $orig eq $new;

	# Arithmetic no-op
	return 1 if $orig =~ /\+\s*0$/;
	return 1 if $orig =~ /-\s*0$/;

	# Double negation, because in Perl they force a boolean context
	if ($m->{context} && $m->{context} eq 'conditional') {
		# Only skip double negation removal inside conditionals
		return 1 if $orig =~ /^\!\!/;
	}

	# Boolean literal flip when already strict boolean
	return 1 if $orig =~ /^\s*(?:1|0)\s*$/;

	# Mutation inside comment
	return 1 if $m->{line_content} && $m->{line_content} =~ /^\s*#/;

	# Equivalent numeric comparison
	if ($orig =~ /^\d+$/ && $new =~ /^\d+$/) {
		return 1 if $orig == $new;
	}

	return 0;
}

=head1 SEE ALSO

=over 4

=item C<bin/app-test-generator-mutate>

=item L<Devel::Mutator>

=back

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

Portions of this module's initial design and documentation were created with the
assistance of AI.

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to licence terms.

The licence terms of this software are as follows:

=over 4

=item * Personal single user, single computer use: GPL2

=item * All other users (including Commercial, Charity, Educational, Government)
  must apply in writing for a licence for use from Nigel Horne at the
  above e-mail.

=back

=cut

1;
