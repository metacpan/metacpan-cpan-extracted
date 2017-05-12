package Data::Printer::Filter::PDL;
$Data::Printer::Filter::PDL::VERSION = '0.007';
use strict;
use warnings;

use Data::Printer::Filter;
use Term::ANSIColor;

filter 'PDL', \&pdl_filter;
filter 'PDL::Char', \&pdl_filter;
filter 'PDL::Complex', \&pdl_filter;

use constant MSG_TOOLONG => 'too long to print';

sub pdl_filter {
  my ($self, $props) = @_;

  ################################################
  # Get Data, Build Structure                    #
  #   add new things as [ tag => data ] to @data #
  ################################################
  my @data;
  if($self->nelem <= $PDL::toolongtoprint) { # NOTE this logic is already in PDL, so this may be superfluous
    (my $string = $self->string) =~ s,^\n|\n$,,gs;
    # TODO if PDL::Char also show $p->PDL::string()
    push @data, [ 'Data' => color_pdl_string($props, ['magenta'], $string) ];
  } else {
    push @data, [ 'Data' => color_pdl_string($props, ['cyan'], MSG_TOOLONG) ];
  }

  # type
  push @data, [ Type => opt_colored($props, ['black on_red'], $self->type->realctype) ];

  # shape
  push @data, [ Shape => color_pdl_string($props, ['cyan'], $self->shape->string) ];

  # elements
  push @data, [ Nelem => opt_colored($props, ['bright_yellow'], $self->nelem) ];

  # min and max
  my ($min, $max) = $self->minmax;
  push @data, [ Min => opt_colored($props, ['bright_red'], $min) ];
  push @data, [ Max => opt_colored($props, ['bright_blue'], $max) ];

  # bad?
  my $bad_flag = $self->badflag;
  $self->check_badflag;
  push @data, [ Badflag => color_bad_bool($props, $bad_flag) ];
  push @data, [ 'Has Bads' =>  color_bad_bool($props, $self->badflag) ];
  $self->badflag($bad_flag);

  #####################
  # Format the Output #
  #####################
  $props ||= {};
  my $indent = defined $props->{indent} ? $props->{indent} : 4;

  my $max_tag_length = List::Util::max map { length $_->[0] } @data;
  my $tag_format = ' ' x $indent . '%-' . $max_tag_length . 's : ';
  (my $empty_tag = sprintf($tag_format, "")) =~ s,:, ,;
  my @formatted =
    map {
      $_->[1] =~ s,\n,@{[newline()]}$empty_tag,gs;
      sprintf($tag_format, $_->[0]) . $_->[1]
    }
    @data;

  my $data = ref($self) . " {" . newline();
  $data .= join newline(), @formatted;
  $data .= newline()."}";

  return $data;
};

sub color_pdl_string {
  my ($props, $color, $pdl) = @_;
  $pdl =~ s/\[(.*)\]/"[".opt_colored($props, $color, $1)."]"/eg;
  $pdl =~ s/^([^\[]+)$/opt_colored($props, $color, $1)/eg;
  $pdl =~ s/^\s*\[|\]$/opt_colored($props, ['bright_green'], $&)/emg;
  return $pdl;
}

sub color_bad_bool {
  my ($props, $bool) = @_;
  return $bool ? opt_colored($props, ['red'],"Yes") : opt_colored($props, ['green'],"No");
}

sub opt_colored {
  my $props = shift;
  my ($color, $string) = @_;
  return $string unless $props->{colored};
  colored(@_);
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Printer::Filter::PDL

=head1 VERSION

version 0.007

=head1 SYNOPSIS

    use PDL;
    use Data::Printer;

    my $pdl = sequence(10,10);
    p $pdl;

    __END__

    PDL {
        Data     : [
                    [0 1]
                    [2 3]
                   ]
        Type     : double
        Shape    : [2 2]
        Nelem    : 4
        Min      : 0
        Max      : 3
        Badflag  : No
        Has Bads : No
    }

=head1 DESCRIPTION

This module provides formatting for L<PDL> data that can be used to quickly see
the contents of a L<PDL> variable.

=head1 NAME

Data::Printer::Filter::PDL - Filter for L<Data::Printer> that handles L<PDL> data.

=head1 CONFIGURATION

Modify L<C<$PDL::toolongtoprint>|PDL::Core/PDL::toolongtoprint> to control
when the contents of piddles with many elements are displayed.

=head1 EXAMPLES

You will want to configure L<Data::Printer> to use this module by creating a
.dataprinter file in your $HOME directory:

    {
        colored => 1,
        filters => {
          -external => [ 'PDL' ],
        }
    };

If you are using this module with the plugin
L<Devel::REPL::Plugin::DataPrinter>, you may want to add the following to your
C<repl.rc> or C<.perldlrc> so that L<PDL> subclass data is displayed correctly
in L<Devel::REPL>:

    $_REPL->dataprinter_config({
        stringify => {
            'PDL::Char' => 0,
            'PDL::Complex' => 0,
        },
    });

=head1 BUGS

Report bugs and submit patches to the repository on L<GitHub|https://github.com/zmughal/Data-Printer-Filter-PDL>.

=head1 SEE ALSO

L<Data::Printer>, L<PDL>, L<Devel::REPL::Plugin::DataPrinter>

=head1 COPYRIGHT

Copyright 2013 Zakariyya Mughal.

This program is free software; you can redistribute it and/or
modify it under the terms of the Artistic License version 2.0.

=head1 ACKNOWLEDGMENTS

Thanks to Joel Berger for the L<original code|https://gist.github.com/2990606>
that this was based upon.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
