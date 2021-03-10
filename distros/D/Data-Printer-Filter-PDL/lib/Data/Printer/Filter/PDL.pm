package Data::Printer::Filter::PDL;
$Data::Printer::Filter::PDL::VERSION = '1.000';
use strict;
use warnings;

use Data::Printer::Filter;

filter 'PDL', \&pdl_filter;
filter 'PDL::Char', \&pdl_filter;
filter 'PDL::Complex', \&pdl_filter;

use constant MSG_TOOLONG => 'too long to print';

use constant COLORS => {
  filter_pdl_data_number => { fallback => 'number', color => 'magenta' },
  filter_pdl_data_brackets => { fallback => 'brackets', color => 'bright_green' },

  filter_pdl_data_message => { fallback => 'string', color => 'cyan' },

  filter_pdl_type => { fallback => 'class', color => 'black on_red' },

  filter_pdl_shape_number => { fallback => 'array', color => 'cyan' },
  filter_pdl_shape_brackets => { fallback => 'brackets', color => 'bright_green' },

  filter_pdl_nelem => { color => 'bright_yellow' },

  filter_pdl_min => { color => 'bright_red' },
  filter_pdl_max => { color => 'bright_blue' },

  filter_pdl_bad_true => { color => 'red' },
  filter_pdl_bad_false => { color => 'green' },
};

# _get_color_pair
sub _gcp {
  my ($ddp, $name) = @_;
  my $color_spec = %{ COLORS() }{$name};
  my $default_color = $color_spec->{color};
  if( exists $color_spec->{fallback} && ( my $fallback_color = $ddp->theme->color_for($color_spec->{fallback}) ) ) {
    $default_color = $fallback_color;
  }
  ( $name, $default_color );
}

sub pdl_filter {
  my ($self, $ddp) = @_;

  ################################################
  # Get Data, Build Structure                    #
  #   add new things as [ tag => data ] to @data #
  ################################################
  my @data;
  if($self->nelem <= $PDL::toolongtoprint) { # NOTE this logic is already in PDL, so this may be superfluous
    (my $string = $self->string) =~ s,^\n|\n$,,gs;
    # TODO if PDL::Char also show $p->PDL::string()
    push @data, [ 'Data' => color_pdl_string($ddp, $string, 'data') ];
  } else {
    push @data, [ 'Data' => $ddp->maybe_colorize(MSG_TOOLONG, _gcp($ddp, 'filter_pdl_data_message') ) ];
  }

  # type
  push @data, [ Type => $ddp->maybe_colorize($self->type->realctype, _gcp($ddp, 'filter_pdl_type') ) ];

  # shape
  push @data, [ Shape => color_pdl_string($ddp, $self->shape->string, 'shape') ];

  # elements
  push @data, [ Nelem => $ddp->maybe_colorize($self->nelem, _gcp($ddp, 'filter_pdl_nelem')) ];

  # min and max
  my ($min, $max) = $self->minmax;
  push @data, [ Min => $ddp->maybe_colorize($min, _gcp($ddp, 'filter_pdl_min') ) ];
  push @data, [ Max => $ddp->maybe_colorize($max, _gcp($ddp, 'filter_pdl_max') ) ];

  # bad?
  my $bad_flag = $self->badflag;
  $self->check_badflag;
  push @data, [ Badflag => color_bad_bool($ddp, $bad_flag) ];
  push @data, [ 'Has Bads' =>  color_bad_bool($ddp, $self->badflag) ];
  $self->badflag($bad_flag);

  #####################
  # Format the Output #
  #####################
  my $data = $ddp->maybe_colorize( ref($self), 'class' );
  $data .= $ddp->maybe_colorize( " {", 'brackets' );

  $ddp->indent;
  $data .= $ddp->newline();

  my $max_tag_length = List::Util::max map { length $_->[0] } @data;
  my $tag_format = $ddp->maybe_colorize( '%-' . $max_tag_length . 's' , 'hash') . ' : ';
  (my $empty_tag = sprintf($tag_format, "")) =~ s,:, ,;
  my @formatted =
    map {
      $_->[1] =~ s,\n,@{[$ddp->newline()]}$empty_tag,gs;
      sprintf($tag_format, $_->[0]) . $_->[1]
    }
    @data;

  $data .= join $ddp->newline(), @formatted;

  $ddp->outdent;
  $data .= $ddp->newline();
  $data .= $ddp->maybe_colorize( "}", 'brackets' );

  return $data;
};

sub color_pdl_string {
  my ($ddp, $pdl, $type) = @_;
  $pdl =~ s/\[(.*)\]/"[".$ddp->maybe_colorize($1, _gcp($ddp, "filter_pdl_${type}_number"))."]"/eg;
  $pdl =~ s/^([^\[]+)$/$ddp->maybe_colorize($1, _gcp($ddp, "filter_pdl_${type}_number"))/eg;
  $pdl =~ s/^\s*\[|\]$/$ddp->maybe_colorize($&, _gcp($ddp, "filter_pdl_${type}_brackets"))/emg;
  return $pdl;
}

sub color_bad_bool {
  my ($ddp, $bool) = @_;
  $ddp->maybe_colorize(
    $bool ? "Yes" : "No",
    _gcp($ddp, $bool ? 'filter_pdl_bad_true' : 'filter_pdl_bad_false' )
  )
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Printer::Filter::PDL

=head1 VERSION

version 1.000

=head1 SYNOPSIS

    use PDL;
    use Data::Printer;

    my $pdl = sequence(2,2);
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
C<.dataprinter> file in your $HOME directory:

    filters = PDL

If you are using this module with the plugin
L<Devel::REPL::Plugin::DataPrinter>, you may want to add the following to your
C<repl.rc> or C<.perldlrc> so that L<PDL> subclass data is displayed correctly
in L<Devel::REPL>:

    $_REPL->dataprinter_config({
        stringify => {
            'PDL'          => 0,
            'PDL::Char'    => 0,
            'PDL::Complex' => 0,
        },
    });

=head1 BUGS

Report bugs and submit patches to the repository on L<GitHub|https://github.com/EntropyOrg/p5-Data-Printer-Filter-PDL>.

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
