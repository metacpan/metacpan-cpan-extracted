package CHI::Cascade;

use strict;
use warnings;

our $VERSION = 0.284;

use Carp;

use CHI::Cascade::Value ':state';
use CHI::Cascade::Rule;
use CHI::Cascade::Target;
use Time::HiRes ();
use POSIX ();

sub min ($$) { $_[0] < $_[1] ? $_[0] : $_[1] }

sub new {
    my ($class, %opts) = @_;

    my $self = bless {
	    %opts,
	    plain_targets	=> {},
	    qr_targets		=> [],
	    target_locks	=> {},
	    stats		=> { recompute => 0, run => 0, dependencies_lookup => 0 }

	}, ref($class) || $class;

    $self->{target_chi} ||= $self->{chi};

    $self;
}

sub rule {
    my ($self, %opts) = @_;

    my $rule = CHI::Cascade::Rule->new( cascade => $self, %opts );

    if (ref($rule->{target}) eq 'Regexp') {
	push @{ $self->{qr_targets} }, $rule;
    }
    elsif (! ref($rule->{target})) {
	$self->{plain_targets}{$rule->{target}} = $rule;
    }
    else {
	croak qq{The rule's target "$rule->{target}" is unknown type};
    }
}

sub target_computing {
    my $trg_obj;

    ( $trg_obj = $_[0]->{target_chi}->get("t:$_[1]") )
      ? ( ( ${ $_[2] } = $trg_obj->ttl ), $trg_obj->locked ? 1 : 0 )
      : 0;
}

sub target_is_actual {
    my ( $self, $target, $actual_term ) = @_;

    my $trg_obj;

    ( $trg_obj = $self->{target_chi}->get("t:$target") )
      ? $trg_obj->is_actual( $actual_term )
      : 0;
}

sub target_time {
    my ($self, $target) = @_;

    my $trg_obj;

    return ( ( $trg_obj = $self->{target_chi}->get("t:$target") )
      ? $trg_obj->time
      : 0
    );
}

sub get_value {
    my ($self, $target) = @_;

    my $value = $self->{chi}->get("v:$target");

    return $value->state( CASCADE_FROM_CACHE )
      if ($value);

    CHI::Cascade::Value->new( state => CASCADE_NO_CACHE );
}

sub target_lock {
    my ( $self, $rule ) = @_;

    my ( $trg_obj, $target );

    # If target is already locked - a return
    return
      if ( $self->target_locked( $target = $rule->target ) );

    $trg_obj = CHI::Cascade::Target->new unless ( ( $trg_obj = $self->{target_chi}->get("t:$target") ) );

    $trg_obj->lock;
    $self->{target_chi}->set( "t:$target", $trg_obj, $rule->target_expires( $trg_obj ) );

    $self->{target_locks}{$target} = 1;
}

sub target_unlock {
    my ( $self, $rule, $value ) = @_;

    my $target = $rule->target;

    if ( my $trg_obj = $self->{target_chi}->get( "t:$target" ) ) {
	$trg_obj->unlock;

	if ( $value && $value->state & CASCADE_RECOMPUTED ) {
	    $trg_obj->touch;
	    $trg_obj->actual_stamp
	      if $self->{run_opts}{actual_term} && $self->{orig_target} eq $target;
	}

	$self->{target_chi}->set( "t:$target", $trg_obj, $rule->target_expires( $trg_obj ) );
    }

    delete $self->{target_locks}{$target};
}

sub target_actual_stamp {
    my ( $self, $rule, $value ) = @_;

    my $target = $rule->target;

    if ( $value && $value->state & CASCADE_ACTUAL_VALUE && ( my $trg_obj = $self->{target_chi}->get( "t:$target" ) ) ) {
	$trg_obj->actual_stamp;
	$self->{target_chi}->set( "t:$target", $trg_obj, $rule->target_expires( $trg_obj ) );
    }
}

sub target_start_ttl {
    my ( $self, $rule, $start_time ) = @_;

    my $target = $rule->target;

    if ( my $trg_obj = $self->{target_chi}->get( "t:$target" ) ) {
	$trg_obj->ttl( $rule->ttl, $start_time );
	$self->{target_chi}->set( "t:$target", $trg_obj, $rule->target_expires( $trg_obj ) );
    }
}

sub target_remove {
    my ($self, $target) = @_;

    $self->{target_chi}->remove("t:$target");
}

sub touch {
    my ( $self, $target ) = @_;

    if ( my $trg_obj = $self->{target_chi}->get("t:$target") ) {
	$trg_obj->touch;
	$self->{target_chi}->set( "t:$target", $trg_obj, $self->find( $target )->target_expires( $trg_obj ) );
    }
}

sub target_locked {
    exists $_[0]->{target_locks}{$_[1]};
}

sub recompute {
    my ( $self, $rule, $target, $dep_values) = @_;

    die CHI::Cascade::Value->new( state => CASCADE_DEFERRED )
      if $self->{run_opts}{defer};

    my $ret = eval { $rule->{code}->( $rule, $target, $rule->{dep_values} = $dep_values ) };

    $self->{stats}{recompute}++;

    if ($@) {
	my $error = $@;
	die( ( eval { $error->isa('CHI::Cascade::Value') } ) ? $error->thrown_from_code(1) : "CHI::Cascade: the target $target - error in the code: $error" );
    }

    my $value;

    # For performance a value should not expire in anyway (only target marker if need)
    $self->{chi}->set( "v:$target", $value = CHI::Cascade::Value->new->value($ret), 'never' );

    $value->state( CASCADE_ACTUAL_VALUE | CASCADE_RECOMPUTED );

    $rule->{recomputed}->( $rule, $target, $value )
      if ( ref $rule->{recomputed} eq 'CODE' );

    return $value;
}

sub value_ref_if_recomputed {
    my ( $self, $rule, $target, $only_from_cache ) = @_;

    return undef unless defined $rule;

    my @qr_params = $rule->qr_params;

    my ( $ret_state, $ttl, $should_be_recomputed ) = ( CASCADE_ACTUAL_VALUE );

    if ( $self->target_computing( $target, \$ttl ) ) {
	# If we have any target as a being computed (dependencie/original)
	# there is no need to compute anything - trying to return original target value
	die CHI::Cascade::Value->new->state( CASCADE_COMPUTING );
    }

    my ( %dep_values, $dep_name );

    if ( $only_from_cache ) {

	# Trying to get value from cache
	my $value = $self->get_value($target);

	return $value
	  if $value->is_value;

	# If no in cache - we should recompute it again
	$self->target_lock($rule);
    }

    push @{ $self->{target_stack} }, $target;

    my $ret = eval {
	my $dep_target;

	my $catcher =  sub {
	    my $sub = shift;

	    my $ret = eval { $sub->() };

	    if ($@) {
		my $exception = $@;

		$rule->{depends_catch}->( $rule, $exception, $dep_values{$dep_target}->[0], $dep_target )
		  if (   exists $rule->{depends_catch}
		      && ref $rule->{depends_catch} eq 'CODE'
		      && eval { $exception->isa('CHI::Cascade::Value') }
		      && $exception->thrown_from_code );

		die $exception;
	    }

	    return $ret;
	};

	$self->target_lock($rule)
	  if ! $self->target_time($target);

	$should_be_recomputed = $self->target_locked($target);

	if ( defined $ttl && $ttl > 0 && ! $should_be_recomputed ) {
	    $ret_state = CASCADE_TTL_INVOLVED;
	    $self->{ttl} = $ttl;
	}
	else {
	    my (
		$rule_ttl,
		$circle_hash,
		$start_time,
		$min_start_time
	    ) = (
		$rule->ttl,
		$only_from_cache ? 'only_cache_chain' : 'chain'
	    );

	    foreach my $depend (@{ $rule->depends }) {
		$dep_target = ref($depend) eq 'CODE' ? $depend->( $rule, @qr_params ) : $depend;

		$dep_values{$dep_target}->[0] = $self->find($dep_target);

		die "Found circle dependencies (trace: " . join( '->', @{ $self->{target_stack} }, $dep_target ) . ") - aborted!"
		  if ( exists $self->{ $circle_hash }{$target}{$dep_target} );

		$self->{ $circle_hash }{$target}{$dep_target} = 1;

		$catcher->( sub {
		    if (   ! $only_from_cache
			&& ( $start_time = ( $self->{stats}{dependencies_lookup}++,
			     ( $dep_values{$dep_target}->[1] = $self->value_ref_if_recomputed( $dep_values{$dep_target}->[0], $dep_target ) )->state & CASCADE_RECOMPUTED && Time::HiRes::time
			|| ( $start_time = $self->target_time($dep_target) ) > $self->target_time($target) && $start_time ) ) )
		    {
			if (    ! $should_be_recomputed
			     && ! defined $ttl
			     && defined $rule_ttl
			     && $rule_ttl > 0
			     && ( $start_time + $rule_ttl ) > Time::HiRes::time )
			{
			    $min_start_time = defined $min_start_time ? min( $start_time, $min_start_time ) : $start_time;
			}
			else {
			    $self->target_lock($rule);
			}
		    }
		} );

		delete $self->{ $circle_hash }{$target}{$dep_target};
	    }

	    if ( defined $min_start_time ) {
		$ret_state = CASCADE_TTL_INVOLVED;
		$self->target_start_ttl( $rule, $min_start_time );
		$self->{ttl} = $min_start_time + $rule_ttl - Time::HiRes::time;
	    }
	}

	if ( $self->target_locked($target) ) {
	    # We should recompute this target
	    # So we should recompute values for other dependencies
	    foreach $dep_target (keys %dep_values) {
		if (   ! defined $dep_values{$dep_target}->[1]
		    || ! $dep_values{$dep_target}->[1]->is_value )
		{
		    $self->{stats}{dependencies_lookup}++;
		    $catcher->( sub {
			if ( ! ( $dep_values{$dep_target}->[1] = $self->value_ref_if_recomputed( $dep_values{$dep_target}->[0], $dep_target, 1 ) )->is_value ) {
			    $self->target_remove($dep_target);
			    return 1;
			}
			return 0;
		    } ) == 1 && return undef;
		}
	    }
	}

	return $self->recompute( $rule, $target, { map { $_ => $dep_values{$_}->[1]->value } keys %dep_values } )
	  if $self->target_locked($target);

	return CHI::Cascade::Value->new( state => $ret_state );
    };

    pop @{ $self->{target_stack} };

    my $e = $@;

    if ( $self->target_locked($target) ) {
	$self->target_unlock( $rule, $ret );
    }
    elsif ( $self->{run_opts}{actual_term} && ! $only_from_cache && $self->{orig_target} eq $target ) {
	$self->target_actual_stamp( $rule, $ret );
    }

    die $e if $e;

    return $ret || CHI::Cascade::Value->new;
}

sub stash { exists $_[0]->{stash} && $_[0]->{stash} || die "The stash method from outside run method!" }

sub run {
    my ( $self, $target, %opts ) = @_;

    my $view_dependencies = 1;

    $self->{run_opts}    = \%opts;
    $self->{ttl}         = undef;
    $opts{actual_term} ||= $self->find($target)->{actual_term};
    $self->{stats}{run}++;

    $self->{stash} = $opts{stash} && ref $opts{stash} eq 'HASH' && $opts{stash} || {};

    $view_dependencies = ! $self->target_is_actual( $target, $opts{actual_term} )
      if ( $opts{actual_term} );

    my $res = $self->_run( ! $view_dependencies, $target );

    $res->state( CASCADE_ACTUAL_TERM )
      if ( $opts{actual_term} && ! $view_dependencies );

    if ( defined $self->{ttl} && $self->{ttl} > 0 ) {
	$res->state( CASCADE_TTL_INVOLVED );
    }

    ${ $opts{ttl} } = $self->{ttl}
      if ( $opts{ttl} );

    ${ $opts{state} } = $res->state
      if ( $opts{state} );

    delete $self->{stash};

    $res->value;
}

sub _run {
    my ( $self, $only_from_cache, $target ) = @_;

    croak qq{The target ($target) for run should be string} if ref($target);
    croak qq{The target for run is empty} if $target eq '';

    $self->{chain}            = {};
    $self->{only_cache_chain} = {};
    $self->{target_stack}     = [];

    my $ret = eval {
	$self->{orig_target} = $target;

	return $self->value_ref_if_recomputed( $self->{orig_rule} = $self->find($target), $target, $only_from_cache );
    };

    my $terminated;

    if ( $terminated = $@ ) {
	$ret = $@;

	die $ret
	  unless eval { $ret->isa('CHI::Cascade::Value') };

	$ret->state( CASCADE_CODE_EXCEPTION )
	  unless $ret->state;
    }

    if ( ! $ret->is_value ) {
        my $from_cache = $self->get_value( $target );

	return $from_cache->state( $ret->state )
	  if ( $terminated || $from_cache->is_value );

	return $self->_run( 1, $target )
	  if ! $only_from_cache;
    }

    return $ret;
}

sub find {
    my ($self, $plain_target) = @_;

    die "CHI::Cascade::find : got empty target\n" if $plain_target eq '';

    my $new_rule;

    # If target is flat text
    if (exists $self->{plain_targets}{$plain_target}) {
	( $new_rule = $self->{plain_targets}{$plain_target}->new )->{matched_target} = $plain_target;
	return $new_rule;
    }

    # If rule's target is Regexp type
    foreach my $rule (@{$self->{qr_targets}}) {
	my @qr_params;

	if (@qr_params = $plain_target =~ $rule->{target}) {
	    ( $new_rule = $rule->new )->qr_params(@qr_params);
	    $new_rule->{matched_target} = $plain_target;
	    return $new_rule;
	}
    }

    die "CHI::Cascade::find : cannot find the target $plain_target\n";
}


1;
__END__

=pod

=head1 NAME

CHI::Cascade - a cache dependencies (cache and like 'make' utility concept)

=head1 SYNOPSIS

    use CHI;
    use CHI::Cascade;

    $cascade = CHI::Cascade->new(chi => CHI->new(...));

    $cascade->rule(
	target	=> 'unique_name',
	depends	=> ['unique_name_other1', 'unique_name_other2'],
	code	=> sub {
	    my ($rule, $target_name, $values_of_depends) = @_;

	    # $values_of_depends == {
	    #     unique_name_other1 => $value_1,
	    #     unique_name_other2 => $value_2
	    # }
	    # $rule->target	eq	$target_name
	    # $rule->depends	===	['unique_name_other1', 'unique_name_other2']
	    # $rule->dep_values	==	$values_of_depends
	    # $rule->params	==	{ a => 1, b => 2 }

	    # Now we can calcualte $value
	    return $value;
	},
	params	=> { a => 1, b => 2 }
    );

    $cascade->rule(
	target	=> 'unique_name_other1',
	depends	=> 'unique_name_other3',
	code	=> sub {
	    my ($rule, $target_name, $values_of_depends) = @_;

	    # $values_of_depends == {
	    #     unique_name_other3 => $value_3
	    # }

	    # computing here
	    return $value;
	}
    );

    $value_of_this_target = $cascade->run('unique_name');

=head1 DESCRIPTION

This module is the attempt to use a benefits of caching and 'make' concept.
If we have many an expensive tasks (a I<computations> or sometimes here used
term as a I<recomputing>) and want to cache it we can split its to small
expsnsive tasks and to describe dependencies for cache items.

This module is experimental yet. I plan to improve it near time but some things
already work. You can take a look for t/* tests as examples.

=head1 CONSTRUCTOR

$cascade = CHI::Cascade->new( %options )

This method constructs a new C<CHI::Cascade> object and returns it.
Key/value pair arguments may be provided to set up the initial state.
Options are:

=over

=item chi

B<Required>. Instance of L<CHI> object. The L<CHI::Cascade> doesn't construct this
object for you. Please create instance of C<CHI> yourself.

=item busy_lock

B<Optional>. Default is I<never>. I<This is not C<busy_lock> option of CHI!>
This is amount of time (to see L<CHI/"DURATION EXPRESSIONS">) until all target
locks expire. When a target is to being computing it is locked. If process which
is to be computing target and it will die or OS will be hangs up we can dead
locks and locked target will never recomputed again. This option helps to avoid
it. You can set up a special busy_lock for rules too.

=item target_chi

B<Optional>. This is CHI cache for target markers. Default value is value of
L</chi> option. It can be useful if you use a L<CHI/l1_cache> option. So you can
separate data of targets from target markers - data will be kept in a file cache
and a marker in memory cache for example.

=back

=head1 METHODS

=over

=item rule( %options )

To add new rule to C<CHI::Cascade> object. All rules should be added before
first L</run> method

The keys of %options are (options are passed directly in L<CHI::Cascade::Rule> constructor):

=over

=item target

B<Required>. A target for L</run> and for searching of L</depends>. It can be as
scalar text or C<Regexp> object created through C<qr//>

=item depends

B<Optional>. The B<scalar>, B<arrayref> or B<coderef> values of dependencies.
This is the definition of target(s) from which this current rule is dependent.
If I<depends> is:

=over

=item scalar

It should be plain text of single dependence of this target.

=item arrayref

An each item of list can be scalar value (exactly matched target) or code
reference. If item is coderef it will be executed as $coderef->( $rule,
L<< $rule->qr_params|CHI::Cascade::Rule/qr_params >> ) and should return a
scalar value as current dependence for this target at runtime (the API for
coderef parameters was changed since v0.16)

=item coderef

This subroutine will be executed every time inside I<run> method if necessary
and with parameters as: $coderef->( $rule,
L<< $rule->qr_params|CHI::Cascade::Rule/qr_params >> ) (API was changed since
v0.16). It should return B<scalar> or B<arrayref>. The returned value is
I<scalar> it will be considered as single dependence of this target and the
behavior will be exactly as described for I<scalar> in this paragraph. If the
returned value is I<arrayref> it will be considered as list of dependencies for
this target and the behavior will be exactly as described for I<arrayref> in
this paragraph.

=back

=item depends_catch

B<Optional>. This is B<coderef> for dependence exceptions. If any dependence
from list of L</depends>'s option throws an exception of type
CHI::Cascade::Value by C<die> (for example like this code: C<< die
CHI::Cascade::Value->new->value( { i_have_problem => 1 } ) >> ) then the
C<$cascade> will execute this code as C<< $rule->{depends_catch}->(
$this_rule_obj, $exception_of_dependence, $rule_obj_of_dependence,
$plain_text_target_of_dependence ) >> and you can do into inside a following:

=over

=item re-C<die> new exception of any type

If your new exception will be type of L<CHI::Cascade::Value> you will get the
value of this object from L</run> method immediately (please to see L</code>
below) without saving in cache.

If exception will be other type this will be propogated onward beyond the
L</run> method

=item to do something

You can make something in this code. After execution of your code the cascade
re-throws original exception of dependence like described above in L<<
/"re-C<die>" >> section.

But please notice that original exception has a status of "thrown from code" so
it can be catched later by other L</depends_catch> callback from other rule
located closer to the call hierarchy of L</run>.

=back

Please notice that there no way to continue a L</code> of current rule if any
dependence throws an exception!. It because that the main concept of execution
code of rules is to have all valid values (cached or recomputed) of all
dependencies before execution of dependent code.

=item code

B<Required>. The code reference for computing a value of this target (a
I<computational code>). Will be executed if no value in cache for this target or
any dependence or dependences of dependences and so on will be recomputed. Will
be executed as C<< $code->( $rule, $target, $hashref_to_value_of_dependencies )
>> I<(The API of running this code was changed since v0.10)>

If you want to terminate a code and to return immediately from L</run> method and
don't want to save a value in cache you can throw an exception from L</code> of
type L<CHI::Cascade::Value>. Your instance of L<CHI::Cascade::Value> can have a
value or cannot (a valid value can be even C<undef>!). A L</run> method returns
either a value is set by you (through L<CHI::Cascade::Value/value> method) or
value from cache or C<undef> in other cases. Please to see
L<CHI::Cascade::Value>

If L</run> method will have a L</defer> option as B<true> this code will not be
executed and you will get a set bit B<CASCADE_DEFERRED> in L</state> bit mask
variable. This may useful when you want to control a target execution.

=over

=item $rule

An instance of L<CHI::Cascade::Rule> object. You can use it object as accessor
for some current executed target data (plain text of target, for getting of
parameters and so on). Please to see L<CHI::Cascade::Rule>

=item $target

The current executed target as plain text for this L</code>

=item $hashref_to_value_of_dependencies

A hash reference of values (values are cleaned values not L<CHI::Cascade::Value>
objects!) of all dependencies for current target. Keys in this hash are flat
strings of dependecies and values are computed or cached ones.

This module should guarantee that values of dependencies will be valid values
even if value is C<undef>. This code can return C<undef> value as a valid code
return but author doesn't recommend it. If C<CHI::Cascade> could not get a valid
values of all dependencies of current target before execution of this code the
last will not be executed (The C<run> will return C<undef>).

=back

=item params

B<Optional>. You can pass in your code any additional parameters by this option.
These parameters are accessed in your rule's code through
L<CHI::Cascade::Rule/params> method of L<CHI::Cascade::Rule> instance object.

=item busy_lock

B<Optional>. Default is L</busy_lock> of constructor or I<never> if first is not
defined. I<This is not C<busy_lock> option of CHI!> This is amount of time (to
see L<CHI/"DURATION EXPRESSIONS">) until target lock expires. When a target is
to being computed it is locked. If process which to be recomputing a target and
it will die or OS will be hangs up we can dead locks and locked target will
never recomputed again. This option helps to avoid it.

=item recomputed

B<Optional>. This is a computational callback (coderef). If target of this rule
was recomputed this callback will be executed right away after a recomputed
value has been saved in cache. The callback will be executed as $coderef->(
$rule, $target, $value ) where passed parameters are:

=over

=item $rule

An instance of L<CHI::Cascade::Rule> class. This instance is recreated for every
target searching and recomputing if need.

=item $target

A current target as string

=item $value

The instance of L<CHI::Cascade::Value> class. You can use a computed value as
$value->value

=back

For example you can use this callback for notifying of other sites that your
target's value has been changed and is already in cache.

=item value_expires

B<Optional>.
Sets an L<CHI>'s cache expire value for all future target markers are created by
this rule in notation described in L<CHI/"DURATION EXPRESSIONS">. The B<default>
is 'never'. It can be B<coderef> or B<string scalar> format as L<CHI/"DURATION
EXPRESSIONS">. A B<coderef> should return value in same format.

=item ttl

B<Optional>.
An arrayref for min & max intervals of TTL. Example: C<[ 60, 3600 ]> - where the
minimum ttl is seconds and the maximum is 3600 seconds. Targets of this rule
will be recomputed during from 60 up to 3600 seconds from touched time of any
dependence this rule. Please read L<CHI::Cascade::Value/CASCADE_TTL_INVOLVED>
too.

=back

=item run( $target, %options )

This method makes a cascade computation if need and returns value (value is
cleaned value not L<CHI::Cascade::Value> object!) for this target If any
dependence of this target of any dependencies of dependencies were
(re)computed this target will be (re)computed too.

=over

=item $target

B<Required.> Plain text string of target.

=item %options

B<Optional.> And B<all options> are B<optional> too A hash of options. Valid keys and values are:

=over

=item state

A B<scalarref> of variable where will be stored a state of L</run>. Value will
be a bit mask.

=item defer

If value will be a B<true> then computational code will not be run if there is a
need. After L</run> you can test status of returned value - it should be
(re)computed or not by bit C<CASCADE_DEFERRED> in saved L</state> variable. If
the B<CASCADE_DEFERRED> bit is set you can recall L</run> method again or
re-execute target in other process for a non-blocking execution of current
process.

=item actual_term

The value in seconds (a floating point value) of actual term. The actual term is
period when dependencies to be checked for $target in L</run> method. If this
option is not defined then the L</run> method checks a dependencies of $target
every time in runtime. But sometimes (when a target has many dependencies) we
could want to reduce an amount of dependencies checks. For example if
C<actual_term> will be defined as C<2.5> this will mean to check a dependencies
only every 2.5 seconds. So recomputing in this example can be recomputed only
one time in every 2.5 seconds (even if one from dependencies will be updated).
But if value of $target is missing in cache a recomputing can be
run regardless of this option.

=item ttl

A B<scalarref> for getting current TTL for value of 'run' target. The TTL is
"time to live" as TTL in DNS. If any rule in a path of following to dependencies
has ttl parameter then the cascade will do there:

=over

=item 1.

will look up a time of this retouched dependence;

=item 2.

if rule's target marker already has a upper time and this time in future
the target will be recomputed in this time in future and before this moment you
will get a old data from cache for 'run' target. If this time is there and has
elapsed cascade will use a standard algorithm.

=item 3.

will look up the rule's ttl parameter (min & max ttl values) and will generate
upper time of computation of this rule's target and will return from L</run>
method old data of 'run' target. Next L</run>s executions will return old values
of any targets where this TTL-marked target is as dependence.

=item 4.

In any case if old value misses in cache the cascade will recompute codes.

=back

This feature was made for I<reset> situation. For example if we have 'reset'
rule and all rules depend from this one rule the better way will be to have
'ttl' parameter in every rule except 'reset' rule. So if rule 'reset' will be
retouched (or deleted) other targets will be recomputed during time from 'min'
and 'max' intervals from 'reset' touched time. It reduce a server's load. Later
i will add examples for this and will document this feature more details. Please
read L<CHI::Cascade::Value/CASCADE_TTL_INVOLVED> too.

=item stash

A I<hashref> to stash - temporary data container between rule's codes. Please
see L</"stash ()"> method for details.

=back

=back

=item touch( $target )

This method refreshes the time of this target. Here is analogy with L<touch>
utility of Unix and behaviour as L<make(1)> after it. After L</touch> all targets
are dependent from this target will be recomputed at next L</run> with an
appropriate ones.

=item target_remove ( $target )

It's like a removing of target file in make. You can force to recompute target
by this method. It will remove target marker if one exists and once when cascade
will need target value it will be recomputed. In a during recomputing of course
cascade will return an old value if one exists in cache.

=item stash ()

It returns I<hashref> to a stash. A stash is hash for temporary data between
rule's codes. It can be used only from inside L</run>. Example:

    $cascade->run( 'target', stash => { key1 => value1 } )

and into rule's code:

    $rule->cascade->stash->{key1}

If a L</run> method didn't get stash hashref the default stash will be as empty
hash. You can pass a data between rule's codes but it's recommended only in
special cases. For example when run's target cannot get a full data from its
target's name.

=back

=head1 STATUS

This module is experimental and not finished for new features ;-)
Please send me issues through L<https://github.com/Perlover/CHI-Cascade> page

=head1 ANALOGIES WITH make

Here simple example how it works. Here is a direct analogy to Unix make
utility:

    In CHI::Cascade:		In make:

    rule			rule
    depends			prerequisites
    code			commands
    run( rule_name )		make target_name

=head1 FEATURES

The features of this module are following:

=over

=item Computing inside process

If module needs to compute item for cache we compute inside process (no forks)
For web applications it means that one process for one request could take
a some time for computing. But other processes will not wait and will get either
old previous computed value or I<undef> value.

=item Non-blocking computing for concurrent processes

If other process want to get data from cache we should not block it. So
concurrent process can get an old data if new computing is run or can get
I<undef> value. A concurrent process should decide itself what it should do
after it - try again after few time or print some message like 'Please wait and
try again' to user.

=item Each target is splitted is two items in cache

For optimization this module keeps target's info by separately from value item.
A target item has lock & timestamp fields. A value item has a computed value.

=back

=head1 EXAMPLE

For example please to see the SYNOPSIS

When we prepared a rules and a depends we can:

If unique_name_other1 and/or unique_name_other2 are(is) more newer than
unique_name the unique_name will be recomputed.
If in this example unique_name_other1 and unique_name_other2 are older than
unique_name but the unique_name_other3 is newer than unique_name_other1 then
unique_name_other1 will be recomputed and after the unique_name will be
recomputed.

And even we can have a same rule:

    $cascade->rule(
	target	=> qr/^unique_name_(.*)$/,
	depends	=> sub { 'unique_name_other_' . $_[1] },
	code	=> sub {
	    my ($rule, $target_name, $values_of_depends) = @_;

	    # $rule->qr_params		=== ( 3 )
	    # $target_name		== 'unique_name_3' if $cascade->run('unique_name_3') was
	    # $values_of_depends	== {
	    #     unique_name_other_3	=> $value_ref_3
	    # }
	}
    );

    $cascade->rule(
	target	=> qr/unique_name_other_(.*)/,
	code	=> sub {
	    my ($rule, $target_name, $values_of_depends) = @_;
	    ...
	}
    );

When we will do:

    $cascade->run('unique_name_52');

$cascade will find rule with qr/^unique_name_(.*)$/, will make =~ and will find
a depend as unique_name_other_52

=head1 AUTHOR

This module has been written by Perlover <perlover@perlover.com>

=head1 LICENSE

This module is free software and is published under the same terms as Perl
itself.

=head1 SEE ALSO

=over

=item L<CHI::Cascade::Rule>

An instance of this object can be used in your target codes.

=item L<CHI>

This object is used for cache.

=item L<CHI::Driver::Memcached::Fast>

Recommended if you have the Memcached

=item L<CHI::Driver::File>

Recommended if you want to use the file caching instead the Memcached for
example

=back

=cut
