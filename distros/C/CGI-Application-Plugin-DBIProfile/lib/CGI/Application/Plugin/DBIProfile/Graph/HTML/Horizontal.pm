package CGI::Application::Plugin::DBIProfile::Graph::HTML::Horizontal;

###############################################################################
# Required inclusions.
###############################################################################
use strict;
use warnings;
use HTML::Template;
use List::Util qw(max);

###############################################################################
# Set up the colours we use for the bar graphs and the row backgrounds.
###############################################################################
my @COLOURS = qw(
    2856E0  8DA6F0  C5D1F7  445896  222C4B  687AB0  9FA9C8
    FFAB2E  FFD596  FFEACB  AA854D  554227  BFA071  DFCDB1
    );
my @ROW_BGS = qw(
    FFFFFF  EEEEFF
    );

###############################################################################
# Subroutine:   build_graph($self, %opts)
# Parameters:   $self       - CAP::DBIProfile object
#               %opts       - Graphing options
###############################################################################
# Builds a horizontal bar graph based on the provided '%opts', and returns the
# HTML for that graph back to the caller.
###############################################################################
sub build_graph {
    my ($self, %opts) = @_;
    my $data = $opts{'data'};
    my $tags = $opts{'tags'};

    # calculate widths for the bar graphs
    my $max    = max( @{$data} ) || 1;
    my @widths = map { ($_ / $max) * 300 } @{$data};

    # assemble data set for HTML::Template
    my $cols = [
        map { { 'width'     => $widths[$_],
                'value'     => $data->[$_],
                'tag'       => $tags->[$_],
                'colour'    => $COLOURS[ $_ % scalar @COLOURS ],
                'row_bg'    => $ROW_BGS[ $_ % scalar @ROW_BGS ],
            } }
        (0 .. $#widths)
        ];

    # template body
    my $body = q{
<table width="400" border="0" cellpadding="2" cellspacing="0" style="font-size: 0.75em">
  <tbody>
    <tmpl_loop name="cols">
      <tr style="background-color: #<tmpl_var name="row_bg">">
        <td width="20"  align="left" ><tmpl_var name="tag"></td>
        <td width="300" align="left" ><div style="background-color: #<tmpl_var name="colour">; width: <tmpl_var name="width">px;">&nbsp;</div></td>
        <td width="80"  align="right"><tmpl_var name="value"></td>
      </tr>
    </tmpl_loop>
  </tbody>
</table>
};

    # generate report using HTML::Template
    my $tmpl = HTML::Template->new(
                die_on_bad_params => 1,
                loop_context_vars => 1,
                scalarref         => \$body,
                );
    $tmpl->param('cols', $cols);
    return $tmpl->output();
}

1;

=head1 NAME

CGI::Application::Plugin::DBIProfile::Graph::HTML::Horizontal - Horizontal bar graph for CAP::DBIProfile

=head1 SYNOPSIS

  # In startup.pl, or your CGI::Application class
  BEGIN {
      $ENV{'CAP_DBIPROFILE_GRAPHMODULE'} = 'CGI::Application::Plugin::DBIProfile::Graph::HTML::Horizontal';
  };

=head1 DESCRIPTION

C<CGI::Application::Plugin::DBIProfile::Graph::HTML::Horizontal> implements a
basic/simple horizontal bar graph for C<CGI::Application::Plugin::DBIProfile>.

=head1 AUTHOR

Graham TerMarsch (cpan@howlingfrog.com)

=head1 COPYRIGHT

Copyright (C) 2007, Graham TerMarsch.  All Rights Reserved.

This is free software; you can redistribute it and/or modify it under the same
license as Perl itself.

=head1 SEE ALSO

L<CGI::Application::Plugin::DBIProfile>,
L<CGI::Application::Plugin::DBIProfile::Graph::HTML>.

=cut

