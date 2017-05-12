
=head1 NAME

Catalyst::Plugin::Params::Profile - Parameter checking with Params::Profile

=head1 SYNOPSIS

    package MyAPP;
    use Catalyst qw/Params::Profile/;

    # In a controller
    MyAPP->register_profile(
                    'method'    => 'subroto',
                    'profile'   => {
                                testkey1 => { required => 1 },
                                testkey2 => {
                                        required => 1,
                                        allow => qr/^\d+$/,
                                    },
                                testkey3 => {
                                        allow => qr/^\w+$/,
                                    },
                                },
                );

    sub subroto : Private {
        my (%params) = @_;

        return unlesss $c->validate('params' => \%params);
        ### OR
        my %opts = $c->check_params or return;

        ### DO SOME STUFF HERE ...

        my $profile = $c->get_profile('method' => 'subroto');
    }


    ### Multiple Profile
    MyAPP->register_profile(
                    'method'    => 'subalso',
                    'profile'   => [
                                    'subroto',
                                    {
                                    testkey4 => { required => 1 },
                                    testkey5 => {
                                            required => 1,
                                            allow => qr/^\d+$/,
                                        },
                                    testkey6 => {
                                            allow => qr/^\w+$/,
                                        },
                                    },
                                ],
                );


    sub subalso : Local {
        my (%params) = @_;

        ### Checks parameters agains profile of subroto and above registered
        ### profile
        return unlesss $c->validate('params' => \%params);

        ### DO SOME STUFF HERE ...
    }


=head1 DESCRIPTION

Catalyst::Plugin::Params::Profile provides a mechanism for a centralised
Params::Check or a Data::FormValidater profile. You can bind a profile to a
class::subroutine, then, when you are in a subroutine you can simply call
$c->check($params) of $c->validate($params) to validate against this profile.

For more information read the manual of C<Params::Profile> , the methods below
are just an interface on it.

=head1 Public Methods

See C<Params::Profile> for more information about the specific methods,
the onse listed below are the most important.

=over 4

=item $c->register_profile('method' => $METHOD, 'profile' => \%PROFILE);

=item $c->get_profile('method' => $METHOD);

=item $c->validate('params' => \%PARAMS);

=item $c->check('params' =>  \%PARAMS);

=back

=head2 $c->check_params;

Checks $c->req->params against the profile of the calling sub. It returns
a HASHREF containing validate parameters, or undef on failure. It will also
log to Catalyst::Log about what happened.

Extra options to this sub are:

=over 4

=item params OPTIONAL

Validate against params instead of $c->req->params

=item profile OPTIONAL

Validate against profile instead of profile of calling sub

=item allow_unknown OPTIONAL

Pass the unknown parameters to the return HREF rather than filtering them out.

=item dv OPTIONAL

Instead of returning a hashref containing validated params, return the
Data::FormValidator::Results object.

NOTE: Only tested with Data::FormValidator yet!!

=back

=head1 XMLRPC

This module also registers a method name called C<system.methodHelp> into
the Server::XMLRPC plugin when it is loaded. This method will try to explain
in plaintext the arguments for the subroutine by parsing the given profile.

Example output when system.methodHelp is called with one argument containing
the name of the method you'd like to be explained:

    Required arguments are:
     * customer_id
     * username
     * product

    Optional arguments are:
     * roaming
     * card_type

NOTE: This currently only works for Data::FormValidator profiles.

=cut

