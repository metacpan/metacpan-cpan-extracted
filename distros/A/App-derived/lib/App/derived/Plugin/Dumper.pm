package App::derived::Plugin::Dumper;

use strict;
use warnings;
use parent qw/App::derived::Plugin/;
use Class::Accessor::Lite (
    rw => [qw/interval/],
);

sub init {
    my $self = shift;
    $self->interval(10) unless $self->interval;
    $self->add_worker(
        'dumper', sub {
            sleep $self->interval;
            my @keys = $self->service_keys;
            for my $key ( @keys ) {
                my $ref = $self->service_stats($key);
                print $self->json->encode([$key,$ref]), "\n"; 
            }
        }
    );
}

1;

__END__

=encoding utf8

=head1 NAME

App::derived::Plugin::Dumper - Display serialized data

=head1 SYNOPSIS

  $ derived -MDumper,interval=10 CmdsFile

=head1 DESCRIPTION

This plugin displays serialized data

=head1 ARGUMENTS

=over 4

=item interval:Int

Interval seconds to post

=back
  
=head1 SEE ALSO

<drived>, <App::derived::Plugin> for writing plugins

=head1 AUTHOR

Masahiro Nagano E<lt>kazeburo@gmail.comE<gt>

=head1 LICENSE

Copyright (C) Masahiro Nagano

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut




