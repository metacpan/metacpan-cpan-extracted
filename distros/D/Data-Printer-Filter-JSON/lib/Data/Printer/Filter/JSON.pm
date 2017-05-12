package Data::Printer::Filter::JSON;

use 5.006;
use strict;
use warnings 'all';
use Carp;

use Data::Printer::Filter qw/filter p/;
use Term::ANSIColor;

our $VERSION = '0.3';

=head1 NAME

Data::Printer::Filter::JSON - pretty-print your decoded JSON structures!

=head1 VERSION

Version 0.03

=head1 SYNOPSIS

# In your program:

    use Data::Printer filters => {
        -external => [ 'JSON' ],
    };

# or, in your C<.dataprinter> file:

    {
        filters => {
            -external => [ 'JSON' ],
        },
    };

# You can also tweak the colors:

    use Data::Printer {
        filters => {
            -external   => [ 'JSON' ],
        }, color => {
            JSON  => {
              true  => 'bright_blue on_black',
              false => 'black on_bright_blue'
            }
        },
    };

=head1 DESCRIPTION

Almost every JSON decoder on CPAN handles JavaScript's booleans with objects, and some
even reuse them in the resulting data structure. The result? A tiny JSON like this:

    {
      "alpha": true,
      "beta" : false,
      "gamma": true,
      "zeta" : false
    }

Results in this Data::Printer output:

    \ {
        alpha   JSON::XS::Boolean  {
            Parents       JSON::Boolean
            public methods (0)
            private methods (1) : __ANON__
            internals: 1
        },
        beta    JSON::XS::Boolean  {
            Parents       JSON::Boolean
            public methods (0)
            private methods (1) : __ANON__
            internals: 0
        },
        gamma   var{alpha},
        zeta    var{beta}
    }

While all I wanted was this:

    \ {
        alpha   true,
        beta    false,
        gamma   true,
        zeta    false
    }

This module fixes that! :)

=head2 Handles

L<JSON::XS> and L<JSON::PP> (L<JSON> 2.x), L<JSON::NotString> (L<JSON> 1.x),
L<JSON::DWIW>, L<JSON::Parser>, L<JSON::SL>, L<Mojo::JSON>, L<boolean> (used by
L<Pegex::JSON>) and L<JSON::JOM>.

=head3 JSON::JOM Caveat

When working with L<JSON::JOM>, make sure you load it B<after> loading L<Data::Printer>.
This is L<a known bug and B<garu>'s working on it!|https://github.com/garu/Data-Printer/issues/33>.

=head2 Can't Handle

The output of any JSON decoder that does NOT use a blessed reference for its
booleans, like L<JSON::Syck> or L<JSON::Streaming::Reader>.

=head1 AUTHOR

Nuba Princigalli <nuba@stastu.com>

=head1 CONTRIBUTORS

Tim Heaney <oylensheegul@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012, Nuba Princigalli <nuba@stastu.com>. All rights reserved.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=cut


# JSON::NotString is from JSON 1.x
# boolean is used by Pegex::JSON

for ( qw/ JSON::DWIW::Boolean JSON::NotString JSON::PP::Boolean JSON::SL::Boolean
    JSON::XS::Boolean Mojo::JSON::_Bool boolean /)
  {
    filter "$_" => 
      sub {
        my ( $obj, $p ) = @_;
        my $str;

        if ( $obj->isa('JSON::NotString') ) {
            $str = $obj->{value};
        }
        else {
            $str = $$obj == 1 ? 'true' : 'false';
        }

        my %defaults = (
            true  => 'bright_green on_black',
            false => 'bright_red on_black'
        );

        my $color = $p->{JSON}{$str};
        $color = $defaults{$str} unless defined $color;
        return colored( $str, $color );
      },
      {
        show_repeated => 1,    # handles object reuse
      };
  };

for ( qw/ JSON::JOM::Value JSON::JOM::Array JSON::JOM::Object /)
  {
    filter "$_" => 
      sub {
        my ( $obj, $p ) = @_;
        return p($obj->TO_JSON);
      };
  };
 

1;
