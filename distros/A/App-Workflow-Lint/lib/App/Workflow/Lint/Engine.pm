package App::Workflow::Lint::Engine;

use strict;
use warnings;
use Carp qw(croak carp);

use YAML::XS qw(DumpFile);
use App::Workflow::Lint::YAML;
use App::Workflow::Lint::Rule::MissingPermissions;
use App::Workflow::Lint::Rule::MissingTimeout;
use App::Workflow::Lint::Rule::UnpinnedActions;
use App::Workflow::Lint::Rule::MissingConcurrency;
use App::Workflow::Lint::Rule::DeprecatedSetEnv;
use App::Workflow::Lint::Rule::MissingRunsOn;

=head1 NAME

App::Workflow::Lint::Engine - Workflow loading, rule execution, and fixing

=head1 SYNOPSIS

  use App::Workflow::Lint::Engine;

  my $engine = App::Workflow::Lint::Engine->new;

  my $wf  = $engine->load_workflow('workflow.yml');
  my @diags = $engine->check_file('workflow.yml');

  my ($fixed, $diags) = $engine->fix_file('workflow.yml');

=head1 DESCRIPTION

C<App::Workflow::Lint::Engine> is responsible for loading workflow files,
running linting rules, and applying automatic fixes where available.

It is used internally by C<App::Workflow::Lint> and the
C<workflow-lint> CLI.

=head1 METHODS

=head2 new

  my $engine = App::Workflow::Lint::Engine->new(%opts);

Creates a new engine instance.

=head2 load_workflow

  my $wf = $engine->load_workflow($file);

Reads the YAML workflow file and returns the parsed data structure.
Position information is stored internally but currently unused.

=head2 save_workflow

  $engine->save_workflow($file, $wf);

Writes the modified workflow back to disk.

=head2 rules

  my @rules = $engine->rules;

Returns the list of linting rule objects applied to workflows.

=head2 check_file

  my @diagnostics = $engine->check_file($file);

Runs all linting rules against the workflow and returns diagnostics.

=head2 apply_fixes

  $engine->apply_fixes($workflow, @diagnostics);

Executes fix callbacks for any diagnostics that provide them.

=head2 fix_file

  my ($workflow, $diagnostics) = $engine->fix_file($file);

Loads the workflow, applies rules, executes fixes, and returns the
modified workflow and diagnostics.

=head2 line_for_path

  my $line = $engine->line_for_path($file, $path);

Returns the stored line number for a given YAML path. Currently always
undef, retained for API compatibility.

=cut

#----------------------------------------------------------------------

sub new {
	my ($class, %opts) = @_;
	return bless { %opts }, $class;
}

#----------------------------------------------------------------------

sub load_workflow {
	my ($self, $file) = @_;

	# Read the YAML file
	open my $fh, '<', $file
		or croak "Cannot open workflow file '$file': $!";
	local $/;
	my $yaml_text = <$fh>;
	close $fh;

	# Load YAML (returns $data, $positions)
	my ($wf, $pos) = App::Workflow::Lint::YAML->load_yaml($yaml_text);

	# Store positions (empty hashref now)
	$self->{_positions}{$file} = $pos;

	return $wf;
}

#----------------------------------------------------------------------

sub save_workflow {
	my ($self, $file, $wf) = @_;

	DumpFile($file, $wf);

	return 1;
}

#----------------------------------------------------------------------

sub rules {
	return (
		App::Workflow::Lint::Rule::MissingPermissions->new,
		App::Workflow::Lint::Rule::MissingTimeout->new,
		App::Workflow::Lint::Rule::UnpinnedActions->new,
		App::Workflow::Lint::Rule::MissingConcurrency->new,
		App::Workflow::Lint::Rule::DeprecatedSetEnv->new,
		App::Workflow::Lint::Rule::MissingRunsOn->new,
	);
}

#----------------------------------------------------------------------

sub check_file {
	my ($self, $file) = @_;

	my $wf = $self->load_workflow($file);
	my @results;

	for my $rule ($self->rules) {
		my @r = $rule->check($wf, { file => $file });
		push @results, @r if @r;
	}

	return @results;
}

#----------------------------------------------------------------------
# apply_fixes($workflow, @diagnostics)
#
# Applies all fix coderefs returned by rules.
#----------------------------------------------------------------------

sub apply_fixes {
	my ($self, $wf, @diags) = @_;

	for my $d (@diags) {
		next unless $d->{fix};
		$d->{fix}->($wf);   # Execute the fix
	}

	return $wf;
}

#----------------------------------------------------------------------
# fix_file($file)
#
# Loads workflow, runs rules, applies fixes, returns modified workflow.
#----------------------------------------------------------------------

sub fix_file {
	my ($self, $file) = @_;

	my $wf = $self->load_workflow($file);
	my @diags = $self->check_file($file);

	$self->apply_fixes($wf, @diags);

	return ($wf, \@diags);
}

sub line_for_path {
	my ($self, $file, $path) = @_;
	return $self->{_positions}{$file}{$path};
}

1;
