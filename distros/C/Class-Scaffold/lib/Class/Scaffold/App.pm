use 5.008;
use warnings;
use strict;

package Class::Scaffold::App;
BEGIN {
  $Class::Scaffold::App::VERSION = '1.102280';
}

# ABSTRACT: Base class for framework applications
use Class::Scaffold::Environment;
use Property::Lookup;
use Error ':try';
use parent 'Class::Scaffold::Storable';
__PACKAGE__->mk_boolean_accessors(qw(initialized));
use IO::Handle;
STDOUT->autoflush;
STDERR->autoflush;
use constant CONTEXT => 'generic/generic';

sub app_init {
    my $self = shift;
    return if $self->initialized;    # See POD
    $self->initialized(1);
    my $configurator = Property::Lookup->instance;

    # If a subclass added a getopt configurator, we can ask it for the
    # location of the conf file, in case the user specified '--conf' on the
    # command line. If a filename is given, we'll use that conf file. If the
    # special string "local" is given, we try to find the conf file.
    # Otherwise use the one given in an environment variable.
    my $conf_file_spec = $configurator->conf || $ENV{CF_CONF} || '';

    # make a note of the configuration file spec in the configurator
    $configurator->default_layer->hash(conf_file_spec => $conf_file_spec);
    for my $conf_file (split /[:;]/, $conf_file_spec) {
        if ($conf_file eq 'local') {

            # only load if needed
            require Class::Scaffold::Introspect;
            $conf_file = Class::Scaffold::Introspect::find_conf_file();
        }
        $configurator->add_layer(file => $conf_file);
    }
    $self->log->max_level(1 + ($configurator->verbose || 0));

    # Now that we have both a getopt and a file configurator, the log file
    # name can come from either the command line (preferred) or the conf file.
    $self->log->filename($configurator->logfile)
      if defined $configurator->logfile;

    # This class subclasses Class::Scaffold::Base, which returns
    # Class::Scaffold::Environment->getenv as the default delegate. So set the
    # proper environment here and then pass the newly formed delegate the
    # configurator. The environment will make use of it in its methods.
    Class::Scaffold::Environment->setenv($configurator->environment);
    $self->delegate->setup;
    $self->delegate->configurator($configurator);
    $self->delegate->context(
        Class::Scaffold::Context->new->parse_context($self->CONTEXT));
    if ($configurator->dryrun) {
        $self->log->clear_timestamp;
        $self->delegate->set_rollback_mode;
    }
}
sub app_finish { 1 }
sub app_code   { }

sub run_app {
    my $self = shift;
    $self->app_init;
    $Error::Debug++;    # to get a stacktrace
    try {
        $self->app_code;
    }
    catch Error with {
        my $E = shift;
        $self->log->info($E->{statement})
          if ref $E eq 'Error::Hierarchy::Internal::DBI::DBH';
        $self->log->info('Application exception: %s', $E);
        $self->log->info('%s',                        $E->stacktrace);

        $self->delegate->set_rollback_mode;
    };
    $self->app_finish;
}
1;


__END__
=pod

=head1 NAME

Class::Scaffold::App - Base class for framework applications

=head1 VERSION

version 1.102280

=head1 SYNOPSIS

    use parent 'Class::Scaffold::App';

    sub app_code {
        my $self = shift;
        $self->SUPER::app_code(@_);
        # ... application-specific tasks ...
    }

    main->new->run_app;

=head1 DESCRIPTION

This is the base class for applications built with the L<Class::Scaffold>
framework, be they command-line applications or server-based applications.
Applications will subclass this class, implement their specific tasks and call
C<run_app()>.

=head1 METHODS

=head2 run_app

This is the main method that application subclasses should invoke. It calls
the other methods described here. If there is an exception, it catches and
logs it.

=head2 app_code

Called by C<run_app()> right at the beginning. Override this method in your
application-specific subclass to do any initialization your application needs.

=head2 app_finish

Called by C<run_app()> within a C<try>/C<catch>-block. Override this method to
do the actual application-specific work.

=head2 app_init

Called by C<run_app()> right before the end. Override this method to do any
cleanup your application needs.

=head2 initialized

Normally, C<app_init()> is called only once, namely, when the program
subclasses this class and does C<< main->new->run_app >>. However, if used
from within mod_perl, for example, the application is a cached object and
C<run_app()> is called repeatedly from the outside. In this case,
C<app_init()> should be called only once. We do this with the boolean flag
C<initialized()>.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see
L<http://search.cpan.org/dist/Class-Scaffold/>.

The development version lives at
L<http://github.com/hanekomu/Class-Scaffold/>.
Instead of sending patches, please fork this project using the standard git
and github infrastructure.

=head1 AUTHORS

=over 4

=item *

Marcel Gruenauer <marcel@cpan.org>

=item *

Florian Helmberger <fh@univie.ac.at>

=item *

Achim Adam <ac@univie.ac.at>

=item *

Mark Hofstetter <mh@univie.ac.at>

=item *

Heinz Ekker <ek@univie.ac.at>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2008 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

