package Crop::Server::Handler;
use base qw/ Crop::Object /;

=begin nd
Class: Crop::Server::Handler
	Handler does all the work to generate a correct response for a client request.

	A handler consists of a callback routine and an input driver that checks a correctness
	of client request parameters.
	
	In the future a hadler will get an output driver that passthrogh only allowed data to the client.
	
	May be is a good idea to isolate input driver to an extern class soon.
=cut

use v5.14;
use warnings;

use Clone qw/ clone /;

use Crop::Error;

use Crop::Debug;

=begin nd
Variable: our %Attributes
	Class attributes:

	call        - callback performs general work and place a result to the output flow
	iflow       - copy of input flow
	input       - declaration of client input rules;
	              item 'allow' describes allowed parameters of client request
	k           - current key of a current node in the input driver tree (the key of the 'offer' hash)
	name        - handler name than is unique for the script
	offer       - current hashref of the input
	offer_stack - parsed input path as a stack of hashrefs from iflow to current, but current excluding; current hash is in the 'offer' attribute
	page        - template name without .ext; special name 'PAGELESS' means no output, only redirect or an error handler is allowed
	rule        - current array of allowed items
	rule_stack  - path of nested arrays of permissions; shrinks and grows synchronously with offer_stack (iflow presentation)
	v           - the value of the current node (value of the 'offer' attribute)
=cut
our %Attributes = (
	call        => {mode => 'read', stable => 1},
	iflow       => undef,
	input       => {stable => 1},
	k           => undef,
	name        => {mode => 'read', stable => 1},
	offer       => undef,
	offer_stack => {default => []},
	page        => {mode => 'read', stable => 1},
	rule        => undef,
	rule_stack  => {default => []},
	v           => undef,
);

=begin nd
Method: checkin ($iflow)
	Run input driver.

	If input flow contains extra parameters not allowed by rules, than returns error.
	The check not work if rules are empty.

	Rules are in %{input=>allow}.

	This method go trough two data tree: input flow and driver rules. They have distinct
	structure. Leading structure is input flow, so bypass starts from it: each of input
	flow param must must have corresponding item in driver rules.

	Node is key-value pair in hash of input flow. Value can be either simple scalar value or hashref.
	Is assumed that no empty hash exist in the input flow.

Parameters:
	$iflow - input flow

Returns:
	true  - input flow satisfy rules
	false - otherwise
=cut
sub checkin {
	my ($self, $iflow) = @_;

	# the script dosn't has input restriction, so check is success
	exists $self->{input}{allow} or return 1;

	$self->{iflow} = clone $iflow;
	$self->{rule} = $self->{input}{allow};
	$self->{rule} = [$self->{rule}] unless ref $self->{rule} eq 'ARRAY';  # for simplified allow=>'param'
	push @{$self->{rule_stack}}, $self->{rule};
	$self->{offer} = $self->{iflow};

	my $error;
	NODE:
	while (my ($k, $v) = $self->_next_node) {
		# If contains the permissions array an item with current key of iflow?
		# In no one exists, the check fails.
		# Then check the value for this key.
		my $key_index;
		RULE:
		while (my ($i, $allow) = each @{$self->{rule}}) {
			next if ref $allow;

			if ($k eq $allow) {
				$key_index = $i;
				keys @{$self->{rule}};  # reset each_iterator for it later use starts at first item
				last RULE;
			}
		}
		unless (defined $key_index) {
			$error = "CHECKIN|ERR: Incorrect params: k=$k; v=$v";
			last NODE;
		}

		my $val_index = $key_index + 1;

		if (ref $v eq 'HASH') {
			# iflow contains inner hash.
			# The key in last position of rules will arise an error, since simple value is expected but hashref found.
			# Missing arrayref after the key will arise an error too.
			if ($val_index == @{$self->{rule}}) {
				$error = "CHECKIN|ERR: Hash found where value expected: k=$k; v=$v";
				last NODE;
			}

			my $next_rule = $self->{rule}[$val_index];
			my $ref_arr = ref $next_rule;

			if (not defined $ref_arr or $ref_arr ne 'ARRAY') {
				$error = "INPUT: Hash found where value expected: k=$k; v=$v";
				last NODE;
			}

			push @{$self->{rule_stack}}, $self->{rule};
			$self->{rule} = $next_rule;
			next;
		} elsif (ref $v eq 'ARRAY') {
			next if $val_index == @{$self->{rule}} or not ref $self->{rule}[$val_index];

			$error = "INPUT: Value found where hash expected: k=$k; v=$v";
			last NODE;

		} else {
			next if $val_index == @{$self->{rule}} or not ref $self->{rule}[$val_index];

			$error = "INPUT: Value found where hash expected: k=$k; v=$v";
			last NODE;
		}
	}
	$self->Erase;
	
	$error ? warn $error : 1;
}

=begin nd
Method: _next_node ( )
	Next step on passing a tree of iflow args.

	Each step returns a key-value pair of current hash.

	Returns empty list at end of iflow.

	This method rely on absence of empty hasses in the iflow.

Returns:
	($k, $v)  - item pair of current hash
	emptylist - at and of iflow
=cut
sub _next_node {
	my $self = shift;

	if (ref $self->{v} eq 'HASH') {
		push @{$self->{offer_stack}}, $self->{offer};
		$self->{offer} = $self->{v};
		return ($self->{k}, $self->{v}) = each %{$self->{offer}};            # current hash of iflow
	} else {
		if (my ($k, $v) = each %{$self->{offer}}) {
			return ($self->{k}, $self->{v}) = ($k, $v);
		} else {                                                             # end of current hsah
			while ($self->{offer} = pop @{$self->{offer_stack}}) {
				$self->{rule} = pop @{$self->{rule_stack}};
				if (my ($k, $v) = each %{$self->{offer}}) {
					return ($self->{k}, $self->{v}) = ($k, $v);
				}
			}
			return ();                                                   # end of iflow, end of traverse
		}
	}
}

1;
