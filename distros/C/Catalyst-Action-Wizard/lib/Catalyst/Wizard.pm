=head1 NAME

Catalyst::Wizard

=head1 DESCRIPTION

This plugin provides same functionallity like Catalyst::Plugin::Wizard
but in some more flexible and correct way.

=head1 SYNOPSIS

Plain:

    # create new wizard
    my $wizard = Catalyst::Wizard->new( $c );

    # add steps for that wizard
    $wizard->add_steps( -detach => '/user/login', '/user/login_submit' );
    $wizard->add_steps( -last => -redirect => '/user/logout' );

    # mark step to go to next step after this action
    $wizard->goto_next;

    # perform step (calls redirect/detach/forward/whatever)
    $wizard->perform_step;


With Catalyst::Action::Wizard and CatalystX::Wizarded:

    # just appending step
    $c->wizard( '/append_this_step' );

    # just marking as goto_next
    # NOTE: wizards can either 'die' after this (like in detach)
    # or just mark wizard as 'goto_next'
    $c->wizard->goto_next;

    # adding -last action in wizard (only one added, other
    # '-last' actions ignored). synonym for -default in C::P::W
    $c->wizard( -last => -redirect => '/logout' )->goto_next;

    # make step back (in case some errors happen)
    $c->wizard->back_to( -redirect => '/append_this_step' );

    # stash into wizard
    my $wizard_stash = $c->wizard->stash;
    $wizard_stash->{parameters} = { %{ $c->req->params } };

    if ( $c->have_wizard ) {
	$c->wizard->goto_next;
    }

In TT:
    [% c.wizard.id_to_form IF c.have_wizard %]

    [%	# INCORRECT! may (and will) cause errors!
	c.wizard.id_to_form %]

In real application:
    See L<there|CatalystX::Wizarded>.

=head1 NOTES

This module is for general wizard'ed actions. It may be used with CatalystX::Wizarded and along in separate realization (for example in Controller base)

You can use it for creating mulitpart actions (wizards) in following cases:

=over

=item *

When you need to move some items into another folder, you may:

=over 4

=item *

keep current folders select in session (can have difficulties with duplicate selecting of same folder)

=item *

use it as wizard and keep that info in wizard's stash

=back

=back

=head1 AUTHORS

Pavel Boldin (), <davinchi@cpan.ru>

=cut

package Catalyst::Wizard;

use strict;
use warnings;

use Digest::MD5 qw(md5_hex);
use URI;
use URI::QueryParam;
use Carp qw/cluck/;
use Scalar::Util;


use constant DEBUG => $ENV{CATALYST_WIZARD_DEBUG} || 0;


if (DEBUG) {
    require Carp;
    Carp->import( 'carp', 'cluck' );
}

sub DEBUG2 {
    DEBUG >= 2;
}


our $GOTO_NEXT = "wizard_goto_next\n";



sub _dump {
    require Data::Dumper;
    Data::Dumper->new(\@_)->Indent(1)->Terse(1)->Dump;
}


#---------------------------------------------------------------------------
#  Main object functions
#---------------------------------------------------------------------------

=head1 METHODS

=head2 new($c [, $wizard_id ])

Create wizard object, either new (empty, missing or equal to 'new' C<$wizard_id>)  or loaded from Catalyst::Wizard::wizard_storage.

Note that C<$wizard_id> can also contain step number (splited from wizard_id by C<_>).

=cut

sub new {
    my $class = shift;
    $class = ref $class || $class;

    my ($c, $my_wizard_id) = @_;

    my $self = {};

    DEBUG2 && cluck();

    DEBUG2 &&
	__PACKAGE__->info("new: $my_wizard_id "._dump([ (caller(0))[0..3] ]));


    if (    $my_wizard_id
	&&  $my_wizard_id ne 'new'
    ) {
	($my_wizard_id, my $step) = ($my_wizard_id =~ /([0-9a-zA-Z]{32})(?:_(\d+))?/);


	$self = $class->wizard_storage( $c, $my_wizard_id );
	die "No such wizard: $my_wizard_id" unless $self;

	$self->{loaded_from_storage} = 1;

	$self->check_step_number( $c, $step ) if defined $step;

    } else {
	$self = {
	    wizard_id	    => _create_wizard_id(),
	    steps	    => [],
	    step_number	    => 0,
	    stash	    => {},
	    no_add_step	    => 0,
	    no_step_back    => 0,

	    steps_already_in_wizard => {},
	};

	$self = bless $self, $class;
    }


    $self->load( $c );
    DEBUG2 && cluck(_dump($self));
    return $self;
}

