package App::Milter::Limit::Plugin;
$App::Milter::Limit::Plugin::VERSION = '0.52';
# ABSTRACT: Milter Limit driver plugin base class

use strict;
use base 'Class::Singleton';
use App::Milter::Limit::Config;

sub _new_instance {
    my $class = shift;

    my $self = $class->SUPER::_new_instance(@_);

    $self->init(@_);

    return $self;
}


sub config_get {
    my ($self, $section, $name) = @_;

    my $conf = $section eq 'global'
             ? App::Milter::Limit::Config->global
             : App::Milter::Limit::Config->section($section);

    return $$conf{$name};
}


sub config_defaults {
    my ($self, $section, %defaults) = @_;

    App::Milter::Limit::Config->set_defaults($section, %defaults);
}


sub init {
    my $self = shift;
    die ref($self)." does not implement init()\n";
}


sub query {
    my $self = shift;
    die ref($self)." does not implement query()\n";
}

1;

__END__

=pod

=head1 NAME

App::Milter::Limit::Plugin - Milter Limit driver plugin base class

=head1 VERSION

version 0.52

=head1 SYNOPSIS

 # in your driver module:
 package App::Milter::Limit::Plugin::FooBar;

 use base 'App::Milter::Limit::Plugin';

 sub init {
     my $self = shift;

     # initialize your driver
 }

 sub query {
     my ($self, $sender) = @_;

     # hand waving

     return $message_count;
 }

=head1 DESCRIPTION

This module is the base class for C<App::Milter::Limit> backend plugins.

=head2 Required Methods

All plugins must implement at least the following methods:

=over 4

=item * init

=item * query

=back

=head1 METHODS

=head2 config_get ($section, $name)

Get a configuration value from the given section with the given name.  If
C<$section> is C<global> then the global config section is used.

=head2 config_defaults ($section, %defaults)

set default values for the given configuration section.

See: L<App::Milter::Limit::Config/set_defaults>

=head2 init

initialize the driver.  Called when the driver class is first constructed.

=head2 query ($sender)

lookup a sender, and update the counters for it.  This is called when a message
is seen for a sender.  Returns the number of messages seen for the sender in
the configured expire time period.

=head1 SOURCE

The development version is on github at L<http://github.com/mschout/milter-limit>
and may be cloned from L<git://github.com/mschout/milter-limit.git>

=head1 BUGS

Please report any bugs or feature requests to bug-app-milter-limit@rt.cpan.org or through the web interface at:
 http://rt.cpan.org/Public/Dist/Display.html?Name=App-Milter-Limit

=head1 AUTHOR

Michael Schout <mschout@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Michael Schout.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