{   package Catalyst::Plugin::Params::Profile;

    use strict;
    use warnings;

    use Catalyst::ActionContainer;
    use Tree::Simple;
    use Class::C3;

    our $VERSION = '0.05';

    use base qw/Params::Profile/;

    ### Override _raise_warning of paramsprofile to log to Catalyst
    ### debug engine
    sub _raise_warning {
        my ($c, $warning) = @_;

        ### Do not warn on missing profile, this will be shown in a nice
        ### formatted table in debug mode ;)
        return if $warning =~ /No profile for/;

        $c->log->debug($warning) if $c->debug;
    }


    ### Extend setup_actions to check Params::Profile registered methods,
    ### and generate a nice table containing Params::Profile specific
    ### informatie. We will also register a method 'system.methodHelp' into
    ### the Server::XMLRPC module when this module is available.
    sub setup_actions {
        my $c = shift;
        $c->next::method( @_ );

        ### Generate nice table containing Params::Profile specific
        ### information
        $c->_check_profiles;

        $c->error('WARNING: Profiles are not correct!') unless
                    Params::Profile->verify_profiles;

        if ($c->registered_plugins('Server::XMLRPC')) {
            $c->server->xmlrpc->add_private_method('system.methodHelp', sub
                {
                    my ($class, @args) = @_;
                    my $action = $class->server->xmlrpc->dispatcher->{
                                        'Path'
                                    }->methods->{$args[0]};
                    my $ns = $action->class .'::'. $action->name;
                    $class->stash->{xmlrpc} = $class->_describe_pp_plaintext(
                                    profile => $ns,
                                );
                }
            );
        }
    }

    sub _check_profiles {
        my ($c) = @_;
        my $actions = {};

        for my $controller ($c->controllers) {
            my @containers = $c->dispatcher->get_containers($c->controller($controller)->action_namespace);

            for my $container (@containers) {
                my $container_actions     = $container->actions;

                for my $action ( keys %{ $container_actions } ) {
                    next if $action =~ /^_.*/;

                    my $action_obj  = $container_actions->{$action};

                    $actions->{
                            $action_obj->class . '::' . $action_obj->name
                        } = $action_obj;
                }
            }
        }

        return 1 if scalar(keys %{ $actions }) < 1;

        { # Table creation
            my $nogotable = Text::SimpleTable->new(
                [ 20, 'Private'],
                [ 38, 'Class'  ],
                [ 12, 'Method' ],
            );

            my $show_nogotable;
            foreach my $method (%{$actions}) {
                my $action = $actions->{$method};
                next unless (
                        $action &&
                        !$action->attributes->{Private} &&
                        !$c->get_profile('method' => $method)
                    );
                $show_nogotable = 1;
                $nogotable->row(
                                '/'.$action->reverse,
                                $action->class,
                                $action->name,
                            );
            }

            $c->log->debug("WARNING: Missing profiles:\n" . $nogotable->draw)
                    if $c->debug && $show_nogotable;
        }
    }

    sub _describe_pp_plaintext {
        my ($self, %opts) = @_;
        my ($profile,$txt);

        ### Check if option profile is a profile or a methodname
        if (!UNIVERSAL::isa($opts{profile},'HASH')) {
            $profile = $self->get_profile(method => $opts{profile}) or return;
        } else {
            $profile = $opts{profile};
        }

        ### Check for Data::FormValidator profile
        return 'No help available for this method' unless
                    UNIVERSAL::isa($profile->{required}, 'ARRAY') ||
                    UNIVERSAL::isa($profile->{optional}, 'ARRAY');

        ### Create describe string
        if ($profile->{required}) {
            $txt .= "Required arguments are:";
            $txt .= "\n * " . $_ for @{$profile->{required}};
            $txt .= "\n\n";
        }
        if ($profile->{optional}) {
            $txt .= "Optional arguments are:";
            $txt .= "\n * " . $_ for @{$profile->{optional}};
            $txt .= "\n\n";
        }
        if ($profile->{constraint_methods} && $opts{constraints}) {
            $txt .= "Given constraints are:";
            while (my ($key, $value) = each %{$profile->{constraint_methods}}) {
                $txt .= "\n $key => " . scalar($value);
            }
        }

        return $txt;
    }

    sub check_params {
        my ($c, %args) = @_;
        my (%ok_params);
        ### Extra option: allow_unknown
        ### allow_unknown: do not filter out parameters we do not know

        ### Get options
        my %params = $args{params} || %{ $c->req->params };

        ### Get caller
        my $caller_sub = $args{method} || [caller(1)]->[3];

        local $Params::Check::VERBOSE = undef;
        local $Params::Check::ALLOW_UNKNOWN = 1 if $args{allow_unknown};

        my $result = $c->check(
                method  => $caller_sub,
                params  => \%params,
            );

        if (
            UNIVERSAL::isa($result, 'Data::FormValidator::Results')
        ) {
            my $dv = $result;

            ### Go into error when parameters validate AND
            ### we have no unknown params or pass_unknown is 1
            unless ($dv->success) {
                my $errmsg = "Problems validating profile:";
                ### Go log something
                $errmsg .= "\n        Missing params:\n        * " .
                            join("\n        * ", $dv->missing)
                            if $dv->has_missing;
                $errmsg .= "\n        Invalid params:\n        * " .
                            join("\n        * ", $dv->invalid)
                            if $dv->has_invalid;
                $errmsg .= "\n        Unknown params:\n        * " .
                            join("\n        * ", $dv->unknown)
                            if $dv->has_unknown;
                $c->log->debug($errmsg) if $c->debug;
                return;
            }

            return $dv if $args{dv};

            ### Force dv->valid to return as href
            my $href = $dv->valid;

            ### Return all params or only validated ones.
            return $args{allow_unknown} ? \%params : $href;
        } else {
            if (my $errmsg = Params::Check::last_error()) {
                $c->log->debug("Problems validating profile:\n" .
                        Params::Check::last_error()) if $c->debug;
            }
            return $result;
        }

        return;
    }
}

1;

__END__

=head1 AUTHOR

Michiel Ootjers E<lt>michiel@cpan.orgE<gt>.

and

Jos Boumans E<lt>kane@cpan.orgE<gt>.

=head1 TODO

=over 4

=item profile explanation

Fix the profile explanation to explain profiles other than
C<Data::FormValidator>

=back

=head1 BUG REPORTS

Please submit all bugs regarding C<Catalyst::Plugin::Params::Profile> to
C<bug-catalyst-plugin-params-profile@rt.cpan.org>

=head1 SOURCE

Please send your improvements as pull request via bitbucket.org to
C<https://bitbucket.org/michielootjers/catalyst-plugin-params-profile>

=head1 COPYRIGHT

This module is
copyright (c) 2002-2013 Michiel Ootjers E<lt>michiel@cpan.orgE<gt>.
All rights reserved.

This library is free software;
you may redistribute and/or modify it under the same
terms as Perl itself.

=cut