#---------------------------------------------------------------------------
#  INITIALIZATION HELPERS FUNCTIONS
#---------------------------------------------------------------------------


sub _create_wizard_id {
    md5_hex(rand().time);
}

#---------------------------------------------------------------------------
#  ADDITION OF STEPS FUNCTIONS
#---------------------------------------------------------------------------

sub _is_force_add_step {
    $_[4]->{-force};
}

sub _check_flags {
    my (undef, $args, $new_steps, undef, $flags) = @_;
    if ( $flags->{-last} && @$args ) {
	die "-last should be last in ->wizard call";
    }

    if ( $flags->{-skip} && @$new_steps && ! exists $new_steps->[-1]{skip} ) {
	die "-skip'ed steps should be first in ->wizard call";
    }
}

sub _get_default_flags {
    return { -force => 0, -last => 0, -skip => 0 };
}

=for api

Making steps from input of @args, passed from add_steps.
You can redefine following functions to make it behave different:

$self->_get_default_flags
    returns default flags

$self->_check_flags( \@args, \@new_steps, $step_ref, $flags )
    to check flags

$self->_is_force_add_step( \@args, \@new_steps, $step_ref, $flags )
    should return true if step should added with force (e.g. even if same already exists)

$self->_handle_$1_item( \@args, $step_ref, $flags )
    to handle '-$1' items in \@args

=cut

sub _make_steps {
    my $self = shift;

    DEBUG2 && carp($self->{wizard_id});

    my @caller = caller;
    while ( $_[0] && $_[0] eq 'caller' ) {
	shift;
	@caller = @{ shift() };
    }

    my $caller = join ':', @caller;
    DEBUG2 && $self->info("make_steps caller is $caller");


    my @args = @_;
    my @new_steps;

    my $flags = $self->_get_default_flags;

    while( @args ) {
	my $step = shift @args;
	my $step_hash;

	while ( exists $flags->{$step} ) {
	    $flags->{$step}++;
	    $step = shift @args;
	}

	my $step_ref = {};

	if ( $flags->{-last} ) {
	    $step_ref->{last} = 1;
	}

	if ( $flags->{-skip} ) {
	    $step_ref->{skip} = 1;
	}

	if ( $step eq '-forward' || $step eq '-detach' ) {
	    my $step_type = $step;
	    my $step_args = shift @args;
	    my $step_path = $step_args;

	    if ( ref $step_args eq 'ARRAY' ) {
		$step_path = shift @$step_args;
	    }

	    %$step_ref = (%$step_ref,
		step_type   => $step_type,
		path	    => $step_path,

		ref $step_args ?
		    (args => $step_args) :
		    (),
	    );
	}
	elsif ( $step eq '-sub' || $step eq '-subfixed' ){
	    my $step_type = $step;
	    my $step_args = shift @args;


	    %$step_ref = (%$step_ref,
		step_type   => '-sub',
		args	    => $step_args,
		fixed	    => $step_type =~ m/fixed/o ? 1 : 0,
	    );
	}
	elsif ( $step eq '-redirect' || $step !~ m/^-/ ) {
	    my $append_wizard_id = '';

	    if ( $step eq '-redirect' ) {
	       $step = shift @args;
	    }
	    else {
		$append_wizard_id = 1;
	    }


	    %$step_ref = (%$step_ref,
		step_type	    => '-redirect',
		path		    => $step,
		append_wizard_id    => $append_wizard_id,
	    );
	}
	elsif ( $step =~ m/-(.*)/ ) {
	    my $step_type = "_handle_$1_item";

	    die "cannot handle tag $1" unless $self->can($step_type);

	    next unless $self->$step_type( \@args, $step_ref, $flags );
	}

	$self->_check_flags( \@args, \@new_steps, $step_ref, $flags );

	$step_ref->{caller} = $caller;
	$step_ref->{hash}	= md5_hex(_dump($step_ref));

	DEBUG2 && $self->info(qq/step is @{[ _dump($step_ref) ]}\n/);

	if (	$self->_is_force_add_step(  \@args, \@new_steps,
					    $step_ref, $flags )
	    ||	!exists $self->{steps_already_in_wizard}{ $step_ref->{hash} } ) {

	    push @new_steps, $step_ref;
	}

	$flags = $self->_get_default_flags;
    }

    DEBUG && $self->info("new steps is @{[ _dump( \@new_steps ) ]}");
    @new_steps;
}

