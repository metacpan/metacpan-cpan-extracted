package Chart::GGPlot::Theme::Functions;

# ABSTRACT: Function interface of Chart::GGPlot::Theme

use Chart::GGPlot::Setup;

our $VERSION = '0.002003'; # VERSION

use Chart::GGPlot::Theme;
use Chart::GGPlot::Types qw(:all);
use Chart::GGPlot::Util qw(:all);

use parent qw(Exporter::Tiny);

our @EXPORT_OK = qw(theme update_theme);

sub theme {
    return Chart::GGPlot::Theme->new(@_);
}

fun update_theme(Theme $old_theme, Theme $new_theme) {
    # If newtheme is a "complete" theme, then it is meant to replace
    # oldtheme; this function just returns newtheme.
    return $new_theme if ($new_theme->complete);

    # These are elements in newtheme that aren't already set in oldtheme.
    # They will be pulled from the default theme.
    my $new_items = aref_diff($old_theme->names, $new_theme->names);
    for my $name (@$new_items) {
        $old_theme->set($name, $ggplot_global->theme_current->at($name));
    }

    my $old_validate = $old_theme->validate;
    my $new_validate = $new_theme->validate;
    $old_theme->validate = ($old_validate and $new_validate);

    return $old_theme->add_theme($new_theme);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Theme::Functions - Function interface of Chart::GGPlot::Theme

=head1 VERSION

version 0.002003

=head1 SEE ALSO

L<Chart::GGPlot::Theme>

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019-2023 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
