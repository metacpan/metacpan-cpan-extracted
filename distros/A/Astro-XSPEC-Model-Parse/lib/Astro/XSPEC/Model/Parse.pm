# --8<--8<--8<--8<--
#
# Copyright (C) 2010 Smithsonian Astrophysical Observatory
#
# This file is part of Astro::XSPEC::Model::Parse
#
# Astro::XSPEC::Model::Parse is free software: you can redistribute it
# and/or modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation, either version 3 of
# the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# -->8-->8-->8-->8--

use strict;
use warnings;
package Astro::XSPEC::Model::Parse;
BEGIN {
  $Astro::XSPEC::Model::Parse::VERSION = '0.01';
}

use Carp;

use IO::File;
use Text::ParseWords;
use Params::Validate qw[ :all ];

my %model_handler = (
    start => { type => CODEREF, optional => 1 },
    end   => { type => CODEREF, optional => 1 },
    );

sub new
{

    my $class = shift;

    my %par = validate( @_,
                        {
                            model => { type => HASHREF,
                                       callbacks => { 'handler' =>
                                                          sub {
                                                              pop @_;
                                                              validate( @_, \%model_handler )
                                                      }
                                       },
                                       default => {},
                            },
                            par   => { type => CODEREF, optional => 1 },
                            args  => { type => HASHREF, optional => 1 },
                            norm  => { type => SCALAR, default => 0 }, }
        );

    return bless {@_}, $class;
}

sub _handle_model {

    my ( $self, $event, $args ) = @_;

    return 1 unless defined $self->{model}->{$event};

    my $ret = eval { $self->{model}->{$event}->( $event, $args, $self->{args} ) };

    die( "error in model handler for event $event: $@\n" )
        unless defined $ret;

    return $ret;
}

sub _handle_par {

    my ( $self, $args ) = @_;

    return 1 unless defined $self->{par};

    my $ret = eval { $self->{par}->( $args, $self->{args} ) };

    die( "error in parameter handler: $@\n" )
        unless defined $ret;

    return $ret;
}

sub parse_file {

    my ( $self, $file ) = @_;

    my $fh = IO::File->new( $file )
      or croak( "$file: error opening file\n" );

    my @stanza;

    while (my $rec = $fh->getline)
    {
        chomp $rec;

        my $blank = $rec =~ /^\s*$/;

        if ( $blank )
        {
            # ignore blank lines between stanzas
            next if 0 == @stanza;
        }
        else
        {
            push @stanza, [ $fh->input_line_number, $rec ];
        }

        # if we hit a blank line, or this is the last record,
        # we're done with the current stanza; parse it.
        if ( $blank || $fh->eof )
        {
            eval { $self->_parse_stanza( \@stanza ) }
              or croak( "$file: $@\n" );

            @stanza = ();
        }

    }

    return $self;
}

sub _parse_stanza {

    my ( $self, $records ) = @_;

    # first line is the model spec
    my ( $lineno, $record ) = @{ shift @{ $records }  };
    my @fields = split( ' ', $record );

    die( "$lineno: syntax error in first line of stanza: $record")
        unless @fields >= 6;

    my %model;

    @model{ qw[ name npars elo ehi subname type calcvar forcecalc ] } = @fields;

    # delete undefined parameters
    delete @model{ grep { ! defined $model{$_} } keys %model };

    $self->_handle_model( 'start', \%model ) or return;

    # now grab the individual parameters
    my @pars;
    for my $par ( 1..$model{npars} )
    {
        my %par;
        my $rec = shift @{ $records };

        my ( $lineno, $record ) = @$rec;

        my @fields = Text::ParseWords::parse_line( qr/\s+/, 0, $record );

        my $name = shift @fields;
        if ( $name =~ /^\*(.*)/ )
        {
            $par{type} = 'scale';
            $par{name} = $1;
            $par{units} = shift @fields;
            $par{value} = shift @fields;
        }

        elsif( $name =~ /^\$(.*)/ )
        {
            $par{type} = 'switch';
            $par{name} = $1;
            $par{units} = shift @fields
                if @fields == 7;

            $par{value} = shift @fields;

            @par{ qw( hard_min soft_min soft_max hard_max delta ) } = @fields
                if @fields == 5;
        }

        else
        {
            $par{type} = 'variable';
            $par{name} = $name;
            @par{ qw( units value hard_min soft_min soft_max hard_max delta periodic ) }
            = @fields;
        }

        # make sure we delete any undefined ones
        delete @par{ grep { ! defined $par{$_} } keys %par };

        $self->_handle_par( \%par );
    }

    if ( @$records )
    {
        die( "$records->[0][0]: extra records in stanza\n" )
    }

    if ( $model{type} eq 'add' && $self->{norm} )
    {
        $self->_handle_par(
            {
                type => 'variable',
                name => 'norm',
                value => 1,
                delta => 0.01,
                hard_min => 0.0,
                soft_min => 0.0,
                soft_max => 1e+24,
                hard_max => 1e+24,
            }) or return;
    }

    $self->_handle_model( 'end', \%model ) or return;

    return 1;
}