sub _check_last_step {
    my $self	    = shift;
    my $new_steps   = shift;

    my $check_for_last_step = $new_steps->[-1];

    return  if ! $check_for_last_step->{last};

    # remove and dont add it
    pop @$new_steps;

    # already have last_step
    return  if exists $self->{have_last_step};

    # ok, append that last step for steps
    $self->{have_last_step} = 1;
    push @{ $self->{steps} }, $check_for_last_step;

    # remove hash from it and append in 'already in wizard'
    $self->_add_to_steps_already_in_wizard( [ $check_for_last_step ] );
}

sub _check_skip_steps {
    my $self	    = shift;
    my $new_steps   = shift;

    # dont skip if some steps remaining
    return if ( $self->{step_number} > @{ $self->{steps} } );

    my $skip_count = grep { delete $_->{skip} } @$new_steps;

    $self->next_step( $skip_count );
}

sub _add_to_steps_already_in_wizard {
    my $self = shift;
    my $new_steps = shift;

    foreach ( @$new_steps ) {
	$self->{steps_already_in_wizard}{ delete $_->{hash} } = 1;
    }
}


=head2 $wizard->add_steps( @args )

Add steps from @args.

@args is an array of path for steps with specification of each step:

=over 3

=item I<< (-redirect => 'path') >> or I<'path'>

Redirect to path. If '-redirect' is given, then no action wizard id will
be append to the redirect URL. Use this for last actions in wizard.

You can append any query parameters to 'path'.

=item I<< (-detach => [ 'path', @step_args ]) >> or I<< (-detach => 'path') >>

Detaches to path.


=item I<< -last => B<[ -forward | -detach | -redirect ]> => 'path' >>

Last step in wizard. Only one (first) '-last' step will be added, all others will be ignored. Note that -last =>  step should be last in ->add_steps call, elsewhere add_steps will throw exception.

=back

=cut

sub add_steps {
    my $self = shift;

    return if $self->{no_add_step};

    my @new_steps = $self->_make_steps( caller => [ caller ], @_ );

    $self->_check_last_step( \@new_steps );

    splice @{ $self->{steps} }, $self->{step_number}, 0, @new_steps;
    $self->_add_to_steps_already_in_wizard( \@new_steps );

    $self->_check_skip_steps( \@new_steps );
}



#---------------------------------------------------------------------------
#  STEP FLOW FUNCTIONS
#---------------------------------------------------------------------------



sub _step {
    my $self = shift;

    if ( exists $self->{step_back} && $self->{step_number} > 0 ) {
	return $self->_step_back();
    }

    return unless exists $self->{steps}[ $self->{step_number} ];

    my $step = $self->{steps}[ $self->{step_number} ];

    $self->next_step($_[0] || 0);

    $step;
}


=head2 $wizard->next_step(I<[ $shift_count ]>)

Shift $shift_count steps, or 1 if no $shift_count is given.

=cut


sub next_step {
    my $self = shift;
    my $shift = shift;

    $shift = 1 unless defined $shift;

    $self->{step_number} += $shift;
}


#===  FUNCTION  ================================================================
#         NAME:  _step_back
#      PURPOSE:  Makes step back.
#     COMMENTS:  none
#===============================================================================

sub _step_back {
    my $self	    = shift;
    my $step_back   = delete $self->{step_back};

    my $path = $step_back->{path};

    my $step_to_go;

    DEBUG && $self->info(_dump($step_back));

    my $i;
    for($i = $self->{step_number} - 1; $i >= 0; $i--) {
	my $step = $self->{steps}[$i];

#	$self->info _dump($i, $self);


	do { $step_to_go = $step; last } if $step->{path} =~ m{^/?$path$};
    }

    DEBUG && $self->info("cant find step back") unless $step_to_go;
    return unless $step_to_go;

    my (undef, $other) =
	grep { $_->{path} =~ m{^/?$path$} }
	    reverse @{ $self->{steps} } [0..$self->{step_number} - 1];

    die "$other remain" if $other;

    my %step_back = (%$step_to_go,
	step_type => $step_back->{type} || '-redirect');
    $step_back = \%step_back;

    # to the next of current step
    $self->{step_number} = $i; # + 1;


    return $step_back;
}

