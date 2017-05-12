package App::CharmKit::Role::Lint;
$App::CharmKit::Role::Lint::VERSION = '2.07';
# ABSTRACT: CharmKit Lint Role

use strict;
use warnings;
no warnings 'experimental::signatures';
use feature 'signatures';

use YAML::Tiny;
use Path::Tiny;
use File::ShareDir qw(dist_file);
use Set::Tiny;
use Email::Address;

use Class::Tiny {
    rules     => YAML::Tiny->read(dist_file('App-CharmKit', 'lint_rules.yaml')),
    has_error => 0
};

sub parse($self) {

    # Check attributes
    my $rules = $self->rules->[0];
    foreach my $meta (@{$rules->{files}}) {
        $self->validate_attributes($meta);
        if ($meta->{name} =~ /^metadata\.yaml/) {
            $self->validate_metadata($meta);
        }
        if ($meta->{name} =~ /^config\.yaml/) {
            $self->validate_configdata($meta);
        }
    }

    # Check for a hooks path
    if (!path('hooks')->exists) {
        $self->lint_fatal('hooks/', 'No hooks directory.');
    }
    else {
        foreach my $hook (@{$rules->{hooks}}) {
            $self->validate_hook($hook);
        }
    }

    # Check for a tests path
    if (!path('tests')->exists) {
        $self->lint_fatal('tests/', 'No tests directory.');
    }
    else {
        $self->validate_tests;
    }

    # Check for icon.svg
    $self->lint_warn('icon.svg', 'No icon.svg')
      unless path('icon.svg')->exists;
}


sub validate_tests($self) {
    my $tests_path = path('tests');
    $self->lint_fatal('00-autogen', 'Includes template test file, tests/00-autogen')
      if ($tests_path->child('00-autogen')->exists);
}

sub validate_configdata ($self, $configdata) {
    my $config_on_disk = YAML::Tiny->read($configdata->{name})->[0];
    my $filepath       = path($configdata->{name});

    # This needs to be a hash
    if (ref($config_on_disk) ne 'HASH') {
        $self->lint_fatal($filepath, 'config.yaml is not properly formatted.');
    }

    # No root options key
    $self->lint_fatal($configdata->{name}, 'options is not the toplevel root key.')
      unless defined($config_on_disk->{options});

    my $known_option_keys = Set::Tiny->new(qw/type description default/);
    foreach my $option (keys %{$config_on_disk->{options}}) {
        my $check_opt            = $config_on_disk->{options}->{$option};
        my $existing_option_keys = Set::Tiny->new(keys %{$check_opt});

        # Missing required keys for an option
        my $missing_keys = $known_option_keys->difference($existing_option_keys);
        $self->lint_fatal($filepath, sprintf("Missing required keys for %s: %s", $option, $missing_keys->as_string))
          unless $missing_keys->is_empty
          || $check_opt->{type} =~ /^(int|float|string)/;

        # Invalid keys in config option
        my $invalid_keys = $existing_option_keys->difference($known_option_keys);
        $self->lint_fatal($filepath, sprintf("Unknown keys for %s: %s", $option, $invalid_keys->as_string))
          unless $invalid_keys->is_empty;
    }

}


