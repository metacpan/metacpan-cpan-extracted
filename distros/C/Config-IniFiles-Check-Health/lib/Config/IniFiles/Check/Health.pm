package Config::IniFiles::Check::Health;
use 5.006;
use Moo 2.004000;
use strictures 2;
use namespace::clean;
use Params::Validate 1.30 qw(validate_with OBJECT SCALAR ARRAYREF UNDEF);

=head1 NAME

Config::IniFiles::Check::Health - check ini-files for needed values

=cut

our $VERSION = '0.04';

=head1 VERSION

Version 0.04

=cut

=head1 SYNOPSIS

    use Config::IniFiles::Check::Health;

    # see new()

=cut

=head1 DESCRIPTION

Config-IniFiles-Check-Health

Working with Config::IniFiles needs to check the ini-files
for 

* checking for existing, needed values in the sections
* double-vars in a single section
* do all needed sections exist

=cut

=head1 SYNOPSIS

    my $ini_fn = 'utf8convertbin.ini';
    my $ini_obj = Config::IniFiles->new( -file => $ini_fn );

    Log::Log4perl::ConfigByInifile->new(
        { ini_obj => $ini_obj, }
    );
    my $logger = get_logger();

    my $ini_health_checker_obj = Config::IniFiles::Check::Health->new({
        logger => $logger,
        ini_obj => $ini_obj
    });

    # Work to be done:
    $ini_health_checker_obj->check_inifile_for_values({
        values_must_exists => [
            { section => 'inifiles', varname => 'findus_ini_latin1_dn' },
            { section => 'inifiles', varname => 'findus_ini_utf8_dn' },
        ]
    });

    $ini_health_checker_obj->check_for_sections({
        sections_must_exist => [ qw(log4perl inifiles) ]
    });

    $ini_health_checker_obj->check_inifile_for_values({
        values_must_exists => [
            { section => 'inifiles', varname => 'findus_ini_latin1_dn' },
            { section => 'inifiles', varname => 'findus_ini_utf8_dn' },
        ]
    });

=cut

=head1 FUNCTIONS

=cut

=head2 new

    my $ini_fn = 'utf8convertbin.ini';
    my $ini_obj = Config::IniFiles->new( -file => $ini_fn );

    my $ini_health_checker_obj = Config::IniFiles::Check::Health->new({
        # Log4perl-definition is a section in the inifile
        # so: firstly undef
        logger => undef,
        ini_obj => $ini_obj
        # optional, with default value
        errors_are_fatal => 1
    });
    $ini_health_checker_obj->check_for_sections({
        sections_must_exist => [ qw(log4perl inifiles) ]
    });

    Log::Log4perl::ConfigByInifile->new(
        { ini_obj => $ini_obj, }
    );
    my $logger = get_logger();

    # Tell about our 
    $ini_health_checker_obj->logger($logger);

    $ini_health_checker_obj->check_inifile_for_values({
        values_must_exists => [
            { section => 'inifiles', varname => 'findus_ini_latin1_dn' },
            { section => 'inifiles', varname => 'findus_ini_utf8_dn' },
        ]
    });

=cut

sub BUILD {
    my $self = shift;
    $self->_check_new_params();
}

sub _check_new_params {
    my $self               = shift;
    my @all_params_must    = qw( logger ini_obj);
    my $params_wanted_href = { map { $_ => $self->$_ } @all_params_must };

    my $params_spec = {
        logger => {
            type => UNDEF | OBJECT,
        },
        ini_obj => {
            type => OBJECT,
            isa  => "Config::IniFiles"
        },
    };

    validate_with(
        params => $params_wanted_href,
        spec   => $params_spec,
    );
}

=head2 logger

You can set logger to a real Perl-Log-Objekt or to undef. This is to
starte the object and make some tests without having a log-object in
the very beginning because the log-object is built with information
from the ini-file.

    $obj->new({ logger => undef, ...})

    # Later...
    $obj->logger( Log::Log4perl::get_logger('Bla::Foo') )

=cut

has 'logger' => (
    is  => 'ro',
    isa => sub {

        # undef is ok
        if ( !defined( $_[0] ) ) {
            return;
        }
        elsif ( ref( $_[0] ) eq 'Config::IniFiles' ) {
            return;
        }
        else {
            die "logger must be undef or of type Log::Log4perl";
        }
    },
);

has 'ini_obj' => (
    is  => 'ro',
    isa => sub {
        die "ini_obj must be of type Config::IniFiles"
          unless ref( $_[0] ) eq 'Config::IniFiles';
    },
);

=head2 errors_are_fatal

You can switch behaviour of the following tests:

    $obj->errors_are_fatal(1); # default
    # There should be errors, but not die
    $obj->errors_are_fatal(0);
    $obj->check_for_duplicate_vars_in_one_section('berlin');

=cut

has 'errors_are_fatal' => (
    is      => 'rw',
    default => sub { 1 },
);

=head2 check_for_duplicate_vars_in_one_section

    $obj->check_for_duplicate_vars_in_all_sections();

=cut

sub check_for_duplicate_vars_in_all_sections {
    my $self    = shift;
    my $logger  = $self->logger;
    my $ini_obj = $self->ini_obj;
    for my $cur_section ( $ini_obj->Sections ) {
        $self->check_for_duplicate_vars_in_one_section(
            { section => $cur_section } );
    }
}

