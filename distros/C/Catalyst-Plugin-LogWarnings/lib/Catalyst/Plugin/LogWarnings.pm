package Catalyst::Plugin::LogWarnings;

use warnings;
use strict;
use MRO::Compat;

=head1 NAME

Catalyst::Plugin::LogWarnings - Log perl warnings to your Catalyst log object

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

In MyApp.pm:

    use Catalyst qw/LogWarnings/;

After that, any C<warn> statement that's executed during action
processing is sent to the log C<$c->log> as a warning (instead of
being dumped to STDERR).

Example:

    package MyApp::Controller::Foo;
    sub foo : Local() { warn 'foobar!'; }
    1;

Output (if you're using the standard Catalyst::Log logger):
    
    [info] MyApp running on Catalyst 5.7001
    [warn] foobar at Foo.pm line 2

=head1 CONFIGURATION

None.

=head1 OVERRIDES

=head2 execute

Wraps C<Catalyst::execute> and catches warnings with a
C<$SIG{__WARN__}> statement.

=cut

sub execute {
    my $c = shift;
    if(eval{$c->log->can('warn')}){
	    return do {
	        local $SIG{__WARN__} = sub {
		        my $warning = shift;
		        chomp $warning;
		        $c->log->warn($warning);
	        };
	        $c->next::method(@_);
	    };
    }
    else {
	    # warn "Can't log warnings";
	    # if we can't log warnings, don't catch them
	    return $c->next::method(@_);
    }
}

=head1 AUTHOR

Jonathan Rockway, C<< <jrockway at cpan.org> >>

=head1 BUGS

Warnings are caught after perl's rewritten them, so the line number
and filename will be tacked on.

Please report any bugs or feature requests to
C<bug-catalyst-plugin-logwarnings at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Catalyst-Plugin-LogWarnings>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Catalyst::Plugin::LogWarnings

You can also look for information at:

=over 4

=item * Catalyst Project Homepage

L<http://www.catalystframework.org/>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Catalyst-Plugin-LogWarnings>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Catalyst-Plugin-LogWarnings>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Catalyst-Plugin-LogWarnings>

=item * Search CPAN

L<http://search.cpan.org/dist/Catalyst-Plugin-LogWarnings>

=back

=head1 ACKNOWLEDGEMENTS

#catalyst (L<irc://irc.perl.org/#catalyst>).

=head1 COPYRIGHT & LICENSE

Copyright 2006 Jonathan Rockway, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Catalyst::Plugin::LogWarnings
