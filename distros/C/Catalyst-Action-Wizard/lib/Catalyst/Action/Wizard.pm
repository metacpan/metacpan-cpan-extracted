=head1 NAME

Catalyst::Action::Wizard

=head1 DESCRIPTION

Actions like realization of wizards. You need this
if you have some multi-actions data gathering which unlikely
to be saved in session and to big to pass them
as POST or GET parameters.

=head1 AUTHORS

Pavel Boldin (), <davinchi@cpan.ru>

=cut

package Catalyst::Action::Wizard;

use strict;
use warnings;

use Catalyst::Action;
use Catalyst::Wizard;
use Catalyst::Utils;
use MRO::Compat;

use Scalar::Util;

use base 'Catalyst::Action';

our $VERSION = '0.008';

sub refaddr($) {
    sprintf "%x", Scalar::Util::refaddr(shift);
}

sub _current_wizard {
    return Catalyst::Wizard::_current_wizard(@_);
}

sub _new_wizard {
    my $c    = shift;
    my $wizard_id = shift || 'new';

    my $class = $c->config->{wizard}{class} || 'Catalyst::Wizard';

    Catalyst::Utils::ensure_class_loaded( $class );

    Catalyst::Wizard::DEBUG &&
        Catalyst::Wizard->info( 'calling _new_wizard: '.$wizard_id );

    _current_wizard($c, $class->new( $c, $wizard_id ) );
}

sub _dont_create_if_empty {
    my $c = shift;
    my $caller_pkg = shift;

    # check if not creating wizard in this caller package
    if ( my $re = $c->config->{wizard}{_ignore_empty_wizard_call_pkg_re} ) {
        return 1  if $caller_pkg =~ $re;
        return;
    }

    return  unless exists $c->config->{wizard}{ignore_empty_wizard_call_pkg};

    my $config = $c->config->{wizard}{ignore_empty_wizard_call_pkg};

    return  unless ref $config  eq 'ARRAY';

    my @prefixes = grep { m/::$/o } @$config;
    my @packages = grep { m/\w$/o } @$config;

    my @regexp;

    if ( @packages ) {
        push @regexp, '^(?:'.join ('|', @packages).')$';
    }

    if ( @prefixes ) {
        push @regexp, '^(?:'.join ('|', @prefixes).')';
    }

    my $regexp = join '|', @regexp;

    $regexp = qr/$regexp/o;

    $c->config->{wizard}{_ignore_empty_wizard_call_pkg_re} = $regexp;

    # pass thru
    return _dont_create_if_empty( $c, $caller_pkg );
}

sub wizard {
    my $self = shift;
    my $c    = shift;

    if ( @_ ) {

        if ( ! _current_wizard( $c )
            &&        $_[0] eq '-last'
            && (
                @_ == 3
                || @_ == 2
            )
        ) {
            shift;

            my $step_type = 'redirect';

            if ( @_ == 2 ) {
                $step_type = shift;
                $step_type =~ s/^-//g;

                if ( $step_type !~ m/redirect|detach|forward/ ) {
                    die "Unknown step type: $step_type";
                }
            }

            my $path = shift;

            my $fake_wizard = [ $c, $step_type, $path ];

            bless $fake_wizard, 'Catalyst::FakeWizard';

            return $fake_wizard;
        }

        if ( !_current_wizard( $c ) ) {
            _new_wizard( $c );
        }

        _current_wizard($c)->add_steps(caller => [ caller ], @_);
    } elsif( ! _current_wizard( $c )
            && _dont_create_if_empty( $c, caller() )
    ) {
        return bless \(my $a = ''), 'Catalyst::FakeWizard';
    }

    return _current_wizard($c);
}

sub execute {
    my $self = shift;
    my ($controller, $c) = @_;

    #warn "executing: $self";

    if ( $self->name eq '_BEGIN' ) {
        my $wizard_id = $c->can('wizard_id') ? $c->wizard_id
            : exists $c->req->params->{wid}  ? $c->req->params->{wid}
            : ''
            ;

        my $wizard_id_without_step;

        if ( $wizard_id ) {
            ($wizard_id_without_step) = $wizard_id =~ /([0-9a-zA-Z]{32})/;
        }

        if ( $wizard_id && $wizard_id_without_step ) {
            _new_wizard( $c, $wizard_id );
        }

    } elsif ( $self->name eq '_END' ) {
#        $self->next::method(@_);
        if ( _current_wizard( $c ) ) {
            _current_wizard( $c )->save( $c );
        }
#        return;
    } elsif ( $self->name !~ /^_(?:ACTION|DISPATCH|AUTO)/ ) {

        my @ret = eval { $self->next::method(@_) };

        # can be created in action
        my $wizard = _current_wizard( $c );

        if ($wizard
            &&
            (
                (
                    $@
                	&& $@ eq $Catalyst::Wizard::GOTO_NEXT
                )
                ||  $wizard->{goto}
            )
        ) {
            undef $@;
            $wizard->perform_step( $c );
        }
        elsif ( $@ ) {
            die $@;
        }

        return wantarray ? @ret : $ret[0];
    }

    $self->next::method(@_);
}

1;
