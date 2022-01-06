package Chart::GGPlot::Util::Pod;

# ABSTRACT: Dev utilities for pod-related tasks of Chart::GGPlot

use Chart::GGPlot::Setup;

our $VERSION = '0.002000'; # VERSION

use List::AllUtils qw(min);

use parent qw(Exporter::Tiny);

our @EXPORT_OK = qw(unindent layer_func_pod);

my $TMPL_COMMON_ARGS = unindent(<<'EOT');

    =item * $mapping

    Set of aesthetic mappings created by C<aes()>. If specified and
    C<$inherit_aes> is true (the default), it is combined with the default
    mapping at the top level of the plot.
    You must supply mapping if there is no plot mapping.

    =item * $data

    The data to be displayed in this layer.
    If C<undef>, the default, the data is inherited from the plot data as
    specified in the call to C<ggplot()>.

    =item * $stat

    The statistical transformation to use on the data for this layer, as a
    string.

    =item * $position

    Position adjustment, either as a string, or the result of a call to a
    position adjustment function.

    =item * $na_rm

    If false, the default, missing values are removed with a warning.
    If true, missing values are silently removed.

    =item * $show_legend

    Should this layer be included in the legends?
    C<undef>, the default, includes if any aesthetics are mapped.
    A true scalar for never includes, and a defined false scalar for always
    includes.

    =item * $inherit_aes

    If false, overrides the default aesthetics, rather than combining with them.
    This is most useful for helper functions that define both data and
    aesthetics and shouldn't inherit behaviour from the default plot
    specification.

    =item * %rest

    Other arguments passed to C<Chart::GGPlot::Layer-E<gt>new()>.
    These are often aesthetics, used to set an aesthetic to a fixed value,
    like C<color =E<gt> "red", size =E<gt> 3>.
    They may also be parameters to the paired geom/stat.

EOT

my %templates = (
    # common args used by the geom_* and stat_* functions
    TMPL_COMMON_ARGS => $TMPL_COMMON_ARGS,
);

sub x_pod {
    my ($tmpl_names) = @_;

    return sub {
        # For why unindent is needed, see
        # https://github.com/perl-pod/pod-simple/issues/95 for why
        my $text = unindent(shift);

        for my $tmpl_name (@$tmpl_names) {
            my $tmpl_text = $templates{$tmpl_name};
            die "Invalid template name $tmpl_name" unless defined $tmpl_text;

            no strict 'refs';
            $text =~ s/\%$tmpl_name\%/$tmpl_text/g;
        }
        return $text;
    };
}

*layer_func_pod = x_pod([qw(TMPL_COMMON_ARGS)]);

# got from Mojo::Util
sub unindent {
  my $str = shift;
  my $min = min map { m/^([ \t]*)/; length $1 || () } split "\n", $str;
  $str =~ s/^[ \t]{0,$min}//gm if $min;
  return $str;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Util::Pod - Dev utilities for pod-related tasks of Chart::GGPlot

=head1 VERSION

version 0.002000

=head1 DESCRIPTION

This module is for Chart::GGPlot library developers only. 

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019-2021 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
