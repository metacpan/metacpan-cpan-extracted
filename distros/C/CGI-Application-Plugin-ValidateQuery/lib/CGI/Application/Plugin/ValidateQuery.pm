package CGI::Application::Plugin::ValidateQuery;

use warnings;
use strict;

use base 'Exporter';

use Carp 'croak';
use Params::Validate ':all';

=head1 NAME

CGI::Application::Plugin::ValidateQuery - lightweight query validation for CGI::Application

=head1 VERSION

Version 1.0.5

=cut

our $VERSION = '1.0.5';

our @EXPORT_OK = qw(
    validate_query_config
    validate_app_params
    validate_query
    validate_query_error_mode
);
push @EXPORT_OK, @Params::Validate::EXPORT_OK;
our %EXPORT_TAGS = (
    all   => \@EXPORT_OK,
    types => $Params::Validate::EXPORT_TAGS{types}
);

local $Params::Validate::NO_VALIDATION = 0;

sub validate_query_config {
    my $self = shift;

    my $opts = {@_};

    $opts = {map {uc $_ => $opts->{$_}} keys %$opts};

    # for now, default checking all params. First config arg is legacy.
    if ( defined $opts->{EXTRA_FIELDS_OPTIONAL} or defined $opts->{ALLOW_EXTRA} ) {
        delete $opts->{EXTRA_FIELDS_OPTIONAL};
        delete $opts->{ALLOW_EXTRA};
        $self->{__CAP_VALQUERY_ALLOW_EXTRA} = 1;
    } else {
        $self->{__CAP_VALQUERY_ALLOW_EXTRA} = 0;
    }

    $self->{__CAP_VALQUERY_ERROR_MODE} = defined $opts->{ERROR_MODE} ?
        delete $opts->{ERROR_MODE} : 'validate_query_error_mode';

    $self->{__CAP_VALQUERY_LOG_LEVEL} = defined $opts->{LOG_LEVEL} ?
        delete $opts->{LOG_LEVEL} : undef;

    croak 'log_level given but no logging interface exists.'
        if $self->{__CAP_VALQUERY_LOG_LEVEL} && !$self->can('log');

    croak 'Invalid option(s) ('.join(', ', keys %{$opts}).') passed to'
          .'validate_query_config' if %{$opts};
}

sub validate_app_params {
    my $self = shift;

    return unless @_;

    my $query_props = {@_};

    $query_props->{allow_extra} = 1;
    $query_props->{app_params}  = 1;

    return _validate($self, $query_props);
}

sub validate_query {
    my $self = shift;

    return unless @_;

    return _validate($self, {@_});
}


sub _validate {
    my $self        = shift;
    my $query_props = shift;

    my $log_level = delete $query_props->{log_level}
                    || $self->{__CAP_VALQUERY_LOG_LEVEL};

    my $allow_extra = delete($query_props->{extra_fields_optional})
                      || delete($query_props->{allow_extra})
                      || $self->{__CAP_ALLOW_EXTRA};

    my $app_params = delete $query_props->{app_params};

    my $param_obj = $app_params ? $self : $self->query;

    # filter query_props to support quick regex syntax
    # turns
        # key => qr/$regex/
    # into
        # key => { regex => qr/$regex/ }
    for my $key (keys %$query_props) {
        my $val = $query_props->{$key};
        if ( ref $val eq 'Regexp' ) {
            $query_props->{$key} = { regex => $val, type => SCALAR };
        }
    }

    my %validated;
    eval {
        my @vars_array;
        for my $p ($param_obj->param) {
            my @values = $param_obj->param($p);
            push @vars_array, ($p, scalar @values > 1 ? \@values : $values[0]);
        }
        %validated = validate_with(
            params      => \@vars_array,
            spec        => $query_props,
            allow_extra => $allow_extra
        );
    };
    if ($@) {
        my $log_msg = "Query Validation Failed: $@";
        $self->log->$log_level($log_msg) if $log_level;
        $self->error_mode($self->{__CAP_VALQUERY_ERROR_MODE});

        croak $log_msg;
    }

    # Account for default values, and use the expanded -name / -value
    # syntax for CGI to ensure proper handling of multivalued fields.
    my $sub = $app_params
        ? sub { my $p = shift; $param_obj->param($p, $validated{$p}) }
        : sub { my $p = shift; $param_obj->param(-name=>$p, -value=>$validated{$p}) };

    map { $sub->($_) } keys %validated;

    return %validated;
}

sub validate_query_error_mode {
    my $self  = shift;
    return "<html><head><title>Request not understood</title></head><body>The
            request submitted could not be understood.</body></html>";
}

1;

__END__