=head2 $wizard->uri_for_next

Returns URI for next step in wizard (if that step is '-redirect').

=cut


sub uri_for_next {
    my $self = shift;

    my $step_number = $self->{step_number}; # + 1;

    return if $step_number > $#{ $self->{steps} };

    my $step = $self->{steps}[ $step_number ];

    #$self->info "uri_for_next: "._dump($step);

    return if ( $step->{step_type} ne '-redirect' );

    $step->{uri_for_next} = 1;

    my $path = $self->_get_full_path( $step,
	{
	    append_wizard_step => 1,
	}
    );
    DEBUG && $self->info("uri_for_next return: $path");

    return $path;
}



sub _mark_goto {
    $_[0]->{goto} = 1;

    # if goto_next and back_to should end executing of wizard
    die $GOTO_NEXT if $_[0]->{die_for_goto};

    1;
}


=head2 $wizard->goto_next

Mark wizard step to be performed.

If $wizard->{die_for_goto} is true will act like detach, throwing $GOTO_NEXT exception.

=cut

sub goto_next {
    my $self = shift;

    DEBUG && $self->info( "goto_next: "._dump([ (caller(0))[0..3] ]) );

    $self->_mark_goto if $self->{step_number} <= $#{ $self->{steps} } ;

    return;
}

=head2 $wizard->back_to( B<< [ -redirect | -detach | -forward => ] >> 'path' )

Return to step 'path' which will be performed by original step type or by step type you set as argument.

Will do nothing if none 'path' step if found.

=cut

sub back_to {
    my $self = shift;

    my $path = shift;
    my $type;

    return unless $self->{step_number};

    if ( $path eq '-detach' or $path eq '-forward' ) {
	$type = $path;
	$path = shift;
    }

    DEBUG && $self->info( $path, $type );

    my $found_in_passed = do {
	grep { $_->{path} =~ m{^/?$path$} }
	    reverse @{ $self->{steps} } [0..$self->{step_number} - 1];
    };

    return unless $found_in_passed;

    $self->{step_back} = {
	path => $path,
	type => $type,
    };

    $self->_mark_goto;

    1;
}


=head2 $wizard->perform_step( $c )

Perform step. Function to call when step performing should be done.
(called, for instance, in Catalyst::Action::Wizard _END)

=cut

sub perform_step {
    my $self	    = shift;
    my $c	    = shift;

    return unless delete $self->{goto};

    my $step = $self->_step;

    DEBUG && $self->info(_dump($step));

    return unless $step;

    if ( $step->{step_type} eq '-detach' or $step->{step_type} eq '-forward' ) {
	my $step_type = $step->{step_type};
	$step_type =~ s/^-//; #THATS NOT SMILE!

	$self->next_step;

	return $c->$step_type($step->{path}, $step->{args});
    }

    if ( $step->{step_type} eq '-sub' ) {
	return $self->_make_sub_wizard( $c, $step );
    }

    my $path = $self->_get_full_path($step,
	{
	    append_wizard_step => 1,
	}
    );

    # dont call ->save, will be saved in Action::Wizard.
    $c->response->redirect($path);
}

#===  FUNCTION  ================================================================
#         NAME:  _make_sub_wizard
#      PURPOSE:  make sub wizard from record in sub wizard
#   PARAMETERS:  $self, $c, $step
#      RETURNS:  nothing, redirects/detaches/forwards to first step
#		 of subwizard
#       THROWS:  no exceptions
#===============================================================================


