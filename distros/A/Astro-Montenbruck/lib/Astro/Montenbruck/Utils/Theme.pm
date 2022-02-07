package Astro::Montenbruck::Utils::Theme;
use 5.22.0;
use strict;
use warnings;
no warnings qw/experimental/;
use feature qw/switch/;
use Carp qw/croak/;

use Readonly;
use Term::ANSIColor;
use Memoize;

use Astro::Montenbruck::Utils::Theme::Dark;
use Astro::Montenbruck::Utils::Theme::Light;
use Astro::Montenbruck::Utils::Theme::Colorless;

our $VERSION = 0.01;

sub new {
    my ( $class, %arg ) = @_;
    bless { 
        _name   => $arg{name}, 
        _scheme => $arg{scheme} 
    }, $class
}

sub scheme { shift->{_scheme} }

sub name { shift->{_name} }

sub decorate {
    my $self = shift;
    colored @_;
}

sub print_data {
    my $self   = shift;
    my $title  = shift;
    my $data   = shift;
    my %arg    = (title_width => 20, highlited => 0, @_);

    my $sch = $self->scheme;
    my $fmt    = '%-' . $arg{title_width} . 's';
    my $data_color = $arg{highlited} ? $sch->{data_row_selected} 
                                     : $sch->{data_row_data};
    print $self->decorate (sprintf($fmt, $title), $sch->{data_row_title});
    print $self->decorate(': ', $sch->{data_row_data});
    $data = " $data" unless $data =~ /^[-+ ].*/;
    say $self->decorate( $data, $data_color);
}

memoize('_get_theme');
sub _get_theme {
    my $name = shift;
    given($name) {
        when ('dark')  { 
            return Astro::Montenbruck::Utils::Theme::Dark->new() 
        }
        when ('light') { 
            return Astro::Montenbruck::Utils::Theme::Light->new() 
        }
        when ('colorless') { 
            return Astro::Montenbruck::Utils::Theme::Colorless->new() 
        }
    }
}

sub create {
    my $class = shift;
    my $theme = shift;
    croak "Unknown theme name: \"$theme\"" 
        unless grep /^$theme$/, qw/dark light colorless/;
    _get_theme($theme, @_);    
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME
Astro::Montenbruck::Utils::Theme - console theme

=head1 SYNOPSIS

  use Astro::Montenbruck::Utils::Theme;
  
  my $theme = Astro::Montenbruck::Utils::Theme->create('dark');
  $theme->print_data('Some Title', 'Some text');
  say $theme->decorate( sprintf('%-8s', 'Moon'), $sheme->scheme->{table_row_title} );


=head1 DESCRIPTION

Base class for a console theme. 

=head1 SUBROUTINES/METHODS

=head2 $self->print_data($title, $text, %options)

Prints title and some data in a row, colon-delimited, which is suitable 
for tabular data, e.g.:
  
  Dawn   :  07:25:56

=head3 Options

=over

=item *

B<title_width> width of title column, default: 20.

=item *

B<highlited> if true, the data column is displayed using 
$self->scheme->{data_row_selected} color. Otherwise,
$scheme->{data_row_data} is used.

=back


=head2 $self->decorate($text, $color)

In all the classes, except L<Astro::Montenbruck::Utils::Theme::Colorless>, 
colorizes the C<$text> using Ansi color symbols. C<$color> argument is one
of th constants, defined in the mentioned package.  


=head1 AUTHOR

Sergey Krushinsky, C<< <krushi at cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2022 by Sergey Krushinsky

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
