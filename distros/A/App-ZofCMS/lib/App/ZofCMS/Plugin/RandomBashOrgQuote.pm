package App::ZofCMS::Plugin::RandomBashOrgQuote;

use warnings;
use strict;

our $VERSION = '1.001007'; # VERSION

use WWW::BashOrg;

sub new { bless {}, shift }

sub process {
    my ( $self, $t ) = @_;

    my $b = WWW::BashOrg->new;
    my $quote = $b->random;

    $t->{t}{plug_random_bash_org_quote} = $quote ? $quote : "Error: " . $b->error;
}

1;
__END__

=encoding utf8

=head1 NAME

App::ZofCMS::Plugin::RandomBashOrgQuote - tiny plugin to fetch random quotes from http://bash.org/

=head1 SYNOPSIS

Include the plugin

    plugins => [
        qw/RandomBashOrgQuote/
    ],

In HTML::Template file:

    <pre><tmpl_var escape='html' name='plug_random_bash_org_quote'></pre>

=head1 DESCRIPTION

The module is a plugin for L<App::ZofCMS> that provides means to fetch a random
quote from L<http://bash.org/>.

This documentation assumes you've read L<App::ZofCMS>, L<App::ZofCMS::Config> and
L<App::ZofCMS::Template>

=head1 TO RUN THE PLUGIN

    plugins => [
        qw/RandomBashOrgQuote/
    ],

Unlike many other plugins, this plugin does not have any configuration options and will
run if it's included in the list of plugins to run.

=head1 OUTPUT

    <pre><tmpl_var escape='html' name='plug_random_bash_org_quote'></pre>

Plugin will set C<< $t->{t}{plug_random_bash_org_quote} >> to the fetched random quote
or to an error message if an error occured; in case of an error the message will be prefixed
with C<Error:> (in case you wanna mingle with that).

=head1 REPOSITORY

Fork this module on GitHub:
L<https://github.com/zoffixznet/App-ZofCMS>

=head1 BUGS

To report bugs or request features, please use
L<https://github.com/zoffixznet/App-ZofCMS/issues>

If you can't access GitHub, you can email your request
to C<bug-App-ZofCMS at rt.cpan.org>

=head1 AUTHOR

Zoffix Znet <zoffix at cpan.org>
(L<http://zoffix.com/>, L<http://haslayout.net/>)

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the C<LICENSE> file included in this distribution for complete
details.

=cut