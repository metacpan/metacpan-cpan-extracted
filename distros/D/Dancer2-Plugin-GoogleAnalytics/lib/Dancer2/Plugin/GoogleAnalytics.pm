# ABSTRACT: A Dancer2 plugin to easily add Google Analytics code.
package Dancer2::Plugin::GoogleAnalytics;
{
  $Dancer2::Plugin::GoogleAnalytics::VERSION = '0.002';
}

use strict;
use warnings;

use Dancer2;
use Dancer2::Plugin;
use Dancer2::Core::Hook;

use Moo::Role;

with 'Dancer2::Plugin';

sub _template {
    my $account = shift;

    << "END_TAG";
<script type="text/javascript">
  var _gaq = _gaq || [];
  _gaq.push(['_setAccount', '$account']);
  _gaq.push(['_trackPageview']);

  (function() {
    var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
    ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
    var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
  })();
</script>
END_TAG

}

on_plugin_import {
    my $dsl = shift;
    my $conf = plugin_setting;

    return unless defined $conf->{account};

    if ($conf->{auto} =~ /false/msi) {
        $dsl->app->add_hook(
            Dancer2::Core::Hook->new(
                name => 'before_template_render',
                code => sub {
                    my $tokens = shift;
                    $tokens->{analytics} = _template $conf->{account};
                }
            )
        );
    }
    else {
        $dsl->app->add_hook(
            Dancer2::Core::Hook->new(
                name => 'after_layout_render',
                code => sub {
                    my $content = shift;
                    my $tag = _template $conf->{account};
                    ${$content} =~ s{</head>}{$tag</head>}msi;
                }
            )
        );
    }
};

register_plugin;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer2::Plugin::GoogleAnalytics - A Dancer2 plugin to easily add Google Analytics code.

=head1 VERSION

version 0.002

=head1 DESCRIPTION

This Dancer2 plugin adds Google Analytics code to your html. It places
the script tag containing Google Analytics code automatically before the
ending html head tag. If you want to control where to place the html script
tag set B<auto: false> in Dancer2 config.yml and use the token B<analytics>
in your template.

=head1 SYNOPSYS

    lib/Dancer.pm:

        package Dancer;
    
        use Dancer2;
        use Dancer2::Plugin::GoogleAnalytics;

    config.yml:

        plugins:
            GoogleAnalytics:
                account: "UA-XXXXX-X"

=head1 SEE ALSO

L<Dancer2> L<Dancer2::Plugins>

=head1 AUTHOR

Cesare Gargano <garcer@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Cesare Gargano.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
