package BioX::Workflow::Command::inspect;

use v5.10;
use MooseX::App::Command;
use namespace::autoclean;

use Data::Dumper;
use YAML;
use Storable qw(dclone);
use Try::Tiny;
use JSON;

extends 'BioX::Workflow::Command';
use BioSAILs::Utils::Traits qw(ArrayRefOfStrs);
use Capture::Tiny ':all';

with 'BioX::Workflow::Command::run::Rules::Directives::Walk';
with 'BioX::Workflow::Command::run::Utils::Samples';
with 'BioX::Workflow::Command::run::Utils::Attributes';
with 'BioX::Workflow::Command::run::Rules::Rules';
with 'BioX::Workflow::Command::run::Utils::WriteMeta';
with 'BioX::Workflow::Command::run::Utils::Files::TrackChanges';
with 'BioX::Workflow::Command::run::Utils::Files::ResolveDeps';
with 'BioX::Workflow::Command::Utils::Files';

use BioX::Workflow::Command::run;
use BioX::Workflow::Command::inspect::Exceptions::Path;

command_short_description 'Inspect your workflow';
command_long_description
'Inspect individual variables in your workflow. Syntax is global.var for global, or rule.rulename.var for rules. Use the --all flag to inspect all variables.';

=head1 BioX::Workflow::Command::inspect

  biox inspect -h
  biox inspect -w variant_calling.yml --path /rules/.*/local/indir

=cut

=head2 Attributes

=cut

option 'all' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

option 'step_key' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
    documentation =>
'Type any key to continue to next rule key. Type \'q\' or \'quit\' to quit.',
);

option 'step_rule' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
    documentation =>
      'Type any key to continue to next rule. Type \'q\' or \'quit\' to quit.',
);

option 'path' => (
    is        => 'rw',
    isa       => 'Str',
    required  => 0,
    predicate => 'has_path',
);

option 'json' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

option 'show_only_errors' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

=head3 samples

This is our actual list of samples

=cut

=head2 Subroutines

=cut

sub execute {
    my $self = shift;

    if ( !$self->load_yaml_workflow ) {
        $self->app_log->warn('Exiting now.');
        return;
    }

    $DB::single = 2;
    if ( $self->json ) {
        capture_stderr {
            $self->inspect;
        };

    }
    else {
        $self->inspect;
    }
}

sub inspect {
    my $self = shift;
    $self->apply_global_attributes;
    $self->global_attr->create_outdir(0);

    $self->return_global_as_object;

    $self->get_samples;
    $self->samples( ['Sample_XYZ'] );
    $self->dummy_sample('Sample_XYZ');
    $self->iterate_rules;

    $self->check_for_json;

}

sub check_for_json {
    my $self = shift;
    ##TODO These should be too different interfaces
    if ( $self->json ) {
        $self->app_log->warn(
            'You have selected a path, but this is not applied with --json')
          if $self->has_path;
        my $json =
          JSON->new->utf8->pretty->allow_blessed->encode( $self->inspect_obj );
        print $json;
    }
    else {
        $self->comment_char('');
        $self->find_inspect_obj;
    }
}

sub find_inspect_obj {
    my $self = shift;

    $self->find_inspect_obj_path if $self->has_path;

    if ( $self->all ) {
        $self->find_inspect_obj_rules( [ '', '.*', '.*', '.*', '.*' ] );
        $self->find_inspect_obj_global( [ '', '.*', '.*', '.*' ] );
    }

    $self->find_inspect_obj_select if $self->select_effect;
}

sub find_inspect_obj_select {
    my $self = shift;

    return unless $self->has_select_rule_keys;

    foreach my $rule ( @{ $self->select_rules } ) {
        $self->find_inspect_obj_rules( [ '', '.*', $rule, '.*', '.*' ] );
    }

}

sub find_inspect_obj_path {
    my $self = shift;

    my @split = split( '/', $self->path );
    if ( scalar @split >= 6 ) {
        my $except =
          BioX::Workflow::Command::inspect::Exceptions::Path->new(
            info => 'Your split path contains too many elements.'
              . ' Portions may still work, but you are probably not getting what you expect.'
          );
        $except->warn( $self->app_log );
    }
    if ( $split[1] eq 'rules' ) {
        $self->find_inspect_obj_rules( \@split );
    }
    elsif ( $split[1] eq 'global' ) {
        $self->find_inspect_obj_global( \@split );
    }
    elsif ( $split[1] eq '*' ) {
        $self->find_inspect_obj_rules( \@split );
        $self->find_inspect_obj_global( \@split );
    }
    else {
        my $except =
          BioX::Workflow::Command::inspect::Exceptions::Path->new(
            info => 'You are searching for something that does not exist.'
              . ' Please see the documentation for allowed values of dpath.' );
        $except->fatal( $self->app_log );
    }

}

