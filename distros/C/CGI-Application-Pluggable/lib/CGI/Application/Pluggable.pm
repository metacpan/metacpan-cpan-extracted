package CGI::Application::Pluggable;

use strict;
use warnings;
use base 'CGI::Application';
use UNIVERSAL::require '0.10';
our $VERSION = '0.03';

sub import {
    my ( $self, @options ) = @_;
    my $caller = caller(0);

    {
        no strict 'refs';
        push @{"$caller\::ISA"}, $self;
    }

    for my $option ( @options ) {
        if ( ref $option eq 'HASH') {
            my ($plugin,$imports) = each(%{$option});
            my $plaggable = $self->_mk_plugin_name($plugin);
            $plaggable->use( @{$imports} ) or die $@;
        }
        else {
            my $plaggable = $self->_mk_plugin_name($option);
            $plaggable->use or die $@;
        }
   }
}

sub _mk_plugin_name {
    my $self = shift;
    my $name = shift;
    return "CGI::Application::Plugin::$name";
}

1;

=head1 NAME

CGI::Application::Pluggable - support to many plugin install.

=head1 VERSION

This documentation refers to CGI::Application::Pluggable version 0.03

=head1 SYNOPSIS

    use CGI::Application::Pluggable 
        qw/TT LogDispatch DebugScreen Session Redirect Forward/,
        {'Config::YAML' => [ qw/
            config_file
            config_param
            config
        / ]},
    ;

=head1 DESCRIPTION

CAP::Pluggable is auto install many plugin.

This only has to do use
 though use base is done when CGI::Application is used usually.

=head1 DEPENDENCIES

L<strict>

L<warnings>

L<CGI::Application>

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.
Please report problems to Atsushi Kobayashi (E<lt>nekokak@cpan.orgE<gt>)
Patches are welcome.

=head1 SEE ALSO

L<strict>

L<warnings>

L<CGI::Application>

=head1 AUTHOR

Atsushi Kobayashi, E<lt>nekokak@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Atsushi Kobayashi (E<lt>nekokak@cpan.orgE<gt>). All rights reserved.

This library is free software; you can redistribute it and/or modify it
 under the same terms as Perl itself. See L<perlartistic>.

=cut