=head1 SYNOPSIS

 use CGI::Application::ValidateQuery qw(validate_query
                                        validate_app_params
                                        validate_query_config
                                        :types);

 sub setup {
     my $self = shift;

     $self->validate_query_config(
            # define a page to show for invalid queries, or default to
            # serving a plain, internal page
            error_mode            => 'my_invalid_query_run_mode',
            log_level             => 'notice',
            allow_extra           => 0
     );

 }

 sub my_run_mode {
    my $self = shift;

    # validate select options stored in the app itself
    $self->validate_app_params(
        user_id  => qr/\A[a-zA-Z]\z/,
    );

    # move on...
 }

 sub another_run_mode {
    my $self = shift;

    # validate the query and return a standard error page on failure.
    $self->validate_query(
            pet_id    => SCALAR,
            direction => { type => SCALAR, default => 'up' },
    );

    # go on with life...

 }

=head1 DESCRIPTION

This plugin is for small query validation tasks. For example, perhaps
you link to a page where a "pet_id" is required, and you need to reality
check that this exists or return essentially a generic error message to
the user.

Even if your application generates the link, it may become altered
through tampering, malware, or other unanticipated events.

This plugin uses L<Params::Validate> to validate either a query object or
values stored in a CGI::Application object. You can define your own error page
to return on failure, or import a plain default one that we supply.

You may also define a C<log_level>, if you do, we will also log each
validation failure at the chosen level like this:

 $self->log->$loglevel("Query validation failed: $@");

L<CGI::Application::Plugin::LogDispatch> is one plugin which implements
this logging API.

=head2 validate_query

    $self->validate_query(
                            pet_id      => qr/\A\d+\z/, # implies regex and type=>SCALAR
                            species     => { type => SCALAR, default => 'lizard' },
                            log_level   => 'critical',  # optional
                            allow_extra => 1  # optional, default is 0
     );

Validates C<< $self->query >> using L<Params::Validate>. If any required
query param is missing or invalid, the  run mode defined with C<<
validate_query_config >> will be used. If  you don't want to supply one, you
can import a plain error run mode--C<< validate_query_error_mode >>
that we provide. It will be returned by default. C<< validate_query_config >>
is usually called in C<< setup() >>, or a in a project super-class.

If C<log_level> is defined, it will override the the log level provided in
C<< validate_query_config >> and log a validation failure at that log
level.

If allow_extra is defined and true, any parameter found in $self->query not
listed in the call to validate_query will be ignored by the check (in other
words, it will be included in the profile passed to L<Params::Validate> but
marked only as optional). If this is all the validation you're performing,
don't use this; this option is here for cases where, for example, a bunch of
POST values are already being checked by something heavier like
L<Data::FormValidator> and you just want to check one or two GET values.

If you set a default for any parameter, the query will be modified with that
value should that parameter be missing.

=head2 validate_app_params

    $self->validate_app_params(
        user_id  => qr/\A[a-zA-Z]\z/,
    );

Behaves like C<< validate_query >> with these exceptions:

=over

=item * allow_extra is set to true

=item * items specified are looked for and validated using C<$self->param>
          instead of C<$self->query->param>.

=back


=head2 IMPLENTATION NOTES

We re-export the constants provided in L<Params::Validate>. They can be loaded
using either the :all tag or by including the :types tag along with the
validate_query methods. Using :all will import everything from both this
module and from Params::Validate.

We set "local $Params::Validate::NO_VALIDATION = 0;" to be sure that
Params::Validate works for us, even if is globally disabled.

To alter the application flow when validation fails, we set
'error_mode()' at the last minute, and then die, so the error mode is
triggered. Other uses of error_mode() should continue to work as normal.

This module is intended to be use for simple query validation tasks,
such as a link with  query string with a small number of arguments or a page
with a few dispatched args. For larger validation tasks, especially for
processing form submissions using L<Data::FormValidator> is recommended, along
with L<CGI::Application::ValidateRM> if you're using L<CGI::Application>.

=head2 FUTURE

This concept could be extended to all check values set through
C<< $ENV{PATH_INFO} >>.

This plugin does not handle file upload validations, and won't in the
future.

Providing untainting is not a goal of this module, but if it's easy and
if someone else provides a patch, perhaps support will be added. L<Params::Validate>
provides untainting functionality and may be useful.

=head1 AUTHOR

Nate Smith C<< nate@summersault.com >>, Mark Stosberg C<< mark@summersault.com >>

=head1 BUGS & ISSUES

Please report any bugs or feature requests to
C<bug-cgi-application-plugin-validatequery at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-Application-Plugin-ValidateQuery>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2009 Summersault, LLC., all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
