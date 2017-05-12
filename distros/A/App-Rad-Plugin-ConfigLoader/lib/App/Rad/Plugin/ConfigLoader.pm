package App::Rad::Plugin::ConfigLoader;
use strict;
use warnings;

use Config::Any;

our $VERSION = '0.01';

sub load_config {
    my ($c, @filepaths) = (@_);

    my $cfg = Config::Any->load_files({ 
                                'files' => \@filepaths,
                                'use_ext' => 1 
                           });
    foreach ( @{$cfg} ) {
        my ($filename, $config) = %{$_};
        $c->debug("loaded configuration from file '$filename'.");

        # I could just fiddle with the internals to make this
        # a little quicker, but let's stick to the API :)
        foreach my $key (keys %{$config}) {
            $c->config->{$key} = $config->{$key};
        }
    }
}

42;
__END__
=head1 NAME

App::Rad::Plugin::ConfigLoader - Load config files of various types


=head1 VERSION

Version 0.01


=head1 SYNOPSIS

    use App::Rad qw(ConfigLoader);

That's it. Now you can use the usual C<< $c->load_config() >> method to load your application's configuration file in any format supported by Config::Any (Apache-like, JSON, YAML, XML, Windows INI, etc).

    $c->load_config('somefile.yml');

Then just access its items through the regular C<< $c->config >> hash.


=head1 DESCRIPTION

Although C<< App::Rad >>'s standard C<< $c->load_config() >> method intends to be intuitive and somewhat flexible for simple configuration files, you may need something more sofisticated or standardized for your applications.

This module extends L<App::Rad>'s functionality by letting you use C<< Config::Any >> to load configuration files of various types transparently.

Please refer to L<Config::Any> for more information on acepted file formats.


=head2 Loading configuration files

This plugin overrides C<< App::Rad >>'s standard C<< $c->load_config >> methodto support different file formats according to their file extension while providing the same syntax.

=head3 $c->load_config( FILE [,FILE2, FILE3, ...] )

Different files can have different extensions and they all should load transparently in order to be accessed via C<< $c->config >>.


=head1 AUTHOR

Breno G. de Oliveira, C<< <garu at cpan.org> >>


=head1 BUGS

Please report any bugs or feature requests to C<bug-app-rad-plugin-configloader at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-Rad-Plugin-ConfigLoader>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::Rad::Plugin::ConfigLoader


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-Rad-Plugin-ConfigLoader>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-Rad-Plugin-ConfigLoader>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-Rad-Plugin-ConfigLoader>

=item * Search CPAN

L<http://search.cpan.org/dist/App-Rad-Plugin-ConfigLoader/>

=back


=head1 ACKNOWLEDGEMENTS

Many thanks to Joel Bernstein, Brian Cassidy and everyone who helped in the Config::Any module.


=head1 SEE ALSO

L<App::Rad>, L<Config::Any>.


=head1 COPYRIGHT & LICENSE

Copyright 2009 Breno G. de Oliveira, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY
         
BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