1;

__END__

=pod

=for test_synopsis
  no strict 'vars';

=head1 NAME

Astro::XSPEC::Model::Parse - parse an XSPEC model.dat file

=head1 VERSION

version 0.01

=head1 SYNOPSIS

  $parser = Astro::XSPEC::Model::Parse->new(
    model => { start => \&model_start_handler,
               end   => \&model_end_handler,
             },
    par => \&par_handler,
    args => \%myargs,
  );

  $parser->parse_file( $file );

=head1 DESCRIPTION

B<Astro::XSPEC::Model::Parse> is an event driver parser for XSPEC
F<model.dat> model description files.

=head2  Methods

=over

=item new

  $parser = Astro::XSPEC::Model::Parse->new( %args );

This constructs a new parser.  It takes the following optional named
arguments:

=over

=item model

This is a hash which may contain one or more of the
following optional entries:

=over

=item start

This is a subroutine reference which will be called for each model
before the model's parameters are parsed.

=item end

This is a subroutine reference which will be called for each model,
after the model's parameters are parsed.

=back

=item par

This is a subroutine reference which will be called for each parameter.

=item args

This is a hashref containing arbitrary data which will be passed to
each handler.

=item norm

If a model is additive and this parameter is true, add a C<norm>
parameter to the model.

=back

=item parse_file

  $parser->parse_file( $filename );

Parses the file associated with the specified filename.

=back

=head2 Handlers

Handlers are called at the beginning and end of each model definition
and for each model parameter.  A handler is called only if defined.
Hashes passed to the handler are not reused and may be stashed.

=over

=item model handlers

The model handlers are called as

  handler( $event, \%event_info, \%user_args );

where C<$event> is either C<start> or C<end>, C<%event_info> contains
the event specific information, and C<%user_args> is the C<%args>
parameter passed in the parser constructor.

C<%event_info> may contain one or more of the following fields:

=over

=item name

model name

=item npars

number of parameters

=item elo, ehi

the low and high energies for which the model is valid

=item subname

the name of the subroutine

=item type

the type of model (C<add>, C<mul>, C<mix>, or C<con>, or C<acn>)

=item calcvar

true if the model variances are calculated by the model function

=item forcecalc

true if if the model should be forced to perform a calculation for each spectrum.

=back

=item parameter handler

The parameter handler is called as

  handler( \%par_info, \%user_args );

where C<%par_info> contains the parameter specific information, and
C<%user_args> is the C<%args> parameter passed in the parser
constructor.

The fields in C<%par_info> will vary depending upon the type of
parameter.  The possible fields are:

=over

=item type

=item name

=item units

=item value

=item hard_min, hard_max

=item soft_min, soft_max

=item delta

=item periodic

=back

=back

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010 The Smithsonian Astrophysical Observatory

Astro::XSPEC::Model::Parse is free software: you can redistribute it
and/or modify it under the terms of the GNU General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=head1 AUTHOR

Diab Jerius  E<lt>djerius@cpan.orgE<gt>