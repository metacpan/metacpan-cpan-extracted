package App::Prove::Plugin::RandomSeed;
use 5.008001;
use strict;
use warnings;

use App::Prove;
use Class::Method::Modifiers qw( before );

our $VERSION = "0.01";

sub load {
    my ( $class, $p ) = @_;
    my @args = @{ $p->{args} };
    my $app  = $p->{app_prove};

    $app->shuffle(1);

    before 'App::Prove::_shuffle' => sub {
        my $seed = $args[0];
        if ( defined $seed && $seed ne '' ) {
            srand $seed;
        }
        else {
            $seed = srand;
        }

        print "Randomized with seed $seed\n";
    };
}

1;
__END__

=encoding utf-8

=head1 NAME

App::Prove::Plugin::RandomSeed - A prove plugin to get/set random seed of shuffled test.

=head1 SYNOPSIS

    # Get random seed and always set --shuffle option.
    $ prove -PRandomSeed

    # Set random seed and always set --shuffle option.
    $ prove -PRandomSeed=3470738367

=head1 DESCRIPTION

App::Prove::Plugin::RandomSeed is a prove plugin to get/set random seed of shuffled test.

This is useful for the investigation of failed test with --shuffle option.

--shuffle option is always set when you load this plugin.

=head1 LICENSE

Copyright (C) Masahiro Iuchi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Masahiro Iuchi E<lt>masahiro.iuchi@gmail.comE<gt>

=cut