sub validate_metadata ($self, $metadata) {
    my $meta_on_disk = YAML::Tiny->read($metadata->{name})->[0];
    my $filepath     = path($metadata->{name});

    # sets
    my $meta_keys_set         = Set::Tiny->new(@{$metadata->{known_meta_keys}});
    my $meta_keys_on_disk_set = Set::Tiny->new(keys %{$meta_on_disk});

    # Check directory name against metadata name
    my $base_dirname = path('.')->absolute->basename;
    if ($base_dirname ne $meta_on_disk->{name}) {
        $self->lint_fatal($metadata->{name},
            sprintf('metadata name(%s) doesnt match directory name(%s)', $meta_on_disk->{name}, $base_dirname));
    }

    # Verify required meta keys
    my $meta_key_optional_set = Set::Tiny->new;
    my $meta_key_required_set = Set::Tiny->new;
    foreach my $metakey (@{$metadata->{known_meta_keys}}) {
        if ($metakey =~ /^(name|summary|description)/
            && !defined($meta_on_disk->{$metakey}))
        {
            $meta_key_required_set->insert($metakey);
        }
        elsif (!defined($meta_on_disk->{$metakey})) {

            # Charm must provide at least one thing
            if ($metakey eq 'provides') {
                $self->lint_fatal($metadata->{name}, sprintf('Charm must provide at least one thing: %s', $metakey));
            }
            else {
                $meta_key_optional_set->insert($metakey);
            }
        }
    }
    $self->lint_fatal($metadata->{name}, sprintf('Missing required item(s): %s', $meta_key_required_set->as_string))
      unless $meta_key_required_set->is_empty;

    $self->lint_info($metadata->{name}, sprintf('Missing optional item(s): %s', $meta_key_optional_set->as_string))
      unless $meta_key_optional_set->is_empty;


    # MAINTAINER
    # Make sure there isn't maintainer and maintainers listed
    if ($meta_keys_on_disk_set->contains(qw/maintainer maintainers/)) {
        $self->lint_fatal($metadata->{name}, "Can not have maintainer and maintainer(s) listed. " . "Only pick one.");
    }

    # no maintainer and maintainers isn't defined
    if (!$meta_keys_on_disk_set->contains(qw/maintainer/)) {
        $self->lint_fatal($metadata->{name}, "Need at least a Maintainer or Maintainers Field defined.");
    }

    my $maintainers = [];
    if (defined($meta_on_disk->{maintainer})) {
        if (ref $meta_on_disk->{maintainer} eq 'ARRAY') {
            $self->lint_fatal($metadata->{name}, 'Maintainer field must not be a list');
        }
        else {
            push @{$maintainers}, $meta_on_disk->{maintainer};
        }
    }

    if (defined($meta_on_disk->{maintainers})) {
        if (ref $meta_on_disk->{maintainers} ne 'ARRAY') {
            $self->lint_fatal($metadata->{name}, 'Maintainers field must be a list');
        }
        else {
            push @{$maintainers}, @{$meta_on_disk->{maintainers}};
        }
    }

    # validate email format
    my $email_invalid = 0;
    foreach my $m (@{$maintainers}) {
        my @addresses = Email::Address->parse($m);
        $email_invalid = 1
          unless (ref $addresses[0] eq 'Email::Address');
    }
    if ($email_invalid) {
        $self->lint_fatal($metadata->{name}, sprintf("Maintainer format should be 'Name <email>'"));
    }


    # check for keys not known to charm
    my $invalid_keys = $meta_keys_on_disk_set->difference($meta_keys_set);
    $self->lint_fatal($metadata->{name}, sprintf("Unknown key: %s", $invalid_keys->as_string))
      unless $invalid_keys->is_empty;

    # check if relations defined
    my $missing_relation = Set::Tiny->new;
    foreach my $relation (@{$metadata->{known_relation_keys}}) {
        $missing_relation->insert($relation)
          unless $meta_keys_on_disk_set->contains([$relation]);
    }
    $self->lint_warn($metadata->{name}, sprintf("Missing relation item(s): %s", $missing_relation->as_string))
      unless $missing_relation->is_empty;

    # no revision key should exist
    if (defined($meta_on_disk->{revision})) {
        $self->lint_fatal($metadata->{name},
            'Revision should not be stored in metadata.yaml. ' . 'Move to a revision file.');
    }

    # TODO lint subordinate
    # TODO lint peers

    foreach my $re (@{$metadata->{parse}}) {

        # Dont parse if file doesn't exist and wasn't required
        next if !$filepath->exists;
        my $input  = $filepath->slurp_utf8;
        my $search = $re->{pattern};
        if ($input !~ /$search/m) {
            $self->lint_warn($filepath, 'Failed to parse.');
        }
    }
}


sub validate_hook ($self, $hookmeta) {
    my $filepath = path('hooks')->child($hookmeta->{name});
    my $name     = $filepath->stringify;
    foreach my $attr (@{$hookmeta->{attributes}}) {
        if ($attr =~ /EXISTS/) {
            $self->lint_fatal($name, 'Required hook does not exist')
              unless $filepath->exists;
        }
        if ($attr =~ /NOT_EMPTY/ && -z $filepath) {
            $self->lint_fatal($name, 'Hook is empty');
        }
    }
    if ($filepath->exists && !-x $filepath) {
        $self->lint_fatal($name, 'Hook is not executable');
    }
}

sub validate_attributes ($self, $filemeta) {
    my $filepath = path($filemeta->{name});
    my $name     = $filemeta->{name};
    foreach my $attr (@{$filemeta->{attributes}}) {
        if ($attr =~ /^NOT_EMPTY/ && -z $name) {
            $self->lint_fatal($name, 'File is empty.');
        }
        if ($attr =~ /^EXISTS/) {

            # Verify any file aliases
            my $alias_exists = 0;
            foreach my $alias (@{$filemeta->{aliases}}) {
                next unless path($alias)->exists;
                $alias_exists = 1;
            }
            if (!$alias_exists) {
                $self->lint_fatal($name, 'File does not exist.')
                  unless $filepath->exists;
            }
        }
        if ($attr =~ /^NOT_EXISTS/) {
            $self->lint_warn($name, 'Includes template ' . $name . ' file.')
              if (path($name)->exists);
        }
    }
}

sub lint_fatal ($self, $item, $message) {
    $self->has_error(1);
    $self->lint_print(
        $item,
        {   level   => 'ERROR',
            message => $message
        }
    );
}

sub lint_warn ($self, $item, $message) {
    $self->lint_print(
        $item,
        {   level   => 'WARN',
            message => $message
        }
    );
}

sub lint_info ($self, $item, $message) {
    $self->lint_print(
        $item,
        {   level   => 'INFO',
            message => $message
        }
    );
}

sub lint_print ($self, $item, $error) {
    printf("%s: (%s) %s\n", substr($error->{level}, 0, 1), $item, $error->{message});
}

1;

__END__

=pod

=head1 NAME

App::CharmKit::Role::Lint - CharmKit Lint Role

=head1 SYNOPSIS

  $ charmkit lint

=head1 DESCRIPTION

Performs various lint checks to make sure the charm is in accordance with
Charm Store policies.

=head1 Format of lint rules

Lint rules are loaded from B<lint_rules.yaml> in the distributions share directory.
The format for rules is as follows:

  ---
  files:
    file:
      name: 'config.yaml'
      attributes:
        - NOT_EMPTY
        - EXISTS
    file:
      name: 'copyright'
      attributes:
        - NOT_EMPTY
        - EXISTS
      parse:
        - pattern: '^options:\s*\n'
          error: 'ERR_INVALID_COPYRIGHT'

=head1 TODO

Switch to L<Module::Pluggable> for seperating out our checks.

=head1 AUTHOR

Adam Stokes <adamjs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Adam Stokes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
