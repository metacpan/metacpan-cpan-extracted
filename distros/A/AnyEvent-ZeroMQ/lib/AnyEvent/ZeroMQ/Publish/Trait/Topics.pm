package AnyEvent::ZeroMQ::Publish::Trait::Topics;
BEGIN {
  $AnyEvent::ZeroMQ::Publish::Trait::Topics::VERSION = '0.01';
}
# ABSTRACT: trait to prefix a message with a topic
use Moose::Role;
use true;
use namespace::autoclean;

requires 'mangle_message';
around 'mangle_message' => sub {
    my ($orig, $self, $msg, %args) = @_;
    my $topic = delete $args{topic};
    $msg = "$topic$msg" if defined $topic;
    return $self->$orig($msg, %args);
};

__END__
=pod

=head1 NAME

AnyEvent::ZeroMQ::Publish::Trait::Topics - trait to prefix a message with a topic

=head1 VERSION

version 0.01

=head1 AUTHOR

Jonathan Rockway <jrockway@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jonathan Rockway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

