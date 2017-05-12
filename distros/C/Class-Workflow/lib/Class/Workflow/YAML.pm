#!/usr/bin/perl

package Class::Workflow::YAML;
use Moose;

use Class::Workflow;
use YAML::Syck ();

has workflow_key => (
	isa => "Str",
	is  => "rw",
	default => "workflow",
);

use tt;
[% FOR type IN ["string", "file"] %]
sub load_[% type %] {
	my ( $self, $data ) = @_;
	my $res = $self->localize_yaml_env( _load_[% type %] => $data );
	my $workflow = $self->empty_workflow;
	$self->inflate_hash( $workflow, $res );
}

sub _load_[% type %] {
	my ( $self, $data ) = @_;
	YAML::Syck::Load[% IF type == "file" %]File[% END %]( $data );
}
[% END %]
no tt;

sub localize_yaml_env {
	my ( $self, $method, @args ) = @_;
	local $YAML::Syck::UseCode = 1;
	$self->$method( @args );
}

sub empty_workflow {
	my $self = shift;
	Class::Workflow->new;
}

sub inflate_hash {
	my ( $self, $workflow, $wrapper ) = @_;
	my $hash = $wrapper->{ $self->workflow_key };

	foreach my $key ( keys %$hash ) {
		if ( my ( $type ) = ( $key =~ /^(state|transition)s$/ ) ) {
			foreach my $item ( @{ $hash->{$key} } ) {
				$workflow->$type( ref($item) ? ( ( ref($item) eq "ARRAY" ) ? @$item : %$item ) : $item );
			}
		} else {
			$workflow->$key( $hash->{$key} );
		}
	}

	return $workflow;
}

__PACKAGE__;

__END__

=pod

=head1 NAME

Class::Workflow::YAML - Load workflow definitions from YAML files.

=head1 SYNOPSIS

	my $y = Class::Workflow::YAML->new;

	my $w = $y->load_file("workflow.yml");

	# an exmaple workflow.yml for the bug flow
	# mentioned in Class::Workflow
	---
	# data not under the key "workflow" is ignored.
	# In this example I use 'misc' to predeclare
	# an alias to some code I'll be using later.
	misc:
	  set_owner_to_current_user: &setowner !perl/code: |
	    {
	      my ( $self, $instance, $c ) = @_;
	      # set the owner to the user applying the
	      # transition (see Class::Workflow::Context)
	      return { owner => $c->user };
	    }
	workflow:
	  initial_state: new
	  states:
	    - name: new
	      transitions:
	        # you can store transition
	        # information inline:
	        - name    : reject
	          to_state: rejected
	        # or symbolically, defining
	        # in the transitions section
	        - accept
	    - name: open
	      transitions:
	        - name    : reassign
	          to_state: unassigned
	          # clear the "owner" field in the instance
	          set_fields:
	            owner: ~
	        - name    : claim_fixed
	          to_state: awaiting_approval
	    - name: awaiting_approval
	      transitions:
	        - name    : resolved
	          to_state: closed
	        - name    : unresolved
	          to_state: open
	    - name: unassigned
	      transitions:
	        - name    : take
	          to_state: open
	          # to dynamically set instance
	          # you do something like this:
	          body_sets_fields: 1
	          body            : *setowner
	    # these two are end states
	    - closed
	    - rejected
	  # we now need to define
	  # the "accept" transition
	  transitions:
	    - name            : accept
	      to_state        : open
	      body_sets_fields: 1
	      body            : *setowner

=head1 DESCRIPTION

This module lets you easily load workflow definitions from YAML files.

YAML is nice for this because its much more concise than XML, and allows clean
embedding of perl code.

=head1 FIELDS

=over 4

=item workflow_key

=back

=head1 METHODS

=over 4

=item load_file $filename

=item load_string $string

Load the YAML data, and call C<inflate_hash> on an empty workflow.

=item inflate_hash $workflow, $hash

Define the workflow using the data inside C<< $hash->{$self->workflow_key} >>.

=item empty_workflow

Calls C<< Class::Workflow->new >>

=item localize_yaml_env

A wrapper method to locally set C<$YAML::Syck::UseCode> to 1.

=back

=head1 SEE ALSO

L<Class::Workflow>, L<YAML>

=cut