sub _make_sub_wizard {
    my $self		= shift;
    my ($c, $step) = @_;

    my $new_wizard = Catalyst::Wizard->new( $c );

    $new_wizard->add_steps( @{ $step->{args} } );

    # to the next step, for ->_step calling in ->last action
    $self->next_step;
    $new_wizard->add_steps(
	-last => -redirect => $self->_get_full_path( $self->_step,
	    {
		append_wizard_step  => 1,
		append_wizard_id    => 1,
	    }
	)
    );

    $new_wizard->{no_add_step} = $step->{fixed};
    $new_wizard->{stash}       = $self->{stash};

    # remove our stash
    $self->save( $c );
    # replace with stash of new_wizard
    $new_wizard->load( $c );

    DEBUG && $self->info("setting wizard for ".$c->action. " ". refaddr( $c->action ));
    $c->req->params->{wid}  = $new_wizard->{wizard_id};
    _current_wizard( $c, $new_wizard );

    DEBUG && $self->info("params: ", $c->req->params->{wid});

    DEBUG && $self->info(
"old wizard: $self->{wizard_id}
new step id: $new_wizard->{wizard_id}");


    # in case it can die
    eval { $new_wizard->goto_next };
    $new_wizard->perform_step( $c );

    # save us, if we reached this point
    $new_wizard->save( $c );
}

#===  FUNCTION  ================================================================
#         NAME:  _get_full_path
#      PURPOSE:  Gets full path for redirect
#===============================================================================


sub _get_full_path {
    my $self = shift;

    my ( $step, $options_ref ) = @_;

    $options_ref ||= {
	append_wizard_step  => 0,
	append_wizard_id    => 1,
    };

    exists $options_ref->{$_} or $options_ref->{$_} = $step->{$_}
			foreach (qw(append_wizard_step append_wizard_id));


    my $uri = URI->new( $step->{path} );


    #die if ! $options_ref->{ append_wizard_id }  && $options_ref->{append_wizard_step};

    if ( $options_ref->{ append_wizard_id } ) {
	my $wizard_id =
	    $self->_get_wizard_id($options_ref->{append_wizard_step});

	$uri->query_param_append( 'wid' => $wizard_id );

	if (	exists $options_ref->{append_to_uri}
	    &&	ref $options_ref->{append_to_uri} eq 'HASH') {

	    my $a = $options_ref->{append_to_uri};

	    $uri->query_param_append( $_ => $a->{$_} ) foreach keys %$a;
	}
    }

    DEBUG && $self->short_info($uri->as_string);

    return $uri->as_string;
}

#---------------------------------------------------------------------------
#  OTHER HELPERS
#---------------------------------------------------------------------------


sub check_step_number {
    my $self	= shift;
    my $c	= shift;
    my $step	= shift;

    DEBUG && $self->info(_dump($step));

    # forward step by redirect + append_wizard_step is ONLY
    # if previous step (ie. from which redirection was)
    # IS redirection type
    if (    $self->{step_number} + 1 == $step
	&&  $self->{steps}[
		$self->{step_number}
	    ]->{step_type} eq '-redirect') {


	return $self->next_step;
    }

    # back step is only for -redirect steps
    if (    $self->{step_number} > $step
	&&  $self->{steps}[$step]->{step_type} eq '-redirect' ) {
	return $self->_force_dont_step_back if $self->{no_step_back};

	$self->{step_number} = $step;
    }
}



sub _force_dont_step_back {
    die "Step back attempt";
}


=head2 $wizard->stash

Stash accessor.

=cut


sub stash {
    shift->{stash};
}



sub _get_wizard_id {
    my $self = shift;
    my $add_steps = shift;

    my @wizard_id = ($self->{wizard_id});

    push @wizard_id, $self->{step_number} + $add_steps if defined $add_steps;

    return join '_', @wizard_id;
}


=head2 $wizard->id_to_form

Get wizard id as <input> tag for <FORM>.

=cut


sub id_to_form {
    my $self = shift;

    if ($self->{steps}[ $self->{step_number} ]->{uri_for_next}) {
	return
	    '<input type="hidden" name="wid" value="' .
	    $self->_get_wizard_id(1)
	    . '"/>'."\n";
    }

    $self->{"id_to_form"} ||=
	'<input type="hidden" name="wid" value="'.
	$self->_get_wizard_id.
	'"/>'."\n";
}

#---------------------------------------------------------------------------
#  LOAD/SAVE AND STORAGES
#---------------------------------------------------------------------------

=head2 $wizard->load( $c )

Loads wizard (by default just installs stash).

=cut


sub load {
    my ( $self, $c ) = @_;

    # all ok, can replace wizard in stash
    if (    ! exists $c->stash->{wizard}
	||  ! keys %{ $c->stash->{wizard} } ) {
	$c->stash->{wizard} = $self->{stash};
    }
    # user first userd stash->wizard and only then
    # created wizard (by call of $c->wizard)
    # handle it
    elsif (
	      keys %{ $c->stash->{wizard} || {} }
	&&  ! keys %{ $self->{stash} } ) {

	# use it as our own stash
	$self->{stash} = $c->stash->{wizard};
    }
    #else {
    # no else -- we cant have both our and catalyst stash->{wizard}
    # filled, because we ->load'ed in ->new
    #}
}

=head2 $wizard->save( $c )

Save wizard into wizard_storage.

If $c have B<wizard_storage> it will be called with two arguments: wizard id and wizard instance.

Elsewhere default (session) storage will be used.

=cut

sub save {
    my ( $self, $c ) = @_;

    DEBUG2 && carp($self->{wizard_id});

    DEBUG && $self->info();

    if ( ! @{ $self->{steps} } ) {
	DEBUG && $self->short_info('dont saving wizard without steps');
	return;
    }

    my $wizard_id = $self->{wizard_id};

    if ( $c->can('wizard_storage' ) ) {
	DEBUG2 && $self->info("Calling supported wizard_storage");
	return $c->wizard_storage( $wizard_id => $self );
    }

    delete $c->stash->{wizard};
    return if $self->{loaded_from_storage};

    DEBUG2 && $self->info("save sing session $wizard_id");
    my $storage = $c->session;

    $self->{expires} ||= time + $c->config->{wizard}{expires};
    return if ( $self->{expires} <= time );

    $storage->{_wizards}{$wizard_id} = $self;
}


=head2 Catalyst::Wizard->wizard_storage( $c, $wizard_id )

Loads $wizard_id from wizard_storage, if can.

First checked if $c can 'wizard_storage'. If yes -- it will be called, else default (session) storage will be used.

Note also that this functions purges old wizards in session.

=cut


sub wizard_storage {
    my ( $class, $c, $wizard_id ) = @_;

    if ( $c->can('wizard_storage' ) ) {
	DEBUG2 && $class->info("calling supported wizard_storage");
	return $c->wizard_storage( $wizard_id );
    }

    DEBUG2 && $class->info("calling session: $wizard_id", $c->action."");
    my $storage = $c->session->{_wizards};

    foreach my $wid (keys %$storage) {
	next if ( $storage->{$wid}{expires} > time );

	delete $storage->{$wid};
    }

    if (exists $storage->{$wizard_id}) {
	return $storage->{$wizard_id};
    }

    return;
}



sub _current_wizard {
    my ( $c, $current ) = @_;

    Carp::cluck unless ref $c;

    if ( $c->can('wizard_storage') ) {
	DEBUG2 && __PACKAGE__->
	    info("calling supported wizard_storage for current_wizard");
	return $c->wizard_storage( 'current' => $current );
    }

    DEBUG2 && __PACKAGE__->
	info("using \$c->stash->{_current_wizard} as storage");

    my $storage = $c->stash;

    $storage->{_current_wizard} = $current if defined $current;
    $storage->{_current_wizard};

}


#---------------------------------------------------------------------------
#  UTILITY FUNCTIONS
#---------------------------------------------------------------------------

sub _dump_self {
    my $self = shift;
    return ($self->{wizard_id}, " ", _dump($self));
}


sub refaddr($) {
    sprintf "%x", Scalar::Util::refaddr(shift);
}

=head2 $wizard->info and $wizard->short_info

Prints current wizard info.

short_info omits steps on print.

Note that info will skip all the inherited methods ($self->SUPER::info call).

=cut


sub info {
    my $self = shift;

    open my $fh, '>>', '/tmp/logfile';

    my $caller_fun;
    for( my $i = 1; $i == 1 || $caller_fun =~ /::(short_)?info$/; $i++ ) {
	$caller_fun = (caller($i))[3];
    }

    unshift @_, $self->_dump_self, " " if ref $self;
    unshift @_, $caller_fun, " ";

    print $fh @_, "\n";
    close $fh;
}


sub short_info {
    my $self = shift;
    local $self->{steps} = '...skipped...';

    $self->info( @_ );
}

=head1 SEE ALSO

L<Catalyst::Plugin::Continuation>, L<Catalyst Plugin Wizard (DEPRECATED)|Catalyst::Plugin::Wizard>

=cut

=head1 AUTHOR

Pavel Boldin <davinchi@cpan.org> for REG.RU.

=cut

package # hide from PAUSE
    Catalyst::FakeWizard;

sub goto_next {
    my $self = shift;

    my $c	  = $self->[0];
    my $step_type = $self->[1];
    my $path	  = $self->[2];

    if ( $step_type eq 'detach' or $step_type eq 'forward' ) {
	return $c->$step_type( $path );
    }

    return $c->response->redirect( $path );
}

sub AUTOLOAD {
}

1;
