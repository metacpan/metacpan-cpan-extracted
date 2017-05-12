package AnyEvent::Groonga::Result;
use strict;
use warnings;
use base qw( Class::Accessor::Fast );
use AnyEvent::Groonga::Result::Select;
use Data::Dumper;
use Encode;

__PACKAGE__->mk_accessors($_) for qw( data posted_command );

sub new {
    my $class = shift;
    my $self = $class->SUPER::new( {@_} );
    if ( $self->posted_command and ( $self->posted_command eq 'select' ) ) {
        return AnyEvent::Groonga::Result::Select->new( data => $self->data );
    }
    return $self;
}

sub dump {
    my $self = shift;
    {
        no warnings 'redefine';
        local *Data::Dumper::qquote = sub { return shift; };
        local $Data::Dumper::Useperl = 1;

        return encode( "utf8", decode( "utf8", Dumper( $self->data ) ) );
    }
}

sub status {
    my $self   = shift;
    my $status = $self->data->[0]->[0];
    return $status ? 0 : 1;
}

sub start_time {
    my $self = shift;
    return $self->data->[0]->[1];
}

sub elapsed {
    my $self = shift;
    return $self->data->[0]->[2];
}

sub body {
    my $self = shift;
    return $self->data->[1];
}

1;
__END__

=head1 NAME

AnyEvent::Groonga::Result - Result class for AnyEvent::Gronnga 

=head1 SYNOPSIS

  my $result = $groonga->call( $command => $args_ref )->recv;
  
  my $status     = $result->status;
  my $start_time = $result->start_time;
  my $elapsed    = $result->elapsed;
  
  print $result->body; # main body contents of result data
  
  print $result->dump; # it dumps the results by un-flagged utf8


=head1 DESCRIPTION

Result class AnyEvent::Groonga.
It is easy to use groonga results for perlish.

=head1 METHOD

=head2 new

=head2 status

=head2 start_time

=head2 elapsed

=head2 body

=head2 dump


=head1 AUTHOR

Takeshi Miki E<lt>miki@cpan.orgE<gt>


=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