=head2 check_for_duplicate_vars_in_one_section

Try to avoid double vars entries like this:

    ; my.ini
    [berlin]
    dogs=20
    dogs=30
    cats=10

Usage:

    $obj->check_for_duplicate_vars_in_one_section({ section => 'berlin' });

=cut

sub check_for_duplicate_vars_in_one_section {
    my $self      = shift;
    my $args_href = validate_with(
        params => shift,
        spec   => {
            section => {
                type => SCALAR,
            },
        }
    );
    my $logger  = $self->logger;
    my $ini_obj = $self->ini_obj;
    my $section = $args_href->{section};
    my $log_msg;
    my $nr_of_errors = 0;

    for my $current_varname ( $ini_obj->Parameters($section) ) {

        # List context gives an element per line:
        my @all_values = $ini_obj->val( $section, $current_varname );
        if ( @all_values > 1 ) {
            $nr_of_errors++;
            $log_msg =
              sprintf "Found duplicate line in section '%s' with varname='%s'",
              $section,
              $current_varname;
            $self->_log_error($log_msg);
        }
    }

    if ( $self->errors_are_fatal && $nr_of_errors > 0 ) {
        $log_msg =
          sprintf 'Too many errors in check_for_duplicate_vars_in_section';
        $self->_log_fatal($log_msg);
    }
}

=head2 check_for_sections

    $ini_health_checker_obj->check_for_sections({
        sections_must_exist => [ qw(berlin vienna) ]
    });

=cut

sub check_for_sections {
    my $self      = shift;
    my $args_href = validate_with(
        params => shift,
        spec   => {
            sections_must_exist => {
                type => ARRAYREF,
            },
        }
    );
    my $logger              = $self->logger;
    my $ini_obj             = $self->ini_obj;
    my @sections_must_exist = @{ $args_href->{sections_must_exist} };

    my $errors_are_fatal = $args_href->{errors_are_fatal};
    my $log_msg;
    my $nr_of_errors = 0;

    for my $section_name (@sections_must_exist) {
        if ( !$ini_obj->SectionExists($section_name) ) {
            $nr_of_errors++;
            $log_msg = sprintf "Section '%s' does not exist in inifile",
              $section_name;
            $self->_log_error($log_msg);
        }
    }

    if ( $self->errors_are_fatal && $nr_of_errors > 0 ) {
        $log_msg = sprintf 'Too many errors in check_inifile_for_sections';
        $self->_log_fatal($log_msg);
    }
}

=head2 check_inifile_for_values

    $ini_health_checker_obj->check_inifiles_for_values({
        values_must_exists => [
            { section => 'bla', varname => 'nr_of_cars'},
            { section => 'bla', varname => 'nr_of_dogs'},
        ],
    });

=cut

sub check_inifile_for_values {
    my $self      = shift;
    my $args_href = validate_with(
        params => shift,
        spec   => {
            values_must_exist => {
                type => ARRAYREF,
            },
        }
    );
    my $logger            = $self->logger;
    my $ini_obj           = $self->ini_obj;
    my @values_must_exist = @{ $args_href->{values_must_exist} };
    my $errors_are_fatal  = $args_href->{errors_are_fatal};

    my $nr_of_errors = 0;
    my $log_msg;

    for my $values_must_exist_href (@values_must_exist) {
        my $section            = $values_must_exist_href->{section};
        my $varname            = $values_must_exist_href->{varname};
        my $value_from_inifile = $ini_obj->val( $section, $varname );
        if ( !defined $value_from_inifile ) {
            $nr_of_errors++;
            $log_msg =
              sprintf
"value MUST exist in inifile, but does not: section='%s', value='%s'",
              $section, $varname;
            $self->_log_error($log_msg);
        }
    }
    if ( $self->errors_are_fatal && $nr_of_errors > 0 ) {
        $log_msg = 'Too many errors in check_inifile_for_values';
        $self->_log_fatal($log_msg);
    }
}

=head2 _log_error

    $self->_log_error("Bad thing");

=cut

sub _log_error {
    my $self    = shift;
    my $log_msg = shift;
    my $logger  = $self->logger;

    if ($logger) {
        $logger->error($log_msg);
    }
    else {
        printf "ERROR - %s\n", $log_msg;
    }
}

=head2 _log_error

    if ($self->errors_are_fatal && $nr_of_errors > 0) {
        $log_msg = sprintf 'Too many errors in check_inifile_for_sections';
        $self->_log_fatal($log_msg);
    }

=cut

sub _log_fatal {
    my $self    = shift;
    my $log_msg = shift;
    my $logger  = $self->logger;

    if ($logger) {
        $logger->error($log_msg);
    }
    else {
        print "ERROR - $log_msg\n";
    }
    if ( $self->errors_are_fatal ) {
        die $log_msg;
    }
}

=head1 AUTHOR

Richard Lippmann, C<< <horshack at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-config-inifiles-check-health at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Config-IniFiles-Check-Health>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Config::IniFiles::Check::Health


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Config-IniFiles-Check-Health>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Config-IniFiles-Check-Health>

=item * Search CPAN

L<https://metacpan.org/release/Config-IniFiles-Check-Health>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2024 by Richard Lippmann.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1;

