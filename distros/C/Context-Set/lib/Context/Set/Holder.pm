package Context::Set::Holder;
use Moose::Role;
use Context::Set;

requires '_build_context';

has 'context' => ( is => 'ro' , isa => 'Context::Set' , lazy => 1, builder => '_build_context'  );

1;
__END__

=head1 NAME

Context::Holder - The role of a context holder. Just enforces the holding of a context.

=head1 SYNOPSIS

Any context holder object can access its context:

 my $o = ...
 $o->get_property('whatever');

=cut
