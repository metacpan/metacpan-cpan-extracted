package Mojolicious::Plugin::MoreTagHelpers;

use strict;
use warnings;

use base 'Mojolicious::Plugin';

use Mojo::ByteStream;

sub register {
    my ($self, $app) = @_;

    $app->renderer->add_helper(
        select_tag => sub {
            my ($c, $name, $options, $selected) = @_;
            $selected ||= "";

            my $opts = join("",
                            map {
                                qq(<option name="$_") .
                                    ($_ eq $selected ?
                                            qq(selected="selected") : "") .
                                    qq(>$_</option>)
                            } @$options);
            return Mojo::ByteStream->new(qq(<select name="$name">$opts</select>));
        }
    );
}

1;