sub find_inspect_obj_rules {
    my $self  = shift;
    my $split = shift;

    ##TODO Apply select_rules
    foreach my $rule ( @{ $self->rule_names } ) {
        my $rule_name = $split->[2];
        if ( !$rule_name ) {
            my $except =
              BioX::Workflow::Command::inspect::Exceptions::Path->new(
                    info => 'You must supply a  rule name '
                  . $rule
                  . ' Examples: --path /rules/.*/local/.* or --path /rules/some_rule/local/.* or --path /rules/.*/process'
              );
            $except->fatal( $self->app_log );
        }
        if ( $rule =~ m/$rule_name/ ) {
            print "Rule: $rule\n";
            my $wanted_key = $split->[4];
            if ( !$wanted_key ) {
                my $except =
                  BioX::Workflow::Command::inspect::Exceptions::Path->new(
                        info => 'You must supply a key to rule '
                      . $rule
                      . ' Examples: --path /rules/.*/local/.*, --path /rules/.*/process'
                  );
                $except->fatal( $self->app_log );
            }
            elsif ( !$split->[3] ) {
                my $except =
                  BioX::Workflow::Command::inspect::Exceptions::Path->new(
                    info => 'You must supply a local/process and key to rule '
                      . $rule
                      . ' Examples: --path /rules/.*/local/.*, --path /rules/.*/process'
                  );
                $except->fatal( $self->app_log );
            }
            elsif ( $split->[3] eq 'local' ) {
                $self->find_inspect_obj_rule_keys( $rule, $wanted_key );
            }
            elsif ( $split->[3] eq 'process' ) {
                $self->find_inspect_obj_rule_process($rule);
            }
            elsif ( $split->[3] eq '.*' ) {
                $self->find_inspect_obj_rule_keys( $rule, $wanted_key );
                $self->find_inspect_obj_rule_process($rule);
            }
        }
        &promptUser("Next rule") if $self->step_rule;
        print "\n";
    }
}

sub find_inspect_obj_rule_keys {
    my $self       = shift;
    my $rule       = shift;
    my $wanted_key = shift;
    my $seen       = 0;

    my @keys = keys %{ $self->inspect_obj->{rules}->{$rule}->{local} };
    foreach my $key (@keys) {
        $seen = 1;
        if ( $key =~ m/$wanted_key/ ) {
            my $value =
              $self->inspect_obj->{rules}->{$rule}->{local}->{$key};
            my $pp = $self->write_pretty_meta( $key, $value );
            print "Key:" . $pp . "\n";

            &promptUser("Next key") if $self->step_key;
        }
    }
    $self->app_log->warn( 'We were not able to find key ' . $wanted_key )
      unless $seen;
}

sub find_inspect_obj_rule_process {
    my $self = shift;
    my $rule = shift;

    my $texts = $self->process_obj->{$rule}->{text};
    return unless $texts;
    print "Process:\t" . $texts->[0] . "\n";
}

sub find_inspect_obj_global {
    my $self  = shift;
    my $split = shift;

    my $wanted_key = $split->[2];
    print "Global\n";
    my $seen = 0;

    my @keys = keys %{ $self->inspect_obj->{global} };
    foreach my $key (@keys) {
        if ( $key =~ m/$wanted_key/ ) {
            $seen = 1;
            my $value = $self->inspect_obj->{global}->{$key};
            my $pp = $self->write_pretty_meta( $key, $value );
            print "Key:" . $pp . "\n";
        }
    }

    $self->app_log->warn( 'We were not able to find key ' . $wanted_key )
      unless $seen;
}

sub promptUser {
    my $promptString = shift;
    my $defaultValue = shift;

    if ($defaultValue) {
        print $promptString, "[", $defaultValue, "]: ";
    }
    else {
        $defaultValue = "";
        print $promptString, ": ";
    }

    $| = 1;          # force a flush after our print
    $_ = <STDIN>;    # get the input from STDIN (presumably the keyboard)

    chomp;

    my $retvalue;
    if ("$defaultValue") {
        $retvalue = $_ ? $_ : $defaultValue;    # return $_ if it has a value
    }
    else {
        $retvalue = $_;
    }

    if ( $retvalue eq 'q' || $retvalue eq 'quit' ) {
        exit 0;
    }
}

__PACKAGE__->meta->make_immutable;

1;
